module SunVox
  # High-level wrapper around a tracker pattern inside a `SunVox::Slot`.
  struct Pattern
    getter slot : Slot
    getter id : Int32

    def initialize(@slot : Slot, @id : Int32)
    end

    # Returns the integer pattern ID.
    def to_i : Int32
      @id
    end

    # Returns true if this pattern slot is non-empty (`lines > 0`).
    def exists? : Bool
      lines > 0
    end

    # Gets the pattern's name.
    def name : String
      SunVox.get_pattern_name(@slot, @id)
    end

    # Sets the pattern's name.
    def name=(new_name : String) : String
      SunVox.set_pattern_name(@slot, @id, new_name)
      new_name
    end

    # Gets the pattern's X position (start line number on the timeline).
    def x : Int32
      SunVox.get_pattern_x(@slot, @id)
    end

    # Gets the pattern's Y position (vertical position on the timeline).
    def y : Int32
      SunVox.get_pattern_y(@slot, @id)
    end

    # Gets the pattern's `{x, y}` coordinates on the timeline.
    def xy : NamedTuple(x: Int32, y: Int32)
      {x: x, y: y}
    end

    # Sets the pattern's `(x, y)` coordinates on the timeline.
    def set_xy(x : Int32, y : Int32) : self
      SunVox.set_pattern_xy(@slot, @id, x, y)
      self
    end

    # Sets the pattern's X coordinate (start line on timeline).
    def x=(new_x : Int32) : Int32
      set_xy(new_x, y)
      new_x
    end

    # Sets the pattern's Y coordinate on the timeline.
    def y=(new_y : Int32) : Int32
      set_xy(x, new_y)
      new_y
    end

    # Gets the number of tracks in this pattern.
    def tracks : Int32
      SunVox.get_pattern_tracks(@slot, @id)
    end

    # Gets the number of lines in this pattern.
    def lines : Int32
      SunVox.get_pattern_lines(@slot, @id)
    end

    # Resizes this pattern (`-1` leaves a dimension unchanged).
    def set_size(tracks : Int32 = -1, lines : Int32 = -1) : self
      SunVox.set_pattern_size(@slot, @id, tracks, lines)
      self
    end

    # Sets the number of tracks in this pattern.
    def tracks=(new_tracks : Int32) : Int32
      set_size(tracks: new_tracks, lines: -1)
      new_tracks
    end

    # Sets the number of lines in this pattern.
    def lines=(new_lines : Int32) : Int32
      set_size(tracks: -1, lines: new_lines)
      new_lines
    end

    # Returns true if this pattern is currently muted.
    def muted? : Bool
      SunVox.pattern_muted?(@slot, @id)
    end

    # Mutes (or unmutes) this pattern and returns its previous mute state.
    def mute!(mute : Bool = true) : Bool
      SunVox.pattern_mute(@slot, @id, mute)
    end

    # Unmutes this pattern and returns its previous mute state.
    def unmute! : Bool
      SunVox.pattern_mute(@slot, @id, false)
    end

    # Sets the mute state of this pattern.
    def muted=(mute : Bool) : Bool
      SunVox.pattern_mute(@slot, @id, mute)
      mute
    end

    # Returns all pattern events organized by track (`Array(Array(SunVox::Event))`).
    def data : Array(Array(SunVox::Event))
      SunVox.get_pattern_data(@slot, @id)
    end

    # Returns a direct mutable `Slice(LibSunVox::Event)` into the underlying SunVox pattern buffer.
    def raw_data : Slice(LibSunVox::Event)
      SunVox.get_raw_pattern_data(@slot, @id)
    end

    # Writes fields to a cell at `(track, line)`. Negative arguments leave the corresponding field unchanged.
    def set_event(track : Int32, line : Int32, note : Note | Int32 = -1, velocity : Int32 = -1, mod : Module | Int32 = -1, ctl : Int32 = -1, effect : Int32 = -1, ctl_value : Int32 = -1) : self
      nn = note.is_a?(Note) ? note.value : note
      mm = if mod.is_a?(Module)
             mod.id + 1
           elsif mod >= 0
             mod + 1
           else
             -1
           end
      ccee = if ctl >= 0 || effect >= 0
               c = ctl >= 0 ? ctl : 0
               e = effect >= 0 ? effect : 0
               (c << 8) | (e & 0xFF)
             else
               -1
             end
      SunVox.set_pattern_event(@slot, @id, track, line, nn, velocity, mm, ccee, ctl_value)
      self
    end

    # Writes a full `SunVox::Event` to the cell at `(track, line)`.
    def set_event(track : Int32, line : Int32, event : SunVox::Event) : self
      mm = event.mod_num >= 0 ? (event.mod_num.to_i + 1) : 0
      ccee = (event.ctl.to_i << 8) | event.effect.to_i
      SunVox.set_pattern_event(@slot, @id, track, line, event.note.value, event.velocity.to_i, mm, ccee, event.ctl_value.to_i)
      self
    end

    # Reads a single column value from the cell at `(track, line)`.
    def get_event_field(track : Int32, line : Int32, column : PatternColumn | Int32) : Int32
      SunVox.get_pattern_event(@slot, @id, track, line, column)
    end

    # Reads the full `SunVox::Event` at `(track, line)`.
    def event(track : Int32, line : Int32) : SunVox::Event
      nn = SunVox.get_pattern_event(@slot, @id, track, line, PatternColumn::Note)
      vv = SunVox.get_pattern_event(@slot, @id, track, line, PatternColumn::Velocity)
      mm = SunVox.get_pattern_event(@slot, @id, track, line, PatternColumn::Module)
      ccee = SunVox.get_pattern_event(@slot, @id, track, line, PatternColumn::CtlEffect)
      xxyy = SunVox.get_pattern_event(@slot, @id, track, line, PatternColumn::CtlValue)

      SunVox::Event.new(
        SunVox::Note.new(nn),
        vv.to_u8,
        mm.to_i16 - 1_i16,
        ((ccee >> 8) & 0xFF).to_u8,
        (ccee & 0xFF).to_u8,
        xxyy.to_u16
      )
    end

    # Reads the `SunVox::Event` at `(track, line)`.
    def [](track : Int32, line : Int32) : SunVox::Event
      event(track, line)
    end

    # Writes `event` to the cell at `(track, line)`.
    def []=(track : Int32, line : Int32, event : SunVox::Event) : SunVox::Event
      set_event(track, line, event)
      event
    end

    # Removes this pattern from its slot.
    def remove! : Nil
      SunVox.remove_pattern(@slot, @id)
    end
  end
end

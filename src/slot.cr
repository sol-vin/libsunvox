module SunVox
  # The slots SunVox can use. MAX: 16
  enum Slot
    Zero
    One
    Two
    Three
    Four
    Five
    Six
    Seven
    Eight
    Nine
    Ten
    Eleven
    Twelve
    Thirteen
    Fourteen
    Fifteen

    # Converts an integer index (0..15) into a `Slot`, raising if out of range.
    def self.from_int(in_int : Int) : Slot
      if (in_int < 0) || (in_int > (MAX_SLOTS - 1))
        raise Exception.new("Slot out of range of #{MAX_SLOTS}, was #{in_int}")
      end

      Slot.new(in_int.to_i)
    end

    # Instance-level helper preserved for backwards compatibility.
    def from_int(in_int : Int) : Slot
      Slot.from_int(in_int)
    end

    # Opens a slot (defaults to `Slot::Zero`) and returns it.
    def self.open(slot : Slot | Int = Slot::Zero) : Slot
      resolved = slot.is_a?(Slot) ? slot : from_int(slot)
      SunVox.open_slot(resolved)
    end

    # Opens a slot, yields it to the block, and ensures it is closed afterwards.
    def self.open(slot : Slot | Int = Slot::Zero, & : Slot ->)
      resolved = open(slot)
      begin
        yield resolved
      ensure
        resolved.close if resolved.open?
      end
    end

    # Opens this slot in the SunVox engine.
    def open : self
      SunVox.open_slot(self)
      self
    end

    # Closes this slot in the SunVox engine.
    def close : Nil
      SunVox.close_slot(self)
    end

    # Returns true if this slot is currently open.
    def open? : Bool
      SunVox.slot_open?(self)
    end

    # Locks this slot for thread-safe access/modification.
    def lock : Nil
      SunVox.lock_slot(self)
    end

    # Unlocks this slot.
    def unlock : Nil
      SunVox.unlock_slot(self)
    end

    # Locks this slot, yields `self`, and unlocks in an `ensure` block.
    def synchronize(&)
      lock
      begin
        yield self
      ensure
        unlock
      end
    end

    # Loads a project file (`.sunvox`, `.mod`, `.xm`) from disk into this slot.
    def load(filename : String | Path) : self
      SunVox.load(self, filename.to_s)
      self
    end

    # Loads a project from a memory buffer (`Bytes`) into this slot.
    def load(data : Bytes) : self
      SunVox.load_from_memory(self, data)
      self
    end

    # Alias for `#load(data : Bytes)`.
    def load_from_memory(data : Bytes) : self
      SunVox.load_from_memory(self, data)
      self
    end

    # Saves the current project in this slot to a file on disk.
    def save(filename : String | Path) : self
      SunVox.save(self, filename.to_s)
      self
    end

    # Saves the current project in this slot to a `Bytes` buffer in memory.
    def save_to_bytes : Bytes
      SunVox.save_to_memory(self)
    end

    # Alias for `#save_to_bytes`.
    def save_to_memory : Bytes
      SunVox.save_to_memory(self)
    end

    # Plays the current project from the current playhead position.
    def play : self
      SunVox.play(self)
      self
    end

    # Plays the current project from the beginning (line 0).
    def play_from_beginning : self
      SunVox.play_from_beginning(self)
      self
    end

    # Stops playback (second call puts all modules into standby mode).
    def stop : self
      SunVox.stop(self)
      self
    end

    # Pauses the audio stream on this slot.
    def pause : self
      SunVox.pause(self)
      self
    end

    # Resumes the audio stream on this slot.
    def resume : self
      SunVox.resume(self)
      self
    end

    # Waits for sync (pattern effect 0x33) and resumes the audio stream on this slot.
    def sync_resume : self
      SunVox.sync_resume(self)
      self
    end

    # Returns true if autostop is enabled (song stops at end instead of looping).
    def autostop? : Bool
      SunVox.autostop?(self)
    end

    # Enables or disables autostop on this slot.
    def autostop=(enabled : Bool) : Bool
      SunVox.set_autostop(self, enabled)
      enabled
    end

    # Returns whether the song repeats (i.e. autostop is disabled).
    def repeats? : Bool
      !SunVox.autostop?(self)
    end

    # Sets whether the song repeats when the end is reached.
    def repeats=(repeat : Bool) : Bool
      SunVox.set_autostop(self, !repeat)
      repeat
    end

    # Returns true if the song has stopped / finished playing.
    def end_of_song? : Bool
      SunVox.end_of_song?(self)
    end

    # Returns true if the song is currently playing.
    def playing? : Bool
      !end_of_song?
    end

    # Jumps the playhead to `line_num`.
    def rewind(line_num : Int32) : self
      SunVox.skip_to_line(self, line_num)
      self
    end

    # Alias for `#rewind`.
    def skip_to_line(line_num : Int32) : self
      rewind(line_num)
    end

    # Gets the current volume of this slot (0..256).
    def volume : Int32
      SunVox.get_volume(self)
    end

    # Sets the volume of this slot (0..256) and returns the previous volume.
    def volume(vol : Int) : Int32
      SunVox.volume(self, vol)
    end

    # Sets the volume of this slot (0..256).
    def volume=(vol : Int)
      SunVox.volume(self, vol)
    end

    # Gets the current line number on the timeline.
    def current_line : Int32
      SunVox.get_current_line(self)
    end

    # Gets the current line number in fixed-point 27.5 format.
    def current_line2 : Int32
      SunVox.get_current_line2(self)
    end

    # Gets the current line number as a floating-point value.
    def current_line_float : Float64
      current_line2 / 32.0
    end

    # Gets the current real-time output signal level (0..255) for `channel` (0 = left, 1 = right).
    def signal_level(channel : Int32 = 0) : Int32
      SunVox.get_current_signal_level(self, channel)
    end

    # Gets the project/song name.
    def name : String
      SunVox.get_song_name(self)
    end

    # Alias for `#name`.
    def song_name : String
      name
    end

    # Sets the project/song name.
    def name=(new_name : String) : String
      SunVox.set_song_name(self, new_name)
      new_name
    end

    # Alias for `#name=`.
    def song_name=(new_name : String) : String
      self.name = new_name
    end

    # Gets the SunVox version used to create the project.
    def base_version : Int32
      SunVox.get_base_version(self)
    end

    # Gets the project BPM (Beats Per Minute).
    def bpm : Int32
      SunVox.get_song_bpm(self)
    end

    # Gets the project TPL (Ticks Per Line).
    def tpl : Int32
      SunVox.get_song_tpl(self)
    end

    # Gets the project length in audio frames.
    def length_frames : UInt32
      SunVox.get_song_length_frames(self)
    end

    # Gets the project length in tracker lines.
    def length_lines : UInt32
      SunVox.get_song_length_lines(self)
    end

    # Gets the approximate duration of the project.
    def duration : Time::Span
      SunVox.get_song_length(self)
    end

    # Gets the project time map for `len` lines starting at `start_line`.
    def time_map(start_line : Int32 = 0, len : Int32 = length_lines.to_i, flags : TimeMapFlags | Int32 = TimeMapFlags::Speed) : Slice(UInt32)
      SunVox.time_map(self, start_line, len, flags.to_i)
    end

    # Sets the timestamp for subsequent events sent to this slot.
    def set_event_time(timestamp : UInt32 = 0_u32, set : Bool = true) : self
      SunVox.set_event_time(self, timestamp, set)
      self
    end

    # Resets event timing on this slot back to automatic mode.
    def reset_event_time : self
      SunVox.set_event_time(self, 0_u32, false)
      self
    end

    # Sends a real-time event to this slot.
    def send_event(track_num : Int32, note : Note | Int32 = Note::None, velocity : Int32 = 0, mod : Module | Int32 = -1, ctl : Int32 = 0, effect : Int32 = 0, ctl_value : Int32 = 0) : self
      mod_id = mod.is_a?(Module) ? mod.id : mod
      SunVox.send_event(self, track_num, note.is_a?(Note) ? note.value : note, velocity, mod_id, ctl, effect, ctl_value)
      self
    end

    # Sends a `SunVox::Event` record to `track_num` on this slot.
    def send_event(track_num : Int32, event : Event) : self
      SunVox.send_event(self, track_num, event)
      self
    end

    # Returns the built-in Output module (module 0) for this slot.
    def output : Module
      Module.new(self, OUTPUT_MODULE)
    end

    # Creates a new module in this slot and returns its `SunVox::Module` wrapper.
    def add_module(type : ModuleType | String, name : String = "", x : Int32 = 512, y : Int32 = 512, z : Int32 = 0) : Module
      mod_type = type.is_a?(ModuleType) ? type : ModuleType.new(type)
      mod_id = SunVox.new_module(self, mod_type, name, x, y, z)
      Module.new(self, mod_id)
    end

    # Alias for `#add_module`.
    def new_module(type : ModuleType | String, name : String = "", x : Int32 = 512, y : Int32 = 512, z : Int32 = 0) : Module
      add_module(type, name, x, y, z)
    end

    # Loads a module or sample from a file (`sunsynth`, `xi`, `wav`, `aiff`, `ogg`, `mp3`, `flac`) and returns a `SunVox::Module`.
    def load_module(filename : String | Path, x : Int32 = 512, y : Int32 = 512, z : Int32 = 0) : Module
      mod_id = SunVox.load_module(self, filename.to_s, x, y, z)
      Module.new(self, mod_id)
    end

    # Loads a module or sample from memory (`Bytes`) and returns a `SunVox::Module`.
    def load_module(data : Bytes, x : Int32 = 512, y : Int32 = 512, z : Int32 = 0) : Module
      mod_id = SunVox.load_module_from_memory(self, data, x, y, z)
      Module.new(self, mod_id)
    end

    # Alias for `#load_module(data : Bytes, ...)`.
    def load_module_from_memory(data : Bytes, x : Int32 = 512, y : Int32 = 512, z : Int32 = 0) : Module
      load_module(data, x, y, z)
    end

    # Returns a `SunVox::Module` handle for `id`.
    def module(id : Int32) : Module
      Module.new(self, id)
    end

    # Finds a module by name and returns its `SunVox::Module`, raising if not found.
    def module(name : String) : Module
      find_module(name) || raise Exception.new("Module '#{name}' not found on slot #{self}")
    end

    # Returns a `SunVox::Module` for `id` if it exists in this slot, or `nil`.
    def module?(id : Int32) : Module?
      return nil if id < 0 || id >= module_slots_count
      mod = Module.new(self, id)
      mod.exists? ? mod : nil
    end

    # Finds a module by name and returns it, or `nil` if not found.
    def module?(name : String) : Module?
      find_module(name)
    end

    # Finds a module by name and returns it, or `nil` if not found.
    def find_module(name : String) : Module?
      id = SunVox.find_module(self, name)
      id >= 0 ? Module.new(self, id) : nil
    end

    # Returns the number of module slots in the project (some slots may be empty).
    def module_slots_count : Int32
      SunVox.get_number_of_modules(self)
    end

    # Returns all active modules currently existing in this slot.
    def modules : Array(Module)
      result = [] of Module
      module_slots_count.times do |id|
        mod = Module.new(self, id)
        result << mod if mod.exists?
      end
      result
    end

    # Creates a new pattern in this slot and returns its `SunVox::Pattern` wrapper.
    def new_pattern(lines : Int32 = 32, tracks : Int32 = 4, x : Int32 = 0, y : Int32 = 0, name : String = "", clone : Pattern | Int32 = -1, icon_seed : Int32 = 0) : Pattern
      clone_id = clone.is_a?(Pattern) ? clone.id : clone
      pat_id = SunVox.new_pattern(self, clone_id, x, y, tracks, lines, icon_seed, name)
      Pattern.new(self, pat_id)
    end

    # Alias for `#new_pattern`.
    def add_pattern(lines : Int32 = 32, tracks : Int32 = 4, x : Int32 = 0, y : Int32 = 0, name : String = "", clone : Pattern | Int32 = -1, icon_seed : Int32 = 0) : Pattern
      new_pattern(lines, tracks, x, y, name, clone, icon_seed)
    end

    # Returns a `SunVox::Pattern` handle for `id`.
    def pattern(id : Int32) : Pattern
      Pattern.new(self, id)
    end

    # Finds a pattern by name and returns its `SunVox::Pattern`, raising if not found.
    def pattern(name : String) : Pattern
      find_pattern(name) || raise Exception.new("Pattern '#{name}' not found on slot #{self}")
    end

    # Returns a `SunVox::Pattern` for `id` if it exists in this slot, or `nil`.
    def pattern?(id : Int32) : Pattern?
      return nil if id < 0 || id >= pattern_slots_count
      pat = Pattern.new(self, id)
      pat.exists? ? pat : nil
    end

    # Finds a pattern by name and returns it, or `nil` if not found.
    def pattern?(name : String) : Pattern?
      find_pattern(name)
    end

    # Finds a pattern by name and returns it, or `nil` if not found.
    def find_pattern(name : String) : Pattern?
      id = SunVox.find_pattern(self, name)
      id >= 0 ? Pattern.new(self, id) : nil
    end

    # Returns the number of pattern slots in the project (some slots may be empty).
    def pattern_slots_count : Int32
      SunVox.get_number_of_patterns(self)
    end

    # Returns all active patterns currently existing in this slot.
    def patterns : Array(Pattern)
      result = [] of Pattern
      pattern_slots_count.times do |id|
        pat = Pattern.new(self, id)
        result << pat if pat.exists?
      end
      result
    end

    # Exports the project in this slot to a WAV file (requires engine started with `offline: true`).
    def export_to_wav(out_filename : String | Path, song_len_frames : Int = length_frames) : self
      SunVox.export_to_wav(self, song_len_frames, out_filename.to_s)
      self
    end
  end
end

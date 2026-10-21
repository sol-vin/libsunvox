module SunVox
  # High-level wrapper around a module controller inside a `SunVox::Module`.
  struct Controller
    getter mod : Module
    getter index : Int32

    def initialize(@mod : Module, @index : Int32)
    end

    # The slot that owns this controller's module.
    def slot : Slot
      @mod.slot
    end

    # Gets the name of this controller.
    def name : String
      SunVox.get_module_ctl_name(slot, @mod.id, @index)
    end

    # Gets the controller value according to `scaled` (`Real`, `Scaled`, or `Displayed`).
    def value(scaled : CtlScale = CtlScale::Real) : Int32
      SunVox.get_module_ctl_value(slot, @mod.id, @index, scaled)
    end

    # Gets the raw internal controller value (`CtlScale::Real`).
    def real_value : Int32
      value(CtlScale::Real)
    end

    # Gets the scaled controller value (`0x0000..0x8000` for normal controllers, `CtlScale::Scaled`).
    def scaled_value : Int32
      value(CtlScale::Scaled)
    end

    # Gets the value as displayed in the SunVox UI (`CtlScale::Displayed`).
    def display_value : Int32
      value(CtlScale::Displayed)
    end

    # Sets the controller value (using `CtlScale::Real` by default).
    def value=(val : Int32) : Int32
      set_value(val, CtlScale::Real)
      val
    end

    # Sets the controller value with an explicit scaling mode (`Real`, `Scaled`, or `Displayed`).
    def set_value(val : Int32, scaled : CtlScale = CtlScale::Real) : self
      SunVox.set_module_ctl_value(slot, @mod.id, @index, val, scaled)
      self
    end

    # Gets the minimum value of this controller.
    def min(scaled : CtlScale = CtlScale::Real) : Int32
      SunVox.get_module_ctl_min(slot, @mod.id, @index, scaled)
    end

    # Gets the maximum value of this controller.
    def max(scaled : CtlScale = CtlScale::Real) : Int32
      SunVox.get_module_ctl_max(slot, @mod.id, @index, scaled)
    end

    # Gets the valid value range (`min..max`) of this controller.
    def range(scaled : CtlScale = CtlScale::Real) : Range(Int32, Int32)
      min(scaled)..max(scaled)
    end

    # Gets the display value offset of this controller.
    def offset : Int32
      SunVox.get_module_ctl_offset(slot, @mod.id, @index)
    end

    # Gets the controller type (`CtlType::Normal` or `CtlType::Selector`).
    def type : CtlType
      SunVox.get_module_ctl_type(slot, @mod.id, @index)
    end

    # Gets the group number of this controller.
    def group : Int32
      SunVox.get_module_ctl_group(slot, @mod.id, @index)
    end
  end

  # High-level wrapper around a synth, effect, or misc module inside a `SunVox::Slot`.
  struct Module
    getter slot : Slot
    getter id : Int32

    def initialize(@slot : Slot, @id : Int32)
    end

    # Returns the integer module ID.
    def to_i : Int32
      @id
    end

    # Returns true if this is the master Output module (ID 0).
    def output_module? : Bool
      @id == OUTPUT_MODULE
    end

    # Raw bitflags for this module (`LibSunVox::MODULE_FLAG_*`).
    def flags : UInt32
      SunVox.get_module_flags(@slot, @id)
    end

    # Returns true if this module exists in the slot.
    def exists? : Bool
      SunVox.module_exists?(@slot, @id)
    end

    # Returns true if this module is a generator (Note input + Sound output).
    def generator? : Bool
      SunVox.module_generator?(@slot, @id)
    end

    # Returns true if this module is an effect (Sound input + Sound output).
    def effect? : Bool
      SunVox.module_effect?(@slot, @id)
    end

    # Returns true if this module is muted.
    def muted? : Bool
      SunVox.module_mute?(@slot, @id)
    end

    # Returns true if this module is soloed.
    def solo? : Bool
      SunVox.module_solo?(@slot, @id)
    end

    # Returns true if this module is bypassed.
    def bypass? : Bool
      SunVox.module_bypass?(@slot, @id)
    end

    # Gets the module's name.
    def name : String
      SunVox.get_module_name(@slot, @id)
    end

    # Sets the module's name.
    def name=(new_name : String) : String
      SunVox.set_module_name(@slot, @id, new_name)
      new_name
    end

    # Gets the module's type string (e.g., `"Generator"`, `"Filter Pro"`, `"Output"`).
    def type : String
      SunVox.get_module_type(@slot, @id)
    end

    # Gets the module's `{x, y}` coordinates.
    def xy : NamedTuple(x: Int32, y: Int32)
      SunVox.get_module_xy(@slot, @id)
    end

    # Gets the module's X coordinate.
    def x : Int32
      xy[:x]
    end

    # Gets the module's Y coordinate.
    def y : Int32
      xy[:y]
    end

    # Sets the module's `(x, y)` coordinates.
    def set_xy(x : Int32, y : Int32) : self
      SunVox.set_module_xy(@slot, @id, x, y)
      self
    end

    # Sets the module's X coordinate.
    def x=(new_x : Int32) : Int32
      set_xy(new_x, y)
      new_x
    end

    # Sets the module's Y coordinate.
    def y=(new_y : Int32) : Int32
      set_xy(x, new_y)
      new_y
    end

    # Gets the module's color in `0xBBGGRR` format.
    def color : Int32
      SunVox.get_module_color(@slot, @id)
    end

    # Sets the module's color in `0xBBGGRR` format.
    def color=(new_color : Int32) : Int32
      SunVox.set_module_color(@slot, @id, new_color)
      new_color
    end

    # Gets the module's color unpacked into `{r, g, b}` bytes (`0..255`).
    def rgb : NamedTuple(r: UInt8, g: UInt8, b: UInt8)
      c = color
      {
        r: (c & 0xFF).to_u8,
        g: ((c >> 8) & 0xFF).to_u8,
        b: ((c >> 16) & 0xFF).to_u8,
      }
    end

    # Sets the module's color from RGB components (`0..255`).
    def set_rgb(r : Int, g : Int, b : Int) : self
      packed = (r.to_i & 0xFF) | ((g.to_i & 0xFF) << 8) | ((b.to_i & 0xFF) << 16)
      self.color = packed
      self
    end

    # Gets both `{finetune, relative_note}` for this module.
    def finetune_info : NamedTuple(finetune: Int32, relative_note: Int32)
      SunVox.get_module_finetune(@slot, @id)
    end

    # Gets the module's finetune (`-256..256`).
    def finetune : Int32
      finetune_info[:finetune]
    end

    # Sets the module's finetune (`-256..256`) immediately.
    def finetune=(val : Int32) : Int32
      SunVox.set_module_finetune(@slot, @id, val)
      val
    end

    # Gets the module's relative note (transposition).
    def relative_note : Int32
      finetune_info[:relative_note]
    end

    # Alias for `#relative_note`.
    def relnote : Int32
      relative_note
    end

    # Sets the module's relative note (transposition) immediately.
    def relative_note=(val : Int32) : Int32
      SunVox.set_module_relnote(@slot, @id, val)
      val
    end

    # Alias for `#relative_note=`.
    def relnote=(val : Int32) : Int32
      self.relative_note = val
    end

    # Connects this module (source) to `destination` and returns `destination` for chaining.
    def connect(destination : Module) : Module
      SunVox.connect_module(@slot, @id, destination.id)
      destination
    end

    # Connects this module (source) to `destination_id` and returns the destination `Module`.
    def connect(destination_id : Int32) : Module
      connect(Module.new(@slot, destination_id))
    end

    # Chainable connection operator: `gen >> filter >> reverb >> slot.output`.
    def >>(destination : Module | Int32) : Module
      connect(destination)
    end

    # Connects this module directly to the slot's master Output module (module 0).
    def connect_to_output : Module
      connect(@slot.output)
    end

    # Disconnects this module from `destination`.
    def disconnect(destination : Module | Int32) : self
      dest_id = destination.is_a?(Module) ? destination.id : destination
      SunVox.disconnect_module(@slot, @id, dest_id)
      self
    end

    # Raw input link slot array (may contain `-1` for empty link slots).
    def raw_inputs : Slice(Int32)
      SunVox.get_module_inputs(@slot, @id)
    end

    # Raw output link slot array (may contain `-1` for empty link slots).
    def raw_outputs : Slice(Int32)
      SunVox.get_module_outputs(@slot, @id)
    end

    # Active input module IDs connected to this module.
    def input_ids : Array(Int32)
      raw_inputs.to_a.select(&.>= 0)
    end

    # Active output module IDs connected from this module.
    def output_ids : Array(Int32)
      raw_outputs.to_a.select(&.>= 0)
    end

    # Active input modules connected to this module.
    def inputs : Array(Module)
      input_ids.map { |in_id| Module.new(@slot, in_id) }
    end

    # Active output modules connected from this module.
    def outputs : Array(Module)
      output_ids.map { |out_id| Module.new(@slot, out_id) }
    end

    # Removes this module from its slot.
    def remove! : Nil
      SunVox.remove_module(@slot, @id)
    end

    # Number of controllers on this module.
    def ctl_count : Int32
      SunVox.get_number_of_module_ctls(@slot, @id)
    end

    # Returns the `Controller` at `index` (0-based).
    def ctl(index : Int32) : Controller
      Controller.new(self, index)
    end

    # Returns the `Controller` at `index` if in range, or `nil`.
    def ctl?(index : Int32) : Controller?
      (index >= 0 && index < ctl_count) ? Controller.new(self, index) : nil
    end

    # Finds a `Controller` by name (case-insensitive), or `nil` if not found.
    def ctl?(name : String) : Controller?
      ctl_count.times do |i|
        c = Controller.new(self, i)
        return c if c.name.compare(name, case_insensitive: true) == 0
      end
      nil
    end

    # Finds a `Controller` by name (case-insensitive), raising if not found.
    def ctl(name : String) : Controller
      ctl?(name) || raise Exception.new("Controller '#{name}' not found on module #{@id} (#{self.name})")
    end

    # Reads a controller value by 0-based index or name.
    def [](index_or_name : Int32 | String, scaled : CtlScale = CtlScale::Real) : Int32
      ctl(index_or_name).value(scaled)
    end

    # Sets a controller value by 0-based index or name.
    def []=(index_or_name : Int32 | String, val : Int32) : Int32
      ctl(index_or_name).value = val
    end

    # Returns all controllers on this module.
    def controllers : Array(Controller)
      Array.new(ctl_count) { |i| Controller.new(self, i) }
    end

    # Sends an event targeting this module.
    def send_event(track : Int32 = 0, note : Note | Int32 = Note::None, velocity : Int32 = 0, ctl : Int32 = 0, effect : Int32 = 0, ctl_value : Int32 = 0) : self
      SunVox.send_event(@slot, track, note.is_a?(Note) ? note.value : note, velocity, @id, ctl, effect, ctl_value)
      self
    end

    # Triggers a note on this module.
    def play_note(note : Note | Int32, track : Int32 = 0, velocity : Int32 = 129, ctl : Int32 = 0, effect : Int32 = 0, ctl_value : Int32 = 0) : self
      send_event(track, note, velocity, ctl, effect, ctl_value)
    end

    # Triggers a specific frequency (in Hz) on this module using `NOTECMD_SET_PITCH`.
    def play_frequency(freq_hz : Number, track : Int32 = 0, velocity : Int32 = 129) : self
      pitch = SunVox.frequency_to_pitch(freq_hz.to_f).round.to_i
      send_event(track, Note::SetPitch, velocity, 0, 0, pitch)
    end

    # Sends a Note Off command on `track` for this module.
    def note_off(track : Int32 = 0) : self
      send_event(track, Note::Off, 0)
    end

    # Stops this module and clears its internal buffers (`NOTECMD_CLEAN_MODULE`).
    def clean!(track : Int32 = 0) : self
      send_event(track, Note::CleanModule, 0)
    end

    # Reads oscilloscope samples (`Int16`) from this module's output.
    def scope(channel : Int32 = 0, samples_to_read : Int32 = 1024) : Slice(Int16)
      SunVox.get_module_scope(@slot, @id, channel, samples_to_read)
    end

    # Reads curve values (`Float32`) from this module.
    def curve(curve_num : Int32 = 0, length : Int32 = 257) : Slice(Float32)
      SunVox.get_module_curve(@slot, @id, curve_num, length)
    end

    # Writes curve values (`Slice(Float32)`) to this module.
    def set_curve(curve_num : Int32, data : Slice(Float32)) : Int32
      SunVox.set_module_curve(@slot, @id, curve_num, data)
    end

    # Writes curve values (`Array(Float32)`) to this module.
    def set_curve(curve_num : Int32, data : Array(Float32)) : Int32
      slice = Slice.new(data.to_unsafe, data.size)
      set_curve(curve_num, slice)
    end

    # Loads a sample file into this Sampler module (`sample_slot = -1` replaces the whole sampler).
    def sampler_load(filename : String | Path, sample_slot : Int32 = -1) : self
      SunVox.sampler_load(@slot, @id, filename.to_s, sample_slot)
      self
    end

    # Loads a sample from memory (`Bytes`) into this Sampler module.
    def sampler_load(data : Bytes, sample_slot : Int32 = -1) : self
      SunVox.sampler_load_from_memory(@slot, @id, data, sample_slot)
      self
    end

    # Gets a sample parameter from this Sampler module (`sv_sampler_par`).
    def sampler_par(par : SamplerParam | Int32, sample_slot : Int32 = 0) : Int32
      SunVox.get_sampler_par(@slot, @id, sample_slot, par)
    end

    # Sets a sample parameter on this Sampler module (`sv_sampler_par`) and returns the previous value.
    def set_sampler_par(par : SamplerParam | Int32, val : Int32, sample_slot : Int32 = 0) : Int32
      SunVox.set_sampler_par(@slot, @id, sample_slot, par, val)
    end

    # Loads a file (`sunvox`, `mod`, `xm`, `midi`) into this MetaModule.
    def metamodule_load(filename : String | Path) : self
      SunVox.metamodule_load(@slot, @id, filename.to_s)
      self
    end

    # Loads a project from memory (`Bytes`) into this MetaModule.
    def metamodule_load(data : Bytes) : self
      SunVox.metamodule_load_from_memory(@slot, @id, data)
      self
    end

    # Loads an OGG Vorbis file into this Vorbis Player module.
    def vplayer_load(filename : String | Path) : self
      SunVox.vplayer_load(@slot, @id, filename.to_s)
      self
    end

    # Loads an OGG Vorbis stream from memory (`Bytes`) into this Vorbis Player module.
    def vplayer_load(data : Bytes) : self
      SunVox.vplayer_load_from_memory(@slot, @id, data)
      self
    end
  end
end

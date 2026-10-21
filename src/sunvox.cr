require "./note"
require "./scales"
require "./macros/**"
require "./slot"
require "./module"
require "./pattern"

module SunVox
  enum SampleType
    Int16
    Float32
  end

  # Scaling modes for `get_module_ctl_value`, `set_module_ctl_value`, `get_module_ctl_min`, `get_module_ctl_max`.
  enum CtlScale
    Real      = 0
    Scaled    = 1
    Displayed = 2
  end

  # Controller types returned by `get_module_ctl_type`.
  enum CtlType
    Normal   = 0
    Selector = 1
  end

  # Sampler parameter IDs for `sampler_par` (`sv_sampler_par`).
  enum SamplerParam
    LoopBegin     = 0
    LoopLength    = 1
    LoopType      = 2
    LoopRelease   = 3
    Volume        = 4
    Panning       = 5
    Finetune      = 6
    RelativeNote  = 7
    StartPosition = 8
  end

  # Column indices for `get_pattern_event` (`sv_get_pattern_event`).
  enum PatternColumn
    Note      = 0
    Velocity  = 1
    Module    = 2
    CtlEffect = 3
    CtlValue  = 4
  end

  # Flags for `time_map` (`sv_get_time_map`).
  enum TimeMapFlags
    Speed      = 0
    FrameCount = 1
  end

  # A module that holds all the different module types, categorized as they are in the SunVox application.
  module Modules
    module Synths
      ANALOG_GENERATOR = SunVox::ModuleType.new("Analog generator")
      DRUM_SYNTH       = SunVox::ModuleType.new("DrumSynth")
      FM               = SunVox::ModuleType.new("FM")
      FMX              = SunVox::ModuleType.new("FMX")
      GENERATOR        = SunVox::ModuleType.new("Generator")
      INPUT            = SunVox::ModuleType.new("Input")
      KICKER           = SunVox::ModuleType.new("Kicker")
      VORBIS_PLAYER    = SunVox::ModuleType.new("Vorbis player")
      SAMPLER          = SunVox::ModuleType.new("Sampler")
      SPECTRAVOICE     = SunVox::ModuleType.new("SpectraVoice")
    end

    module Effects
      AMPLIFIER     = SunVox::ModuleType.new("Amplifier")
      COMPRESSOR    = SunVox::ModuleType.new("Compressor")
      DC_BLOCKER    = SunVox::ModuleType.new("DC Blocker")
      DELAY         = SunVox::ModuleType.new("Delay")
      DISTORTION    = SunVox::ModuleType.new("Distortion")
      ECHO          = SunVox::ModuleType.new("Echo")
      EQ            = SunVox::ModuleType.new("EQ")
      FFT           = SunVox::ModuleType.new("FFT")
      FILTER        = SunVox::ModuleType.new("Filter")
      FILTER_PRO    = SunVox::ModuleType.new("Filter Pro")
      FILER_PRO     = FILTER_PRO # Backwards-compatible alias for typo
      FLANGER       = SunVox::ModuleType.new("Flanger")
      LFO           = SunVox::ModuleType.new("LFO")
      LOOP          = SunVox::ModuleType.new("Loop")
      MODULATOR     = SunVox::ModuleType.new("Modulator")
      PITCH_SHIFTER = SunVox::ModuleType.new("Pitch shifter")
      REVERB        = SunVox::ModuleType.new("Reverb")
      SMOOTH        = SunVox::ModuleType.new("Smooth")
      VOCAL_FILTER  = SunVox::ModuleType.new("Vocal filter")
      VIBRATO       = SunVox::ModuleType.new("Vibrato")
      WAVESHAPER    = SunVox::ModuleType.new("WaveShaper")
    end

    module Misc
      ADSR           = SunVox::ModuleType.new("ADSR")
      CTL_2_NOTE     = SunVox::ModuleType.new("Ctl2Note")
      FEEDBACK       = SunVox::ModuleType.new("Feedback")
      GLIDE          = SunVox::ModuleType.new("Glide")
      GPIO           = SunVox::ModuleType.new("GPIO")
      METAMODULE     = SunVox::ModuleType.new("MetaModule")
      MULTICTL       = SunVox::ModuleType.new("MultiCtl")
      MULTISYNTH     = SunVox::ModuleType.new("MultiSynth")
      PITCH_2_CTL    = SunVox::ModuleType.new("Pitch2Ctl")
      PITCH_DETECTOR = SunVox::ModuleType.new("Pitch Detector")
      SOUND_2_CTL    = SunVox::ModuleType.new("Sound2Ctl")
      VELOCITY_2_CTL = SunVox::ModuleType.new("Velocity2Ctl")
    end
  end

  class ModuleType
    getter type = ""

    def initialize(@type)
    end

    def to_s(io : IO) : Nil
      io << @type
    end
  end

  record Event,
    note : SunVox::Note = SunVox::Note::None,
    velocity : UInt8 = 0_u8,
    mod_num : Int16 = -1_i16,
    ctl : UInt8 = 0_u8,
    effect : UInt8 = 0_u8,
    ctl_value : UInt16 = 0_u16

  MAX_SLOTS = 16

  CURRENT_VERSION_MAJOR  = 2
  CURRENT_VERSION_MINOR  = 1
  CURRENT_VERSION_MINOR2 = 4
  DEFAULT_CONFIG         = ""
  DEFAULT_FREQ           = 44100
  DEFAULT_CHANNELS       =     2

  OUTPUT_MODULE =  0
  NO_MODULE     = -1

  class_getter? started = false
  class_getter sample_rate = 0
  class_getter sample_size = 2
  class_getter engine_version = {major: 0, minor: 0, minor2: 0}
  BUFFER_SIZE = 1024

  @@open_slots = {} of Int32 => Slot
  class_getter? offline = false
  @@at_exit_registered = false

  # Starts up the SunVox Engine. Hooks `at_exit` to ensure `stop_engine` is run on close.
  def self.start_engine(config = DEFAULT_CONFIG, freq = DEFAULT_FREQ, channels = DEFAULT_CHANNELS, no_debug_output = false, offline = false, sample_type = SampleType::Int16, one_thread = false)
    flags = 0_u32
    flags |= LibSunVox::INIT_FLAG_NO_DEBUG_OUTPUT if no_debug_output
    flags |= LibSunVox::INIT_FLAG_OFFLINE if offline
    flags |= LibSunVox::INIT_FLAG_AUDIO_INT16 if sample_type == SampleType::Int16
    flags |= LibSunVox::INIT_FLAG_AUDIO_FLOAT32 if sample_type == SampleType::Float32
    flags |= LibSunVox::INIT_FLAG_ONE_THREAD if one_thread

    @@offline = offline
    cfg_ptr = config.empty? ? Pointer(LibC::Char).null : config.to_unsafe

    # init spits out the version number in 0xMMmm22 format
    version = LibSunVox.init(cfg_ptr, freq, channels, flags)

    @@sample_size = (sample_type == SampleType::Float32) ? 4 : 2

    if version > 0 && _check_version(version)
      @@started = true
      @@engine_version = _unpack_version(version)
      @@sample_rate = LibSunVox.get_sample_rate

      unless @@at_exit_registered
        @@at_exit_registered = true
        at_exit { stop_engine }
      end
      @@engine_version
    else
      raise Exception.new("Cannot start the SunVox Engine :( Try starting in offline mode if there is no audio device.")
    end
  end

  # Starts the SunVox Engine for the duration of the block and ensures `stop_engine` is called afterwards.
  def self.start_engine(config = DEFAULT_CONFIG, freq = DEFAULT_FREQ, channels = DEFAULT_CHANNELS, no_debug_output = false, offline = false, sample_type = SampleType::Int16, one_thread = false, &)
    start_engine(config, freq, channels, no_debug_output, offline, sample_type, one_thread)
    begin
      yield
    ensure
      stop_engine
    end
  end

  # Shuts down the engine and closes all open slots.
  def self.stop_engine
    if started?
      # Close all slots (iterate over a copy of keys since close_slot mutates @@open_slots)
      @@open_slots.values.each do |slot|
        close_slot(slot)
      end
      LibSunVox.deinit
      @@started = false
    end
  end

  # Formatted version string of the active SunVox engine (e.g. `"2.1.4"`).
  def self.version_string : String
    "#{@@engine_version[:major]}.#{@@engine_version[:minor]}.#{@@engine_version[:minor2]}"
  end

  private def self._unpack_version(version_integer : Int32)
    major = (version_integer >> 16) & 0xFF
    minor = (version_integer >> 8) & 0xFF
    minor2 = version_integer & 0xFF
    {major: major, minor: minor, minor2: minor2}
  end

  # Checks if the version returned by `init` is compatible with our target version (2.1.x).
  private def self._check_version(version_integer)
    v = _unpack_version(version_integer)
    v[:major] == CURRENT_VERSION_MAJOR && v[:minor] >= CURRENT_VERSION_MINOR
  end

  protected def self._resolve_slot(slot : Slot | Int32) : Slot
    slot.is_a?(Slot) ? slot : Slot.from_int(slot)
  end

  protected def self._resolve_module_id(mod : Module | Int32) : Int32
    mod.is_a?(Module) ? mod.id : mod
  end

  protected def self._resolve_pattern_id(pat : Pattern | Int32) : Int32
    pat.is_a?(Pattern) ? pat.id : pat
  end

  # Returns true if `slot` is currently open.
  def self.slot_open?(slot : Slot | Int32) : Bool
    resolved = _resolve_slot(slot)
    @@open_slots.has_key?(resolved.value)
  end

  # Returns an array of all currently open `Slot`s.
  def self.open_slots : Array(Slot)
    @@open_slots.values
  end

  # Checks if a slot is open, and raises exception if it is already open.
  private def self._raise_if_slot_open!(slot : Slot)
    if @@open_slots[slot.value]?
      raise Exception.new("Cannot open slot #{slot} because it is already open!")
    end
  end

  # Checks if a slot is closed, and raises exception if it is not open.
  private def self._raise_if_slot_closed!(slot : Slot)
    if !@@open_slots[slot.value]?
      raise Exception.new("Slot #{slot} is not open!")
    end
  end

  # Locks the slot for thread-safe modification.
  def self.lock_slot(slot : Slot | Int32) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    LibSunVox.lock_slot(resolved.value)
  end

  # Unlocks the slot after modification.
  def self.unlock_slot(slot : Slot | Int32) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    LibSunVox.unlock_slot(resolved.value)
  end

  private def self._lock_slot(slot : Slot)
    LibSunVox.lock_slot(slot.value)
  end

  private def self._unlock_slot(slot : Slot)
    LibSunVox.unlock_slot(slot.value)
  end

  # Opens a slot (defaults to `Slot::Zero`) and returns the `Slot`.
  def self.open_slot(slot : Slot | Int32 = Slot::Zero) : Slot
    resolved = _resolve_slot(slot)
    _raise_if_slot_open!(resolved)

    success = LibSunVox.open_slot(resolved.value) == 0
    raise Exception.new("Something went wrong opening slot #{resolved}") unless success
    @@open_slots[resolved.value] = resolved
  end

  # Opens a slot for the duration of the block and ensures it is closed afterwards.
  def self.open_slot(slot : Slot | Int32 = Slot::Zero, & : Slot ->)
    resolved = open_slot(slot)
    begin
      yield resolved
    ensure
      close_slot(resolved) if slot_open?(resolved)
    end
  end

  # Closes a slot. Raises exception if the slot is closed or something goes wrong.
  def self.close_slot(slot : Slot | Int32) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    success = LibSunVox.close_slot(resolved.value) == 0
    raise Exception.new("Something went wrong closing slot #{resolved}") unless success
    @@open_slots.delete(resolved.value)
  end

  # Loads a project file from disk into a slot.
  def self.load(slot : Slot | Int32, filename : String | Path) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    success = LibSunVox.load(resolved.value, filename.to_s) == 0
    raise Exception.new("Something went wrong loading #{filename} into slot #{resolved}") unless success
  end

  # Loads a project from a memory buffer (`Bytes`) into a slot.
  def self.load_from_memory(slot : Slot | Int32, data : Bytes) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    success = LibSunVox.load_from_memory(resolved.value, data.to_unsafe.as(Void*), data.size.to_u32) == 0
    raise Exception.new("Something went wrong loading project from memory into slot #{resolved}") unless success
  end

  # Saves the project in `slot` to a file on disk.
  def self.save(slot : Slot | Int32, filename : String | Path) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    success = LibSunVox.save(resolved.value, filename.to_s) == 0
    raise Exception.new("Something went wrong saving slot #{resolved} to #{filename}") unless success
  end

  # Saves the project in `slot` to a newly allocated `Bytes` slice in memory.
  def self.save_to_memory(slot : Slot | Int32) : Bytes
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    size = uninitialized LibC::SizeT
    ptr = LibSunVox.save_to_memory(resolved.value, pointerof(size))
    raise Exception.new("Something went wrong saving slot #{resolved} to memory") if ptr.null? || size == 0

    begin
      bytes = Bytes.new(size.to_i)
      bytes.copy_from(ptr.as(UInt8*), size.to_i)
      bytes
    ensure
      _free_sunvox_memory(ptr)
    end
  end

  private def self._free_sunvox_memory(ptr : Void*) : Nil
    return if ptr.null?
    {% if flag?(:win32) %}
      mod = LibSunVoxWin32.get_module_handle_a("msvcrt.dll")
      if !mod.null?
        fn_ptr = LibSunVoxWin32.get_proc_address(mod, "free")
        if !fn_ptr.null?
          Proc(Void*, Void).new(fn_ptr, Pointer(Void).null).call(ptr)
          return
        end
      end
      LibC.free(ptr)
    {% else %}
      LibC.free(ptr)
    {% end %}
  end

  # Plays the current song from the beginning (line 0).
  sunvox_slot_call("play_from_beginning")
  # Plays the current song from the current line.
  sunvox_slot_call("play")
  # Stops the current song from playing. 2 calls will stop all the synths and sounds.
  sunvox_slot_call("stop")
  # Pauses the playback at the current line.
  sunvox_slot_call("pause")
  # Resumes playback from a paused state.
  sunvox_slot_call("resume")
  # Waits for sync (pattern effect 0x33 on any slot) and resumes the audio stream on `slot`.
  sunvox_slot_call("sync_resume")

  # Returns true if autostop is enabled on `slot`.
  def self.autostop?(slot : Slot | Int32) : Bool
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    LibSunVox.get_autostop(resolved.value) == 1
  end

  # Enables or disables autostop on `slot`.
  def self.set_autostop(slot : Slot | Int32, autostop : Bool) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    success = LibSunVox.set_autostop(resolved.value, autostop ? 1 : 0) == 0
    raise Exception.new("Cannot set_autostop on slot #{resolved}") unless success
  end

  # Returns whether or not autostop is set (preserved for backwards compatibility).
  def self.repeats?(slot : Slot | Int32) : Bool
    autostop?(slot)
  end

  # Sets autostop flag (preserved for backwards compatibility).
  def self.set_repeat(slot : Slot | Int32, bool : Bool) : Nil
    set_autostop(slot, bool)
  end

  # Is the song over and the end has been reached?
  def self.end_of_song?(slot : Slot | Int32) : Bool
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    LibSunVox.end_of_song(resolved.value) == 1
  end

  # Jumps the current position of the playhead to a line number.
  def self.skip_to_line(slot : Slot | Int32, line_num : Int32)
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    LibSunVox.rewind(resolved.value, line_num)
  end

  # Alias for `skip_to_line`.
  def self.rewind(slot : Slot | Int32, line_num : Int32)
    skip_to_line(slot, line_num)
  end

  # Sets the output volume of the slot (`0..256`). Negative values query current volume without changing it.
  def self.volume(slot : Slot | Int32, volume : Int) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    LibSunVox.volume(resolved.value, volume.to_i)
  end

  # Queries the current volume of `slot` (`0..256`).
  def self.get_volume(slot : Slot | Int32) : Int32
    volume(slot, -1)
  end

  # Gets the name of the song in `slot`.
  def self.get_song_name(slot : Slot | Int32) : String
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    ptr = LibSunVox.get_song_name(resolved.value)
    ptr.null? ? "" : String.new(ptr)
  end

  # Sets the name of the song in `slot`.
  def self.set_song_name(slot : Slot | Int32, name : String) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    success = LibSunVox.set_song_name(resolved.value, name) == 0
    raise Exception.new("Cannot set_song_name on slot #{resolved}") unless success
  end

  # Gets the SunVox version used to create the project in `slot`.
  sunvox_slot_call_return "get_base_version"

  # Sends an event to SunVox. Can be used to send notes, change ctl values, or set note effects.
  def self.send_event(slot : Slot | Int32, track_num : Int32, note : Note, velocity : Int, module_num : Module | Int = -1, ctl : Int = 0, effect : Int = 0, ctl_value : Int = 0)
    send_event(slot, track_num, note.value, velocity, module_num, ctl, effect, ctl_value)
  end

  # Sends an event to SunVox. Can be used to send notes, change ctl values, or set note effects.
  def self.send_event(slot : Slot | Int32, track_num : Int32, note : Int32, velocity : Int, module_num : Module | Int = -1, ctl : Int = 0, effect : Int = 0, ctl_value : Int = 0)
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = module_num.is_a?(Module) ? module_num.id : module_num.to_i
    success = LibSunVox.send_event(resolved.value, track_num, note, velocity.to_i, mod_id + 1, (ctl.to_i << 8) + effect.to_i, ctl_value.to_i) == 0
    raise Exception.new("Cannot send_event on slot #{resolved}") unless success
  end

  # Sends an `Event` record to SunVox on `track_num`.
  def self.send_event(slot : Slot | Int32, track_num : Int32, event : Event)
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    success = LibSunVox.send_event(resolved.value, track_num, event.note.value, event.velocity.to_i, event.mod_num.to_i + 1, (event.ctl.to_i << 8) + event.effect.to_i, event.ctl_value.to_i) == 0
    raise Exception.new("Cannot send_event on slot #{resolved}") unless success
  end

  # Sets the timestamp of events to be sent by `send_event`.
  def self.set_event_time(slot : Slot | Int32, timestamp : UInt32 = 0_u32, set = true)
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    success = LibSunVox.set_event_t(resolved.value, set ? 1 : 0, timestamp.to_i!) == 0
    raise Exception.new("Cannot set_event_time on slot #{resolved}") unless success
  end

  # Gets the project time map for `len` lines starting at `start_line`.
  def self.time_map(slot : Slot | Int32, start_line : Int32, len : Int32, flags : TimeMapFlags | Int32 = TimeMapFlags::Speed) : Slice(UInt32)
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    return Slice(UInt32).empty if len <= 0

    dest_ptr = Pointer(UInt32).malloc(len)
    rv = LibSunVox.get_time_map(resolved.value, start_line, len, dest_ptr, flags.to_i)
    raise Exception.new("Cannot get_time_map on slot #{resolved}") if rv < 0
    dest_ptr.to_slice(len)
  end

  # Gets the next piece of SunVox audio from the Output module (requires `offline: true`).
  def self.audio_callback(buf : Bytes | Slice(Int16) | Slice(Float32), frames : Int32, latency : Int32 = 0, out_time : UInt32 = ticks) : Int32
    LibSunVox.audio_callback(buf.to_unsafe.as(Void*), frames, latency, out_time)
  end

  # Sends audio to the Input module and receives filtered audio from the Output module (requires `offline: true`).
  def self.audio_callback2(out_buf : Bytes | Slice(Int16) | Slice(Float32), frames : Int32, in_buf : Bytes | Slice(Int16) | Slice(Float32), in_type : SampleType = SampleType::Int16, in_channels : Int32 = DEFAULT_CHANNELS, latency : Int32 = 0, out_time : UInt32 = ticks) : Int32
    in_type_val = (in_type == SampleType::Float32) ? 1 : 0
    LibSunVox.audio_callback2(out_buf.to_unsafe.as(Void*), frames, latency, out_time, in_type_val, in_channels, in_buf.to_unsafe.as(Void*))
  end

  # Gets the debug log messages.
  def self.get_log(bytes : Int32 = 4096) : String
    ptr = LibSunVox.get_log(bytes)
    ptr.null? ? "" : String.new(ptr)
  end

  # The current system tick.
  def self.ticks : UInt32
    LibSunVox.get_ticks
  end

  # How many system ticks happen per second.
  def self.ticks_per_second : UInt32
    LibSunVox.get_ticks_per_second
  end

  # The current line the playhead is at.
  sunvox_slot_call_return "get_current_line"
  # The current line the playhead is at in fixed-point 27.5 format.
  sunvox_slot_call_return "get_current_line2"
  # Gets the number of pattern slots in `slot`.
  sunvox_slot_call_return "get_number_of_patterns"
  # Gets the BPM of the song in `slot`.
  sunvox_slot_call_return "get_song_bpm"
  # Gets the TPL (Ticks Per Line) of the song in `slot`.
  sunvox_slot_call_return "get_song_tpl"
  # The total length in frames of the song in `slot`.
  sunvox_slot_call_return "get_song_length_frames"
  # The total song length in lines of `slot`.
  sunvox_slot_call_return "get_song_length_lines"
  # The number of module slots in `slot`.
  sunvox_slot_call_return "get_number_of_modules"

  # Creates a new pattern in `slot`. Returns the pattern number.
  def self.new_pattern(slot : Slot | Int32, clone : Pattern | Int32 = -1, x : Int32 = 0, y : Int32 = 0, tracks : Int32 = 4, lines : Int32 = 32, icon_seed : Int32 = 0, name : String = "") : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    clone_id = _resolve_pattern_id(clone)
    _lock_slot(resolved)
    pat_num = LibSunVox.new_pattern(resolved.value, clone_id, x, y, tracks, lines, icon_seed, name)
    _unlock_slot(resolved)

    raise Exception.new("Cannot create new pattern '#{name}' on slot #{resolved}") if pat_num < 0
    pat_num
  end

  # Removes a pattern in `slot`.
  def self.remove_pattern(slot : Slot | Int32, pat_num : Pattern | Int32) : Bool
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    pat_id = _resolve_pattern_id(pat_num)
    _lock_slot(resolved)
    success = LibSunVox.remove_pattern(resolved.value, pat_id) == 0
    _unlock_slot(resolved)

    raise Exception.new("Cannot remove pattern #{pat_id} on slot #{resolved}") unless success
    success
  end

  # Finds the pattern in `slot` by `name` (returns `-1` if not found).
  def self.find_pattern(slot : Slot | Int32, name : String) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    LibSunVox.find_pattern(resolved.value, name)
  end

  # Gets the pattern's starting line (X coordinate on timeline).
  def self.get_pattern_x(slot : Slot | Int32, pat_num : Pattern | Int32) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    LibSunVox.get_pattern_x(resolved.value, _resolve_pattern_id(pat_num))
  end

  # Gets the pattern's vertical position (Y coordinate on timeline).
  def self.get_pattern_y(slot : Slot | Int32, pat_num : Pattern | Int32) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    LibSunVox.get_pattern_y(resolved.value, _resolve_pattern_id(pat_num))
  end

  # Sets the pattern's `(x, y)` coordinates on the timeline.
  def self.set_pattern_xy(slot : Slot | Int32, pat_num : Pattern | Int32, x : Int32, y : Int32) : Bool
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    pat_id = _resolve_pattern_id(pat_num)
    _lock_slot(resolved)
    success = LibSunVox.set_pattern_xy(resolved.value, pat_id, x, y) == 0
    _unlock_slot(resolved)

    raise Exception.new("Cannot set_pattern_xy for pattern #{pat_id} on slot #{resolved}") unless success
    success
  end

  # Get the length of the song in seconds as a `Time::Span`.
  def self.get_song_length(slot : Slot | Int32) : Time::Span
    sr = sample_rate > 0 ? sample_rate : DEFAULT_FREQ
    frames = get_song_length_frames(slot)
    Time::Span.new(nanoseconds: ((frames.to_f64 / sr) * 1_000_000_000.0).to_i64)
  end

  # Gets the current output signal level (`0..255`).
  def self.get_current_signal_level(slot : Slot | Int32, channel : Int32 = 0) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    LibSunVox.get_current_signal_level(resolved.value, channel)
  end

  # Gets the number of lines in a pattern.
  def self.get_pattern_lines(slot : Slot | Int32, pattern_num : Pattern | Int32) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    LibSunVox.get_pattern_lines(resolved.value, _resolve_pattern_id(pattern_num))
  end

  # Gets the number of tracks in a pattern.
  def self.get_pattern_tracks(slot : Slot | Int32, pattern_num : Pattern | Int32) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    LibSunVox.get_pattern_tracks(resolved.value, _resolve_pattern_id(pattern_num))
  end

  # Sets the number of tracks and/or lines of a pattern (`-1` leaves unchanged).
  def self.set_pattern_size(slot : Slot | Int32, pattern_num : Pattern | Int32, tracks : Int32 = -1, lines : Int32 = -1) : Bool
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    pat_id = _resolve_pattern_id(pattern_num)
    _lock_slot(resolved)
    success = LibSunVox.set_pattern_size(resolved.value, pat_id, tracks, lines) == 0
    _unlock_slot(resolved)

    raise Exception.new("Cannot set_pattern_size for pattern #{pat_id} on slot #{resolved}") unless success
    success
  end

  # Gets the pattern's name.
  def self.get_pattern_name(slot : Slot | Int32, pattern_num : Pattern | Int32) : String
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    name_ptr = LibSunVox.get_pattern_name(resolved.value, _resolve_pattern_id(pattern_num))
    name_ptr.null? ? "" : String.new(name_ptr)
  end

  # Sets the pattern's name.
  def self.set_pattern_name(slot : Slot | Int32, pattern_num : Pattern | Int32, name : String) : Bool
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    pat_id = _resolve_pattern_id(pattern_num)
    _lock_slot(resolved)
    success = LibSunVox.set_pattern_name(resolved.value, pat_id, name) == 0
    _unlock_slot(resolved)

    raise Exception.new("Cannot set_pattern_name for pattern #{pat_id} on slot #{resolved}") unless success
    success
  end

  # Returns the raw mutable pattern buffer (`Slice(LibSunVox::Event)`).
  def self.get_raw_pattern_data(slot : Slot | Int32, pattern_num : Pattern | Int32) : Slice(LibSunVox::Event)
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    pat_id = _resolve_pattern_id(pattern_num)
    lines = get_pattern_lines(resolved, pat_id)
    tracks = get_pattern_tracks(resolved, pat_id)
    return Slice(LibSunVox::Event).empty if lines <= 0 || tracks <= 0

    ptr = LibSunVox.get_pattern_data(resolved.value, pat_id)
    return Slice(LibSunVox::Event).empty if ptr.null?
    ptr.to_slice(tracks * lines)
  end

  # Get the event data, separated by tracks (`Array(Array(SunVox::Event))`).
  def self.get_pattern_data(slot : Slot | Int32, pattern_num : Pattern | Int32) : Array(Array(SunVox::Event))
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    pat_id = _resolve_pattern_id(pattern_num)
    lines = get_pattern_lines(resolved, pat_id)
    tracks = get_pattern_tracks(resolved, pat_id)
    return [] of Array(SunVox::Event) if lines <= 0 || tracks <= 0

    data = LibSunVox.get_pattern_data(resolved.value, pat_id).to_slice(tracks * lines)
    track_data = [] of Array(SunVox::Event)
    tracks.times { track_data << ([] of SunVox::Event) }
    lines.times do |line_offset|
      tracks.times do |track_offset|
        libsunvox_event = data[tracks * line_offset + track_offset]
        sunvox_event = SunVox::Event.new(
          SunVox::Note.new(libsunvox_event.note.to_i),
          libsunvox_event.vel,
          libsunvox_event.mod_num.to_i16 - 1_i16, # -1 means no module
          (libsunvox_event.ctl >> 8).to_u8,
          (libsunvox_event.ctl & 0xFF).to_u8,
          libsunvox_event.ctl_val
        )

        track_data[track_offset] << sunvox_event
      end
    end
    track_data
  end

  # Writes a pattern event to the cell at `(track, line)`. Negative field values are ignored (left unchanged).
  def self.set_pattern_event(slot : Slot | Int32, pat_num : Pattern | Int32, track : Int32, line : Int32, nn : Int32 = -1, vv : Int32 = -1, mm : Int32 = -1, ccee : Int32 = -1, xxyy : Int32 = -1) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    pat_id = _resolve_pattern_id(pat_num)
    rv = LibSunVox.set_pattern_event(resolved.value, pat_id, track, line, nn, vv, mm, ccee, xxyy)
    raise Exception.new("Cannot set_pattern_event on pattern #{pat_id} (track #{track}, line #{line}) on slot #{resolved}") if rv < 0
  end

  # Reads a field (`column`) from the pattern event at `(track, line)`.
  def self.get_pattern_event(slot : Slot | Int32, pat_num : Pattern | Int32, track : Int32, line : Int32, column : PatternColumn | Int32) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    pat_id = _resolve_pattern_id(pat_num)
    col_val = column.is_a?(PatternColumn) ? column.value : column
    rv = LibSunVox.get_pattern_event(resolved.value, pat_id, track, line, col_val)
    raise Exception.new("Cannot get_pattern_event on pattern #{pat_id} (track #{track}, line #{line}, col #{col_val}) on slot #{resolved}") if rv < 0
    rv
  end

  # Mute/Unmute the pattern. Returns the previous mute state (`true` if previously muted).
  def self.pattern_mute(slot : Slot | Int32, pattern_num : Pattern | Int32, mute : Bool = true) : Bool
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    pat_id = _resolve_pattern_id(pattern_num)
    _lock_slot(resolved)
    prev = LibSunVox.pattern_mute(resolved.value, pat_id, mute ? 1 : 0)
    _unlock_slot(resolved)
    raise Exception.new("Cannot pattern_mute pattern #{pat_id} on slot #{resolved}") if prev < 0
    prev == 1
  end

  # Queries whether `pattern_num` is currently muted without changing its state.
  def self.pattern_muted?(slot : Slot | Int32, pattern_num : Pattern | Int32) : Bool
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    pat_id = _resolve_pattern_id(pattern_num)
    _lock_slot(resolved)
    state = LibSunVox.pattern_mute(resolved.value, pat_id, -1)
    _unlock_slot(resolved)
    state == 1
  end

  # Create a new module in `slot`. Returns the number of the new module.
  def self.new_module(slot : Slot | Int32, type : ModuleType | String, name = "", x = 512, y = 512, z = 0) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    type_str = type.is_a?(ModuleType) ? type.type : type
    _lock_slot(resolved)
    module_num = LibSunVox.new_module(resolved.value, type_str, name, x, y, z)
    _unlock_slot(resolved)

    raise Exception.new("Cannot create new module #{name} of #{type_str} on slot #{resolved}") if module_num < 0
    module_num
  end

  # Remove the module `module_num` in `slot`.
  def self.remove_module(slot : Slot | Int32, module_num : Module | Int32) : Bool
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(module_num)
    _lock_slot(resolved)
    success = LibSunVox.remove_module(resolved.value, mod_id) == 0
    _unlock_slot(resolved)
    raise Exception.new("Cannot remove module #{mod_id} on slot #{resolved}") unless success
    success
  end

  # Connect a module `src` to a module `dest`.
  def self.connect_module(slot : Slot | Int32, src : Module | Int32, dest : Module | Int32) : Bool
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    src_id = _resolve_module_id(src)
    dest_id = _resolve_module_id(dest)
    _lock_slot(resolved)
    success = LibSunVox.connect_module(resolved.value, src_id, dest_id) == 0
    _unlock_slot(resolved)

    raise Exception.new("Cannot connect module #{src_id} to #{dest_id} on slot #{resolved}") unless success
    success
  end

  # Disconnect a module `src` from a module `dest`.
  def self.disconnect_module(slot : Slot | Int32, src : Module | Int32, dest : Module | Int32) : Bool
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    src_id = _resolve_module_id(src)
    dest_id = _resolve_module_id(dest)
    _lock_slot(resolved)
    success = LibSunVox.disconnect_module(resolved.value, src_id, dest_id) == 0
    _unlock_slot(resolved)

    raise Exception.new("Cannot disconnect module #{src_id} from #{dest_id} on slot #{resolved}") unless success
    success
  end

  # Load a module from a file (`sunsynth`, `xi`, `wav`, `aiff`, `ogg`, `mp3`, `flac`).
  def self.load_module(slot : Slot | Int32, filename : String | Path, x = 512, y = 512, z = 0) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    module_num = LibSunVox.load_module(resolved.value, filename.to_s, x, y, z)
    raise Exception.new("Cannot load module #{filename} on slot #{resolved}") if module_num < 0
    module_num
  end

  # Load a module or sample from a memory block (`Bytes`).
  def self.load_module_from_memory(slot : Slot | Int32, data : Bytes, x = 512, y = 512, z = 0) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    module_num = LibSunVox.load_module_from_memory(resolved.value, data.to_unsafe.as(Void*), data.size.to_u32, x, y, z)
    raise Exception.new("Cannot load module from memory on slot #{resolved}") if module_num < 0
    module_num
  end

  # Find a module in a `slot` by `name` (returns `-1` if not found).
  def self.find_module(slot : Slot | Int32, name : String) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    LibSunVox.find_module(resolved.value, name)
  end

  # Get the flags set on a module.
  def self.get_module_flags(slot : Slot | Int32, module_num : Module | Int32) : UInt32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    LibSunVox.get_module_flags(resolved.value, _resolve_module_id(module_num))
  end

  def self.module_exists?(slot : Slot | Int32, module_num : Module | Int32) : Bool
    (get_module_flags(slot, module_num) & LibSunVox::MODULE_FLAG_EXISTS) != 0
  end

  def self.module_generator?(slot : Slot | Int32, module_num : Module | Int32) : Bool
    (get_module_flags(slot, module_num) & LibSunVox::MODULE_FLAG_GENERATOR) != 0
  end

  def self.module_effect?(slot : Slot | Int32, module_num : Module | Int32) : Bool
    (get_module_flags(slot, module_num) & LibSunVox::MODULE_FLAG_EFFECT) != 0
  end

  def self.module_mute?(slot : Slot | Int32, module_num : Module | Int32) : Bool
    (get_module_flags(slot, module_num) & LibSunVox::MODULE_FLAG_MUTE) != 0
  end

  def self.module_solo?(slot : Slot | Int32, module_num : Module | Int32) : Bool
    (get_module_flags(slot, module_num) & LibSunVox::MODULE_FLAG_SOLO) != 0
  end

  def self.module_bypass?(slot : Slot | Int32, module_num : Module | Int32) : Bool
    (get_module_flags(slot, module_num) & LibSunVox::MODULE_FLAG_BYPASS) != 0
  end

  # Loads a file into a Sampler (`xi`, `wav`, `aiff`, `ogg`, `mp3`, `flac`).
  def self.sampler_load(slot : Slot | Int32, sampler_module_num : Module | Int32, filename : String | Path, sample_slot = -1) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(sampler_module_num)
    success = LibSunVox.sampler_load(resolved.value, mod_id, filename.to_s, sample_slot) == 0
    raise Exception.new("Cannot load #{filename} into sampler module #{mod_id} on slot #{resolved}") unless success
  end

  # Loads a sample from memory (`Bytes`) into a Sampler module.
  def self.sampler_load_from_memory(slot : Slot | Int32, sampler_module_num : Module | Int32, data : Bytes, sample_slot = -1) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(sampler_module_num)
    success = LibSunVox.sampler_load_from_memory(resolved.value, mod_id, data.to_unsafe.as(Void*), data.size.to_u32, sample_slot) == 0
    raise Exception.new("Cannot load sample from memory into sampler module #{mod_id} on slot #{resolved}") unless success
  end

  # Gets or sets a sample parameter on a Sampler module (`sv_sampler_par`).
  def self.sampler_par(slot : Slot | Int32, sampler_module_num : Module | Int32, sample_slot : Int32, par : SamplerParam | Int32, par_val : Int32 = 0, set : Bool = false) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(sampler_module_num)
    par_id = par.is_a?(SamplerParam) ? par.value : par
    LibSunVox.sampler_par(resolved.value, mod_id, sample_slot, par_id, par_val, set ? 1 : 0)
  end

  # Gets a sample parameter from a Sampler module.
  def self.get_sampler_par(slot : Slot | Int32, sampler_module_num : Module | Int32, sample_slot : Int32, par : SamplerParam | Int32) : Int32
    sampler_par(slot, sampler_module_num, sample_slot, par, 0, false)
  end

  # Sets a sample parameter on a Sampler module and returns the previous value.
  def self.set_sampler_par(slot : Slot | Int32, sampler_module_num : Module | Int32, sample_slot : Int32, par : SamplerParam | Int32, val : Int32) : Int32
    sampler_par(slot, sampler_module_num, sample_slot, par, val, true)
  end

  # Loads a file (`sunvox`, `mod`, `xm`, `midi`) into a MetaModule.
  def self.metamodule_load(slot : Slot | Int32, module_num : Module | Int32, filename : String | Path) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(module_num)
    success = LibSunVox.metamodule_load(resolved.value, mod_id, filename.to_s) == 0
    raise Exception.new("Cannot load #{filename} into MetaModule #{mod_id} on slot #{resolved}") unless success
  end

  # Loads a file from memory (`Bytes`) into a MetaModule.
  def self.metamodule_load_from_memory(slot : Slot | Int32, module_num : Module | Int32, data : Bytes) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(module_num)
    success = LibSunVox.metamodule_load_from_memory(resolved.value, mod_id, data.to_unsafe.as(Void*), data.size.to_u32) == 0
    raise Exception.new("Cannot load data from memory into MetaModule #{mod_id} on slot #{resolved}") unless success
  end

  # Loads an OGG file into a Vorbis Player module.
  def self.vplayer_load(slot : Slot | Int32, module_num : Module | Int32, filename : String | Path) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(module_num)
    success = LibSunVox.vplayer_load(resolved.value, mod_id, filename.to_s) == 0
    raise Exception.new("Cannot load #{filename} into Vorbis Player #{mod_id} on slot #{resolved}") unless success
  end

  # Loads an OGG file from memory (`Bytes`) into a Vorbis Player module.
  def self.vplayer_load_from_memory(slot : Slot | Int32, module_num : Module | Int32, data : Bytes) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(module_num)
    success = LibSunVox.vplayer_load_from_memory(resolved.value, mod_id, data.to_unsafe.as(Void*), data.size.to_u32) == 0
    raise Exception.new("Cannot load data from memory into Vorbis Player #{mod_id} on slot #{resolved}") unless success
  end

  # The number of module input link slots.
  def self.get_module_inputs_number(slot : Slot | Int32, module_num : Module | Int32) : Int32
    ((get_module_flags(slot, module_num) & LibSunVox::MODULE_INPUTS_MASK) >> LibSunVox::MODULE_INPUTS_OFF).to_i
  end

  # The number of module output link slots.
  def self.get_module_outputs_number(slot : Slot | Int32, module_num : Module | Int32) : Int32
    ((get_module_flags(slot, module_num) & LibSunVox::MODULE_OUTPUTS_MASK) >> LibSunVox::MODULE_OUTPUTS_OFF).to_i
  end

  # A slice of all input link slots a module has (entries may be `-1` if unconnected).
  def self.get_module_inputs(slot : Slot | Int32, module_num : Module | Int32) : Slice(Int32)
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(module_num)
    count = get_module_inputs_number(resolved, mod_id)
    return Slice(Int32).empty if count <= 0

    ptr = LibSunVox.get_module_inputs(resolved.value, mod_id)
    ptr.null? ? Slice(Int32).empty : ptr.to_slice(count)
  end

  # A slice of all output link slots a module has (entries may be `-1` if unconnected).
  def self.get_module_outputs(slot : Slot | Int32, module_num : Module | Int32) : Slice(Int32)
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(module_num)
    count = get_module_outputs_number(resolved, mod_id)
    return Slice(Int32).empty if count <= 0

    ptr = LibSunVox.get_module_outputs(resolved.value, mod_id)
    ptr.null? ? Slice(Int32).empty : ptr.to_slice(count)
  end

  # Gets the type string of a module (e.g. `"Generator"`, `"Filter Pro"`, `"Output"`).
  def self.get_module_type(slot : Slot | Int32, module_num : Module | Int32) : String
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    ptr = LibSunVox.get_module_type(resolved.value, _resolve_module_id(module_num))
    ptr.null? ? "" : String.new(ptr)
  end

  # Gets the name of a module.
  def self.get_module_name(slot : Slot | Int32, module_num : Module | Int32) : String
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    ptr = LibSunVox.get_module_name(resolved.value, _resolve_module_id(module_num))
    ptr.null? ? "" : String.new(ptr)
  end

  # Sets the name of a module.
  def self.set_module_name(slot : Slot | Int32, module_num : Module | Int32, name : String) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(module_num)
    success = LibSunVox.set_module_name(resolved.value, mod_id, name) == 0
    raise Exception.new("Cannot set_module_name on module #{mod_id} in slot #{resolved}") unless success
  end

  # Get the `{x, y}` position of a module.
  def self.get_module_xy(slot : Slot | Int32, module_num : Module | Int32) : NamedTuple(x: Int32, y: Int32)
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    _unpack_module_xy(LibSunVox.get_module_xy(resolved.value, _resolve_module_id(module_num)))
  end

  # Set the `(x, y)` position of a module.
  def self.set_module_xy(slot : Slot | Int32, module_num : Module | Int32, x : Int32, y : Int32) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(module_num)
    success = LibSunVox.set_module_xy(resolved.value, mod_id, x, y) == 0
    raise Exception.new("Cannot set_module_xy on module #{mod_id} in slot #{resolved}") unless success
  end

  # Get the color of a module in `0xBBGGRR` format.
  def self.get_module_color(slot : Slot | Int32, module_num : Module | Int32) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    LibSunVox.get_module_color(resolved.value, _resolve_module_id(module_num))
  end

  # Set the color of a module in `0xBBGGRR` format.
  def self.set_module_color(slot : Slot | Int32, module_num : Module | Int32, color : Int32) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(module_num)
    success = LibSunVox.set_module_color(resolved.value, mod_id, color) == 0
    raise Exception.new("Cannot set_module_color on module #{mod_id} in slot #{resolved}") unless success
  end

  # Get module's `{finetune, relative_note}` values.
  def self.get_module_finetune(slot : Slot | Int32, module_num : Module | Int32) : NamedTuple(finetune: Int32, relative_note: Int32)
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    _unpack_module_finetune(LibSunVox.get_module_finetune(resolved.value, _resolve_module_id(module_num)))
  end

  # Set the module's finetune (`-256..256`) immediately.
  def self.set_module_finetune(slot : Slot | Int32, module_num : Module | Int32, finetune : Int32) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(module_num)
    success = LibSunVox.set_module_finetune(resolved.value, mod_id, finetune) == 0
    raise Exception.new("Cannot set_module_finetune on module #{mod_id} in slot #{resolved}") unless success
  end

  # Set the module's relative note (transposition) immediately.
  def self.set_module_relnote(slot : Slot | Int32, module_num : Module | Int32, relative_note : Int32) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)

    mod_id = _resolve_module_id(module_num)
    success = LibSunVox.set_module_relnote(resolved.value, mod_id, relative_note) == 0
    raise Exception.new("Cannot set_module_relnote on module #{mod_id} in slot #{resolved}") unless success
  end

  # Get the raw audio output scope values (`Slice(Int16)`) for a module.
  def self.get_module_scope(slot : Slot | Int32, module_num : Module | Int32, channel : Int32 = 0, samples_to_read : Int32 = 1024) : Slice(Int16)
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    return Slice(Int16).empty if samples_to_read <= 0

    samples = Pointer(Int16).malloc(samples_to_read)
    received = LibSunVox.get_module_scope2(resolved.value, _resolve_module_id(module_num), channel, samples, samples_to_read.to_u32)
    samples.to_slice(received.to_i)
  end

  # Get the curve data (`Slice(Float32)`) from a module.
  def self.get_module_curve(slot : Slot | Int32, module_num : Module | Int32, curve_num : Int32, length : Int32 = 257) : Slice(Float32)
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    return Slice(Float32).empty if length <= 0

    curve_data = Pointer(Float32).malloc(length)
    curve_data_length = LibSunVox.module_curve(resolved.value, _resolve_module_id(module_num), curve_num, curve_data, length, 0)
    raise Exception.new("Cannot get_module_curve on slot #{resolved}") if curve_data_length < 0
    curve_data.to_slice(curve_data_length)
  end

  # Set the curve data of a module. Returns the number of items written.
  def self.set_module_curve(slot : Slot | Int32, module_num : Module | Int32, curve_num : Int32, curve_data : Slice(Float32)) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    return 0 if curve_data.empty?

    written = LibSunVox.module_curve(resolved.value, _resolve_module_id(module_num), curve_num, curve_data.to_unsafe, curve_data.size, 1)
    raise Exception.new("Cannot set_module_curve on slot #{resolved}") if written < 0
    written
  end

  # Get the number of controllers a module has.
  def self.get_number_of_module_ctls(slot : Slot | Int32, module_num : Module | Int32) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    LibSunVox.get_number_of_module_ctls(resolved.value, _resolve_module_id(module_num))
  end

  # Get the name of a module's controller.
  def self.get_module_ctl_name(slot : Slot | Int32, module_num : Module | Int32, ctl_num : Int32) : String
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    ptr = LibSunVox.get_module_ctl_name(resolved.value, _resolve_module_id(module_num), ctl_num)
    ptr.null? ? "" : String.new(ptr)
  end

  # Get the value of a module's controller (`scaled` can be a `Bool`, `CtlScale`, or `0..2`).
  def self.get_module_ctl_value(slot : Slot | Int32, module_num : Module | Int32, ctl_num : Int32, scaled : Bool | CtlScale | Int32 = false) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    scaled_val = case scaled
                 in Bool     then scaled ? 1 : 0
                 in CtlScale then scaled.value
                 in Int32    then scaled
                 end
    LibSunVox.get_module_ctl_value(resolved.value, _resolve_module_id(module_num), ctl_num, scaled_val)
  end

  # Set the value of a module's controller (`sv_set_module_ctl_value`).
  def self.set_module_ctl_value(slot : Slot | Int32, module_num : Module | Int32, ctl_num : Int32, val : Int32, scaled : Bool | CtlScale | Int32 = false) : Nil
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    scaled_val = case scaled
                 in Bool     then scaled ? 1 : 0
                 in CtlScale then scaled.value
                 in Int32    then scaled
                 end
    mod_id = _resolve_module_id(module_num)
    success = LibSunVox.set_module_ctl_value(resolved.value, mod_id, ctl_num, val, scaled_val) == 0
    raise Exception.new("Cannot set_module_ctl_value on module #{mod_id} (ctl #{ctl_num}) in slot #{resolved}") unless success
  end

  # Get the minimum value of a module's controller.
  def self.get_module_ctl_min(slot : Slot | Int32, module_num : Module | Int32, ctl_num : Int32, scaled : Bool | CtlScale | Int32 = false) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    scaled_val = case scaled
                 in Bool     then scaled ? 1 : 0
                 in CtlScale then scaled.value
                 in Int32    then scaled
                 end
    LibSunVox.get_module_ctl_min(resolved.value, _resolve_module_id(module_num), ctl_num, scaled_val)
  end

  # Get the maximum value of a module's controller.
  def self.get_module_ctl_max(slot : Slot | Int32, module_num : Module | Int32, ctl_num : Int32, scaled : Bool | CtlScale | Int32 = false) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    scaled_val = case scaled
                 in Bool     then scaled ? 1 : 0
                 in CtlScale then scaled.value
                 in Int32    then scaled
                 end
    LibSunVox.get_module_ctl_max(resolved.value, _resolve_module_id(module_num), ctl_num, scaled_val)
  end

  # Get the display value offset of a module's controller.
  def self.get_module_ctl_offset(slot : Slot | Int32, module_num : Module | Int32, ctl_num : Int32) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    LibSunVox.get_module_ctl_offset(resolved.value, _resolve_module_id(module_num), ctl_num)
  end

  # Get the type of a module's controller (`CtlType::Normal` or `CtlType::Selector`).
  def self.get_module_ctl_type(slot : Slot | Int32, module_num : Module | Int32, ctl_num : Int32) : CtlType
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    raw = LibSunVox.get_module_ctl_type(resolved.value, _resolve_module_id(module_num), ctl_num)
    CtlType.from_value?(raw) || CtlType::Normal
  end

  # Get the group number of a module's controller.
  def self.get_module_ctl_group(slot : Slot | Int32, module_num : Module | Int32, ctl_num : Int32) : Int32
    resolved = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved)
    LibSunVox.get_module_ctl_group(resolved.value, _resolve_module_id(module_num), ctl_num)
  end

  def self.update_input
    LibSunVox.update_input
  end

  # Unpacks the xy position
  private def self._unpack_module_xy(in_xy)
    out_x = (in_xy & 0xFFFF).to_i32
    out_x &-= 0x10000 if (out_x & 0x8000) > 0
    out_y = ((in_xy >> 16) & 0xFFFF).to_i32
    out_y &-= 0x10000 if (out_y & 0x8000) > 0
    {x: out_x, y: out_y}
  end

  # Unpacks the module's finetuning settings
  private def self._unpack_module_finetune(in_finetune)
    out_finetune = (in_finetune & 0xFFFF).to_i32
    out_finetune &-= 0x10000 if (out_finetune & 0x8000) > 0
    out_relative_note = ((in_finetune >> 16) & 0xFFFF).to_i32
    out_relative_note &-= 0x10000 if (out_relative_note & 0x8000) > 0
    {finetune: out_finetune, relative_note: out_relative_note}
  end

  def self.pitch_to_frequency(in_pitch)
    Math.pow(2, (30720.0_f32 - in_pitch) / 3072.0_f32) * 16.333984375
  end

  def self.frequency_to_pitch(in_freq)
    30720 - Math.log2(in_freq / 16.333984375) * 3072
  end

  def self.export_to_wav(slot : Slot | Int32, song_len_frames : Int, out_filename : String | Path)
    raise "Must start in offline mode to export" unless offline?
    resolved = _resolve_slot(slot)
    play_from_beginning(resolved)
    frame_size = DEFAULT_CHANNELS * sample_size

    buf = Slice(UInt8).new(BUFFER_SIZE * frame_size)
    song_len_bytes = (song_len_frames * frame_size).to_u32

    File.open(out_filename.to_s, "w+") do |file|
      file << "RIFF"
      file.write_bytes((4_u32 + 24_u32 + 8_u32 + song_len_bytes), IO::ByteFormat::LittleEndian)
      file << "WAVEfmt "
      file.write_bytes(16_u32, IO::ByteFormat::LittleEndian)
      file.write_bytes((sample_size == 4 ? 3_u16 : 1_u16), IO::ByteFormat::LittleEndian)
      file.write_bytes(DEFAULT_CHANNELS.to_u16, IO::ByteFormat::LittleEndian)
      file.write_bytes(sample_rate.to_u32, IO::ByteFormat::LittleEndian)
      file.write_bytes((sample_rate * frame_size).to_u32, IO::ByteFormat::LittleEndian)
      file.write_bytes(frame_size.to_u16, IO::ByteFormat::LittleEndian)
      file.write_bytes((sample_size * 8).to_u16, IO::ByteFormat::LittleEndian)
      file << "data"
      file.write_bytes(song_len_bytes, IO::ByteFormat::LittleEndian)

      cur_frame = 0_u32
      total_frames = song_len_frames.to_u32
      while cur_frame < total_frames
        frames_num = BUFFER_SIZE.to_u32
        frames_num = total_frames - cur_frame if (cur_frame + frames_num) > total_frames

        LibSunVox.audio_callback(buf.to_unsafe.as(Pointer(Void)), frames_num.to_i, 0, LibSunVox.get_ticks)
        cur_frame += frames_num

        file.write(buf[0, (frames_num * frame_size).to_i])
      end
    end
  end
end

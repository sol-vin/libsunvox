require "./note"
require "./scales"

require "./macros/**"

module SunVox
  @[Flags]

  # TODO: Fix this :(
  # The different float/int types that the output can be typed as.
  enum SampleType
    Int16
  end

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

    # Allows for conversion of int types to Slot, but throws exceptions if it is outside the range of 16 slots.
    def from_int(in_int)
      if (in_int < 0) || (in_int > (MAX_SLOTS - 1))
        raise Exception.new("Slot out of range of #{MAX_SLOTS}, was #{in_int}")
      end

      Slot.new in_int
    end
  end

  # A module that holds all the different module types, categorized as they are in the SunVox application.
  module Modules
    module Synths
      ANALOG_GENERATOR = SunVox::ModuleType.new("Analog generator")
      DRUM_SYNTH       = SunVox::ModuleType.new("DrumSynth")
      FM               = SunVox::ModuleType.new("FM")
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
      FILTER        = SunVox::ModuleType.new("Filter")
      FILER_PRO     = SunVox::ModuleType.new("Filter Pro")
      FLANGER       = SunVox::ModuleType.new("Flanger")
      LFO           = SunVox::ModuleType.new("LFO")
      LOOP          = SunVox::ModuleType.new("Loop")
      MODULATOR     = SunVox::ModuleType.new("Modulator")
      PITCH_SHIFTER = SunVox::ModuleType.new("Pitch shifter")
      REVERB        = SunVox::ModuleType.new("Reverb")
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
      MULTICTL       = SunVox::ModuleType.new("MultiC tl")
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
  end

  record Event,
    note : SunVox::Note,
    velocity : UInt8,
    mod_num : Int16,
    ctl : UInt8,
    effect : UInt8,
    ctl_value : UInt16

  MAX_SLOTS = 16

  CURRENT_VERSION_MAJOR  = 1
  CURRENT_VERSION_MINOR  = 9
  CURRENT_VERSION_MINOR2 = 6
  DEFAULT_CONFIG         = ""
  DEFAULT_FREQ           = 44100
  DEFAULT_CHANNELS       =     2

  OUTPUT_MODULE = 0
  NO_MODULE = -1

  class_getter? started = false
  class_getter sample_rate = 0

  @@open_slots = {} of Int32 => Slot

  # Starts up the SunVox Engine. Hooks `at_exit` to ensure `stop_engine` is run on close
  def self.start_engine(config = DEFAULT_CONFIG, freq = DEFAULT_FREQ, channels = DEFAULT_CHANNELS, no_debug_output = false, offline = false, sample_type = SampleType::Int16, one_thread = false)
    flags = 0
    flags |= LibSunVox::INIT_FLAG_NO_DEBUG_OUTPUT if no_debug_output
    flags |= LibSunVox::INIT_FLAG_OFFLINE if offline
    # TODO: Not sure how to actually support this :|
    # flags |= LibSunVox::INIT_FLAG_AUDIO_INT16 if sample_type == SampleType::Int16
    # flags |= LibSunVox::INIT_FLAG_AUDIO_FLOAT32 if sample_type == SampleType::Float32
    flags |= LibSunVox::INIT_FLAG_ONE_THREAD if one_thread

    # init spits out the version number in 0xMMmm22 format
    version = LibSunVox.init(config, freq, channels, flags)
    if version > 0 && _check_version(version)
      @@started = true
      # set sampling rate
      @@sample_rate = LibSunVox.get_sample_rate

      at_exit { stop_engine }
    else
      raise Exception.new("Cannot start the SunVox Engine :( Try starting in offline mode if there is no audio device.")
    end
  end

  # `Shuts down the engine.`
  def self.stop_engine
    if started?
      # Close all slots
      @@open_slots.each do |_, slot|
        close_slot(slot)
      end
      # Need to call this
      LibSunVox.deinit
      @@started = false
    end
  end

  # Checks if the version returned by `init` is the same as the version we are supposed to use.
  private def self._check_version(version_integer)
    major = (version_integer >> 16)
    minor = (version_integer >> 8) & 0xFF
    minor2 = (version_integer & 0xFF)

    major == CURRENT_VERSION_MAJOR && minor == CURRENT_VERSION_MINOR && minor2 == CURRENT_VERSION_MINOR2
  end

  # Checks if a slot is open, and raises exception if it is closed
  private def self._raise_if_slot_open!(slot : Slot)
    if @@open_slots[slot.value]?
      raise Exception.new("Cannot open a slot that's already opened!")
    end
  end

  # Checks if a slot is closed, and raises exception if it is open
  private def self._raise_if_slot_closed!(slot : Slot)
    if !@@open_slots[slot.value]?
      raise Exception.new("Cannot open a slot that's already opened!")
    end
  end

  # TODO: Fix one_thread: false by adding  proper locks
  # Locks the slot for modification. Need to test this by disabling one_thread.
  private def self._lock_slot(slot : Slot)
    LibSunVox.lock_slot(slot.value)
  end

  # Unlocks the slot for modification. Need to test this by disabling one_thread.
  private def self._unlock_slot(slot : Slot)
    LibSunVox.unlock_slot(slot.value)
  end

  # Opens a slot
  def self.open_slot(slot : Slot)
    _raise_if_slot_open!(slot)

    success = LibSunVox.open_slot(slot.value) == 0
    raise Exception.new("Something went wrong opening slot #{slot}") unless success
    @@open_slots[slot.value] = slot
  end

  # Closes a slot. Raises exception if the slot is closed or something goes wrong.
  def self.close_slot(slot : Slot)
    _raise_if_slot_closed!(slot)

    success = LibSunVox.close_slot(slot.value) == 0
    raise Exception.new("Something went wrong closing slot #{slot}") unless success
    @@open_slots.delete(slot.value)
  end

  # Loads a filename into a slot.
  def self.load(slot : Slot, filename)
    _raise_if_slot_closed!(slot)

    success = LibSunVox.load(slot.value, filename) == 0
    raise Exception.new("Something went wrong closing slot #{slot}") unless success
  end

  # Plays the current song from the beginning.
  sunvox_slot_call("play_from_beginning")
  # Plays the current song from the current line.
  sunvox_slot_call("play")
  # Stops the current song from playing. 2 calls will stop all the synths and sounds.
  sunvox_slot_call("stop")
  # Pauses the playback at the current line.
  sunvox_slot_call("pause")
  # Resumes playback from a paused state.
  sunvox_slot_call("resume")

  # Returns whether or not a song will repeat when the end is reached.
  def self.repeats?(slot : Slot) : Bool
    _raise_if_slot_closed!(slot)

    LibSunVox.get_autostop(slot.value) == 1
  end

  # Sets whether or not a song will repeat when the end is reached.
  def self.set_repeat(slot : Slot, bool) : Nil
    _raise_if_slot_closed!(slot)

    LibSunVox.set_autostop(slot.value, bool ? 1 : 0)
  end

  # Is the song over and the end has been reached?
  def self.end_of_song?(slot : Slot) : Bool
    _raise_if_slot_closed!(slot)

    LibSunVox.end_of_song(slot.value) == 1
  end

  # Jumps the current position of the playhead to a line number.
  def self.skip_to_line(slot : Slot, line_num : Int32)
    _raise_if_slot_closed!(slot)

    LibSunVox.rewind(slot.value, line_num)
  end

  # Sets the output volume of the slot.
  def self.volume(slot : Slot, volume : UInt8)
    _raise_if_slot_closed!(slot)

    LibSunVox.volume(slot.value, volume.to_i)
  end

  # Gets the name of the song in `slot`
  def self.get_song_name(slot : Slot)
    _raise_if_slot_closed!(slot)

    String.new LibSunVox.get_song_name(slot.value)
  end

  # Sends an event to SunVox. Can be used to send notes, change ctl values, or set note effects. A `module_num` of `0` causes no effect, so any module you would like to actually use must have `1` added to it
  def self.send_event(slot : Slot, track_num, note : Note, velocity, module_num = -1, ctl = 0, effect = 0, ctl_value = 0)
    _raise_if_slot_closed!(slot)

    success = LibSunVox.send_event(slot.value, track_num, note, velocity, module_num + 1, (ctl << 8) + effect, ctl_value) == 0
    raise Exception.new("Cannot send_event on slot #{slot}") unless success
  end

  # Sends an event to SunVox. Can be used to send notes, change ctl values, or set note effects. A `module_num` of `0` causes no effect, so any module you would like to actually use must have `1` added to it
  def self.send_event(slot : Slot, track_num, note : Int32, velocity, module_num = -1, ctl = 0, effect = 0, ctl_value = 0)
    _raise_if_slot_closed!(slot)

    success = LibSunVox.send_event(slot.value, track_num, note, velocity, module_num + 1, (ctl << 8) + effect, ctl_value) == 0
    raise Exception.new("Cannot send_event on slot #{slot}") unless success
  end

  # Sends an event to SunVox. Can be used to send notes, change ctl values, or set note effects. A `module_num` of `0` causes no effect, so any module you would like to actually use must have `1` added to it
  def self.send_event(slot : Slot, track_num, event : Event)
    _raise_if_slot_closed!(slot)

    success = LibSunVox.send_event(slot.value, track_num, event.note, event.velocity, event.module + 1, (event.ctl << 8) + event.effect, event.ctl_value) == 0
    raise Exception.new("Cannot send_event on slot #{slot}") unless success
  end

  # Changes how SunVox processes `send_event`. Instead of playing the event as soon as it's called, this allows `send_event` to be delayed by a number of ticks. When setting `set` to `false` it will reset the timing method back to immediate. When used `timestamp` should generally be `SunVox.ticks + (SunVox.ticks_per_second/1000 * delay_milliseconds)`
  def self.set_event_time(slot : Slot, timestamp : UInt32 = 0_u32, set = true)
    _raise_if_slot_closed!(slot)
    success = LibSunVox.set_event_t(slot.value, set ? 1 : 0, timestamp)
    raise Exception.new("Cannot send_event on slot #{slot}") unless success
  end

  # Honestly, no idea how this one works. Seems like it should be useful if someone who isn't me wants to figure it out lol: https://warmplace.ru/soft/sunvox/sunvox_lib.php#sv_get_time_map Good Luck!
  def self.time_map(slot : Slot, start_line, len, flags = 0)
    dest_ptr = Pointer(UInt32).malloc(len)
    LibSunVox.get_time_map(slot.value, start_line, len, dest_ptr, flags)
    dest_ptr.to_slice(len)
  end

  # Gets the debug log messages
  def self.get_log(bytes : Int32)
    String.new LibSunVox.get_log(bytes)
  end

  # The current tick
  def self.ticks : UInt32
    LibSunVox.get_ticks
  end

  # How many ticks happen per second
  def self.ticks_per_second : UInt32
    LibSunVox.get_ticks_per_second
  end

  # The current line the playhead is at
  sunvox_slot_call_return "get_current_line"
  # THe current line the play head is at in a fractional form (not sure how this works) https://warmplace.ru/soft/sunvox/sunvox_lib.php#sv_get_current_line2
  sunvox_slot_call_return "get_current_line2"
  # Gets the number of patterns in a `slot`
  sunvox_slot_call_return "get_number_of_patterns"
  # Gets the BPM of the song in `slot`
  sunvox_slot_call_return "get_song_bpm"

  # Number of lines executed in a second in the song.
  sunvox_slot_call_return "get_song_tpl"
  # The total length in ticks of the song in `slot`s.
  sunvox_slot_call_return "get_song_length_frames"
  # The total song length in lines of `slot`.
  sunvox_slot_call_return "get_song_length_lines"
  # The number of modules in `slot`
  sunvox_slot_call_return "get_number_of_modules"

  # Finds the pattern in `slot` by `name`
  def self.find_pattern(slot : Slot, name)
    _raise_if_slot_closed!(slot)
    LibSunVox.find_pattern(slot.value, name)
  end

  # Gets the pattern's starting line.
  def self.get_pattern_x(slot : Slot, pat_num)
    _raise_if_slot_closed!(slot)
    LibSunVox.get_pattern_x(slot.value, pat_num)
  end

  # Gets the pattern's height.
  def self.get_pattern_y(slot : Slot, pat_num)
    _raise_if_slot_closed!(slot)
    LibSunVox.get_pattern_y(slot.value, pat_num)
  end

  # Get the length of the song in seconds
  def self.get_song_length(slot : Slot)
    # get_song_length_frames(slot) / ticks_per_second
    Time::Span.new(seconds: (get_song_length_lines(slot) / get_song_tpl(slot)).to_i)
  end

  # Gets the current output signal level
  def self.get_current_signal_level(slot : Slot, channel)
    _raise_if_slot_closed!(slot)

    LibSunVox.get_current_signal_level(slot.value, channel)
  end

  # Gets the number of lines in a pattern
  def self.get_pattern_lines(slot : Slot, pattern_num)
    _raise_if_slot_closed!(slot)

    LibSunVox.get_pattern_lines(slot.value, pattern_num)
  end

  # Gets the pattern's name
  def self.get_pattern_name(slot : Slot, pattern_num)
    _raise_if_slot_closed!(slot)

    name_ptr = LibSunVox.get_pattern_name(slot.value, pattern_num)
    if name_ptr.null?
      ""
    else
      String.new name_ptr
    end
  end

  # Get the number of track in the pattern.
  def self.get_pattern_tracks(slot : Slot, pattern_num)
    _raise_if_slot_closed!(slot)

    LibSunVox.get_pattern_tracks(slot.value, pattern_num)
  end

  # Get the event data, seperated by tracks.
  def self.get_pattern_data(slot : Slot, pattern_num)
    _raise_if_slot_closed!(slot)

    lines = get_pattern_lines(slot, pattern_num)
    tracks = get_pattern_tracks(slot, pattern_num)
    data = LibSunVox.get_pattern_data(slot, pattern_num).to_slice(tracks * lines)
    track_data = [] of Array(SunVox::Event)
    tracks.times { track_data << ([] of SunVox::Event) }
    lines.times do |line_offset|
      tracks.times do |track_offset|
        libsunvox_event = data[tracks * line_offset + track_offset]
        sunvox_event = SunVox::Event.new(
          SunVox::Note.new(libsunvox_event.note.to_i),
          libsunvox_event.vel,
          libsunvox_event.mod_num.to_i16 - 1, # This can be negative in Crystal's structure for SunVox::Event
          (libsunvox_event.ctl >> 8).to_u8,
          (libsunvox_event.ctl & 0xFF).to_u8,
          libsunvox_event.ctl_val
        )

        track_data[track_offset] << sunvox_event
      end
    end
    track_data
  end

  # Mute/Unmute the pattern.
  def self.pattern_mute(slot : Slot, pattern_num, mute = true)
    _raise_if_slot_closed!(slot)

    _lock_slot(slot)
    muted = LibSunVox.pattern_mute(slot.value, pattern_num, mute ? 1 : 0) == mute
    _unlock_slot(slot)
    muted
  end

  # Create a new module in `slot`. Returns the number of the new module.
  def self.new_module(slot : Slot, type : ModuleType, name = "", x = 0, y = 0, z = 0)
    _raise_if_slot_closed!(slot)

    _lock_slot(slot)
    module_num = LibSunVox.new_module(slot.value, type.type, name, x, y, z)
    _unlock_slot(slot)

    raise Exception.new("Cannot create new module #{name} of #{type.type} on slot #{slot}") if module_num < 0
    module_num
  end

  # Remove the module `module_num` in `slot`.
  def self.remove_module(slot : Slot, module_num)
    _raise_if_slot_closed!(slot)

    _lock_slot(slot)
    success = LibSunVox.remove_module(slot.value, module_num) == 0
    _unlock_slot(slot)
    raise Exception.new("Cannot remove module on slot #{slot}") unless success
    success
  end

  # Connect a module `src` to a module `dest`.
  def self.connect_module(slot : Slot, src, dest)
    _raise_if_slot_closed!(slot)

    _lock_slot(slot)
    success = LibSunVox.connect_module(slot.value, src, dest) == 0
    _unlock_slot(slot)

    raise Exception.new("Cannot connect module #{src} to #{dest} on slot #{slot}") unless success
    success
  end

  # Disconnect a module `src` from a module `dest`.
  def self.disconnect_module(slot : Slot, src, dest)
    _raise_if_slot_closed!(slot)

    _lock_slot(slot)
    success = LibSunVox.disconnect_module(slot.value, src, dest) == 0
    _unlock_slot(slot)

    raise Exception.new("Cannot disconnect module #{src} from #{dest} on slot #{slot}") unless success
    success
  end

  # Load a module from a file. File can be sunsynth, xi, wav, or aiff.
  def self.load_module(slot : Slot, filename, x = 0, y = 0, z = 0)
    _raise_if_slot_closed!(slot)
    _lock_slot(slot)
    module_num = LibSunVox.load_module(slot.value, filename, x, y, z)
    _unlock_slot(slot)
    raise Exception.new("Cannot load module #{filename} on slot #{slot}") unless module_num > 0
    module_num
  end

  # Find a module in a `slot` by `name`
  def self.find_module(slot : Slot, name)
    _raise_if_slot_closed!(slot)
    LibSunVox.find_module(slot.value, name)
  end

  # TODO: Parse the flags
  # Get the flags set on a module
  def self.get_module_flags(slot : Slot, module_num)
    _raise_if_slot_closed!(slot)
    LibSunVox.get_module_flags(slot.value, module_num)
  end

  def self.module_exists?(slot : Slot, module_num)
    _raise_if_slot_closed!(slot)
    (LibSunVox.get_module_flags(slot.value, module_num) & 1) == 1 
  end

  def self.module_effect?(slot : Slot, module_num)
    _raise_if_slot_closed!(slot)
    ((LibSunVox.get_module_flags(slot.value, module_num) >> 1) & 1) == 1 
  end

  def self.module_mute?(slot : Slot, module_num)
    _raise_if_slot_closed!(slot)
    ((LibSunVox.get_module_flags(slot.value, module_num) >> 2) & 1) == 1 
  end

  def self.module_solo?(slot : Slot, module_num)
    _raise_if_slot_closed!(slot)
    ((LibSunVox.get_module_flags(slot.value, module_num) >> 3) & 1) == 1 
  end

  def self.module_bypass?(slot : Slot, module_num)
    _raise_if_slot_closed!(slot)
    ((LibSunVox.get_module_flags(slot.value, module_num) >> 4) & 1) == 1 
  end
  # Loads a file into a sampler. File must be xi, wav, or aiff.
  def self.sampler_load(slot : Slot, sampler_module_num, filename, sample_slot = -1)
    _raise_if_slot_closed!(slot)
    success = LibSunVox.sampler_load(slot.value, sampler_module_num, filename, sample_slot) == 0
    raise Exception.new("Cannot load #{filename} into sampler module #{src} from #{dest} on slot #{slot}") unless success
  end

  # The number of module inputs.
  def self.get_module_inputs_number(slot : Slot, module_num)
    (get_module_flags(slot, module_num) & LibSunVox::MODULE_INPUTS_MASK) >> MODULE_INPUTS_OFF
  end

  # The number of module outputs.
  def self.get_module_outputs_number(slot : Slot, module_num)
    (get_module_flags(slot, module_num) & LibSunVox::MODULE_OUTPUTS_MASK) >> MODULE_OUTPUTS_OFF
  end

  # A list of all the inputs a module has.
  def self.get_module_inputs(slot : Slot, module_num)
    LibSunVox.get_module_inputs(slot.value, module_num).to_slice(get_module_inputs_number(slot, module_num))
  end

  # A list of all the outputs a module has.
  def self.get_module_outputs(slot : Slot, module_num)
    LibSunVox.get_module_outputs(slot.value, module_num).to_slice(get_module_outputs_number(slot, module_num))
  end

  # Gets the name of a module.
  def self.get_module_name(slot : Slot, name)
    _raise_if_slot_closed!(slot)
    String.new LibSunVox.get_module_name(slot.value, name)
  end

  # Get the x, y positon of a module.
  def self.get_module_xy(slot : Slot, module_num)
    _raise_if_slot_closed!(slot)
    _unpack_module_xy(LibSunVox.get_module_xy(slot.value, module_num))
  end

  # TODO: Parse the color
  # Get the color of a module in 0xBBGGRR format.
  def self.get_module_color(slot : Slot, module_num)
    _raise_if_slot_closed!(slot)
    LibSunVox.get_module_color(slot.value, module_num)
  end

  # Get module's finetune values.
  def self.get_module_finetune(slot : Slot, module_num)
    _raise_if_slot_closed!(slot)
    _unpack_module_finetune(LibSunVox.get_module_finetune(slot.value, module_num))
  end

  # TODO: Not sure if this works right, and not sure how to check if it does.... Maybe try to output to WAV or something....
  # Get the raw audio output values for a module.
  def self.get_module_scope(slot : Slot, module_num, channel, samples_to_read)
    _raise_if_slot_closed!(slot)

    samples = Pointer(Int16).malloc(samples_to_read)
    LibSunVox.get_module_scope2(slot.value, module_num, channel, samples, samples_to_read)
    samples.to_slice(samples_to_read)
  end

  # Get the curve from a module
  def self.get_module_curve(slot : Slot, module_num, curve_num, length)
    _raise_if_slot_closed!(slot)
    curve_data = Pointer(Float32).malloc(length)

    curve_data_length = LibSunVox.get_module_curve(slot.value, module_num, curve_num, curve_data, length, 0)
    curve_data.to_slice(curve_data_length)
  end

  # TODO: Do I need to `Pointer.malloc` here?
  # Set the curve data of a module
  def self.set_module_curve(slot : Slot, module_num, curve_num, curve_data : Slice(Float32))
    _raise_if_slot_closed!(slot)
    LibSunVox.get_module_curve(slot.value, module_num, curve_num, pointerof(curve_data[0]), curve_data.size, 1)
  end

  # Get the number of controllers a module has.
  def self.get_number_of_module_ctls(slot : Slot, module_num)
    _raise_if_slot_closed!(slot)
    LibSunVox.get_number_of_module_ctls(slot.value, module_num)
  end

  # Get the name of a module's controller.
  def self.get_module_ctl_name(slot : Slot, module_num, ctl_num)
    _raise_if_slot_closed!(slot)
    String.new LibSunVox.get_module_ctl_name(slot.value, module_num, ctl_num)
  end

  # Get the value of a modules controller.
  def self.get_module_ctl_value(slot : Slot, module_num, ctl_num, scaled = false)
    _raise_if_slot_closed!(slot)
    LibSunVox.get_module_ctl_value(slot.value, module_num, ctl_num, scaled ? 1 : 0)
  end

  def self.update_input
    LibSunVox.update_input
  end

  # Unpacks the xy position
  private def self._unpack_module_xy(in_xy)
    out_x = in_xy & 0xFFFF
    out_x &-= 0x10000 if (out_x & 0x8000) > 0
    out_y = (in_xy >> 16) & 0xFFFF
    out_y &-= 0x10000 if (out_y & 0x8000) > 0
    {x: out_x, y: out_y}
  end

  # Unpacks the module's finetuning settings
  private def self._unpack_module_finetune(in_finetune)
    out_finetune = in_finetune & 0xFFFF
    out_finetune &-= 0x10000 if (out_finetune & 0x8000) > 0
    out_relative_note = (in_finetune >> 16) & 0xFFFF
    out_relative_note &-= 0x10000 if (out_relative_note & 0x8000) > 0
    {finetune: out_finetune, relative_note: out_relative_note}
  end

  def self.pitch_to_frequency(in_pitch)
    Math.pow(2, (30720.0_f32 - in_pitch) / 3072.0_f32) * 16.333984375
  end

  def self.frequency_to_pitch(in_freq)
    30720 - Math.log2(in_freq / 16.333984375) * 3072
  end
end

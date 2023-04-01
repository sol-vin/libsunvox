
@[Link("sunvox")]
lib LibSunVox
  # STYPE_INT16   = 0
  # STYPE_INT32   = 1
  # STYPE_FLOAT32 = 2
  # STYPE_FLOAT64 = 3

  # Send a "note off"
  NOTE_CMD_NOTE_OFF = 128
  # Send "note off" to all modules
  NOTECMD_ALL_NOTES_OFF = 129
  # Put all modules into standby state (stop and clear all internal buffers)
  NOTECMD_CLEAN_SYNTHS = 130
  NOTECMD_STOP         = 131
  NOTECMD_PLAY         = 132
  # Set the pitch specified in column XXYY, where 0x0000 - highest possible pitch, 0x7800 - lowest pitch (note C0); one semitone = 0x100.
  NOTECMD_SET_PITCH = 133

  INIT_FLAG_NO_DEBUG_OUTPUT = (1 << 0)

  # Offline mode: system-dependent audio stream will not be created; user must call sv_audio_callback() to get the next piece of sound stream;
  INIT_FLAG_OFFLINE       = (1 << 1)
  INIT_FLAG_AUDIO_INT16   = (1 << 2)
  INIT_FLAG_AUDIO_FLOAT32 = (1 << 3)
  INIT_FLAG_ONE_THREAD    = (1 << 4)

  TIME_MAP_SPEED          =  0
  TIME_MAP_FRAMECNT       =  1

  # Number of the module inputs = ( flags & SV_MODULE_INPUTS_MASK ) >> SV_MODULE_INPUTS_OFF
  # Number of the module outputs = ( flags & SV_MODULE_OUTPUTS_MASK ) >> SV_MODULE_OUTPUTS_OFF
  MODULE_FLAG_EXISTS  = (1 << 0)
  MODULE_FLAG_EFFECT  = (1 << 1)
  MODULE_FLAG_MUTE    = (1 << 2)
  MODULE_FLAG_SOLO    = (1 << 3)
  MODULE_FLAG_BYPASS  = (1 << 4)
  MODULE_INPUTS_OFF       = 16
  MODULE_INPUTS_MASK  = (255 << MODULE_INPUTS_OFF)
  MODULE_OUTPUTS_OFF  = (16 + 8)
  MODULE_OUTPUTS_MASK = (255 << MODULE_OUTPUTS_OFF)

  struct Event
    note : UInt8
    vel : UInt8
    mod_num : UInt8
    #    zero : UInt8 # WHy is this here?
    ctl : UInt16
    ctl_val : UInt16
  end

  # sv_init(), sv_deinit() - global sound system init/deinit
  # Parameters:
  #   config - string with additional configuration in the following format: "option_name=value|option_name=value";
  #            example: "buffer=1024|audiodriver=alsa|audiodevice=hw:0,0";
  #            use NULL for automatic configuration;
  #   freq - desired sample rate (Hz); min - 44100;
  #          the actual rate may be different, if SV_INIT_FLAG_USER_AUDIO_CALLBACK is not set;
  #   channels - only 2 supported now;
  #   flags - mix of the SV_INIT_FLAG_xxx flags.
  fun init = sv_init(LibC::Char*, LibC::Int, LibC::Int, LibC::UInt) : LibC::Int

  fun deinit = sv_deinit : LibC::Int

  # sv_get_sample_rate() - get current sampling rate (it may differ from the frequency specified in sv_init())
  fun get_sample_rate = sv_get_sample_rate : LibC::Int

  # TODO: Add these to SunVox module?
  # sv_update_input() -
  # handle input ON/OFF requests to enable/disable input ports of the sound card
  # (for example, after the Input module creation).
  # Call it from the main thread only, where the SunVox sound stream is not locked.
  fun update_input = sv_update_input : LibC::Int
  
  # TODO: Add these to SunVox module?
  # sv_audio_callback() - get the next piece of SunVox audio from the Output module.
  # With sv_audio_callback() you can ignore the built-in SunVox sound output mechanism and use some other sound system.
  # SV_INIT_FLAG_USER_AUDIO_CALLBACK flag in sv_init() must be set.
  # Parameters:
  #   buf - destination buffer of type int16_t (if SV_INIT_FLAG_AUDIO_INT16 used in sv_init())
  #         or float (if SV_INIT_FLAG_AUDIO_FLOAT32 used in sv_init());
  #         stereo data will be interleaved in this buffer: LRLR... (LR is a single frame (Left+Right));
  #   frames - number of frames in destination buffer;
  #   latency - audio latency (in frames);
  #   out_time - buffer output time (in system ticks);
  # Return values: 0 - silence, the output buffer is filled with zeros; 1 - the output buffer is filled.
  # Example 1 (simplified, without accurate time sync) - suitable for most cases:
  #   sv_audio_callback( buf, frames, 0, sv_get_ticks() );
  # Example 2 (accurate time sync) - when you need to maintain exact time intervals between incoming events (notes, commands, etc.):
  #   user_out_time = ... ; //output time in user time space (depends on your own implementation)
  #   user_cur_time = ... ; //current time in user time space
  #   user_ticks_per_second = ... ; //ticks per second in user time space
  #   user_latency = user_out_time - user_cur_time; //latency in user time space
  #   uint32_t sunvox_latency = ( user_latency * sv_get_ticks_per_second() ) / user_ticks_per_second; //latency in system time space
  #   uint32_t latency_frames = ( user_latency * sample_rate_Hz ) / user_ticks_per_second; //latency in frames
  #   sv_audio_callback( buf, frames, latency_frames, sv_get_ticks() + sunvox_latency );
  fun audio_callback = sv_audio_callback(Void*, LibC::Int, LibC::Int, LibC::UInt) : LibC::Int
  # TODO: Add these to SunVox module?
  # sv_audio_callback2() - send some data to the Input module and receive the filtered data from the Output module.
  # It's the same as sv_audio_callback() but you also can specify the input buffer.
  # Parameters:
  #   ...
  #   in_type - input buffer type: 0 - int16_t (16bit integer); 1 - float (32bit floating point);
  #   in_channels - number of input channels;
  #   in_buf - input buffer; stereo data must be interleaved in this buffer: LRLR... ; where the LR is the one frame (Left+Right channels);
  fun audio_callback2 = sv_audio_callback2(Void*, LibC::Int, LibC::Int, LibC::UInt, LibC::Int, LibC::Int, Void*) : LibC::Int

  # sv_open_slot(), sv_close_slot(), sv_lock_slot(), sv_unlock_slot() -
  # open/close/lock/unlock sound slot for SunVox.
  # You can use several slots simultaneously (each slot with its own SunVox engine).
  # Use lock/unlock when you simultaneously read and modify SunVox data from different threads (for the same slot);
  # example:
  #   thread 1: sv_lock_slot(0); sv_get_module_flags(0,mod1); sv_unlock_slot(0);
  #   thread 2: sv_lock_slot(0); sv_remove_module(0,mod2); sv_unlock_slot(0);
  # Some functions (marked as "USE LOCK/UNLOCK") can't work without lock/unlock at all.
  fun open_slot = sv_open_slot(LibC::Int) : LibC::Int
  fun close_slot = sv_close_slot(LibC::Int) : LibC::Int
  fun lock_slot = sv_lock_slot(LibC::Int) : LibC::Int
  fun unlock_slot = sv_unlock_slot(LibC::Int) : LibC::Int

  # sv_load(), sv_load_from_memory() -
  # load SunVox project from the file or from the memory block.
  fun load = sv_load(LibC::Int, LibC::Char*) : LibC::Int
  fun load_from_memory = sv_load_from_memory(LibC::Int, Void*, LibC::UInt) : LibC::Int

  # sv_play() - play from the current position;
  fun play = sv_play(LibC::Int) : LibC::Int
  # sv_play_from_beginning() - play from the beginning (line 0);
  fun play_from_beginning = sv_play_from_beginning(LibC::Int) : LibC::Int
  # sv_stop(): first call - stop playing; second call - reset all SunVox activity and switch the engine to standby mode
  fun stop = sv_stop(LibC::Int) : LibC::Int
  fun pause = sv_pause(LibC::Int) : LibC::Int
  fun resume = sv_resume(LibC::Int) : LibC::Int

  # sv_set_autostop(), sv_get_autostop() -
  # autostop values: 0 - disable autostop; 1 - enable autostop.
  # When autostop is OFF, the project plays endlessly in a loop.
  fun set_autostop = sv_set_autostop(LibC::Int, LibC::Int) : LibC::Int
  fun get_autostop = sv_get_autostop(LibC::Int) : LibC::Int

  # sv_end_of_song() return values: 0 - song is playing now; 1 - stopped.
  fun end_of_song = sv_end_of_song(LibC::Int) : LibC::Int
  fun rewind = sv_rewind(LibC::Int, LibC::Int) : LibC::Int
  #  sv_volume() - set volume from 0 (min) to 256 (max 100%);
  #  negative values are ignored;
  #  return value: previous volume;
  fun volume = sv_volume(LibC::Int, LibC::Int) : LibC::Int
  # sv_set_event_t() - set the timestamp of events to be sent by sv_send_event()
  # Parameters:
  #   slot;
  #   set: 1 - set; 0 - reset (use automatic time setting - the default mode);
  #   t: timestamp (in system ticks).
  # Examples:
  #   sv_set_event_t( slot, 1, 0 ) //not specified - further events will be processed as quickly as possible
  #   sv_set_event_t( slot, 1, sv_get_ticks() ) //time when the events will be processed = NOW + sound latancy * 2
  fun set_event_t = sv_set_event_t(LibC::Int, LibC::Int, LibC::Int) : LibC::Int
  # sv_send_event() - send an event (note ON, note OFF, controller change, etc.)
  # Parameters:
  #   slot;
  #   track_num - track number within the pattern;
  #   note: 0 - nothing; 1..127 - note num; 128 - note off; 129, 130... - see NOTECMD_xxx defines;
  #   vel: velocity 1..129; 0 - default;
  #   module: 0 (empty) or module number + 1 (1..65535);
  #   ctl: 0xCCEE. CC - number of a controller (1..255). EE - effect;
  #   ctl_val: value of controller or effect.
  fun send_event = sv_send_event(LibC::Int, LibC::Int, LibC::Int, LibC::Int, LibC::Int, LibC::Int, LibC::Int) : LibC::Int
  fun get_current_line = sv_get_current_line(LibC::Int) : LibC::Int
  fun get_current_line2 = sv_get_current_line2(LibC::Int) : LibC::Int
  fun get_current_signal_level = sv_get_current_signal_level(LibC::Int, LibC::Int) : LibC::Int
  fun get_song_name = sv_get_song_name(LibC::Int) : LibC::Char*
  fun get_song_bpm = sv_get_song_bpm(LibC::Int) : LibC::Int
  fun get_song_tpl = sv_get_song_tpl(LibC::Int) : LibC::Int

  # sv_get_song_length_frames(), sv_get_song_length_lines() -
  # get the project length.
  # Frame is one discrete of the sound. Sample rate 44100 Hz means, that you hear 44100 frames per second.
  fun get_song_length_frames = sv_get_song_length_frames(LibC::Int) : LibC::UInt
  fun get_song_length_lines = sv_get_song_length_lines(LibC::Int) : LibC::UInt
  # sv_get_time_map()
  # Parameters:
  #   slot;
  #   start_line - first line to read (usually 0);
  #   len - number of lines to read;
  #   dest - pointer to the buffer (size = len*sizeof(uint32_t)) for storing the map values;
  #   flags:
  #     SV_TIME_MAP_SPEED: dest[X] = BPM | ( TPL << 16 ) (speed at the beginning of line X);
  #     SV_TIME_MAP_FRAMECNT: dest[X] = frame counter at the beginning of line X;
  # Return value: 0 if successful, or negative value in case of some error.
  fun get_time_map = sv_get_time_map(LibC::Int, LibC::Int, LibC::Int, LibC::UInt*, LibC::Int) : LibC::Int
  # sv_new_module() - create a new module;
  fun new_module = sv_new_module(LibC::Int, LibC::Char*, LibC::Char*, LibC::Int, LibC::Int, LibC::Int) : LibC::Int
  # sv_remove_module() - remove selected module;
  fun remove_module = sv_remove_module(LibC::Int, LibC::Int) : LibC::Int
  # sv_connect_module() - connect the source to the destination;
  fun connect_module = sv_connect_module(LibC::Int, LibC::Int, LibC::Int) : LibC::Int
  # sv_disconnect_module() - disconnect the source from the destination;
  fun disconnect_module = sv_disconnect_module(LibC::Int, LibC::Int, LibC::Int) : LibC::Int
  # sv_load_module() - load a module or sample; supported file formats: sunsynth, xi, wav, aiff;
  #                   return value: new module number or negative value in case of some error;
  fun load_module = sv_load_module(LibC::Int, LibC::Char*, LibC::Int, LibC::Int, LibC::Int) : LibC::Int
  # TODO: Figure out how this works :(
  # sv_load_module_from_memory() - load a module or sample from the memory block;
  fun load_module_from_memory = sv_load_module_from_memory(LibC::Int, LibC::Int, Void*, LibC::UInt, LibC::Int) : LibC::Int
  # sv_sampler_load() - load a sample to already created Sampler; to replace the whole sampler - set sample_slot to -1;
  fun sampler_load = sv_sampler_load(LibC::Int, LibC::Int, LibC::Char*, LibC::Int) : LibC::Int
  # sv_sampler_load_from_memory() - load a sample from the memory block;
  fun sampler_load_from_memory = sv_sampler_load_from_memory(LibC::Int, LibC::Int, Void*, LibC::UInt, LibC::Int) : LibC::Int
  fun get_number_of_modules = sv_get_number_of_modules(LibC::Int) : LibC::Int
  # sv_find_module() - find a module by name;
  # return value: module number or -1 (if not found);
  fun find_module = sv_find_module(LibC::Int, LibC::Char*) : LibC::Int
  fun get_module_flags = sv_get_module_flags(LibC::Int, LibC::Int) : LibC::UInt

  # sv_get_module_inputs(), sv_get_module_outputs() -
  # get pointers to the int[] arrays with the input/output links.
  # Number of inputs = ( module_flags & SV_MODULE_INPUTS_MASK ) >> SV_MODULE_INPUTS_OFF.
  # Number of outputs = ( module_flags & SV_MODULE_OUTPUTS_MASK ) >> SV_MODULE_OUTPUTS_OFF.
  fun get_module_inputs = sv_get_module_inputs(LibC::Int, LibC::Int) : LibC::Int*
  fun get_module_outputs = sv_get_module_outputs(LibC::Int, LibC::Int) : LibC::Int*
  fun get_module_name = sv_get_module_name(LibC::Int, LibC::Int) : LibC::Char*

  #    sv_get_module_xy() - get module XY coordinates packed in a single uint32 value:
  #  ( x & 0xFFFF ) | ( ( y & 0xFFFF ) << 16 )
  #  Normal working area: 0x0 ... 1024x1024
  #  Center: 512x512
  #  Use LibSunVoxMacros.get_module_xy() macro to unpack X and Y.
  fun get_module_xy = sv_get_module_xy(LibC::Int, LibC::Int) : LibC::UInt
  #  sv_get_module_color() - get module color in the following format: 0xBBGGRR
  fun get_module_color = sv_get_module_color(LibC::Int, LibC::Int) : LibC::Int

  # sv_get_module_finetune() - get the relative note and finetune of the module;
  # return value: ( finetune & 0xFFFF ) | ( ( relative_note & 0xFFFF ) << 16 ).
  # Use SV_GET_MODULE_FINETUNE() macro to unpack finetune and relative_note.
  fun get_module_finetune = sv_get_module_finetune(LibC::Int, LibC::Int) : LibC::UInt
  # sv_get_module_scope2() return value = received number of samples (may be less or equal to samples_to_read).
  # Example:
  #   int16_t buf[ 1024 ];
  #   int received = sv_get_module_scope2( slot, mod_num, 0, buf, 1024 );
  #   //buf[ 0 ] = value of the first sample (-32768...32767);
  #   //buf[ 1 ] = value of the second sample;
  #   //...
  #   //buf[ received - 1 ] = value of the last received sample;
  fun get_module_scope2 = sv_get_module_scope2(LibC::Int, LibC::Int, LibC::Int, LibC::Short*, LibC::UInt) : LibC::UInt
  # sv_module_curve() - access to the curve values of the specified module
  # Parameters:
  #   slot;
  #   mod_num - module number;
  #   curve_num - curve number;
  #   data - destination or source buffer;
  #   len - number of items to read/write;
  #   w - read (0) or write (1).
  # return value: number of items processed successfully.
  # Available curves (Y=CURVE[X]):
  #   MultiSynth:
  #     0 - X = note (0..127); Y = velocity (0..1); 128 items;
  #     1 - X = velocity (0..256); Y = velocity (0..1); 257 items;
  #     2 - X = note (0..127); Y = pitch (0..1); 128 items;
  #         pitch range: 0 ... 16384/65535 (note0) ... 49152/65535 (note128) ... 1; semitone = 256/65535;
  #   WaveShaper:
  #     0 - X = input (0..255); Y = output (0..1); 256 items;
  #   MultiCtl:
  #     0 - X = input (0..256); Y = output (0..1); 257 items;
  #   Analog Generator, Generator:
  #     0 - X = drawn waveform sample number (0..31); Y = volume (-1..1); 32 items;
  fun module_curve = sv_module_curve(LibC::Int, LibC::Int, LibC::Int, LibC::Float*, LibC::Int, LibC::Int) : LibC::Int
  fun get_number_of_module_ctls = sv_get_number_of_module_ctls(LibC::Int, LibC::Int) : LibC::Int
  fun get_module_ctl_name = sv_get_module_ctl_name(LibC::Int, LibC::Int, LibC::Int) : LibC::Char*
  fun get_module_ctl_value = sv_get_module_ctl_value(LibC::Int, LibC::Int, LibC::Int, LibC::Int) : LibC::Int
  fun get_number_of_patterns = sv_get_number_of_patterns(LibC::Int) : LibC::Int
  # sv_find_pattern() - find a pattern by name;
  # return value: pattern number or -1 (if not found);
  fun find_pattern = sv_find_pattern(LibC::Int, LibC::Char*) : LibC::Int
  # sv_get_pattern_xxxx - get pattern information
  # x - time (line number);
  # y - vertical position on timeline;
  # tracks - number of pattern tracks;
  # lines - number of pattern lines;
  # name - pattern name or NULL;
  fun get_pattern_x = sv_get_pattern_x(LibC::Int, LibC::Int) : LibC::Int
  fun get_pattern_y = sv_get_pattern_y(LibC::Int, LibC::Int) : LibC::Int
  fun get_pattern_tracks = sv_get_pattern_tracks(LibC::Int, LibC::Int) : LibC::Int
  fun get_pattern_lines = sv_get_pattern_lines(LibC::Int, LibC::Int) : LibC::Int
  fun get_pattern_name = sv_get_pattern_name(LibC::Int, LibC::Int) : LibC::Char*
  # sv_get_pattern_data() - get the pattern buffer (for reading and writing)
  # containing notes (events) in the following order:
  #   line 0: note for track 0, note for track 1, ... note for track X;
  #   line 1: note for track 0, note for track 1, ... note for track X;
  #   ...
  #   line X: ...
  # Example:
  #   int pat_tracks = sv_get_pattern_tracks( slot, pat_num ); //number of tracks
  #   sunvox_note* data = sv_get_pattern_data( slot, pat_num ); //get the buffer with all the pattern events (notes)
  #   sunvox_note* n = &data[ line_number * pat_tracks + track_number ];
  #   ... and then do someting with note n ...
  fun get_pattern_data = sv_get_pattern_data(LibC::Int, LibC::Int) : Event*

  # sv_pattern_mute() - mute (1) / unmute (0) specified pattern;
  # negative values are ignored;
  # return value: previous state (1 - muted; 0 - unmuted) or -1 (error);
  fun pattern_mute = sv_pattern_mute(LibC::Int, LibC::Int, LibC::Int) : LibC::Int

  # SunVox engine uses system-provided time space, measured in system ticks (don't confuse it with the project ticks).
  # These ticks are required for parameters of functions such as sv_audio_callback() and sv_set_event_t().
  # Use sv_get_ticks() to get current tick counter (from 0 to 0xFFFFFFFF).
  # Use sv_get_ticks_per_second() to get the number of system ticks per second.
  fun get_ticks = sv_get_ticks : LibC::UInt
  fun get_ticks_per_second = sv_get_ticks_per_second : LibC::UInt
  # sv_get_log() - get the latest messages from the log
  # Parameters:
  #   size - max number of bytes to read.
  # Return value: pointer to the null-terminated string with the latest log messages.
  fun get_log = sv_get_log(LibC::Int) : LibC::Char*


  # TODO: Found in lib when dumpbin
  # sv_metamodule_load
  # sv_metamodule_load_from_memory
  # sv_sync_resume
  # sv_vplayer_load
  # sv_vplayer_load_from_memory
  # sv_fsave
  # sv_fload


  # Wondows. 💩
  # fun load_dll2 = sv_load_dll2(filename : LibC::Char*) : LibC::Int
  # fun load_dll = sv_load_dll : LibC::Int
  # fun unload_dll = sv_unload_dll : LibC::Int

  # Removed????
  # fun get_module_scope = sv_get_module_scope(LibC::Int, LibC::Int, LibC::Int, LibC::Int*, LibC::Int*) : Void*
  # fun get_module_ctl_name = sv_get_module_ctl_name(LibC::Int, LibC::Int, LibC::Int) : LibC::Char*
  # fun get_module_ctl_value = sv_get_module_ctl_value(LibC::Int, LibC::Int, LibC::Int, LibC::Int) : LibC::Int
  # fun get_number_of_patterns = sv_get_number_of_patterns(LibC::Int) : LibC::Int
  # fun get_sample_type = sv_get_sample_type : LibC::Int
end

require "./note"
require "./sunvox"

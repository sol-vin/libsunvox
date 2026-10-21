{% if flag?(:win32) %}
  # On Windows, sunvox.dll is built with MinGW and allocates memory via msvcrt.dll's malloc(),
  # whereas Crystal links LibC against UCRT. Resolve msvcrt.dll's free() dynamically.
  lib LibSunVoxWin32
    fun get_module_handle_a = GetModuleHandleA(module_name : LibC::Char*) : Void*
    fun get_proc_address = GetProcAddress(mod : Void*, proc_name : LibC::Char*) : Void*
  end
{% end %}

{% if flag?(:darwin) %}
  @[Link(ldflags: "-L/usr/local/lib -lsunvox")]
{% else %}
  @[Link("sunvox")]
{% end %}
lib LibSunVox
  # Send a "note off"
  NOTE_CMD_NOTE_OFF = 128
  NOTECMD_NOTE_OFF  = 128
  # Send "note off" to all modules
  NOTECMD_ALL_NOTES_OFF = 129
  # Put all modules into standby state (stop and clear all internal buffers)
  NOTECMD_CLEAN_SYNTHS = 130
  NOTECMD_STOP         = 131
  NOTECMD_PLAY         = 132
  # Set the pitch specified in column XXYY, where 0x0000 - highest possible pitch, 0x7800 - lowest pitch (note C0); one semitone = 0x100.
  NOTECMD_SET_PITCH = 133
  # Stop the module - clear its internal buffers and put it into standby mode
  NOTECMD_CLEAN_MODULE = 140

  INIT_FLAG_NO_DEBUG_OUTPUT = (1 << 0)
  # Offline mode: system-dependent audio stream will not be created; user must call sv_audio_callback() to get the next piece of sound stream
  INIT_FLAG_USER_AUDIO_CALLBACK = (1 << 1)
  INIT_FLAG_OFFLINE             = (1 << 1)
  INIT_FLAG_AUDIO_INT16         = (1 << 2)
  INIT_FLAG_AUDIO_FLOAT32       = (1 << 3)
  INIT_FLAG_ONE_THREAD          = (1 << 4)

  TIME_MAP_SPEED    = 0
  TIME_MAP_FRAMECNT = 1

  # Flags for sv_get_module_flags():
  # Number of the module inputs = ( flags & SV_MODULE_INPUTS_MASK ) >> SV_MODULE_INPUTS_OFF
  # Number of the module outputs = ( flags & SV_MODULE_OUTPUTS_MASK ) >> SV_MODULE_OUTPUTS_OFF
  MODULE_FLAG_EXISTS    = (1 << 0)
  MODULE_FLAG_GENERATOR = (1 << 1) # Note input + Sound output
  MODULE_FLAG_EFFECT    = (1 << 2) # Sound input + Sound output
  MODULE_FLAG_MUTE      = (1 << 3)
  MODULE_FLAG_SOLO      = (1 << 4)
  MODULE_FLAG_BYPASS    = (1 << 5)
  MODULE_INPUTS_OFF     = 16
  MODULE_INPUTS_MASK    = (255 << MODULE_INPUTS_OFF)
  MODULE_OUTPUTS_OFF    = (16 + 8)
  MODULE_OUTPUTS_MASK   = (255 << MODULE_OUTPUTS_OFF)

  struct Event
    note : UInt8     # NN: 0 - nothing; 1..127 - note num; 128 - note off; 129, 130... - see NOTECMD_* defines
    vel : UInt8      # VV: Velocity 1..129; 0 - default
    mod_num : UInt16 # MM: 0 - nothing; 1..65535 - module number + 1
    ctl : UInt16     # 0xCCEE: CC: 1..127 - controller number + 1; EE - effect
    ctl_val : UInt16 # 0xXXYY: controller value or effect parameter
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
  fun init = sv_init(config : LibC::Char*, freq : LibC::Int, channels : LibC::Int, flags : LibC::UInt) : LibC::Int

  fun deinit = sv_deinit : LibC::Int

  # sv_get_sample_rate() - get current sampling rate (it may differ from the frequency specified in sv_init())
  fun get_sample_rate = sv_get_sample_rate : LibC::Int

  # sv_update_input() -
  # handle input ON/OFF requests to enable/disable input ports of the sound card
  # (for example, after the Input module creation).
  # Call it from the main thread only, where the SunVox sound stream is not locked.
  fun update_input = sv_update_input : LibC::Int

  # sv_audio_callback() - get the next piece of SunVox audio from the Output module.
  # With sv_audio_callback() you can ignore the built-in SunVox sound output mechanism and use some other sound system.
  # SV_INIT_FLAG_USER_AUDIO_CALLBACK flag in sv_init() must be set.
  fun audio_callback = sv_audio_callback(buf : Void*, frames : LibC::Int, latency : LibC::Int, out_time : LibC::UInt) : LibC::Int

  # sv_audio_callback2() - send some data to the Input module and receive the filtered data from the Output module.
  # It's the same as sv_audio_callback() but you also can specify the input buffer.
  fun audio_callback2 = sv_audio_callback2(buf : Void*, frames : LibC::Int, latency : LibC::Int, out_time : LibC::UInt, in_type : LibC::Int, in_channels : LibC::Int, in_buf : Void*) : LibC::Int

  # sv_open_slot(), sv_close_slot(), sv_lock_slot(), sv_unlock_slot() -
  # open/close/lock/unlock sound slot for SunVox.
  fun open_slot = sv_open_slot(slot : LibC::Int) : LibC::Int
  fun close_slot = sv_close_slot(slot : LibC::Int) : LibC::Int
  fun lock_slot = sv_lock_slot(slot : LibC::Int) : LibC::Int
  fun unlock_slot = sv_unlock_slot(slot : LibC::Int) : LibC::Int

  # sv_load(), sv_load_from_memory() -
  # load SunVox project from the file or from the memory block.
  fun load = sv_load(slot : LibC::Int, name : LibC::Char*) : LibC::Int
  fun load_from_memory = sv_load_from_memory(slot : LibC::Int, data : Void*, data_size : LibC::UInt) : LibC::Int

  # sv_save(), sv_save_to_memory() -
  # save project to a file or to a malloc-allocated memory block (caller must free()).
  fun save = sv_save(slot : LibC::Int, name : LibC::Char*) : LibC::Int
  fun save_to_memory = sv_save_to_memory(slot : LibC::Int, size : LibC::SizeT*) : Void*

  # sv_play() - play from the current position;
  fun play = sv_play(slot : LibC::Int) : LibC::Int
  # sv_play_from_beginning() - play from the beginning (line 0);
  fun play_from_beginning = sv_play_from_beginning(slot : LibC::Int) : LibC::Int
  # sv_stop(): first call - stop playing; second call - reset all SunVox activity and switch the engine to standby mode
  fun stop = sv_stop(slot : LibC::Int) : LibC::Int
  fun pause = sv_pause(slot : LibC::Int) : LibC::Int
  fun resume = sv_resume(slot : LibC::Int) : LibC::Int
  # sv_sync_resume() - wait for sync (pattern effect 0x33 on any slot) and resume the audio stream on the specified slot
  fun sync_resume = sv_sync_resume(slot : LibC::Int) : LibC::Int

  # sv_set_autostop(), sv_get_autostop() -
  # autostop values: 0 - disable autostop; 1 - enable autostop.
  # When autostop is OFF, the project plays endlessly in a loop.
  fun set_autostop = sv_set_autostop(slot : LibC::Int, autostop : LibC::Int) : LibC::Int
  fun get_autostop = sv_get_autostop(slot : LibC::Int) : LibC::Int

  # sv_end_of_song() return values: 0 - song is playing now; 1 - stopped.
  fun end_of_song = sv_end_of_song(slot : LibC::Int) : LibC::Int
  fun rewind = sv_rewind(slot : LibC::Int, line_num : LibC::Int) : LibC::Int

  # sv_volume() - set volume from 0 (min) to 256 (max 100%);
  # negative values are ignored;
  # return value: previous volume;
  fun volume = sv_volume(slot : LibC::Int, vol : LibC::Int) : LibC::Int

  # sv_set_event_t() - set the timestamp of events to be sent by sv_send_event()
  fun set_event_t = sv_set_event_t(slot : LibC::Int, set : LibC::Int, t : LibC::Int) : LibC::Int

  # sv_send_event() - send an event (note ON, note OFF, controller change, etc.)
  fun send_event = sv_send_event(slot : LibC::Int, track_num : LibC::Int, note : LibC::Int, vel : LibC::Int, mod : LibC::Int, ctl : LibC::Int, ctl_val : LibC::Int) : LibC::Int

  fun get_current_line = sv_get_current_line(slot : LibC::Int) : LibC::Int
  fun get_current_line2 = sv_get_current_line2(slot : LibC::Int) : LibC::Int
  fun get_current_signal_level = sv_get_current_signal_level(slot : LibC::Int, channel : LibC::Int) : LibC::Int

  fun get_song_name = sv_get_song_name(slot : LibC::Int) : LibC::Char*
  fun set_song_name = sv_set_song_name(slot : LibC::Int, name : LibC::Char*) : LibC::Int
  fun get_base_version = sv_get_base_version(slot : LibC::Int) : LibC::Int
  fun get_song_bpm = sv_get_song_bpm(slot : LibC::Int) : LibC::Int
  fun get_song_tpl = sv_get_song_tpl(slot : LibC::Int) : LibC::Int

  # sv_get_song_length_frames(), sv_get_song_length_lines() -
  # get the project length.
  fun get_song_length_frames = sv_get_song_length_frames(slot : LibC::Int) : LibC::UInt
  fun get_song_length_lines = sv_get_song_length_lines(slot : LibC::Int) : LibC::UInt

  # sv_get_time_map()
  fun get_time_map = sv_get_time_map(slot : LibC::Int, start_line : LibC::Int, len : LibC::Int, dest : LibC::UInt*, flags : LibC::Int) : LibC::Int

  # sv_new_module() - create a new module (USE LOCK/UNLOCK!);
  fun new_module = sv_new_module(slot : LibC::Int, type : LibC::Char*, name : LibC::Char*, x : LibC::Int, y : LibC::Int, z : LibC::Int) : LibC::Int
  # sv_remove_module() - remove selected module (USE LOCK/UNLOCK!);
  fun remove_module = sv_remove_module(slot : LibC::Int, mod_num : LibC::Int) : LibC::Int
  # sv_connect_module() - connect the source to the destination (USE LOCK/UNLOCK!);
  fun connect_module = sv_connect_module(slot : LibC::Int, source : LibC::Int, destination : LibC::Int) : LibC::Int
  # sv_disconnect_module() - disconnect the source from the destination (USE LOCK/UNLOCK!);
  fun disconnect_module = sv_disconnect_module(slot : LibC::Int, source : LibC::Int, destination : LibC::Int) : LibC::Int

  # sv_load_module() - load a module or sample; supported file formats: sunsynth, xi, wav, aiff, ogg, mp3, flac;
  fun load_module = sv_load_module(slot : LibC::Int, file_name : LibC::Char*, x : LibC::Int, y : LibC::Int, z : LibC::Int) : LibC::Int
  # sv_load_module_from_memory() - load a module or sample from the memory block;
  fun load_module_from_memory = sv_load_module_from_memory(slot : LibC::Int, data : Void*, data_size : LibC::UInt, x : LibC::Int, y : LibC::Int, z : LibC::Int) : LibC::Int

  # sv_sampler_load() - load a sample into the Sampler; to replace the whole sampler - set sample_slot to -1;
  fun sampler_load = sv_sampler_load(slot : LibC::Int, mod_num : LibC::Int, file_name : LibC::Char*, sample_slot : LibC::Int) : LibC::Int
  # sv_sampler_load_from_memory() - load a sample from the memory block;
  fun sampler_load_from_memory = sv_sampler_load_from_memory(slot : LibC::Int, mod_num : LibC::Int, data : Void*, data_size : LibC::UInt, sample_slot : LibC::Int) : LibC::Int
  # sv_sampler_par() - set/get sample parameter;
  fun sampler_par = sv_sampler_par(slot : LibC::Int, mod_num : LibC::Int, sample_slot : LibC::Int, par : LibC::Int, par_val : LibC::Int, set : LibC::Int) : LibC::Int

  # sv_metamodule_load() - load a file into the MetaModule; supported file formats: sunvox, mod, xm, midi;
  fun metamodule_load = sv_metamodule_load(slot : LibC::Int, mod_num : LibC::Int, file_name : LibC::Char*) : LibC::Int
  fun metamodule_load_from_memory = sv_metamodule_load_from_memory(slot : LibC::Int, mod_num : LibC::Int, data : Void*, data_size : LibC::UInt) : LibC::Int

  # sv_vplayer_load() - load a file into the Vorbis Player; supported file formats: ogg;
  fun vplayer_load = sv_vplayer_load(slot : LibC::Int, mod_num : LibC::Int, file_name : LibC::Char*) : LibC::Int
  fun vplayer_load_from_memory = sv_vplayer_load_from_memory(slot : LibC::Int, mod_num : LibC::Int, data : Void*, data_size : LibC::UInt) : LibC::Int

  fun get_number_of_modules = sv_get_number_of_modules(slot : LibC::Int) : LibC::Int
  # sv_find_module() - find a module by name; return value: module number or -1 (if not found);
  fun find_module = sv_find_module(slot : LibC::Int, name : LibC::Char*) : LibC::Int
  fun get_module_flags = sv_get_module_flags(slot : LibC::Int, mod_num : LibC::Int) : LibC::UInt

  # sv_get_module_inputs(), sv_get_module_outputs() -
  # get pointers to the int[] arrays with the input/output links.
  fun get_module_inputs = sv_get_module_inputs(slot : LibC::Int, mod_num : LibC::Int) : LibC::Int*
  fun get_module_outputs = sv_get_module_outputs(slot : LibC::Int, mod_num : LibC::Int) : LibC::Int*

  fun get_module_type = sv_get_module_type(slot : LibC::Int, mod_num : LibC::Int) : LibC::Char*
  fun get_module_name = sv_get_module_name(slot : LibC::Int, mod_num : LibC::Int) : LibC::Char*
  fun set_module_name = sv_set_module_name(slot : LibC::Int, mod_num : LibC::Int, name : LibC::Char*) : LibC::Int

  # sv_get_module_xy() - get module XY coordinates packed in a single uint32 value
  fun get_module_xy = sv_get_module_xy(slot : LibC::Int, mod_num : LibC::Int) : LibC::UInt
  fun set_module_xy = sv_set_module_xy(slot : LibC::Int, mod_num : LibC::Int, x : LibC::Int, y : LibC::Int) : LibC::Int

  # sv_get_module_color(), sv_set_module_color() - get/set module color in the following format: 0xBBGGRR
  fun get_module_color = sv_get_module_color(slot : LibC::Int, mod_num : LibC::Int) : LibC::Int
  fun set_module_color = sv_set_module_color(slot : LibC::Int, mod_num : LibC::Int, color : LibC::Int) : LibC::Int

  # sv_get_module_finetune() - get the relative note and finetune of the module
  fun get_module_finetune = sv_get_module_finetune(slot : LibC::Int, mod_num : LibC::Int) : LibC::UInt
  fun set_module_finetune = sv_set_module_finetune(slot : LibC::Int, mod_num : LibC::Int, finetune : LibC::Int) : LibC::Int
  fun set_module_relnote = sv_set_module_relnote(slot : LibC::Int, mod_num : LibC::Int, relative_note : LibC::Int) : LibC::Int

  # sv_get_module_scope2() return value = received number of samples (may be less or equal to samples_to_read).
  fun get_module_scope2 = sv_get_module_scope2(slot : LibC::Int, mod_num : LibC::Int, channel : LibC::Int, dest_buf : LibC::Short*, samples_to_read : LibC::UInt) : LibC::UInt

  # sv_module_curve() - access to the curve values of the specified module
  fun module_curve = sv_module_curve(slot : LibC::Int, mod_num : LibC::Int, curve_num : LibC::Int, data : LibC::Float*, len : LibC::Int, w : LibC::Int) : LibC::Int

  fun get_number_of_module_ctls = sv_get_number_of_module_ctls(slot : LibC::Int, mod_num : LibC::Int) : LibC::Int
  fun get_module_ctl_name = sv_get_module_ctl_name(slot : LibC::Int, mod_num : LibC::Int, ctl_num : LibC::Int) : LibC::Char*
  fun get_module_ctl_value = sv_get_module_ctl_value(slot : LibC::Int, mod_num : LibC::Int, ctl_num : LibC::Int, scaled : LibC::Int) : LibC::Int
  fun set_module_ctl_value = sv_set_module_ctl_value(slot : LibC::Int, mod_num : LibC::Int, ctl_num : LibC::Int, val : LibC::Int, scaled : LibC::Int) : LibC::Int
  fun get_module_ctl_min = sv_get_module_ctl_min(slot : LibC::Int, mod_num : LibC::Int, ctl_num : LibC::Int, scaled : LibC::Int) : LibC::Int
  fun get_module_ctl_max = sv_get_module_ctl_max(slot : LibC::Int, mod_num : LibC::Int, ctl_num : LibC::Int, scaled : LibC::Int) : LibC::Int
  fun get_module_ctl_offset = sv_get_module_ctl_offset(slot : LibC::Int, mod_num : LibC::Int, ctl_num : LibC::Int) : LibC::Int
  fun get_module_ctl_type = sv_get_module_ctl_type(slot : LibC::Int, mod_num : LibC::Int, ctl_num : LibC::Int) : LibC::Int
  fun get_module_ctl_group = sv_get_module_ctl_group(slot : LibC::Int, mod_num : LibC::Int, ctl_num : LibC::Int) : LibC::Int

  # Pattern management
  fun new_pattern = sv_new_pattern(slot : LibC::Int, clone : LibC::Int, x : LibC::Int, y : LibC::Int, tracks : LibC::Int, lines : LibC::Int, icon_seed : LibC::Int, name : LibC::Char*) : LibC::Int
  fun remove_pattern = sv_remove_pattern(slot : LibC::Int, pat_num : LibC::Int) : LibC::Int
  fun get_number_of_patterns = sv_get_number_of_patterns(slot : LibC::Int) : LibC::Int
  fun find_pattern = sv_find_pattern(slot : LibC::Int, name : LibC::Char*) : LibC::Int
  fun get_pattern_x = sv_get_pattern_x(slot : LibC::Int, pat_num : LibC::Int) : LibC::Int
  fun get_pattern_y = sv_get_pattern_y(slot : LibC::Int, pat_num : LibC::Int) : LibC::Int
  fun set_pattern_xy = sv_set_pattern_xy(slot : LibC::Int, pat_num : LibC::Int, x : LibC::Int, y : LibC::Int) : LibC::Int
  fun get_pattern_tracks = sv_get_pattern_tracks(slot : LibC::Int, pat_num : LibC::Int) : LibC::Int
  fun get_pattern_lines = sv_get_pattern_lines(slot : LibC::Int, pat_num : LibC::Int) : LibC::Int
  fun set_pattern_size = sv_set_pattern_size(slot : LibC::Int, pat_num : LibC::Int, tracks : LibC::Int, lines : LibC::Int) : LibC::Int
  fun get_pattern_name = sv_get_pattern_name(slot : LibC::Int, pat_num : LibC::Int) : LibC::Char*
  fun set_pattern_name = sv_set_pattern_name(slot : LibC::Int, pat_num : LibC::Int, name : LibC::Char*) : LibC::Int
  fun get_pattern_data = sv_get_pattern_data(slot : LibC::Int, pat_num : LibC::Int) : Event*
  fun set_pattern_event = sv_set_pattern_event(slot : LibC::Int, pat_num : LibC::Int, track : LibC::Int, line : LibC::Int, nn : LibC::Int, vv : LibC::Int, mm : LibC::Int, ccee : LibC::Int, xxyy : LibC::Int) : LibC::Int
  fun get_pattern_event = sv_get_pattern_event(slot : LibC::Int, pat_num : LibC::Int, track : LibC::Int, line : LibC::Int, column : LibC::Int) : LibC::Int
  fun pattern_mute = sv_pattern_mute(slot : LibC::Int, pat_num : LibC::Int, mute : LibC::Int) : LibC::Int

  # System ticks and log
  fun get_ticks = sv_get_ticks : LibC::UInt
  fun get_ticks_per_second = sv_get_ticks_per_second : LibC::UInt
  fun get_log = sv_get_log(size : LibC::Int) : LibC::Char*
end

require "./sunvox"

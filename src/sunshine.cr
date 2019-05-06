#@[Include("/home/ian/Documents/crystal/sunshine/src/sunvox.h", prefix: %w(SV_ sv_))]
@[Link(ldflags: "-lsunvox")]

lib SunVox
  MODULE_FLAG_EXISTS = 1
  MODULE_FLAG_EFFECT = 2
  MODULE_INPUTS_OFF = 16
  STYPE_INT16 = 0
  STYPE_INT32 = 1
  STYPE_FLOAT32 = 2
  STYPE_FLOAT64 = 3
  alias TsvAudioCallback = (Void*, LibC::Int, LibC::Int, LibC::UInt -> LibC::Int)
  alias TsvAudioCallback2 = (Void*, LibC::Int, LibC::Int, LibC::UInt, LibC::Int, LibC::Int, Void* -> LibC::Int)
  alias TsvOpenSlot = (LibC::Int -> LibC::Int)
  alias TsvCloseSlot = (LibC::Int -> LibC::Int)
  alias TsvLockSlot = (LibC::Int -> LibC::Int)
  alias TsvUnlockSlot = (LibC::Int -> LibC::Int)
  alias TsvInit = (LibC::Char*, LibC::Int, LibC::Int, LibC::UInt -> LibC::Int)
  alias TsvDeinit = ( -> LibC::Int)
  alias TsvUpdateInput = ( -> LibC::Int)
  alias TsvGetSampleType = ( -> LibC::Int)
  alias TsvLoad = (LibC::Int, LibC::Char* -> LibC::Int)
  alias TsvLoadFromMemory = (LibC::Int, Void*, LibC::UInt -> LibC::Int)
  alias TsvPlay = (LibC::Int -> LibC::Int)
  alias TsvPlayFromBeginning = (LibC::Int -> LibC::Int)
  alias TsvStop = (LibC::Int -> LibC::Int)
  alias TsvSetAutostop = (LibC::Int, LibC::Int -> LibC::Int)
  alias TsvEndOfSong = (LibC::Int -> LibC::Int)
  alias TsvRewind = (LibC::Int, LibC::Int -> LibC::Int)
  alias TsvVolume = (LibC::Int, LibC::Int -> LibC::Int)
  alias TsvSendEvent = (LibC::Int, LibC::Int, LibC::Int, LibC::Int, LibC::Int, LibC::Int, LibC::Int -> LibC::Int)
  alias TsvGetCurrentLine = (LibC::Int -> LibC::Int)
  alias TsvGetCurrentLine2 = (LibC::Int -> LibC::Int)
  alias TsvGetCurrentSignalLevel = (LibC::Int, LibC::Int -> LibC::Int)
  alias TsvGetSongName = (LibC::Int -> LibC::Char*)
  alias TsvGetSongBpm = (LibC::Int -> LibC::Int)
  alias TsvGetSongTpl = (LibC::Int -> LibC::Int)
  alias TsvGetSongLengthFrames = (LibC::Int -> LibC::UInt)
  alias TsvGetSongLengthLines = (LibC::Int -> LibC::UInt)
  alias TsvNewModule = (LibC::Int, LibC::Char*, LibC::Char*, LibC::Int, LibC::Int, LibC::Int -> LibC::Int)
  alias TsvRemoveModule = (LibC::Int, LibC::Int -> LibC::Int)
  alias TsvConnectModule = (LibC::Int, LibC::Int, LibC::Int -> LibC::Int)
  alias TsvDisconnectModule = (LibC::Int, LibC::Int, LibC::Int -> LibC::Int)
  alias TsvLoadModule = (LibC::Int, LibC::Char*, LibC::Int, LibC::Int, LibC::Int -> LibC::Int)
  alias TsvLoadModuleFromMemory = (LibC::Int, Void*, LibC::UInt, LibC::Int, LibC::Int, LibC::Int -> LibC::Int)
  alias TsvSamplerLoad = (LibC::Int, LibC::Int, LibC::Char*, LibC::Int -> LibC::Int)
  alias TsvSamplerLoadFromMemory = (LibC::Int, LibC::Int, Void*, LibC::UInt, LibC::Int -> LibC::Int)
  alias TsvGetNumberOfModules = (LibC::Int -> LibC::Int)
  alias TsvGetModuleFlags = (LibC::Int, LibC::Int -> LibC::UInt)
  alias TsvGetModuleInputs = (LibC::Int, LibC::Int -> LibC::Int)
  alias TsvGetModuleOutputs = (LibC::Int, LibC::Int -> LibC::Int)
  alias TsvGetModuleName = (LibC::Int, LibC::Int -> LibC::Char*)
  alias TsvGetModuleXy = (LibC::Int, LibC::Int -> LibC::UInt)
  alias TsvGetModuleColor = (LibC::Int, LibC::Int -> LibC::Int)
  alias TsvGetModuleScope = (LibC::Int, LibC::Int, LibC::Int, LibC::Int*, LibC::Int* -> Void*)
  alias TsvGetModuleScope2 = (LibC::Int, LibC::Int, LibC::Int, LibC::Short*, LibC::UInt -> LibC::UInt)
  alias TsvGetNumberOfModuleCtls = (LibC::Int, LibC::Int -> LibC::Int)
  alias TsvGetModuleCtlName = (LibC::Int, LibC::Int, LibC::Int -> LibC::Char*)
  alias TsvGetModuleCtlValue = (LibC::Int, LibC::Int, LibC::Int, LibC::Int -> LibC::Int)
  alias TsvGetNumberOfPatterns = (LibC::Int -> LibC::Int)
  alias TsvGetPatternX = (LibC::Int, LibC::Int -> LibC::Int)
  alias TsvGetPatternY = (LibC::Int, LibC::Int -> LibC::Int)
  alias TsvGetPatternTracks = (LibC::Int, LibC::Int -> LibC::Int)
  alias TsvGetPatternLines = (LibC::Int, LibC::Int -> LibC::Int)
  struct SunvoxNote
    note : Uint8T
    vel : Uint8T
    module : Uint8T
    zero : Uint8T
    ctl : Uint16T
    ctl_val : Uint16T
  end
  alias TsvGetPatternData = (LibC::Int, LibC::Int -> SunvoxNote*)
  alias X__Uint8T = UInt8
  alias Uint8T = X__Uint8T
  alias X__Uint16T = LibC::UShort
  alias Uint16T = X__Uint16T
  alias TsvPatternMute = (LibC::Int, LibC::Int, LibC::Int -> LibC::Int)
  alias TsvGetTicks = ( -> LibC::UInt)
  alias TsvGetTicksPerSecond = ( -> LibC::UInt)
  alias TsvGetLog = (LibC::Int -> LibC::Char*)
  fun load_dll2 = sv_load_dll2(filename : LibnameStrType) : LibC::Int
  alias LibnameStrType = LibC::Char*
  fun load_dll = sv_load_dll : LibC::Int
  fun unload_dll = sv_unload_dll : LibC::Int
  $audio_callback : TsvAudioCallback
  $audio_callback2 : TsvAudioCallback2
  $open_slot : TsvOpenSlot
  $close_slot : TsvCloseSlot
  $lock_slot : TsvLockSlot
  $unlock_slot : TsvUnlockSlot
  $init : TsvInit
  $deinit : TsvDeinit
  $update_input : TsvUpdateInput
  $get_sample_type : TsvGetSampleType
  $load : TsvLoad
  $load_from_memory : TsvLoadFromMemory
  $play : TsvPlay
  $play_from_beginning : TsvPlayFromBeginning
  $stop : TsvStop
  $set_autostop : TsvSetAutostop
  $end_of_song : TsvEndOfSong
  $rewind : TsvRewind
  $volume : TsvVolume
  $send_event : TsvSendEvent
  $get_current_line : TsvGetCurrentLine
  $get_current_line2 : TsvGetCurrentLine2
  $get_current_signal_level : TsvGetCurrentSignalLevel
  $get_song_name : TsvGetSongName
  $get_song_bpm : TsvGetSongBpm
  $get_song_tpl : TsvGetSongTpl
  $get_song_length_frames : TsvGetSongLengthFrames
  $get_song_length_lines : TsvGetSongLengthLines
  $new_module : TsvNewModule
  $remove_module : TsvRemoveModule
  $connect_module : TsvConnectModule
  $disconnect_module : TsvDisconnectModule
  $load_module : TsvLoadModule
  $load_module_from_memory : TsvLoadModuleFromMemory
  $sampler_load : TsvSamplerLoad
  $sampler_load_from_memory : TsvSamplerLoadFromMemory
  $get_number_of_modules : TsvGetNumberOfModules
  $get_module_flags : TsvGetModuleFlags
  $get_module_inputs : TsvGetModuleInputs
  $get_module_outputs : TsvGetModuleOutputs
  $get_module_name : TsvGetModuleName
  $get_module_xy : TsvGetModuleXy
  $get_module_color : TsvGetModuleColor
  $get_module_scope : TsvGetModuleScope
  $get_module_scope2 : TsvGetModuleScope2
  $get_number_of_module_ctls : TsvGetNumberOfModuleCtls
  $get_module_ctl_name : TsvGetModuleCtlName
  $get_module_ctl_value : TsvGetModuleCtlValue
  $get_number_of_patterns : TsvGetNumberOfPatterns
  $get_pattern_x : TsvGetPatternX
  $get_pattern_y : TsvGetPatternY
  $get_pattern_tracks : TsvGetPatternTracks
  $get_pattern_lines : TsvGetPatternLines
  $get_pattern_data : TsvGetPatternData
  $pattern_mute : TsvPatternMute
  $get_ticks : TsvGetTicks
  $get_ticks_per_second : TsvGetTicksPerSecond
  $get_log : TsvGetLog
end

puts SunVox.load_dll
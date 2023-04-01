require "libsunvox"

SunVox.start_engine(offline: true, no_debug_output: false, one_thread: false)


slot = SunVox.open_slot(SunVox::Slot::Zero)
SunVox.load(slot, "rsrc/trance.sunvox")
SunVox.export_to_wav(slot, SunVox.get_song_length_frames(slot), "test.wav")
SunVox.stop_engine
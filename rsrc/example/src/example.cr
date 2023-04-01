require "libsunvox"

# Set the audiodevice and audiodevice_in to your alsa driver then speak into your microphone :)

{% if flag?(:win32) %}
  SunVox.start_engine(config: "audiodriver=dsound|audiodevice=1|audiodevice_in=1", no_debug_output: false, one_thread: true)
{% else %}
  SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: true)
{% end %}

slot = SunVox.open_slot(SunVox::Slot::One)

input = SunVox.new_module(slot, SunVox::Modules::Synths::INPUT)
generator = SunVox.new_module(slot, SunVox::Modules::Synths::GENERATOR)
carrier = SunVox.new_module(slot, SunVox::Modules::Effects::AMPLIFIER)
modulator = SunVox.new_module(slot, SunVox::Modules::Effects::AMPLIFIER)
vocoder = SunVox.load_module(slot, "./rsrc/vocoder.sunsynth")

# Connect the module to the output

SunVox.connect_module(slot, input, modulator)
SunVox.connect_module(slot, generator, carrier)
SunVox.connect_module(slot, carrier, vocoder)
SunVox.connect_module(slot, modulator, vocoder)
SunVox.connect_module(slot, vocoder, SunVox::OUTPUT_MODULE)

SunVox.update_input

SunVox.send_event(slot, 0, SunVox::Note::None, 0, generator, ctl: 2, ctl_value: 0x1)


# Set carrier controls
SunVox.send_event(slot, 0, SunVox::Note::None, 0, carrier, ctl: 1, ctl_value: 0x4000)

SunVox.send_event(slot, 0, SunVox::Note::None, 0, carrier, ctl: 2, ctl_value: 0x8000)

# Set modulator controls
SunVox.send_event(slot, 0, SunVox::Note::None, 0, modulator, ctl: 1, ctl_value: 0x69c0)
SunVox.send_event(slot, 0, SunVox::Note::None, 0, modulator, ctl: 2, ctl_value: 0)

# Send all the notes
SunVox.send_event(slot, 0, SunVox::Note::D1, 0, generator)
SunVox.send_event(slot, 1, SunVox::Note::D2, 0, generator)
SunVox.send_event(slot, 2, SunVox::Note::D3, 0, generator)
SunVox.send_event(slot, 3, SunVox::Note::G4, 0, generator)
SunVox.send_event(slot, 4, SunVox::Note::D5, 0, generator)

sleep
How to time events using `set_event_time`

```crystal
require "libsunvox"

SunVox.start_engine(no_debug_output: true, one_thread: true)
slot = SunVox.open_slot(SunVox::Slot::One)

fm_synth_number = SunVox.new_module(slot, SunVox::Modules::Synths::FM)

# Connect the module to the output
SunVox.connect_module(slot, fm_synth_number, SunVox::OUTPUT_MODULE)
puts "Sending Events"
tps = SunVox.ticks_per_second
ticks = SunVox.ticks + tps

# Send events
10.times do
  20.times do |x|
    SunVox.set_event_time(slot, ticks += (tps*0.25).to_i)
    SunVox.send_event(slot, 0, SunVox::Note::C5 + x, 0, fm_synth_number)
  end
  SunVox.set_event_time(slot, ticks += tps)
  SunVox.send_event(slot, 0, SunVox::Note::Off, 128, fm_synth_number)
end
```

Playing Scales

```crystal
require "libsunvox"

SunVox.start_engine(no_debug_output: true, one_thread: false)
slot = SunVox.open_slot(SunVox::Slot::One)

fm_synth_number = SunVox.new_module(slot, SunVox::Modules::Synths::GENERATOR)

# Connect the module to the output
SunVox.connect_module(slot, fm_synth_number, SunVox::OUTPUT_MODULE)

scale = SunVox::Scales.make(SunVox::Note::C3, SunVox::Scales::HEXATONIC)
pp scale

tps = SunVox.ticks_per_second
starting_ticks = SunVox.ticks
ticks = starting_ticks

# Send events
10.times do
  scale.each do |note|
    SunVox.set_event_time(slot, ticks += (tps*0.25).to_i)
    SunVox.send_event(slot, 0, note, 0, fm_synth_number)
  end
  SunVox.set_event_time(slot, ticks += tps)
  SunVox.send_event(slot, 0, SunVox::Note::Off, 0, fm_synth_number)
end

sleep
```

Simple Instrument
```crystal
require "libsunvox"

SunVox.start_engine(no_debug_output: true, one_thread: true)
slot = SunVox.open_slot(SunVox::Slot::One)

generator_number = SunVox.new_module(slot, SunVox::Modules::Synths::GENERATOR)
reverb_number = SunVox.new_module(slot, SunVox::Modules::Effects::REVERB)

# Connect the module to the output
SunVox.connect_module(slot, generator_number, reverb_number)
SunVox.connect_module(slot, reverb_number, SunVox::OUTPUT_MODULE)

# Set up the sound settings

# Change waveform to noise
SunVox.send_event(slot, 0, SunVox::Note::None, 0, generator_number, ctl: 2, ctl_value: 0)

100.times do
  attack_low = 0xb80
  attack_high = 0x1540

  release_low = 0x31c0
  release_high = 0x6000

  attack = Random.rand(attack_low..attack_high)
  release = Random.rand(release_low..release_high)
  note = Random.rand(SunVox::Note::C2.to_i..SunVox::Note::C4.to_i)
  
  
  # Change Attack
  SunVox.send_event(slot, 0, SunVox::Note::None, 0, generator_number, ctl: 4, ctl_value: attack)
  # Change Release
  SunVox.send_event(slot, 0, SunVox::Note::None, 0, generator_number, ctl: 5, ctl_value: release)

  # Send a note
  SunVox.send_event(slot, 0, note, 0, generator_number)
  sleep 0.3
  SunVox.send_event(slot, 0, SunVox::Note::Off, 0, generator_number)

  sleep 3
end



sleep
```

Bad Generative Music Example
```crystal
require "libsunvox"

SunVox.start_engine(config: "audiodevice=hw:0,0", no_debug_output: true, one_thread: false)
slot = SunVox.open_slot(SunVox::Slot::One)

generator = SunVox.new_module(slot, SunVox::Modules::Synths::GENERATOR)
reverb = SunVox.new_module(slot, SunVox::Modules::Effects::REVERB)
drum_synth = SunVox.new_module(slot, SunVox::Modules::Synths::DRUM_SYNTH)

# Connect the module to the output
SunVox.connect_module(slot, generator, reverb)
SunVox.connect_module(slot, reverb, SunVox::OUTPUT_MODULE)
SunVox.connect_module(slot, drum_synth, reverb)

# Set up the sound settings

# Change waveform to noise
SunVox.send_event(slot, 0, SunVox::Note::None, 0, generator, ctl: 2, ctl_value: 0)
# Change Attack and release
SunVox.send_event(slot, 0, SunVox::Note::None, 0, generator, ctl: 4, ctl_value: 0x1000)
SunVox.send_event(slot, 0, SunVox::Note::None, 0, generator, ctl: 5, ctl_value: 0x1000)

spawn do
  1_000_000.times do |x|
    if x % 2 == 0
      SunVox.send_event(slot, 0, SunVox::Note::C5, 0, drum_synth)
      sleep 0.25
      SunVox.send_event(slot, 0, SunVox::Note::C5, 0, drum_synth)
      sleep 0.25
    else
      SunVox.send_event(slot, 0, SunVox::Note::D5, 0, drum_synth)
      sleep 0.5
    end

    2.times do
      SunVox.send_event(slot, 0, SunVox::Note::FSharp1, 0, drum_synth)
      sleep 0.5
    end

    SunVox.send_event(slot, 0, SunVox::Note::FSharp1, 0, drum_synth)
    sleep 0.25
    SunVox.send_event(slot, 0, SunVox::Note::FSharp1, 0, drum_synth)
    sleep 0.25
  end
end

spawn do
  scale = SunVox::Scales.make(SunVox::Note::F3, SunVox::Scales::MINOR_HEXATONIC)
  scale_size = scale.size
  scale = scale + SunVox::Scales.make(SunVox::Note::F4, SunVox::Scales::MINOR_HEXATONIC)
  1_000_000.times do

    3.times do
      note = rand(scale_size)
      SunVox.send_event(slot, 0, scale[note], 0, generator)
      sleep 0.25/2
      SunVox.send_event(slot, 1, scale[note + 2], 0, generator)
      sleep 0.25/2
      SunVox.send_event(slot, 2, scale[note + 4], 0, generator)
      sleep 0.75

      SunVox.send_event(slot, 0, SunVox::Note::Off, 0, generator)
      SunVox.send_event(slot, 1, SunVox::Note::Off, 0, generator)
      SunVox.send_event(slot, 2, SunVox::Note::Off, 0, generator)
      sleep 1
    end

    note = rand(scale_size)
    SunVox.send_event(slot, 3, scale[note], 0, generator)
    sleep 1
    SunVox.send_event(slot, 3, SunVox::Note::Off, 0, generator)
    sleep 1
  end
end

sleep
```

Make a live vocoder - https://youtu.be/PoH34XjlLLE

```crystal
require "libsunvox"

# Set the audiodevice and audiodevice_in to your device then speak into your microphone :)
SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: false)
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

SunVox.send_event(slot, 0, SunVox::Note::D1, 0, generator)
SunVox.send_event(slot, 1, SunVox::Note::D2, 0, generator)
SunVox.send_event(slot, 2, SunVox::Note::D3, 0, generator)
SunVox.send_event(slot, 3, SunVox::Note::G4, 0, generator)
SunVox.send_event(slot, 4, SunVox::Note::D5, 0, generator)

sleep
```

Live monitor output levels
```crystal
require "crysterm" #{crystallabs/crysterm}
require "libsunvox"


include Crysterm

COLORS = [10, 11, 9]

SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: false)
# Opens a slot for us to use
slot = SunVox.open_slot(SunVox::Slot::Zero)
SunVox.load(slot, "./rsrc/song.sunvox")
SunVox.play_from_beginning(slot)

def draw(s : Screen, x, y, fg = 0, bg = 0, char = ' ')
    s.fill_region(Widget.sattr(Namespace::Style.new, fg, bg), char, x, x+1, y, y+1)
end

def draw_region(s : Screen, x1, y1, x2, y2, fg = 0, bg = 0, char = ' ')
  s.fill_region(Widget.sattr(Namespace::Style.new, fg, bg), char, x1, x2, y1, y2)
end

def clear(s : Screen)
  draw_region(s, 0, 0, s.width, s.height)
end

def draw_frame(s)
  output_level = (SunVox.get_current_signal_level(SunVox::Slot::Zero, 0)/100.0).clamp(0, 0.9)
  output_color = COLORS[(COLORS.size*output_level).to_i]
  draw_region(s, 0, 5, (s.width*output_level).to_i , 10, bg: output_color)

  output_level =(SunVox.get_current_signal_level(SunVox::Slot::Zero, 1)/100.0).clamp(0, 0.9)
  output_color = COLORS[(COLORS.size*output_level).to_i]
  draw_region(s, 0, 12, (s.width*output_level).to_i , 17, bg: output_color-8)
end

# `Display` is a phyiscal device (terminal hardware or emulator).
# It can be instantiated manually as shown, or for quick coding it can be
# skipped and it will be created automatically when needed.
d = Display.new

# `Screen` is a full-screen surface which contains visual elements (Widgets),
# on which graphics is rendered, and which is then drawn onto the terminal.
# An app can have multiple screens, but only one can be showing at a time.
s = Screen.new display: d

# When q is pressed, exit the demo.
s.on(Event::KeyPress) do |e|
  if e.char == 'q'
    exit
  end
end

spawn do
  loop do
    sleep 0.1
    clear(s)
    draw_frame(s)
    s.render
  end
end

d.exec

```
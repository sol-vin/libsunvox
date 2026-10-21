# Welcome to the basics!

Here you will learn everything I know about SunVox, its libraries, and all the cool stuff it can do!

First of all, if you haven't headed over to [warmplace.ru](https://warmplace.ru), please give SunVox a look over. The tool is surprisingly simple to use, and can save you a lot of work. Check out its [tutorial](https://www.youtube.com/watch?v=FJh6yiKPqE4) for more information. However, you do not have to use the SunVox application at all, which is why this library exists for us to use.

## A quick SunVox 101
This is the quickest dirtiest intro into the realm that is SunVox.

SunVox is a modular synthesizer and tracker. What that means is that you can build instruments, and play notes through them. A sunvox file is a whole "song". This song is made up of two parts, the "tracker" which controls the notes played (essentially) and the modular synth, which uses a series of connected modules to make an instrument. In the tracker, the notes to be played are stored in patterns, which can be easily duplicated and its position changed. The SunVox library allows you to control all those aspects.

### Install

- **Linux**: Run `sudo ./rsrc/linux/install.sh`
- **macOS**: Run `sudo ./rsrc/macos/install.sh`
- **Windows**: Run `./rsrc/windows/install.ps1` (as Administrator)

### Basic setup

```crystal
require "libsunvox"

# Starts the SunVox audio engine
# Set the audiodevice and audiodevice_in to your devices
# Automatically adds an `at_exit` hook to close all the slots that are open, and stop the engine.
SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: false)
# Opens a slot for us to use
slot = SunVox.open_slot(SunVox::Slot::Zero)
```

You can also use block syntax for automatic cleanup of both the engine and slots:

```crystal
SunVox.start_engine(no_debug_output: true) do
  SunVox::Slot.open(SunVox::Slot::Zero) do |slot|
    # Work with `slot` here; it closes automatically when the block exits
  end
end
```

A slot contains a single song or `.sunvox` file. You can have multiple slots playing multiple songs at the same time. You have a maximum of 16 slots as allowed in `SunVox::Slot`.

You can load and save any sunvox file into the slot of your choice:

```crystal
slot.load("./file/some_file.sunvox")
slot.save("./file/saved_file.sunvox")

# Or load/save in-memory Bytes:
bytes = slot.save_to_bytes
slot.load(bytes)
```

You have many easy to use controls for playback control (available directly on `slot` or via `SunVox.*`):

```crystal
slot.play_from_beginning # or SunVox.play_from_beginning(slot)
slot.play                # or SunVox.play(slot)
slot.pause               # or SunVox.pause(slot)
slot.resume              # or SunVox.resume(slot)
slot.sync_resume         # or SunVox.sync_resume(slot)
slot.stop                # When used twice stops all sounds completely (Also known as SunVox::Note::CleanSynths)
slot.rewind(line_number) # or SunVox.skip_to_line(slot, line_number)
slot.autostop = false    # When false, the project loops endlessly
slot.repeats?            # Does the track repeat?
slot.volume = 256        # Max volume (0..256)
```

How to play any song:

```crystal
require "libsunvox"

SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: false)
slot = SunVox.open_slot(SunVox::Slot::Zero)
slot.load("./file.sunvox")

slot.play_from_beginning

sleep # Wait forever
```

You can also get and set the names, BPM, TPL, and other information for the modules, patterns, and the song in a slot (`slot.name`, `slot.bpm`, `slot.tpl`, `slot.modules`, `slot.patterns`).

You can also process any event SunVox has to offer. What's an event? It's an instruction executed by SunVox to do either one, some, or all of the following: Play a note on a module, set a controller value on a module, set an effect on a note.

Modules are interconnected sound pipelines that alter or produce sound in some way. For example, you could take your microphone input (A `SunVox::Modules::Synths::INPUT`) and pipe it into the reverb module (`SunVox::Modules::Effects::REVERB`), then pipe that reverb module to output (`slot.output` or `SunVox::OUTPUT_MODULE`). All modules have controllers which control different ways the module behaves. For example, the volume controller controls its output volume. Each module type has unique controllers that can behave in unique ways. Some modules take notes and produce sound, these are called `Synths`. Others called `Effects` take sound and alter it in some way as output. There is also a `Misc` category for special modules that don't fit the status quo of the other two.

You can create new modules using `slot.add_module` (or `SunVox.new_module`), connect them using the chainable `>>` operator (`gen >> filter >> slot.output`) or `mod.connect(dest)`, disconnect them with `mod.disconnect(dest)`, and delete a module using `mod.remove!`.

Events sent to modules can change controller values and play notes.

Events can be played in a couple of ways:
  - By `slot.play`, etc. These events are stored in the song's patterns.
  - By `mod.play_note` / `slot.send_event` / `SunVox.send_event` which will immediately play an event.
  - By using `slot.set_event_time` / `SunVox.set_event_time` to time the event using ticks as a timer, then sending the event at that time.

### Creating, connecting, and sending events to a module

With the object-oriented `SunVox::Module` wrapper:

```crystal
require "libsunvox"

SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: false)
slot = SunVox.open_slot(SunVox::Slot::Zero)

generator = slot.add_module(SunVox::Modules::Synths::GENERATOR, name: "Lead")
generator >> slot.output

# Send a note
generator.play_note(SunVox::Note::C5, track: 0)
sleep 1.second
# Send the "note off" to the track (0), or else it will keep playing forever
generator.note_off(track: 0)

# Play multiple notes at the same time up to the module's polyphony limit
generator.play_note(SunVox::Note::C5, track: 0)
generator.play_note(SunVox::Note::D5, track: 1)
generator.play_note(SunVox::Note::E5, track: 2)
sleep 1.second
generator.note_off(track: 0)
generator.note_off(track: 1)
generator.note_off(track: 2)

# Change a controller's value by name or index
generator["Waveform"] = 2 # or generator[1] = 2 (0-based controller index)
generator.play_note(SunVox::Note::C5, track: 0)
sleep 1.second
generator.note_off(track: 0)
```

### Timing events

You can time events using SunVox's built-in timing. To do that you can use `slot.set_event_time` (or `SunVox.set_event_time`) to ensure events are played exactly when you want them to!

```crystal
require "libsunvox"
SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: false)
slot = SunVox.open_slot(SunVox::Slot::Zero)

generator = slot.add_module(SunVox::Modules::Synths::GENERATOR)
generator >> slot.output

# The current frame SunVox is processing. This helps us time ourselves against SunVox.
starting_ticks = SunVox.ticks
ticks = starting_ticks
tps = SunVox.ticks_per_second

# Set event one second from the current tick
slot.set_event_time(ticks += tps)
generator.play_note(SunVox::Note::C5, track: 0)
slot.set_event_time(ticks += (tps // 2))
generator.note_off(track: 0)

# Keep adding to ticks to time your event for the future.
9.times do
  slot.set_event_time(ticks += tps)
  generator.play_note(SunVox::Note::C5, track: 0)
  slot.set_event_time(ticks += (tps // 2))
  generator.note_off(track: 0)
end

sleep
```

### Getting basic module and controller information

Using `slot.modules` and `mod.controllers`, we can inspect every module and controller in a `.sunvox` file:

```crystal
require "libsunvox"

SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: false)
slot = SunVox.open_slot(SunVox::Slot::Zero)
slot.load("./rsrc/test.sunvox")

slot.modules.each do |mod|
  puts "M#{mod.id} #{mod.name} (#{mod.type})"
  mod.controllers.each do |ctl|
    puts "  C#{ctl.index} - #{ctl.name} - #{ctl.value} (range: #{ctl.min}..#{ctl.max})"
  end
  puts
end
```

### Getting and editing pattern information/data

`.sunvox` files can (but don't have to) contain pattern information. Using `slot.patterns` or `slot.new_pattern`, you can inspect, create, resize, mute, and edit patterns using `pat[track, line]`:

```crystal
require "libsunvox"

SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: false)
slot = SunVox.open_slot(SunVox::Slot::Zero)
slot.load("./rsrc/trance.sunvox")

slot.patterns.each do |pat|
  puts "P#{pat.id} #{pat.name}"
  pat.data.each_with_index do |track, track_num|
    puts "  T#{track_num}"
    track.each_with_index do |event, line_num|
      if event.note == SunVox::Note::None && event.mod_num == SunVox::NO_MODULE && event.effect == 0 && event.ctl == 0
        puts "    L#{line_num + pat.x} - Blank"
      else
        puts "    L#{line_num + pat.x} - N: #{event.note} | V: #{event.velocity} | M: #{event.mod_num} | C: #{event.ctl} | E: #{event.effect} | P: #{event.ctl_value}"
      end
    end
  end
  puts
end
```

# Welcome to the basics!

Here you will learn everything I know about SunVox, it's libraries, and all the cool stuff it can do!

First of all, if you haven't headed over to [warmplace.ru](https://warmplace.ru), please give SunVox a look over. The tool is surprisingly simple to use, and can save you a lot of work. Check out it's [tutorial](https://www.youtube.com/watch?v=FJh6yiKPqE4) for more information. However, you do not have to use the SunVox application at all, which is why this library exists for us to use. 

## A quick SunVox 101
This is the quickest dirtiest intro into the realm that is SunVox.

SunVox is a modular synthesizer and tracker. What that means is that you can build instruments, and play notes through them. A sunvox file is a whole "song". This song is made up of two parts, the "tracker" which controls the notes played (essentially) and the modular synth, which uses a series of connected modules to make a instrument. In the tracker, the notes to be played are stored in patterns, which can be easily duplicated and it's position changed. The SunVox library allows you to control all those aspects.

### Install

Run `sudo ./install.sh`. You may need to install the correct arch library into the correct location.

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

A slot contains a single song or `.sunvox` file. You can have multiple slots playing multiple songs at the same time. You have a maximum of 16 slots as allowed in `SunVox::Slot`.

You can load any sunvox file into the slot of your choice by using:

```crystal
SunVox.load(slot, "./file/some_file.sunvox")
```

You have many easy to use controls for playback control

```crystal
SunVox.play_from_beginning(slot)
SunVox.play(slot)
SunVox.pause(slot)
SunVox.resume(slot)
SunVox.stop(slot) # When used twice stops all sounds completely (Also known as SunVox::Note::CleanSynths)
SunVox.skip_to_line(slot, line_number)
SunVox.set_repeat(slot, true | false)
SunVox.repeats?(slot) # Does the track repeat?
SunVox.volume(slot, 256_u8) # Max volume
```

How to play any song.

```crystal
require "libsunvox"

SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: false)
slot = SunVox.open_slot(SunVox::Slot::Zero)
SunVox.load(slot "./file.sunvox")

SunVox.play_from_beginning(slot)

sleep # Wait forever
```

You can also get the names, and other information for the modules, patterns, and the song in a slot, using methods like `SunVox.get_song_tpl` or `SunVox.get_number_of_patterns`.

You can also process any event SunVox has to offer. What's an event? It's an instruction executed by SunVox to do either one, some, or all of the following: Play a note on a module, set a controller value on a module, set an effect on a note.

Modules are interconnected sound pipelines that alter or produce sound in some way. For example, you could take your microphone input (A `SunVox::Modules::Synths::INPUT`) and pipe it into the reverb module (`SunVox::Modules::Effects::REVERB`), then pipe that reverb module to output (`SunVox::OUTPUT_MODULE`). All modules have controllers which control different ways the module behaves. For example, the volume controller controls it's output volume. Each module type has unique controllers that can behave in unique ways. Some modules take notes and produce sound, these are called `Synths`. Others called `Effects` take sound and alter it in some way as output. There is also a `Misc` category for special modules that don't fit the status quo of the other two.

You can create new modules using `SunVox.new_module`, and connect and disconnect them using `SunVox.connect_module` and `SunVox.disconnect_module`. You can delete a module using `SunVox.remove_module`

Events sent to modules can change controller values and play notes. 

Events can be played in a couple of ways.
  - By `SunVox.play`, etc. These events are stored in the song's patterns.


  - By `Sunvox.send_event` which will immediately play an event.

  - By using `SunVox.set_event_time` to time the event based using the ticks as a timer. Then using `Sunvox.send_event` to send the event at that time.

### Creating, connecting, and sending events to a module

`send_event` takes a slot, track number, note, velocity (how hard the note is played, 0 is hard as possible, `1..127` is soft to hard), module (if left blank no module is specified), controller (if blank no control is specified), and a controller value (doesn't matter if no controller is set.)

```crystal
require "libsunvox"

SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: false)
slot = SunVox.open_slot(SunVox::Slot::Zero)

generator = SunVox.new_module(slot, SunVox::Modules::Synths::GENERATOR)
SunVox.connect_module(slot, generator, SunVox::OUTPUT_MODULE)

# Send a note
SunVox.send_event(slot, 0, SunVox::Note::C5, 0, generator)
sleep 1
# Send the "note off" to the track (0), or else it will keep playing forever
SunVox.send_event(slot, 0, SunVox::Note::Off, 0, generator)

# Play multiple notes at the same time up to the modules polyphony limit. A modules polyphony is how many tracks of notes the module can play simultaneously. 
SunVox.send_event(slot, 0, SunVox::Note::C5, 0, generator)
SunVox.send_event(slot, 1, SunVox::Note::D5, 0, generator)
SunVox.send_event(slot, 2, SunVox::Note::E5, 0, generator)
sleep 1
SunVox.send_event(slot, 0, SunVox::Note::Off, 0, generator)
SunVox.send_event(slot, 1, SunVox::Note::Off, 0, generator)
SunVox.send_event(slot, 2, SunVox::Note::Off, 0, generator)

# Change a controller's value to make it sound different 
# Changes the controller(2): waveform, from triangle wave to square wave.
SunVox.send_event(slot, 0, SunVox::Note::None, 0, generator, ctl: 2, ctl_value: 2) 
SunVox.send_event(slot, 0, SunVox::Note::C5, 0, generator)
sleep 1
SunVox.send_event(slot, 0, SunVox::Note::Off, 0, generator)
```

### Timing events

You can time events using SunVox's built in timing. To do that you can use `SunVox.set_event_time` to ensure events are played exactly when you want them to!

```crystal
require "libsunvox"
SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: false)
slot = SunVox.open_slot(SunVox::Slot::Zero)

generator = SunVox.new_module(slot, SunVox::Modules::Synths::GENERATOR)
SunVox.connect_module(slot, generator, SunVox::OUTPUT_MODULE)

# The current frame SunVox is processing. This helps us time ourselves against SunVox.
starting_ticks = SunVox.ticks
ticks = starting_ticks
tps = SunVox.ticks_per_second

# Set event one second from the current tick
SunVox.set_event_time(slot, ticks += tps) 
# Send a note
SunVox.send_event(slot, 0, SunVox::Note::C5, 0, generator)
SunVox.set_event_time(slot, ticks += (tps/2).to_i) 
SunVox.send_event(slot, 0, SunVox::Note::Off, 0, generator)
# Keep adding to ticks to time your event for the future.
9.times do
  SunVox.set_event_time(slot, ticks += tps) 
  SunVox.send_event(slot, 0, SunVox::Note::C5, 0, generator)
  SunVox.set_event_time(slot, ticks += (tps/2).to_i) 
  SunVox.send_event(slot, 0, SunVox::Note::Off, 0, generator)
end

sleep
```

### Getting basic module and controller information

Using `SunVox.get_module_name(slot, module_number)` we can get the `String` name of a module. 

Using `SunVox.get_module_ctl_name(slot, module_number, controller_number)` we can get the `String` name of a module.

Lists the the modules and controllers in a `.sunvox` file

```crystal
require "libsunvox"

SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: false)
slot = SunVox.open_slot(SunVox::Slot::Zero)
SunVox.load(slot, "./rsrc/test.sunvox")

SunVox.get_number_of_modules(slot).times do |mod_num|
  mod_name = SunVox.get_module_name(slot, mod_num)
  # Check to see if the module is actually real
  mod_exists = SunVox.get_module_flags(slot, mod_num) & 1 == 1
  if mod_exists
    puts "M#{mod_num} #{mod_name}"
    SunVox.get_number_of_module_ctls(slot, mod_num).times do |ctl_num|
      ctl_name = SunVox.get_module_ctl_name(slot, mod_num, ctl_num)
      ctl_value = SunVox.get_module_ctl_value(slot, mod_num, ctl_num)
      puts "  C#{ctl_num} - #{ctl_name} - #{ctl_value}"
    end
    puts
  end
end
```

Any module you add/remove will change this list. 

### Getting pattern information/data

`.sunvox` files can (but don't have to) contain pattern information. This is the list of events for each track. A pattern is a certain size of lines long, you can determine length by `SunVox.get_pattern_lines(slot, pattern_num)`. You can also get the number of tracks using `SunVox.get_pattern_tracks(slot, pattern_num)`. You can find what line a pattern starts at (relative to the whole song) by using `SunVox..get_pattern_x(slot, pattern_num)`. Patterns can also have names.

To get a list of all events per track, use `SunVox.get_pattern_data(slot, pattern_num)` to return an `Array(Array(SunVox::Event))`. Each `Array(SunVox::Event)` is a track. You can use this to peel through the pattern event data youself.

```crystal
require "libsunvox"

SunVox.start_engine(config: "audiodriver=alsa|audiodevice=hw:0,0|audiodevice_in=hw:2,0", no_debug_output: true, one_thread: false)
slot = SunVox.open_slot(SunVox::Slot::Zero)
SunVox.load(slot, "./rsrc/trance.sunvox")

SunVox.get_number_of_patterns(slot).times do |pat_num|
  pat_name = SunVox.get_pattern_name(slot, pat_num)
  pat_line_start = SunVox.get_pattern_x(slot, pat_num)
  if SunVox.get_pattern_lines(slot, pat_num) > 0
    puts "P#{pat_num} #{pat_name}"
    SunVox.get_pattern_data(slot, pat_num).each_with_index do |track, track_num|
      puts "  T#{track_num}"
      track.each_with_index do |event, line_num|
        if event.note == SunVox::Note::None && event.mod_num == SunVox::NO_MODULE && event.effect == 0 && event.ctl == 0
          puts "    L#{line_num + pat_line_start} - Blank"
        else
          puts "    L#{line_num + pat_line_start} - N: #{event.note} | V: #{event.velocity} | M : #{event.mod_num}| C: #{event.ctl} | E: #{event.effect} | P: #{event.ctl_value}"
        end
      end
    end
    puts
  end
end
```




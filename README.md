# libsunvox

SunVox C Bindings! Will, in the future, be a fully features library for using and playing with sunvox.

## Installation

## Linux
Run `sudo ./rsrc/linux/install.sh` to install sunvox library.
Then run `./rsrc/example/build.sh` to run a test

## Windows
Run `sudo ./rsrc/windows/install.ps1` to install sunvox library.

Run
```ps1
$env:LIB = "${env:LIB};C:\sunvox"
$env:PATH = "${env:PATH};C:\sunvox"
```
Then run `./rsrc/example/build.ps1` to run a test



## Docs

https://sol-vin.github.io/libsunvox/

## Usage Example

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

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/sol-vin/libsunvox/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ian Rash](https://github.com/your-github-user) - creator and maintainer

Powered by SunVox (modular synth & tracker)
Copyright (c) 2008 - 2020, Alexander Zolotov <nightradio@gmail.com>, WarmPlace.ru

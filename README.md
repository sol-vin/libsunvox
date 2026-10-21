# libsunvox

<!-- carbon:badges -->
[![CI](https://github.com/sol-vin/libsunvox/actions/workflows/ci.yml/badge.svg)](https://github.com/sol-vin/libsunvox/actions/workflows/ci.yml)
[![Docs](https://img.shields.io/badge/docs-GitHub%20Pages-blue.svg)](https://sol-vin.github.io/libsunvox/)
[![Crystal](https://img.shields.io/badge/crystal-%3E%3D%201.6.0-black.svg)](https://crystal-lang.org)
[![Version](https://img.shields.io/badge/version-0.10.14-blue.svg)](https://github.com/sol-vin/libsunvox/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
<!-- /carbon:badges -->


Crystal bindings and high-level object-oriented wrapper for the [SunVox Library](https://warmplace.ru/soft/sunvox/sunvox_lib.php) (`v2.1.4d`).

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  libsunvox:
    github: sol-vin/libsunvox
```

2. Install the native SunVox shared library for your platform:

### Linux
Run `sudo ./rsrc/linux/install.sh` to install `sunvox.so` to `/usr/lib/`.

### macOS
Run `sudo ./rsrc/macos/install.sh` to install `sunvox.dylib` to `/usr/local/lib/`.

### Windows
Run `./rsrc/windows/install.ps1` (as Administrator) to install `sunvox.dll` and `sunvox.lib` to `C:\sunvox`, then add `C:\sunvox` to your environment:

```powershell
$env:LIB = "${env:LIB};C:\sunvox"
$env:PATH = "${env:PATH};C:\sunvox"
```

## Docs

https://sol-vin.github.io/libsunvox/

## Usage Example (Object-Oriented API)

```crystal
require "libsunvox"

SunVox.start_engine(no_debug_output: true) do
  SunVox::Slot.open(SunVox::Slot::One) do |slot|
    slot.name = "Vocoder Demo"
    slot.volume = 256

    # Create and load modules
    input     = slot.add_module(SunVox::Modules::Synths::INPUT, name: "Mic")
    generator = slot.add_module(SunVox::Modules::Synths::GENERATOR, name: "Gen")
    carrier   = slot.add_module(SunVox::Modules::Effects::AMPLIFIER, name: "Carrier")
    modulator = slot.add_module(SunVox::Modules::Effects::AMPLIFIER, name: "Modulator")
    vocoder   = slot.load_module("./rsrc/vocoder.sunsynth")

    # Connect modules using the chainable >> operator
    input     >> modulator >> vocoder >> slot.output
    generator >> carrier   >> vocoder

    SunVox.update_input

    # Set module controllers by name or index
    generator["Waveform"] = 1
    carrier[0]   = 0x4000
    carrier[1]   = 0x8000
    modulator[0] = 0x69c0
    modulator[1] = 0

    # Play a chord across tracks 0..4
    [SunVox::Note::D1, SunVox::Note::D2, SunVox::Note::D3, SunVox::Note::G4, SunVox::Note::D5].each_with_index do |note, track|
      generator.play_note(note, track: track, velocity: 128)
    end

    sleep
  end
end
```

## Procedural API Example

All classic `SunVox.*` module-level functions remain available and accept either `SunVox::Slot` / `SunVox::Module` / `SunVox::Pattern` wrappers or raw `Int32` IDs:

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

Run the test suite (uses offline audio mode so no sound hardware is required):

```bash
crystal spec
```

## Contributing

1. Fork it (<https://github.com/sol-vin/libsunvox/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ian Rash](https://github.com/sol-vin) - creator and maintainer

Powered by SunVox (modular synth & tracker)
Copyright (c) 2008 - 2024, Alexander Zolotov <nightradio@gmail.com>, WarmPlace.ru

# libsunvox

SunVox C Bindings! Will, in the future, be a fully features library for using and playing with sunvox.

## Installation

This was only tested on Ubuntu so it might not work on other systems :(

Run `sudo ./install.sh` to install sunvox library.

Then run `./run-example.sh` to run a test

## Docs

https://sol-vin.github.io/libsunvox/

## Usage Example

```crystal
require "libsunvox"

SunVox.start_engine
slot = SunVox.open_slot(SunVox::Slot::One)
SunVox.load(slot, "./rsrc/test3.sunvox")
puts "SONG NAME: #{SunVox.get_song_name slot}"

# Play the song from the beginning
SunVox.play_from_beginning(slot)

# Wait ten seconds
sleep 10

# Start playing notes from Crystal while the song is playing
119.times do |x|
  SunVox.send_event(slot, 0, SunVox::Note::C5 + x, 129, 0x0B, 0, 0)
  sleep 0.25
end
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

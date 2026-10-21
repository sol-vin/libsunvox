require "./spec_helper"

describe SunVox do
  before_all do
    SunVox.start_engine(offline: true, no_debug_output: true, one_thread: true)
  end

  after_all do
    SunVox.stop_engine
  end

  it "starts the engine in offline mode and reports version 2.1.4" do
    SunVox.started?.should be_true
    SunVox.offline?.should be_true
    SunVox.engine_version[:major].should eq(2)
    SunVox.engine_version[:minor].should eq(1)
    SunVox.engine_version[:minor2].should eq(4)
    SunVox.version_string.should eq("2.1.4")
    SunVox.sample_rate.should be >= 44100
    SunVox.ticks_per_second.should be > 0
  end

  describe SunVox::Slot do
    it "opens, manages project metadata, saves/loads to memory, and closes" do
      SunVox::Slot.open(SunVox::Slot::Zero) do |slot|
        slot.open?.should be_true
        slot.name = "Crystal Test Song"
        slot.name.should eq("Crystal Test Song")
        slot.bpm.should be > 0
        slot.tpl.should be > 0
        slot.base_version.should be > 0

        slot.volume = 200
        slot.volume.should eq(200)

        slot.autostop = true
        slot.autostop?.should be_true
        slot.repeats?.should be_false

        slot.autostop = false
        slot.autostop?.should be_false
        slot.repeats?.should be_true

        # Create a module so the saved project has custom state
        gen = slot.add_module(SunVox::Modules::Synths::ANALOG_GENERATOR, name: "LeadSynth", x: 256, y: 384)
        gen >> slot.output

        bytes = slot.save_to_bytes
        bytes.size.should be > 0
        String.new(bytes[0, 4]).should eq("SVOX")

        # Load into another slot from memory
        SunVox::Slot.open(SunVox::Slot::One) do |slot2|
          slot2.load(bytes)
          slot2.name.should eq("Crystal Test Song")
          loaded_mod = slot2.find_module("LeadSynth")
          loaded_mod.should_not be_nil
          loaded_mod.not_nil!.type.should eq("Analog generator")
          loaded_mod.not_nil!.xy.should eq({x: 256, y: 384})
        end
      end

      SunVox::Slot::Zero.open?.should be_false
    end

    it "loads an existing .sunvox file and inspects time map and playback" do
      SunVox::Slot.open(SunVox::Slot::Two) do |slot|
        slot.load("rsrc/example/rsrc/test.sunvox")
        slot.length_lines.should be > 0
        slot.length_frames.should be > 0
        slot.duration.total_seconds.should be >= 0

        tmap = slot.time_map(0, 4, SunVox::TimeMapFlags::Speed)
        tmap.size.should eq(4)
        tmap[0].should be > 0

        slot.play_from_beginning
        slot.playing?.should be_true

        buf = Slice(Int16).new(256 * 2)
        SunVox.audio_callback(buf, 256)

        slot.pause
        slot.resume
        slot.stop
      end
    end
  end

  describe SunVox::Module do
    it "creates modules, chains connections with >>, and modifies properties" do
      SunVox::Slot.open(SunVox::Slot::Three) do |slot|
        gen = slot.add_module(SunVox::Modules::Synths::FMX, name: "MyFMX", x: 100, y: 200)
        flt = slot.add_module(SunVox::Modules::Effects::FILTER_PRO, name: "MyFilter", x: 300, y: 200)
        fft = slot.add_module(SunVox::Modules::Effects::FFT, name: "MyFFT", x: 400, y: 200)
        smooth = slot.add_module(SunVox::Modules::Effects::SMOOTH, name: "MySmooth", x: 500, y: 200)
        mctl = slot.add_module(SunVox::Modules::Misc::MULTICTL, name: "MyMultiCtl", x: 600, y: 200)

        gen.exists?.should be_true
        gen.generator?.should be_true
        gen.effect?.should be_true # FMX accepts both note input and audio input for modulation
        gen.type.should eq("FMX")
        gen.name.should eq("MyFMX")

        flt.effect?.should be_true
        flt.generator?.should be_false
        flt.type.should eq("Filter Pro")
        fft.type.should eq("FFT")
        smooth.type.should eq("Smooth")
        mctl.type.should eq("MultiCtl")

        # Rename, move, recolor, and tune
        gen.name = "RenamedFMX"
        gen.name.should eq("RenamedFMX")

        gen.set_xy(120, 240)
        gen.x.should eq(120)
        gen.y.should eq(240)

        gen.set_rgb(10, 20, 30)
        gen.rgb.should eq({r: 10_u8, g: 20_u8, b: 30_u8})

        gen.finetune = 64
        gen.relative_note = -12
        gen.finetune.should eq(64)
        gen.relative_note.should eq(-12)

        # Chain connections: gen >> flt >> smooth >> slot.output
        gen >> flt >> smooth >> slot.output
        gen.output_ids.should contain(flt.id)
        flt.input_ids.should contain(gen.id)
        flt.output_ids.should contain(smooth.id)
        smooth.output_ids.should contain(SunVox::OUTPUT_MODULE)

        # Disconnect and remove
        gen.disconnect(flt)
        gen.output_ids.should_not contain(flt.id)

        mctl.remove!
        mctl.exists?.should be_false
      end
    end

    it "inspects and updates module controllers via SunVox::Controller" do
      SunVox::Slot.open(SunVox::Slot::Four) do |slot|
        gen = slot.add_module(SunVox::Modules::Synths::GENERATOR, name: "Gen")
        gen >> slot.output

        gen.ctl_count.should be > 0
        ctls = gen.controllers
        ctls.size.should eq(gen.ctl_count)

        vol_ctl = gen.ctl("Volume")
        vol_ctl.index.should eq(0)
        vol_ctl.min.should eq(0)
        vol_ctl.max.should be > 0
        vol_ctl.type.should eq(SunVox::CtlType::Normal)

        # Set controller value and process a frame so the event queue applies it
        gen["Waveform"] = 2
        buf = Slice(Int16).new(128 * 2)
        SunVox.audio_callback(buf, 128)
        gen["Waveform"].should eq(2)

        # Play note, read scope, and send note off
        gen.play_note(SunVox::Note::C5, track: 0, velocity: 128)
        SunVox.audio_callback(buf, 128)
        scope = gen.scope(0, 64)
        scope.size.should be <= 64
        gen.note_off(track: 0)
        gen.clean!

        # Read/write module curve
        curve = gen.curve(0, 32)
        curve.size.should eq(32)
        written = gen.set_curve(0, curve)
        written.should eq(32)
      end
    end
  end

  describe SunVox::Pattern do
    it "creates, modifies, mutes, and reads/writes events in patterns" do
      SunVox::Slot.open(SunVox::Slot::Five) do |slot|
        gen = slot.add_module(SunVox::Modules::Synths::GENERATOR, name: "PatGen")
        gen >> slot.output

        pat = slot.new_pattern(lines: 16, tracks: 2, x: 8, y: 4, name: "MainBeat")
        pat.exists?.should be_true
        pat.name.should eq("MainBeat")
        pat.lines.should eq(16)
        pat.tracks.should eq(2)
        pat.x.should eq(8)
        pat.y.should eq(4)

        pat.name = "UpdatedBeat"
        pat.name.should eq("UpdatedBeat")

        pat.set_xy(16, 10)
        pat.xy.should eq({x: 16, y: 10})

        pat.set_size(tracks: 4, lines: 32)
        pat.tracks.should eq(4)
        pat.lines.should eq(32)

        # Write and read pattern cell events
        pat.set_event(track: 0, line: 0, note: SunVox::Note::C4, velocity: 100, mod: gen, ctl: 1, effect: 2, ctl_value: 0x1234)
        ev = pat[0, 0]
        ev.note.should eq(SunVox::Note::C4)
        ev.velocity.should eq(100_u8)
        ev.mod_num.should eq(gen.id.to_i16)
        ev.ctl.should eq(1_u8)
        ev.effect.should eq(2_u8)
        ev.ctl_value.should eq(0x1234_u16)

        # Indexing assignment with SunVox::Event
        pat[1, 2] = SunVox::Event.new(note: SunVox::Note::E5, velocity: 80_u8, mod_num: gen.id.to_i16)
        pat[1, 2].note.should eq(SunVox::Note::E5)
        pat[1, 2].velocity.should eq(80_u8)

        # Mute and unmute
        pat.muted?.should be_false
        pat.mute!
        pat.muted?.should be_true
        pat.unmute!
        pat.muted?.should be_false

        pat.remove!
        pat.exists?.should be_false
      end
    end
  end

  describe SunVox::Scales do
    it "generates scales using SunVox::Note arithmetic" do
      scale = SunVox::Scales.make(SunVox::Note::C3, SunVox::Scales::HEXATONIC)
      scale.first.should eq(SunVox::Note::C3)
      scale.size.should eq(6)
      (SunVox::Note::C4 + 12).should eq(SunVox::Note::C5)
      (SunVox::Note::C5 - 12).should eq(SunVox::Note::C4)
    end
  end
end

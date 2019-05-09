module SunVox::Scales
  class ::SunVox::Scale
    getter data : Array(Int32)
    def initialize(@data)
    end
  end

  CHROMATIC = SunVox::Scale.new [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
  NONATONIC = SunVox::Scale.new [2, 1, 1, 1, 1, 1, 2, 1]
  OCTATONIC_HALF_WHOLE = SunVox::Scale.new [1, 2, 1, 2, 1, 2, 1]
  OCTATONIC_WHOLE_HALF = SunVox::Scale.new [2, 1, 2, 1, 2, 1, 2]
  HEPTATONIC = SunVox::Scale.new [3, 1, 1, 1, 1, 3]
  HEXATONIC = SunVox::Scale.new [3, 2, 1, 1, 3]
  PENTATONIC = SunVox::Scale.new [3, 2, 1, 4]
  MINOR_HEXATONIC = SunVox::Scale.new [2, 1, 2, 2, 3]
  def self.make(starting_note : SunVox::Note, scale : SunVox::Scale)
    output_notes = [starting_note] of SunVox::Note

    current_note = starting_note

    scale.data.each do |interval|
     output_notes << (current_note = SunVox::Note.new(current_note + interval))
    end

    output_notes
  end
end

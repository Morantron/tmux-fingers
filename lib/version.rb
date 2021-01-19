class Version
  include Comparable

  EXTRACT_PATTERN = /([0-9])+\.([0-9])+\.?([0-9]+|[a-z]+)?/.freeze
  CHAR_SHIFT = 97 - 1

  def initialize(version)
    segments = version.match(EXTRACT_PATTERN).to_a

    @major = segments[1].to_i
    @minor = segments[2].to_i
    @patch = parse_patch(segments[3])
  end

  def <=>(raw_other)
    other = if raw_other.is_a?(String)
              Version.new(raw_other)
            else
              raw_other
            end

    [:major, :minor, :patch].each do |segment|
      this_segment = self.send(segment)
      other_segment = other.send(segment)

      next if this_segment == other_segment

      return this_segment <=> other_segment
    end

    0
  end

  def to_s
    segments = if alphabetic_patch?
                 [major, minor.to_s + patch_representation]
               else
                 [major, minor, patch_representation]
               end

    segments.join('.')
  end

  attr_reader :major, :minor, :patch

  private

  def patch_representation
    alphabetic_patch? ? (patch + CHAR_SHIFT).chr : patch
  end

  def alphabetic_patch?
    @has_alphabetic_patch
  end

  def parse_patch(patch)
    patch ||= '0'

    if patch.match(/^[a-z]$/)
      @has_alphabetic_patch = true
      return patch.ord - CHAR_SHIFT
    else
      @has_alphabetic_patch = false
      return patch.to_i
    end
  end
end

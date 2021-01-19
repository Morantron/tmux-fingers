require 'spec_helper'

describe Version do
  it 'can be compared' do
    expect(Version.new("1.2.3") > Version.new("0.2.3")).to be(true)
    expect(Version.new("1.3.3") > Version.new("1.2.3")).to be(true)
    expect(Version.new("1.2.4") > Version.new("1.2.3")).to be(true)

    expect(Version.new("0.2.3") < Version.new("1.2.3")).to be(true)
    expect(Version.new("1.2.3") < Version.new("1.3.3")).to be(true)
    expect(Version.new("1.2.3") < Version.new("1.2.4")).to be(true)

    expect(Version.new("1.2.3") >= Version.new("0.2.3")).to be(true)
    expect(Version.new("1.3.3") >= Version.new("1.2.3")).to be(true)
    expect(Version.new("1.2.4") >= Version.new("1.2.3")).to be(true)

    expect(Version.new("0.2.3") <= Version.new("1.2.3") ).to be(true)
    expect(Version.new("1.2.3") <= Version.new("1.3.3") ).to be(true)
    expect(Version.new("1.2.3") <= Version.new("1.2.4") ).to be(true)

    expect(Version.new("0.2.3") <= Version.new("1.2.3") ).to be(true)
    expect(Version.new("1.2.3") <= Version.new("1.3.3") ).to be(true)
    expect(Version.new("1.2.3") <= Version.new("1.2.4") ).to be(true)
  end

  it 'can be sorted' do
    puts [
      Version.new("3.1"),
      Version.new("3.2b"),
      Version.new("3.3b"),
      Version.new("1.1.2"),
      Version.new("3.3c"),
      Version.new("3.1.2"),
      Version.new("3.3a"),
      Version.new("2.1.2"),
      Version.new("3.3"),
      Version.new("3.1.1"),
      Version.new("3.2"),
      Version.new("3.2.2"),
      Version.new("0.1.2")
    ].sort
  end
end


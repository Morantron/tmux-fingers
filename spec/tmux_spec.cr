require "./spec_helper"
require "../src/tmux"

describe Tmux do
  it "returns a semantic version for versions without letters" do
    result = Tmux.tmux_version_to_semver("3.1")
    result.major.should eq 3
    result.minor.should eq 1
    result.patch.should eq 0
  end

  it "returns a semantic version for versions with letters" do
    result = Tmux.tmux_version_to_semver("3.1b")
    result.major.should eq 3
    result.minor.should eq 1
    result.patch.should eq 2
  end

  it "returns a semantic version for versions with letters" do
    result = Tmux.tmux_version_to_semver("3.3a")
    result.major.should eq 3
    result.minor.should eq 3
    result.patch.should eq 1
  end

  it "returns comparable semversions" do
    result = Tmux.tmux_version_to_semver("3.0a") >= Tmux.tmux_version_to_semver("3.1")

    result.should eq false
  end
end

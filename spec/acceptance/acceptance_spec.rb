require "spec_helper"
require_relative "../tmuxomatic_setup"

describe "acceptance", retry: 3 do
  include_context "tmuxomatic setup"
  let(:config_name) { "basic" }

  context "basic yank" do
    before do
      exec("cat spec/fixtures/grep-output")

      invoke_fingers

      send_keys("b")

      echo_yanked
    end

    it { should contain_content("yanked text is scripts/debug.sh") }
  end

  context "custom patterns" do
    let(:config_name) { "custom-patterns" }

    before do
      exec("cat spec/fixtures/custom-patterns")

      send_keys("echo yanked text is ")

      invoke_fingers
      send_keys("y")
      wait_for_fingers_teardown
      paste

      invoke_fingers
      send_keys("b")
      wait_for_fingers_teardown
      paste

      send_keys("Enter")
    end

    it { should contain_content("yanked text is W00TW00TW00TYOLOYOLOYOLO") }
  end

  context "more than one match per line" do
    before do
      exec("cat spec/fixtures/ip-output")

      invoke_fingers
      send_keys("i")
      echo_yanked
    end

    it { should contain_content("yanked text is 10.0.3.255") }
  end

  context "preserve zoom state" do
    let(:config_name) { "basic" }
    before do
      send_prefix_and("%")
      # TODO: moving back to pane with PS1="# ". If you have emojis in PS1 it
      # will break with this exception when splitting lines in hinter
      #
      #     invalid byte sequence in US-ASCII (ArgumentError)
      #
      send_prefix_and("Left")
      send_prefix_and("z")

      exec("echo 123456")

      invoke_fingers
      send_keys("C-c")
      wait_for_fingers_teardown
      exec('echo current pane is $(tmux list-panes -F "#{?window_zoomed_flag,zoomed,not_zoomed}" | head -1)')
    end

    it { should contain_content("current pane is zoomed") }
  end

  context "alt action" do
    let(:config_name) { "alt-action" }

    before do
      `rm -rf /tmp/fingers-stub-output`
      exec("cat spec/fixtures/grep-output")

      invoke_fingers
      send_keys("M-y")
      wait_for_fingers_teardown

      exec("cat /tmp/fingers-stub-output")

      zzz 10
    end

    it { should contain_content("action-stub => scripts/hints.sh") }

    after do
      `rm -rf /tmp/fingers-stub-output`
    end
  end

  context "shift action" do
    before do
      exec("cat spec/fixtures/grep-output")

      send_keys("yanked text is ")
      invoke_fingers
      send_keys("Y")
      wait_for_fingers_teardown
    end

    it { should contain_content("yanked text is scripts/hints.sh") }
  end

  context "ctrl action" do
    let(:config_name) { "ctrl-action" }
    let(:prefix) { "C-b" }
    let(:hint_to_press) { "C-y" }

    before do
      `rm -rf /tmp/fingers-stub-output`
      exec("cat spec/fixtures/grep-output")

      invoke_fingers
      send_keys(hint_to_press)
      wait_for_fingers_teardown

      exec("cat /tmp/fingers-stub-output")
    end

    it { should contain_content("action-stub => scripts/hints.sh") }

    context "and is sending prefix" do
      let(:hint_to_press) { prefix }

      it { should contain_content("action-stub => scripts/debug.sh") }
    end

    after do
      `rm -rf /tmp/fingers-stub-output`
    end
  end

  context "copy stuff with quotes" do
    let(:config_name) { "quotes" }

    before do
      # zleep 3
      exec("cat spec/fixtures/quotes")
      send_keys("echo yanked text is ")
      invoke_fingers
      send_keys("b")
      wait_for_fingers_teardown
      paste
      send_keys(" ")
      invoke_fingers
      send_keys("y")
      wait_for_fingers_teardown
      paste
    end

    it { should contain_content(%(yanked text is "laser" 'laser')) }
  end

  context "config options validation" do
    let(:config_name) { "invalid" }
    let(:wait_for_initial_clear) { false }

    before do
      zzz 5
    end

    it { should contain_content("@fingers-lol is not a valid option") }
  end

  # TODO: multi match spec
end

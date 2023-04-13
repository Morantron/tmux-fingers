require "spec"
require "../../../src/fingers/input_socket"

describe Fingers::InputSocket do
  it "works" do
    spawn do
      sleep 1
      sender = Fingers::InputSocket.new
      sender.send_message("hey")
    end

    listener = Fingers::InputSocket.new
    listener.on_input do |msg|
      msg.should eq("hey")
      break
    end
  end
end

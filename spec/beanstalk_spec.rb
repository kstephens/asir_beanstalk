require 'spec_helper'

describe "ASIR::Transport::Beanstalk" do
  attr_accessor :t

  it "should default to localhost:11300" do
    t.host.should == '127.0.0.1'
    t.host_default.should == '127.0.0.1'
    t.port.should == 11300
    t.port_default.should == 11300
    t.tube.should == 'asir'
    t.tube_default.should == 'asir'
    t.path.should == '/asir'
    t.uri.should == 'beanstalk://127.0.0.1:11300/asir'
  end

  it "should return a #host, #port, #tube based on #uri" do
    t.uri = "beanstalk://host:12345/tube"
    t.scheme.should == 'beanstalk'
    t.host.should == 'host'
    t.port.should == 12345
    t.tube.should == 'tube'
    t.path.should == '/tube'
  end

  it "should return a #uri based on #host, #port, #tube" do
    t.host = 'host'
    t.port = 12345
    t.tube = 'tube'
    t.uri.should == "beanstalk://host:12345/tube"
  end

  before :each do
    @t = ASIR::Transport::Beanstalk.new
  end
end

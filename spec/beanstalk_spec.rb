require 'spec_helper'
require 'asir/coder/marshal'
require 'timeout'
#require 'pp'

describe "ASIR::Transport::Beanstalk" do
  let :t do
      t =
        ASIR::Transport::Beanstalk.new({
                                         :encoder => ASIR::Coder::Marshal.new,
                                         :uri => "beanstalk://localhost:31033/spec",
                                         :conduit_options => {
                                           :bind_host => '127.0.0.1',
                                           :pid_file => "/tmp/asir-beanstalk-test.pid",
                                           :verbose => 1,
                                         },
                                         :verbose => 9,
                                         :_logger => $stderr,
                                       })
  end

  context "for uninitialized instance" do
    let :t do
      ASIR::Transport::Beanstalk.new
    end

  it "should default to 127.0.0.1:11300" do
    t.host.should == '127.0.0.1'
    t.conduit_host.should == t.host
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
    t.conduit_host.should == t.host
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

    it "should handle an alternate conduit_host" do
      t.uri = "beanstalk://host:12345/tube"
      t.conduit_host = '0.0.0.0'
      t.host.should == 'host'
      t.conduit_host.should == '0.0.0.0'
    end
  end

  context "with started beanstalk conduit" do
    before :all do
      $transport ||= t
      t.port.should == 31033
      t.conduit_options = {
        :bind_host => '127.0.0.1',
        :verbose => 1,
      }
      t.conduit_host.should == '127.0.0.1'
      t.conduit_host.should_not == t.host
      t.start_conduit!
      sleep 1
    end
    after :all do
      $transport.stop_conduit!
    end

    context "with connected transport" do
      let :connected_transport do
        t.stream
        # pp t
        t
      end

      it "should be able to get stats" do
        s = t.stats
        s['pid'].should_not == nil
        s['version'].should_not == nil
      end

      it "should be able to get stats_tube" do
        s = t.stats_tube
        t.tube.should == 'spec'
        s['name'].should == t.tube
        s['current-using'].should_not == nil
      end

      it "should not get stats_tube on an unknown tube" do
        s = t.stats_tube "UNKNOWN"
        s.should == :NOT_FOUND
      end

      it "should be able to get conduit_status" do
        s = t.conduit_status
        s = s[:beanstalkd]
        s.should_not == nil
        s[:stats].class.should == Hash
        s[:stats_tube].class.should == Hash
        s[:response_time].class.should == Float
      end

      context "with a sent message" do
        let :m do
          ASIR::Message.new(ASIR, :name, [ ], nil, nil)
        end

        let :sent_message do
          t.send_message(m)
          # pp m
          m
        end

        it "should have at least one job in its tube" do
          s = t.stats_tube
          # pp [ __LINE__, s ]
          # PENDING
        end

        it "should be able to get status on job" do
          job_id = sent_message[:beanstalk_job_id]
          s = t.stats_job job_id
          # pp [ __LINE__, job_id, s ]
          s["id"].should == job_id
          s["tube"].should == 'spec'
          s["state"].should == 'ready'
        end

        context "with received message" do
          let :state do
            state = nil
            Timeout.timeout(5) do
              stream, stream = t._server_accept_connection! nil
              state =
                ASIR::Message::State.new(:in_stream => stream, :out_stream => stream)
              # pp t
              t.receive_message(state)
              state.message.class.should == ASIR::Message
              state.message.receiver.should == ASIR
              state.message.selector.should == :name
              state.message.arguments.should == [ ]
            end
            state
          end

          it "should have consumed job" do
            t._after_invoke_message state
            job_id = sent_message[:beanstalk_job_id]
            s = t.stats_job job_id
            # pp [ __LINE__, job_id, s ]
            s.should == :NOT_FOUND
          end
        end
      end
    end
  end
end

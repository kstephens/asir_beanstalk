require 'asir/transport/tcp_socket'

module ASIR
  class Transport
    # !SLIDE
    # Beanstalk Transport
    class Beanstalk < TcpSocket
      attr_accessor :tube, :tube_default
      attr_accessor :priority, :delay, :ttr

      def initialize *args
        @one_way = true
        self.scheme_default ||= 'beanstalk'
        self.host_default   ||= '127.0.0.1'
        self.port_default   ||= 11300
        self.tube_default   ||= 'asir'
        @priority ||= 0
        @delay ||= 0
        @ttr ||= 600
        super
      end

      def tube
        @tube ||=
          @uri && (
            p = _uri.path.sub(%r{\A/}, '')
            p = nil if p.empty?
            p
          ) || tube_default
      end

      def path_default
        "/#{tube}"
      end

      # !SLIDE
      # Sends the encoded Message payload String.
      def _send_message state
        stream.with_stream! do | s |
          message = state.message
          begin
            match =
              _beanstalk(s,
                         "put #{message[:beanstalk_priority] || @priority} #{message[:beanstalk_delay] || @delay} #{message[:beanstalk_ttr] || @ttr} #{state.message_payload.size}\r\n",
                         /\AINSERTED (\d+)\r\n\Z/,
                         state.message_payload)
            job_id = message[:beanstalk_job_id] = match[1].to_i
            _log { "beanstalk_job_id = #{job_id.inspect}" } if @verbose >= 2
          rescue ::Exception => exc
            message[:beanstalk_error] = exc
            close
            raise exc
          end
        end
      end

      RESERVE = "reserve\r\n".freeze

      # !SLIDE
      # Receives the encoded Message payload String.
      def _receive_message state
        additional_data = state.additional_data ||= { }
        state.in_stream.with_stream! do | stream |
          begin
            match = with_force_stop! do
              _beanstalk(stream,
               RESERVE,
               /\ARESERVED (\d+) (\d+)\r\n\Z/)
            end
            additional_data[:beanstalk_job_id] = match[1].to_i
            additional_data[:beanstalk_message_size] =
              size = match[2].to_i
            state.message_payload = stream.read(size)
            _read_line_and_expect! stream, /\A\r\n\Z/
            state.result_opaque = stream
          rescue ::Exception => exc
            _log { [ :_receive_message, :exception, exc ] }
            additional_data[:beanstalk_error] = exc
            state.in_stream.close
            raise exc
          end
        end
      end

      # !SLIDE
      # Sends the encoded Result payload String.
      def _after_invoke_message state
        #
        # There is a possibility here the following could happen:
        #
        #   _receive_message
        #     channel == #<Channel:1>
        #     channel.stream == #<TCPSocket:1234>
        #   end
        #   ...
        #   ERROR OCCURES:
        #      channel.stream.close
        #      channel.stream = nil
        #   ...
        #   _send_result
        #     channel == #<Channel:1>
        #     channel.stream == #<TCPSocket:5678> # NEW CONNECTION
        #     stream.write "delete #{job_id}"
        #   ...
        #
        # Therefore: _receiver_message passes the original message stream to us.
        stream = state.result_opaque
        job_id = state.message[:beanstalk_job_id] or raise "no beanstalk_job_id"
        _beanstalk(stream,
         "delete #{job_id}\r\n",
         /\ADELETED\r\n\Z/)
        # state.in_stream.close # Force close.
      end

      # !SLIDE
      # Receives the encoded Result payload String.
      def _receive_result state
        nil
      end

      # !SLIDE
      # Sets beanstalk_delay if message.delay was specified.
      def relative_message_delay! message, now = nil
        if delay = super
          message[:beanstalk_delay] = delay.to_i
        end
        delay
      end

      # !SLIDE
      # Beanstalk protocol support

      # Send "something ...\r\n".
      # Expect /\ASOMETHING (\d+)...\r\n".
      def _beanstalk stream, message, expect, payload = nil
        _log { [ :_beanstalk, :message, message ] } if @verbose >= 3
        stream.write message
        if payload
          stream.write payload
          stream.write LINE_TERMINATOR
        end
        if match = _read_line_and_expect!(stream, expect) # , /\A(BAD_FORMAT|UNKNOWN_COMMAND)\r\n\Z/)
          _log { [ :_beanstalk, :result, match[0] ] } if @verbose >= 3
        end
        match
      end

      LINE_TERMINATOR = "\r\n".freeze

      def _after_connect! stream
        if t = tube
          _beanstalk(stream,
                     "use #{t}\r\n",
                     /\AUSING #{t}\r\n\Z/)
        end
      end

      # !SLIDE
      # Beanstalk Server
      def _server!
        _log { "_server! #{uri}" } if @verbose >= 1
        @server = connect!(:try_max => nil,
                           :try_sleep => 1,
                           :try_sleep_increment => 0.1,
                           :try_sleep_max => 10) do | stream |
          if t = tube
            _beanstalk(stream,
                       "watch #{t}\r\n",
                       /\AWATCHING (\d+)\r\n\Z/)
          end
        end
        self
      end

      def _server_accept_connection! server
        prepare_server! unless @server
        [ @server, @server ]
      end

      def _server_close_connection! in_stream, out_stream
        # NOTHING
      end

      def stream_eof? stream
        # Note: stream.eof? on a beanstalkd connection,
        # will cause blocking read *forever* because
        # beanstalk connections are long lived.
        false
      end

      def _start_conduit!
        opt = host ? "-l #{host} " : ""
        cmd = "beanstalkd #{opt}-p #{port} -z #{1 * 1024 * 1024} #{@conduit_options[:beanstalkd_options]}"
        $stderr.puts "  #{cmd}" rescue nil if @conduit_options[:verbose]
        exec(cmd)
      end
    end
    # !SLIDE END
  end # class
end # module


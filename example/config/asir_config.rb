# Used by asir/bin/asir.
# Configures asir worker transport and error logging.
# asir object is bound to ASIR::Environment instance.

$stderr.puts "asir.phase = #{asir.phase.inspect}" if asir.verbose >= 1
case asir.phase
when :configure
  # NOTHING
  true
when :environment
  require 'rubygems'

  gem 'asir'
  require 'asir'
  require 'asir/transport/file'
  require 'asir/coder/marshal'
  require 'asir/coder/yaml'

  $:.unshift File.expand_path('..')
  require 'example_helper'
  require 'sample_service'
when :start
  # NOTHING
  true
when :transport
  # Compose with Marshal for final coding.
  coder = ASIR::Coder::Marshal.new

  # Logger for worker-side Exceptions.
  error_log_file = asir.log_file.sub(/\.log$/, '-error.log')
  error_transport =
    ASIR::Transport::File.new(:file => error_log_file,
                              :mode => 'a+',
                              :perms => 0666)
  error_transport.encoder = ASIR::Coder::Yaml.new

  # Setup requested Transport.
  case asir.adjective
  when :beanstalk
    require 'asir/transport/beanstalk'
    transport = ASIR::Transport::Beanstalk.new(:uri => "tcp://localhost:31001/test0")
  else
    raise "Cannot configure Transport for #{asir.adjective}"
  end

  transport.encoder = coder
  transport._logger = STDERR
  transport._log_enabled = true
  # transport.verbose = 3
  transport.on_exception =
    lambda { | transport, exc, phase, state |
      $stderr.puts "ERROR: #{transport} #{exc} #{phase}"
      if state.message
        error_transport.send_message(state.message)
      end
    }

  transport
else
  $stderr.puts "Warning: unhandled asir.phase: #{asir.phase.inspect}"
end

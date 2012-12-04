require 'example_helper'
require 'asir/transport/beanstalk'
require 'asir/coder/marshal'
begin
  Email.asir.transport = t =
    ASIR::Transport::Beanstalk.new(:uri => "tcp://localhost:31001")
  t.one_way = true
  t.encoder = ASIR::Coder::Marshal.new
  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user@email.com",
                             :customer => @customer)
ensure
  t.close rescue nil
end


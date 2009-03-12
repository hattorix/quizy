#
# mail_server.rb: Simple SMTP server
#
# Copyright (c) 2006 Shinya Kasatani <kasatani@gmail.com>
#

require 'smtpd'
require 'socket'

class MailServer
  class Daemon < SMTPD
    def initialize(socket, server)
      super(socket, server.host)
      @server = server
      self.error_interval = server.error_interval
    end

    def data_hook(data)
      begin
        @recipients.each do |rcpt|
          headers = <<EOS
Return-Path: <#{@sender}>
Delivered-To: #{rcpt}
Received: from #{@sock.peeraddr[2]} by #{@sock.addr[2]}; #{Time.now.rfc2822}
EOS
          @server.handler.call "#{headers}#{data}"
        end
      rescue
        error "550 #{$!.message.gsub(/\n/, ' ')}"
      end
    end

    def rcpt_hook(rcpt)
      @server.rcpt_filters.each do |filter|
        error "553 Relay access denied" unless filter.call(rcpt)
      end
    end
  end
  
  attr_accessor :rcpt_filters, :handler, :host, :service, :error_interval
  
  def initialize(host, service, &block)
    @rcpt_filters = []
    @host = host
    @service = service
    @error_interval = 1
    yield self
  end
  
  def start
    server = TCPServer.new(@host, @service)
    while true
      Thread.start(server.accept) do |s|
        begin
          daemon = MailServer::Daemon.new(s, self)
          daemon.start
        rescue
          ActiveRecord::Base.logger.error "An error occured in mail server: #{$!} at #{$@}"
        ensure
          s.close
        end
      end
    end
  end
  
  def filter_rcpt(&block)
    self.rcpt_filters << Proc.new
  end
  
  def handle(&block)
    self.handler = Proc.new
  end
end

require 'socket'

module Celluloid
  module IO
    # TCPServer with combined blocking and evented support
    class TCPServer

      def initialize(hostname, port)
        @server = ::TCPServer.new(hostname, port)
        self.extend SingleForwardable
        eval("self.def_delegators :@server, :#{(@server.methods-self.methods).join(", :")}")
      end

      def accept
        actor = Thread.current[:actor]

        if evented?
          Celluloid.current_actor.wait_readable @server
          accept_nonblock
        else
          Celluloid::IO::TCPSocket.from_ruby_socket @server.accept
        end
      end

      def accept_nonblock
        Celluloid::IO::TCPSocket.from_ruby_socket @server.accept_nonblock
      end

      def to_io
        @server
      end

      # Are we inside a Celluloid ::IO actor?
      def evented?
        actor = Thread.current[:actor]
        actor && actor.mailbox.is_a?(Celluloid::IO::Mailbox)
      end

    end
  end
end

module Celluloid
  module IO
    # UDPSockets with combined blocking and evented support
    class UDPSocket

      def initialize
        @socket = ::UDPSocket.new
        # Delegate underlying socket methods to this class for better interoperability
        self.extend SingleForwardable
        eval("self.def_delegators :@socket, :#{(@socket.methods-self.methods).join(", :")}")
      end

      # Are we inside of a Celluloid::IO actor?
      def evented?
        actor = Thread.current[:actor]
        actor && actor.mailbox.is_a?(Celluloid::IO::Mailbox)
      end

      # Wait until the socket is readable
      def wait_readable
        if evented?
          Celluloid.current_actor.wait_readable(@socket)
        else
          Kernel.select([@socket])
        end
      end

      # Receives up to maxlen bytes from socket. flags is zero or more of the
      # MSG_ options. The first element of the results, mesg, is the data
      # received. The second element, sender_addrinfo, contains
      # protocol-specific address information of the sender.
      def recvfrom(maxlen, flags = nil)
        begin
          if @socket.respond_to? :recvfrom_nonblock
            @socket.recvfrom_nonblock(maxlen, flags)
          else
            # FIXME: hax for JRuby
            @socket.recvfrom(maxlen, flags)
          end
        rescue ::IO::WaitReadable
          wait_readable
          retry
        end
      end

      def to_io; @socket; end
    end
  end
end

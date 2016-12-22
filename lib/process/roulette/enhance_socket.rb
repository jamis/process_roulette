module Process
  module Roulette # rubocop:disable Style/Documentation

    # A factory method for applying the EnhanceSocket module to a socket.
    # It adds the module, and automatically calls #ping!, to ensure that
    # the socket begins in an "alive" state.
    def self.EnhanceSocket(socket) # rubocop:disable Style/MethodName
      socket.tap do |s|
        s.extend(EnhanceSocket)
        s.ping!
      end
    end

    # A module that adds helper methods to socket objects. In particular,
    # it makes it easier to read and write entire packets (where a packet is
    # defined as a 4-byte length field, followed by a variable length body,
    # and the body is a marshalled Ruby object.)
    module EnhanceSocket
      def read_packet
        raw = recv(4, 0)
        return nil if raw.empty?

        length = raw.unpack('N').first
        raw = recv(length, 0)
        return nil if raw.empty?

        Marshal.load(raw)
      end

      def send_packet(payload)
        body = Marshal.dump(payload)
        len = [body.length].pack('N')
        send(len, 0)
        send(body, 0)
        body.length
      end

      def wait_with_ping
        loop do
          ready, = IO.select([self], [], [], 0.2)
          return read_packet if ready && ready.any?

          send_packet('PING')
        end
      end

      attr_accessor :username
      attr_accessor :victims
      attr_accessor :killed_at

      def killed?
        @killed_at != nil
      end

      def has_victim?
        @current_victim != nil
      end

      def victim=(v)
        @current_victim = v
        (@victims ||= []).push(v) if v
      end

      def confirmed?
        @confirmed
      end

      def confirmed!(confirm = true)
        @confirmed = confirm
      end

      def ping!
        @last_ping = Time.now.to_f
      end

      def dead?
        Time.now.to_f - @last_ping > 1.0
      end
    end

  end
end

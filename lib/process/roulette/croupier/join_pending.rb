module Process
  module Roulette
    module Croupier

      # The JoinPending class encapsulates the handling of pending connections
      # during the 'join' phase of the croupier state machine. It explicitly
      # handles new player and new controller connections, moving them from
      # the pending list to the appropriate collections of the croupier itself,
      # depending on their handshake.
      class JoinPending < Array
        def initialize(croupier)
          super()
          @croupier = croupier
        end

        def reap!
          delete_if(&:dead?)
        end

        def cleanup!
          return unless any?

          puts 'closing pending connections'
          each(&:close)
        end

        def process(socket, packet)
          _handle_nil(socket, packet) ||
            _handle_new_player(socket, packet) ||
            _handle_new_controller(socket, packet) ||
            _handle_ping(socket, packet) ||
            _handle_unexpected(socket, packet)
        end

        def _handle_nil(socket, packet)
          return false unless packet.nil?
          puts 'pending socket closed'
          delete(socket)
          true
        end

        def _handle_new_player(socket, packet)
          return false unless /^OK:(?<username>.*)/ =~ packet

          socket.username = username
          delete(socket)

          if @croupier.players.any? { |p| p.username == socket.username }
            _player_username_taken(socket)
          else
            _player_accepted(socket)
          end

          true
        end

        def _handle_new_controller(socket, packet)
          return false unless packet == @croupier.password

          puts 'accepting new controller'
          socket.send_packet('OK')
          delete(socket)
          @croupier.controllers << socket

          true
        end

        def _handle_ping(_socket, packet)
          return false unless packet == 'PING'
          true
        end

        def _handle_unexpected(_socket, packet)
          puts "unexpected input from pending socket (#{packet.inspect})"
          true
        end

        def _player_username_taken(socket)
          puts 'rejecting: username already taken'
          socket.send_packet('username already taken')
          socket.close
        end

        def _player_accepted(socket)
          puts "accepting new player #{socket.username}"
          socket.send_packet('OK')
          @croupier.players << socket
        end
      end

    end
  end
end

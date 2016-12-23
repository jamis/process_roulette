require 'process/roulette/croupier/controller_socket'

module Process
  module Roulette
    module Croupier

      # The JoinPending class encapsulates the handling of pending connections
      # during the 'join' phase of the croupier state machine. It explicitly
      # handles new player and new controller connections, moving them from
      # the pending list to the appropriate collections of the croupier itself,
      # depending on their handshake.
      class JoinPending < Array
        def initialize(driver)
          super()
          @driver = driver
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
            _handle_new_controller(socket, packet, @driver.password) ||
            _handle_new_controller(socket, packet, 'OK') ||
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

          if @driver.players.any? { |p| p.username == socket.username }
            _player_username_taken(socket)
          else
            _player_accepted(socket)
          end

          true
        end

        def _handle_new_controller(socket, packet, password)
          return false unless packet == password

          socket.extend(ControllerSocket)
          socket.spectator! if password == 'OK'

          puts format('accepting new %s',
                      socket.spectator? ? 'spectator' : 'controller')
          socket.send_packet('OK')
          delete(socket)
          @driver.controllers << socket

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
          @driver.players << socket
          @driver.broadcast_update(
            "player '#{socket.username}' added" \
            " (#{@driver.players.length} total)")
        end
      end

    end
  end
end

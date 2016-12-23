require 'process/roulette/croupier/restart_handler'

module Process
  module Roulette
    module Croupier

      # The StartHandler encapsulates the "start" state of the croupier state
      # machine. It sends "GO" to all players, listens for their replies
      # with the processes they intend to kill, and waits for all players to
      # check in afterward. It manages the list if active players (removing
      # those that fail to check-in) and transitions to the "restart" state
      # when all players are dead.
      class StartHandler
        def initialize(driver)
          @driver = driver
        end

        def run
          @standing = _prepare_live_players
          @started = Time.now

          until _all_players_confirmed? || _time_elapsed?
            ready = _wait_for_input
            _process_ready_sockets(ready)
          end

          remaining = _kill_unconfirmed_players
          remaining.any? ? StartHandler : RestartHandler
        end

        def _wait_for_input
          ready, = IO.select([*@standing, *@driver.controllers], [], [], 1)
          ready || []
        end

        def _time_elapsed?
          (Time.now - @started) > 1.0
        end

        def _all_players_confirmed?
          @standing.all?(&:confirmed?)
        end

        def _prepare_live_players
          standing = @driver.players.select { |s| !s.killed? }

          @driver.controllers.each do |s|
            s.send_packet('GO')
          end

          standing.each do |s|
            s.victim = nil
            s.confirmed! false
            s.send_packet('GO')
          end
        end

        def _kill_unconfirmed_players
          @standing.select do |s|
            next true if s.confirmed?
            _player_died(s, remove: false)
            false
          end
        end

        def _process_ready_sockets(list)
          list.each do |socket|
            packet = socket.read_packet
            socket.ping! if packet

            if packet.nil?            then _handle_closed_socket(socket)
            elsif _is_player?(socket) then _handle_player(socket, packet)
            elsif packet != 'PING'
              puts "unexpected comment from controller #{packet.inspect}"
            end
          end
        end

        def _is_player?(socket)
          @standing.include?(socket)
        end

        def _handle_closed_socket(socket)
          if @standing.include?(socket)
            _player_died(socket)
          else
            @controllers.delete(socket)
          end
        end

        def _broadcast_update(message)
          payload = "UPDATE:#{message}"
          @driver.controllers.each { |s| s.send_packet(payload) }
        end

        def _player_died(socket, remove: true)
          socket.killed_at = Time.now
          socket.close
          _broadcast_update("#{socket.username} died")
          @standing.delete(socket) if remove
        end

        def _handle_player(socket, packet)
          if socket.has_victim? && packet == 'OK'
            socket.confirmed!
          else
            socket.victim = packet
          end
        end
      end

    end
  end
end

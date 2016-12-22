require 'process/roulette/croupier/join_pending'
require 'process/roulette/croupier/start_handler'
require 'process/roulette/croupier/finish_handler'

module Process
  module Roulette
    module Croupier

      # The JoinHandler encapsulates the "join" state of the croupier state
      # machine. It listens for new connections, builds up the lists of players
      # controllers, and indicates the next state (either 'start' or
      # 'finish') based on the input from the controllers.
      class JoinHandler
        def initialize(croupier)
          @croupier = croupier
          @pending = JoinPending.new(croupier)
          @next_state = nil
        end

        def run
          @croupier.players.clear

          puts 'listening...'
          listener = TCPServer.new(@croupier.port)

          _process_current_state(listener)
          @pending.cleanup!

          listener.close

          @next_state
        end

        def _process_current_state(listener)
          until @next_state
            ready = _wait_for_connections(listener)
            _process_ready_list(ready, listener)

            @pending.reap!
            @croupier.reap!
          end
        end

        def _wait_for_connections(*extras)
          ready, = IO.select(
            [*extras, *@pending, *@croupier.sockets],
            [], [], 1)

          ready || []
        end

        def _process_ready_list(list, listener)
          list.each do |socket|
            if socket == listener
              _process_new_connection(socket)
            else
              _process_participant_connection(socket)
            end
          end
        end

        def _process_new_connection(socket)
          puts 'new pending connection...'
          client = socket.accept
          @pending << Process::Roulette::EnhanceSocket(client)
        end

        def _process_participant_connection(socket)
          packet = socket.read_packet
          socket.ping! if packet

          if @pending.include?(socket)
            @pending.process(socket, packet)
          elsif @croupier.controllers.include?(socket)
            _process_controller_packet(socket, packet)
          else
            _process_player_packet(socket, packet)
          end
        end

        def _process_controller_packet(socket, packet)
          case packet
          when nil    then _controller_disconnected(socket)
          when 'GO'   then _controller_go
          when 'EXIT' then _controller_exit
          when 'PING' then nil
          else puts "unexpected command from controller (#{packet.inspect})"
          end
        end

        def _controller_disconnected(socket)
          puts 'controller has disconnected'
          @croupier.controllers.delete(socket)
        end

        def _controller_go
          puts 'command given to start'
          @next_state = StartHandler
        end

        def _controller_exit
          puts 'command given to exit'
          @next_state = FinishHandler
        end

        def _process_player_packet(socket, packet)
          case packet
          when nil    then @croupier.players.delete(socket)
          when 'PING' then # do nothing
          else puts "unexpected comment from player (#{packet.inspect})"
          end
        end
      end

    end
  end
end

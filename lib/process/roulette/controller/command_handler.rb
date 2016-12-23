require 'process/roulette/controller/game_handler'
require 'process/roulette/controller/finish_handler'

module Process
  module Roulette
    module Controller

      # Handles the COMMAND state of the controller state machine. Listens to
      # both STDIN (unless we're a spectator) and the socket and acts
      # accordingly.
      class CommandHandler
        def initialize(driver)
          @driver = driver
          @next_handler = nil
        end

        def run
          STDOUT.sync = true
          _say 'waiting for bout to begin'

          while @next_handler.nil?
            ready = _wait_for_input
            @driver.socket.send_packet('PING')

            ready.each do |io|
              _process_ready_socket(io)
            end
          end

          @next_handler
        end

        def _say(message, update_prompt = true)
          puts unless @driver.spectator?
          puts message if message
          print 'controller> ' if update_prompt && !@driver.spectator?
        end

        def _wait_for_input
          ios = [ @driver.socket ]
          ios << STDIN unless @driver.spectator?

          ready, = IO.select(ios, [], [], 0.2)
          ready || []
        end

        def _process_ready_socket(io)
          if io == STDIN
            _process_user_input
          elsif io == @driver.socket
            _process_croupier_input
          end
        end

        def _process_user_input
          command = (STDIN.gets || '').strip.upcase

          case command
          when '', 'EXIT'  then _invoke_exit
          when 'GO'        then _invoke_go
          when 'HELP', '?' then _invoke_help
          else                  _invoke_error(command)
          end
        end

        def _invoke_exit
          _say 'telling croupier to terminate'
          @driver.socket.send_packet('EXIT')
        end

        def _invoke_go
          _say 'telling croupier to start game'
          @driver.socket.send_packet('GO')
        end

        def _invoke_help
          puts 'Ok. I understand these commands:'
          puts ' - EXIT (terminates the croupier)'
          puts ' - GO (starts the bout)'
          puts ' - HELP (this page)'
          _say nil
        end

        def _process_croupier_input
          packet = @driver.socket.read_packet

          case packet
          when nil, 'EXIT' then _handle_exit
          when 'GO' then _handle_go
          else _handle_unexpected(packet)
          end
        end

        def _invoke_error(text)
          _say "#{text.inspect} is not understood", false
          _invoke_help
        end

        def _handle_exit
          _say 'croupier is terminating. bye!', false
          @next_handler = Controller::FinishHandler
        end

        def _handle_go
          _say nil, false
          @next_handler = Controller::GameHandler
        end

        def _handle_unexpected(packet)
          _say "unexpected message from croupier: #{packet.inspect}"
        end
      end

    end
  end
end

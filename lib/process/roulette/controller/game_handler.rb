require 'process/roulette/controller/command_handler'

module Process
  module Roulette
    module Controller

      # Handles the GAME state of the controller state machine.
      class GameHandler
        def initialize(driver)
          @driver = driver
        end

        def run
          puts 'BOUT BEGINS'

          @bout_active = true
          @round = 1

          while @bout_active
            _process_input if _wait_for_input
            @driver.socket.send_packet('PING')
          end

          Controller::CommandHandler
        end

        def _wait_for_input
          ready, = IO.select([@driver.socket], [], [], 0.2)
          ready ? ready.first : nil
        end

        def _process_input
          packet = @driver.socket.read_packet

          case packet
          when nil then abort 'disconnected!'
          when 'GO' then _start_next_round
          when 'DONE' then _finish_bout
          when /^UPDATE:(.*)/ then _report_update(Regexp.last_match(1))
          else _handle_unexpected(packet)
          end
        end

        def _start_next_round
          @round += 1
          puts "- ROUND #{@round}"
        end

        def _finish_bout
          puts 'BOUT FINISHED'
          @bout_active = false

          scoreboard = @driver.socket.read_packet
          _display_scoreboard(scoreboard)

          puts
        end

        def _report_update(message)
          puts "- #{message}"
        end

        def _handle_unexpected(packet)
          puts "- unexpected message from croupier (#{packet.inspect})"
        end

        def _display_scoreboard(scoreboard)
          _scoreboard_header
          scoreboard.each.with_index do |player, index|
            puts format('%2d | %-10s | %-10s | %5d',
                        index + 1, player[:name],
                        player[:killer], player[:victims].length)
          end
        end

        def _scoreboard_header
          puts format('   | %-10s | %-10s | %-6s', 'Name', 'Killer', 'Rounds')
          puts format('---+-%10s-+-%10s-+-%6s', '-' * 10, '-' * 10, '-' * 6)
        end
      end

    end
  end
end

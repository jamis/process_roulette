require 'process/roulette/croupier/join_handler'

module Process
  module Roulette
    module Croupier

      # The RestartHandler encapsulates the "restart" state of the croupier
      # state machine. It builds a scoreboard of results from the most recent
      # game and sends it to all controllers, and then advances the state
      # machine to the "join" state.
      class RestartHandler
        def initialize(croupier)
          @croupier = croupier
        end

        def run
          scoreboard = _sorted_players.map do |player|
            _results_for(player)
          end

          @croupier.controllers.each do |controller|
            controller.send_packet('DONE')
            controller.send_packet(scoreboard)
          end

          JoinHandler
        end

        def _sorted_players
          @croupier.players.sort_by { |player| -player.victims.length }
        end

        def _results_for(player)
          {
            name:      player.username,
            killed_at: player.killed_at,
            killer:    player.victims.last,
            victims:   player.victims
          }
        end
      end

    end
  end
end

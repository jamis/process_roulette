module Process
  module Roulette
    module Croupier

      # The FinishHandler encapsulates the "finish" state of the croupier state
      # machine. It closes all player and controller sockets and terminates
      # the state machine.
      class FinishHandler
        def initialize(croupier)
          @croupier = croupier
        end

        def run
          @croupier.sockets.each do |socket|
            socket.send_packet('EXIT')
            socket.close
          end

          nil
        end
      end

    end
  end
end

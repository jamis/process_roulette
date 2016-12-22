module Process
  module Roulette

    # Enhances controller sockets so that controllers can be differentiated
    # from mere spectators.
    module ControllerSocket
      def spectator!
        @spectator = true
      end

      def spectator?
        @spectator
      end
    end

  end
end

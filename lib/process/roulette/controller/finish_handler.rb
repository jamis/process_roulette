module Process
  module Roulette
    module Controller

      # Handles the FINISH state of the controller state machine, by
      # disconnecting from the croupier.
      class FinishHandler
        def initialize(driver)
          @driver = driver
        end

        def run
          puts 'terminating...'
          @driver.socket.close
          nil
        end
      end

    end
  end
end

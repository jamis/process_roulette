require 'process/roulette/croupier/driver'

module Process
  module Roulette

    # The Croupier is actually backed by Croupier::Driver
    module Croupier

      def self.new(port, password)
        Driver.new(port, password)
      end

    end

  end
end

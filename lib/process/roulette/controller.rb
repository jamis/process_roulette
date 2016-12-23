require 'process/roulette/controller/driver'

module Process
  module Roulette

    # Delegates to Controller::Driver
    module Controller

      def self.new(host, port, password = nil)
        Driver.new(host, port, password)
      end

    end

  end
end

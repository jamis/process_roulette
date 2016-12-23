require 'process/roulette/controller/connect_handler'

module Process
  module Roulette
    module Controller

      # Encapsulates both the controller and spectator behavior. If the password
      # is nil, the controller is considered a spectator, allowed to watch the
      # bout, but not to control it.
      #
      # It's state machine works as follows:
      #
      #   CONNECT
      #     - connects to croupier, performs handshake
      #     - advances to COMMAND
      #   COMMAND
      #     - waits for input from terminal (unless spectator)
      #       * "GO" => sends "GO" to croupier
      #       * "EXIT" => sends "EXIT" to croupier
      #     - listens for commands from croupier
      #       * "GO" => advances to GAME
      #       * "EXIT" => advances to FINISH
      #   GAME
      #     - listens for updates from croupier
      #       # "GO" => begins next round
      #       * "UPDATE" => print update from croupier
      #       * "DONE" => advances to DONE
      #   DONE
      #     - diplays final scoreboard
      #     - advances to COMMAND
      #   FINISH
      #     - closes sockets, terminates
      #
      class Driver
        attr_reader :host, :port, :password
        attr_accessor :socket

        def initialize(host, port, password = nil)
          @host = host
          @port = port
          @password = password
        end

        def spectator?
          password.nil?
        end

        def run
          handler = Controller::ConnectHandler
          handler = handler.new(self).run while handler
        end
      end

    end
  end
end

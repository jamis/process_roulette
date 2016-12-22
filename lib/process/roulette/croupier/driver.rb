require 'socket'
require 'process/roulette/croupier/join_handler'
require 'process/roulette/enhance_socket'

module Process
  module Roulette
    module Croupier

      # The croupier is the person who runs a roulette table
      #
      # Croupier is started with a password (see WAIT state, below)
      #
      # STATES
      # - JOIN
      #   * accept connections
      #   * if a connection says :OK, they are added to player list
      #     - should include a desired username
      #     - if username is already taken, reject connection
      #     - if accepted, server sends :OK
      #   * if a connection gives password, they are added to controller list
      #   * all connections must send a :PING at least every 1000ms or be
      #     discarded
      #   * when controller says :EXIT, advance to FINISH
      #   * when controller says :GO, state advances to START and no further
      #     connections are accepted (listening socket is closed)
      # - START
      #   * sends :GO to all players
      #   * players reply with name/pid of process they will kill
      #   * players must next respond with :OK after killing the process
      #   * if player does not reply within 1000ms they are flagged "DEAD"
      #   * if all players are flagged "DEAD", advance to RESTART
      #   * when either all players have responded with :OK, or 1000ms have
      #     elapsed, advance to START
      # - RESTART
      #   * send 'DONE' to controllers
      #   * send final score info to controllers
      #   * cleanup
      #   * advance to JOIN
      # - FINISH
      #   * notify all players and controllers that server is ending
      #   * cleanup
      #   * exit
      class Driver
        attr_reader :port, :password
        attr_reader :players, :controllers

        def initialize(port, password)
          @port = port
          @password = password

          @players = []
          @controllers = []
        end

        def reap!
          @players.delete_if(&:dead?)
          @controllers.delete_if(&:dead?)
        end

        def sockets
          @players + @controllers
        end

        def run
          next_state = Croupier::JoinHandler
          next_state = next_state.new(self).run while next_state
        end
      end

    end
  end
end

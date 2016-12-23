require 'socket'
require 'process/roulette/enhance_socket'
require 'process/roulette/controller/command_handler'

module Process
  module Roulette
    module Controller

      # Handles the CONNECT state of the controller state machine. Connects
      # to the croupier, performs the handshake, and advances to COMMAND state.
      class ConnectHandler
        def initialize(driver)
          @driver = driver
        end

        def run
          puts 'connecting...'

          socket = TCPSocket.new(@driver.host, @driver.port)
          Roulette::EnhanceSocket(socket)

          _handshake(socket)
          @driver.socket = socket

          Controller::CommandHandler
        end

        def _handshake(socket)
          socket.send_packet(@driver.password || 'OK')

          packet = socket.wait_with_ping
          abort 'lost connection' unless packet
          abort "unexpected packet #{packet.inspect}" unless packet == 'OK'
        end
      end

    end
  end
end

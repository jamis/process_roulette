require 'socket'
require 'process/roulette/enhance_socket'

module Process
  module Roulette

    # A simple controller class that initiates a game on the croupier, prints
    # the results when the game ends, and then tells the croupier server to
    # terminate. If the password is nil, the controller is considered a
    # spectator, allowed to watch the bout, but not to control it.
    class Controller
      def initialize(host, port, password = nil)
        @host = host
        @port = port
        @password = password
      end

      def run
        puts 'connecting...'
        socket = Process::Roulette::EnhanceSocket(TCPSocket.new(@host, @port))
        _handshake(socket)

        puts 'starting it up!'
        socket.send_packet('GO')

        _wait_for_end(socket)
        _terminate_game(socket)

        puts 'finishing...'
        socket.close
      end

      def _handshake(socket)
        socket.send_packet(@password || 'OK')

        packet = socket.wait_with_ping
        abort 'lost connection' unless packet
        abort "unexpected packet #{packet.inspect}" if packet != 'OK'
      end

      def _wait_for_end(socket)
        packet = socket.wait_with_ping
        return unless packet == 'DONE'

        scoreboard = socket.read_packet
        _display_scoreboard(scoreboard)
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

      def _terminate_game(socket)
        socket.send_packet('EXIT')
      end
    end

  end
end

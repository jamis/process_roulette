$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'process/roulette/version'

Gem::Specification.new do |s|
  s.name        = 'process-roulette'
  s.version     = Process::Roulette::VERSION
  s.authors     = ['Jamis Buck']
  s.email       = ['jamis@jamisbuck.org']
  s.license     = 'MIT'

  s.homepage    = 'https://github.com/jamis/process_roulette'
  s.summary     = 'A roulette party game for devs'
  s.description = <<DESCRIPTION
Play roulette with your computer! Randomly kill processes until your machine
crashes. The person who lasts the longest, wins! (Best enjoyed in a VM, and
with friends.)
DESCRIPTION

  s.files = Dir['{bin,lib}/**/*', 'LICENSE', 'README.md']

  s.executables << 'croupier'
  s.executables << 'roulette-ctl'
  s.executables << 'roulette-player'

  s.add_dependency 'sys-proctable'
end

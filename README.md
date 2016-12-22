# Process Roulette

This started as a throw-away tweet:
https://twitter.com/jamis/status/808779302468665344 . Only I couldn't stop
thinking about it...and then I needed a project to start experimenting with
[atom](https://atom.io/) and [Rubocop](http://rubocop.readthedocs.io/en/latest/)...
and the next thing I knew, I was working on this.

It's still a work-in-progress, and is not guaranteed to work, and is most
_definitely_ not guaranteed to be safe. (I mean, heck, the whole _point_ of
this is to randomly kill processes on your machine. Use with extreme
caution!)


## Overview

There are three components to process roulette:

* The _croupier_. This is a supervisor that oversees the game. Start it running
  on some machine (preferably one that will not be used during the roulette
  game). The players and controllers will connect to the croupier, which will
  referee the game.
* The _player_. Each player should be running in a virtual machine (or, at the
  very least, on a box that you absolutely despise). Do _not_ run this process
  on any machine that you care about! It's job is to connect to the croupier
  service, and then (when the croupier gives the "go" signal) proceed to whack
  random processes until the machine crashes. _You have been warned._
* The _controller_. Each controller should be running somewhere far away from
  the players. They connect to the croupier service, and are used to control
  the game. The controller says "go", and "exit", and the controller is told
  the results of the game.


## Running a game

First, start the croupier service.

    $ bin/croupier <password>

Then, start players and controllers.

    $ bin/player <username>
    $ bin/controller <password>

When everyone is joined, one of the controllers issues the "GO" command, and
the rest happens automatically!


## License

This software is made available under the terms of the MIT license. (See the
LICENSE file for full details.)


## Author

This software is written by Jamis Buck (<jamis@jamisbuck.org>).

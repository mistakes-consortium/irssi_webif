irssi_webif
===========

web interface to control irssi (so you can irc from your phone)

super alpha, paths are still hard coded and shit

setup
-----

$ cp webif_irssi.pl ~/.irssi/scripts/autorun

/script load webif_irssi.pl

install Mojolicious:

$ curl get.mojolicio.us | sh

Start Mojolicious server thing:

morbo webif_srv.pl &

visit http://localhost:3000/

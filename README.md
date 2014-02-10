irssi_webif
===========

web interface to control irssi (so you can irc from your phone)

super alpha, paths are still hard coded and shit

planned features:
* authenticates directly against user running server process (no need to setup a username and password)
* status bar
* easy window switching
* less ugly interface to irssi (i.e. not using external files)
* integrated into one script that you load in irssi

setup
-----

Change shit in webif_irssi.pl and webif_srv.pl to suit your needs, then:
<pre>
$ cp webif_irssi.pl ~/.irssi/scripts/autorun
</pre>

In Irssi:
<pre>
/script load webif_irssi.pl
</pre>

install Mojolicious:
<pre>
$ curl get.mojolicio.us | sh
</pre>

Start Mojolicious server thing:
<pre>
perl webif_srv.pl daemon &
</pre>

visit https://localhost:3000/

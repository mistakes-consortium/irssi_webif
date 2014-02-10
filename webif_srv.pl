#!/usr/bin/env perl

use strict;
use warnings;
use Fcntl;

use Mojolicious::Lite;

# CHANGE THIS?!
app->secrets(['2930hgxogq0dtlhif83kmdmfjvodk2i39d9FFW']);

# CHANGE THIS TOOOO!!
my $USERS = {
    YOURUSERNAME => 'YOURPASSWORD'};

# ALSO THIS
my $rd_fifo = "/home/ksnieckus/.irssi/web_if_fifo_wr";
my $wr_fifo = "/home/ksnieckus/.irssi/web_if_fifo_rd";

# want to change the port or address?
$ENV{MOJO_LISTEN} = "https://*:3000";

# from here on I don't think there's anything to change really
helper check_user => sub {
    my ($self, $user, $pass) = @_;
    return 1 if $USERS->{$user} && $USERS->{$user} eq $pass;
    return undef;
};

any '/' => sub {
    my $self = shift;

    my $user = $self->param('user') || '';
    my $pass = $self->param('pass') || '';

    return $self->render unless $self->check_user($user, $pass);

    $self->session(user => $user);

    $self->flash(message => 'You\'re authenticated');

    $self->redirect_to('if');
} => 'index';

group {
    under sub {
        my $self = shift;

        return $self->session('user') || !$self->redirect_to('index');
    };

    any '/if' => sub {
        my $self = shift;
        $self->render;
        my $fh;
        sysopen($fh, '/home/ksnieckus/.irssi/web_if_fifo_rd', O_NONBLOCK | O_WRONLY);
        print $fh $self->param('text');
        close $fh;
    };

    websocket '/echo' => sub {
            my $self = shift;

            $self->on(json => sub {
                    my ($self, $hash) = @_;
                    my $fh;
                    sysopen($fh, ">", '/home/ksnieckus/.irssi/web_if_fifo_rd');
                    print $fh $hash->{msg};
                    close $fh;
                });

            # Start recurring timer
            my $id = Mojo::IOLoop->recurring(1 => sub {
                    my $msg;
                    my $fh;
                    open($fh, "<", '/home/ksnieckus/.irssi/web_if_screen');
                    foreach (<$fh>) {
                        $msg->{msg} = $_;
                        $self->send({json => $msg});
                    }
                    close $fh;
                });

            # Stop recurring timer
            $self->on(finish => sub {
                    Mojo::IOLoop->remove($id);
                });
        };
};

get '/logout' => sub {
    my $self = shift;
    $self->session(expires => 1);
    $self->redirect_to('index');
};


app->start;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
<head>
<title>IRSSI Web - Login</title>
<style type="text/css">
body
{
}
</style>

</head> <body>
%= form_for index => begin
% if (param 'user') {
<b>Wrong username or password</b><br />
% }
Name:<br />
%= text_field 'user'
<br />
Password:<br />
%= password_field 'pass'
<br />
%= submit_button 'Authenticate'
%end
</body> </html>

@@ if.html.ep
<!DOCTYPE html>
<html>
<head>
<title>irssi</title>
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
%= javascript begin
var ws = new WebSocket('<%= url_for('echo')->to_abs %>');
ws.onmessage = function (event) {
var buffer = document.getElementById("buffer");
buffer.innerHTML = JSON.parse(event.data).msg;
buffer.scrollTop = buffer.scrollHeight;
};

function insert() {
$('#input').focus();
$('#input').keydown(function (e) {
if (e.keyCode == 13 && $('#input').val()) {
ws.send($('#input').val());
$('#input').val('');
}
});
}
% end


<style type="text/css">
body
{
}

#buffer{
position:absolute;
background-color: rgba(0,0,0,0.9);
padding:0;
bottom:25px;
top:0;
left:0;
width:100%;
display: block;
overflow: auto;
color:white;
font-size: 12px;
font-family: monospace;
}

#inputarea{
position:absolute;
bottom:0;
font-size: 14px;
font-family:monospace;
}
#input {
width: 100%;
}

</style>

</head>
<body>
<div id="buffer"></div>
<div id="inputarea">
%= form_for '/if' => (method => 'POST') => begin
%= text_field 'text'
%= submit_button '>'
% end
</body>
</html>


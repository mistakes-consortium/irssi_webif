# read and write fifos to read from and control irssi
#

our $VERSION = '0.1';
our %IRSSI = (
    authors     => 'Mistakes Consortium',
    contact     => 'ksnieck@alum.wpi.edu',
    name        => 'web_if',
    description => 'Hacky web interface to irssi, requires other external scripts',
    license     => 'GPLv3',
    url         => 'http://github.com/ksnieck/irssi-web_if/',
);

use strict;
use Irssi;
use Irssi::TextUI;
use Fcntl;
our ( $WR_FIFO, $WR_FIFO_HANDLE );
our ( $RD_FIFO, $RD_FIFO_HANDLE, $RD_FIFO_TAG );

sub create_fifo {
    my ($new_fifo) = @_;
    if (not -p $new_fifo) {
        if (system "mkfifo '$new_fifo' &>/dev/null" and
            system "mknod  '$new_fifo' &>/dev/null") {
            print CLIENTERROR "'mkfifo' failed, could not create named pipe";
            return "";
        }
    }
    return 1;
}

sub open_rd_fifo {
    if (not sysopen $RD_FIFO_HANDLE, $RD_FIFO,
        O_NONBLOCK | O_RDONLY) {
        print CLIENTERROR "could not open named pipe for read";
        return "";
    }
    Irssi::input_remove($RD_FIFO_TAG) if defined $RD_FIFO_TAG;
    $RD_FIFO_TAG = Irssi::input_add fileno($RD_FIFO_HANDLE), INPUT_WRITE, \&read_fifo, '';
    return 1;
}

# hooked via Irssi::input_add
sub read_fifo {
    foreach (<$RD_FIFO_HANDLE>) {
        chomp;
        if (substr($_, 0, 1) eq "/") {
            Irssi::active_win->command(substr($_,1));
        } else {
            my $window = Irssi::active_win()->get_active_name();
            if ($window ne "(status)" or $window ne '') { # can't /msg into '(status)' or ''
                Irssi::active_win->command("msg $window $_");
            }
        }
    }
    open_rd_fifo();
}

sub open_wr_fifo {
    if (not sysopen $WR_FIFO_HANDLE, $WR_FIFO, O_NONBLOCK | O_RDWR) {
        print CLIENTERROR "could not open named pipe for write";
        return "";
    }
}

sub destroy_rd_fifo {
    if (define $RD_FIFO_TAG) {
        Irssi::input_remove($RD_FIFO_TAG);
        undef $RD_FIFO_TAG;
    }
    if (defined $RD_FIFO_HANDLE) {
        close $RD_FIFO_HANDLE;
        undef $RD_FIFO_HANDLE;
    }
    if (define $WR_FIFO_HANDLE) {
        close $WR_FIFO_HANDLE;
        undef $WR_FIFO_HANDLE;
    }
    if (-p $RD_FIFO) {
        unlink $RD_FIFO;
        undef $RD_FIFO;
    }
    if (-p $WR_FIFO) {
        unlink $WR_FIFO;
        undef $WR_FIFO;
    }
    return 1;
}

# cleanup fifo on unload
Irssi::signal_add_first 'command script unload', sub {
    my ($script) = @_;
    return unless $script =~
        /(?:^|\s) $IRSSI{name}
         (?:\.[^. ]*)? (?:\s|$) /x;
    destroy_fifos();       #   destroy old fifo
    Irssi::print("%B>>%n $IRSSI{name} $VERSION unloaded", MSGLEVEL_CLIENTCRAP);
};

#not sure which ones are actually useful, but together it's pretty seamless
Irssi::signal_add_last 'gui print text finished', 'write_screen';
Irssi::signal_add_last 'window item changed', 'write_screen';
Irssi::signal_add_last 'window changed', 'write_screen';
Irssi::signal_add_last 'window changed automatic', 'write_screen';

sub write_screen() {
    #my ($text_dest, $str, $stripped_str) = @_;

    my $fh;
    open($fh, "+>", Irssi::get_irssi_dir().'/web_if_screen');

    my $line = Irssi::active_win->view->get_lines;
    my $lines = 1;
    if (defined $line) {
        {
            print $fh Irssi::strip_codes($line->get_text(1) . "<br />");
            $line = $line->next;
            $lines++;
            redo if defined $line;
        }
    }

    close $fh;

};

sub setup() {
    my $new_fifo = Irssi::get_irssi_dir().'/web_if_fifo';

    if (not -p $RD_FIFO) {
        create_fifo($new_fifo."_rd");
        $RD_FIFO = $new_fifo."_rd";
    }
    open_rd_fifo();

    if (not -p $WR_FIFO) {
        create_fifo($new_fifo."_wr");
        $WR_FIFO = $new_fifo."_wr";
    }
    open_wr_fifo();
}

setup();
print CLIENTCRAP "%B>>%n $IRSSI{name} $VERSION (by $IRSSI{authors}) loaded";
print CLIENTCRAP "   (Fifo names: $RD_FIFO $WR_FIFO)";

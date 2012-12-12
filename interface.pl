#!/usr/bin/perl -I/opt/local/lib/perl5//vendor_perl/5.12.4/darwin-thread-multi-2level/


$model=120;  #ft817
$speed=38400;
$device="/dev/tty.usbserial";
$port=4532;
$cmd="rigctld -vvvv --rig-file=$device --model=$model --serial-speed=$speed --port=$port";
#system("$cmd &");

use IO::Socket;
use IO::Select;

# Create a socket
my $socket = new IO::Socket::INET (
  PeerAddr => '127.0.0.1',
  PeerPort => $port,
  Proto => 'tcp',
);
$socket or die "no socket";

sub get_rig()
{
print $socket "m\n";
$mode=<$socket>;
$bw=<$socket>;
print $socket "f\n";
$freq=<$socket>;
print $socket "i\n";
$split_freq=<$socket>;
print $socket "c\n";
$ctcss_tone=<$socket>;
print $socket "r\n";
$rpt_shift=<$socket>;
#print $socket "w \0x00\0x00\0x00\0x00\0xE7\n";
#FT817_READ_RX_STATE 0xE7
#$level=<$socket>;
#print $socket "get_dcd\n";
#$sql_stat=<$socket>;
chomp $mode;
chomp $bw;
chomp $freq;
chomp $split_freq;
chomp $ctcss_tone;
chomp $rpt_shift;
chomp $sql_stat;
chomp $level;
print "$freq $split_freq $mode $bw $ctcss_tone $rpt_shift $level\n";
}


#get_rig();
use Gtk2;

Gtk2->init;

$window = Gtk2::Window->new('toplevel');
$window->show;
$window->signal_connect('delete-event' => sub { Gtk2->main_quit });
my $label  = Gtk2::Label->new('Hello World!');
$window->add($label);
$label ->show;


Gtk2->main;

0;



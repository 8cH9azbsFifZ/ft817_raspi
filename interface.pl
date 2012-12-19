#!/usr/bin/perl -I/opt/local/lib/perl5//vendor_perl/5.12.4/darwin-thread-multi-2level/
# This file is part of the Raspberry Pi Yaesu FT 817 Controller (ft817_raspi).
#
# ft817_raspi is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ft817_raspi is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ft817_raspi.  If not, see http://www.gnu.org/licenses/;.	  
#	 
#	 
# Contributing Authors:
#	Gerolf Ziegenhain, DG6FL
#

use IO::Socket;
use XML::Simple;
use Data::Dumper;
use XML::Parser;
use threads;
use threads::shared;
use Gtk2;      
use Glib;

##########################################################################
##########################################################################
##########################################################################

# Configuration of the code
my $port=4532;
my $machine = "192.168.1.68";

# Global Variables
my $band : shared;
my $bands : shared;
my $channel : shared; 
my %rig : shared;
my $socket;



##########################################################################
##########################################################################
##########################################################################
# Function definition

sub maidenhead_to_wgs () { }
sub wgs_to_maidenhead () { }
sub read_gps () {}
sub calculate_distance_wgs84() {}
sub get_cur_band_name() {}
sub set_channel() {}
sub find_nearest_channel() {}
sub signal_detected() {}
sub watchdog() {}
sub read_rotary () {}

# Initialize the Hamlib backend
sub init_rig ()
{
	$model=120;  #ft817
	$speed=38400;
	$device="/dev/tty.usbserial";
	$cmd="rigctld -vvvv --rig-file=$device --model=$model --serial-speed=$speed --port=$port --listen-addr=$machine";
	print $cmd;
	#system("$cmd &");
}

# Initialize the socket for accessing the Hamlib backend
sub init_rig_socket ()
{
	# Create a socket
	$socket = new IO::Socket::INET (
	  PeerAddr => $machine,
	  PeerPort => $port,
	  Proto => 'tcp',
	);
	$socket or die "no socket";
}

# Read all neccessary variables from the rig
sub read_rig()
{
	print "Read rig: ";
	print $socket "m\n";
	$rig{mode}=<$socket>;
	$rig{bw}=<$socket>;
	print $socket "f\n";
	$rig{freq}=<$socket>;
	#print $socket "i\n";
	#$rig{split_freq}=<$socket>;
	#print $socket "c\n";
	#$rig{ctcss_tone}=<$socket>;
	print $socket "r\n";
	$rig{rpt_shift}=<$socket>;
	#print $socket "w \0x00\0x00\0x00\0x00\0xE7\n";
	#FT817_READ_RX_STATE 0xE7
	#$level=<$socket>;
	#print $socket "get_dcd\n";
	#$sql_stat=<$socket>;
	print $socket "l STRENGTH\n";
	$rig{strength}=<$socket>;

	#working commands
	# found using: echo "t" | nc -w 1 192.168.1.68 4532
	# get_ptto
	# --dump-caps|
	# Get level: RFPOWER(0..0/0) RAWSTR(0..0/0) STRENGTH(0..0/0) 
	# 
	$rig{$_} =~ s/\R//g foreach (keys %rig);
	$rig{$_} =~ s/\r//g foreach (keys %rig);
	$rig{$_} =~ s/\n//g foreach (keys %rig);

	$mhz = int($rig{freq} / 1000000);
	$khz = int(($rig{freq} % 1000000)/1000);
	$hz = int($rig{freq} % 1000);
	$rig{freqformatted} = sprintf  "%03d.%03d.%03d", $mhz, $khz, $hz;

	print "\n";
}

# Display all neccessary variables of the rig on the console
sub display_text ()
{
	printf "$rig{freqformatted} Hz\nMode: $rig{mode}\nChannel: $channel\nBand: $band\nLocator: $locator\n", $mhz, $khz, $hz;
}

# Main loop for controlling the rig
sub main_rig ()
{
	print "Main rig\n";
	my $update_delay = 0.1;
	init_rig_socket();
	while (1 == 1)
	{
		print "Run main rig\n";
		read_rig();
		freq_to_band();
		freq_to_channel();
		select(undef, undef, undef, $update_delay); 
	}
}

# Read the bandplan.xml definitions
sub read_bandplan ()
{
	$filename="bandplan.xml";
	print "Read bandplan: $filename";
	#$parser = new XML::Parser( Style => 'Tree' );
	#$tree = $parser->parsefile( $filename);
	
	my $xml = new XML::Simple;
	my	$data = $xml->XMLin($filename);
	my %B = %{$data->{band}};
	%bands = %B;
	#foreach my $b (keys %B)
	#{
#		print "$B{$b}{min} $B{$b}{max} $B{$b}{name}\n";
		#print Dumper $B{$b};
		#}

#	print Dumper $tree;
		#my $B = $tree;
		#$bands = $tree;
	foreach my $b (keys %B)
	{
		print "===> Band:$b $B{$b}->{min} $B{$b}->{max}\n";
		#my $r = $B{$b}->{region};
		#print "==>";
		#print Dumper $r[0]->{comment};
		#print "==>";
		#print Dumper $r;
		#foreach my $c (keys %C)
		#{
		#		print $c;
		#}
	}
}

# Convert the current rig frequency to a region name
sub freq_to_region ()
{
	my $f = $rig{freq};
	my @regions = $bands{$band}->{"region"};
	my %r;
	foreach my $i (0..$#regions)
	{
		print "$regions[$i]->{min} $f $regions[$i]->{max}\n";
		if ($regions[$i]->{min} <= $f and $f <= $regions[$i]->{max})
		{
			if ($regions[$i]->{"region"})
			{
			} else {
				%r = $regions[$i];
			}
			#print Dumper $regions[$i];
		}
#			print Dumper $regions[$i];
	}
	print Dumper %r; #@regions;
}

# Convert the current rig frequency to a channel name
sub freq_to_channel ()
{
	my $f = $rig{freq};
	print "Find channel for $f ";
	$channel = "";
	my @channels = $bands{$band}->{"channels"}->{"channel"}; # repeater...
	my %cc = %{$channels[0]};
	for my $c (keys %cc)
	{
		if ($cc{$c}->{"freq"} == $f)
		{
			$channel = $c;
		}
	}
}

# Convert the current rig frequency to a band name
sub freq_to_band ()
{
	my $f = $rig{freq};
	print "Find band for $f ";
	$band ="";
	foreach my $b (keys %bands)
	{
		print "$b? ";
		if ($bands{$b}->{min} <= $f and $f <= $bands{$b}->{max})
		{
			$band = $b;
		}
	}
	print " found $band\n";
}

##########################################################################
##########################################################################
##########################################################################
# This is the actual code 
read_bandplan();
$thr = threads->new(\&main_rig);
display_text();



##########################################################################
##########################################################################
##########################################################################
# GTK Interface follows :)

Gtk2->init;

# Style definitions
my $red = Gtk2::Gdk::Color->new (0xFFFF,0,0);
my $bluel = Gtk2::Gdk::Color->new (0,0xCCCC,0xFFFF);
my $black= Gtk2::Gdk::Color->new (0,0,0);
my $white = Gtk2::Gdk::Color->new (0xFFFF,0xFFFF,0xFFFF);
my $font     = Gtk2::Pango::FontDescription->from_string("Sans Bold 42 ");

# Elements
my $window = Gtk2::Window->new;
my $l_freq = Gtk2::Label->new($rig{freqformatted});
my $l_mode = Gtk2::Label->new($rig{mode});
my $l_strength = Gtk2::Label->new($rig{strength});
my $l_channel = Gtk2::Label->new($channel);
my $l_band = Gtk2::Label->new($band);
my $l_locator = Gtk2::Label->new($locator);
 

# Element style
$l_freq->modify_font($font);
$l_mode->modify_font($font);
$l_strength->modify_font($font);
$l_channel->modify_font($font);
$l_band->modify_font($font);
$l_locator->modify_font($font);

$l_freq->modify_fg('normal',$red);
$l_mode->modify_fg('normal',$white);
$l_strength->modify_fg('normal',$white);
$l_band->modify_fg('normal',$white);
$l_channel->modify_fg('normal',$white);
$l_locator->modify_fg('normal',$white);

# Window style
$window->set_border_width(30);
$window->set_title("Combiner");
$window->set_default_size(656,416);
$window->modify_bg("normal",$black);
#$window->fullscreen;

# Organization of the elements
$hbox1 = Gtk2::HBox->new($homogenous, $spacing);
$hbox1->pack_start($l_freq, $expand, $fill, $padding);
$hbox1->pack_start($l_mode, $expand, $fill, $padding);
$hbox1->pack_start($l_strength, $expand, $fill, $padding);
$hbox2 = Gtk2::HBox->new($homogenous, $spacing);
$hbox2->pack_start($l_band, $expand, $fill, $padding);
$hbox3 = Gtk2::HBox->new($homogenous, $spacing);
$hbox3->pack_start($l_channel, $expand, $fill, $padding);
$hbox4 = Gtk2::HBox->new($homogenous, $spacing);
$hbox4->pack_start($l_locator, $expand, $fill, $padding);

$vbox = Gtk2::VBox->new($homogenous, $spacing);
$vbox->pack_start($hbox1, $expand, $fill, $padding);
$vbox->pack_start($hbox2, $expand, $fill, $padding);
$vbox->pack_start($hbox3, $expand, $fill, $padding);
$vbox->pack_start($hbox4, $expand, $fill, $padding);

$window->add($vbox);

$window->show_all();

# Updates of the Interface
#Glib::Timeout->add($timer, \&update_screen);

$window->signal_connect('delete-event' => sub { Gtk2->main_quit });
 Glib::Timeout->add( 1000, sub {
#		 $count++;
#                $l_freq->set_text((localtime(time))[0]);
#					 read_rig();
$l_freq->set_text($rig{freqformatted});
$l_mode->set_text($rig{mode});
$l_strength->set_text($rig{strength});
$l_band->set_text($band);
$l_channel->set_text($channel);
					 #0;
					 return TRUE;
        });

Gtk2->main; 
0;



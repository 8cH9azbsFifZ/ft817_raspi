#!/usr/bin/perl -I/opt/local/lib/perl5//vendor_perl/5.12.4/darwin-thread-multi-2level/
use IO::Socket;
use XML::Simple;
use Data::Dumper;
#use threads;
#use threads::shared;

$real = FALSE;

$port=4532;
sub init_rig ()
{
	$model=120;  #ft817
	$speed=38400;
	$device="/dev/tty.usbserial";
	$cmd="rigctld -vvvv --rig-file=$device --model=$model --serial-speed=$speed --port=$port";
	#system("$cmd &");
}

my %rig;
my $socket;
sub init_rig_socket ()
{
	# Create a socket
	$socket = new IO::Socket::INET (
	  PeerAddr => '127.0.0.1',
	  PeerPort => $port,
	  Proto => 'tcp',
	);
	$socket or die "no socket";
}

sub read_rig()
{
	print $socket "m\n";
	$rig{mode}=<$socket>;
	$rig{bw}=<$socket>;
	print $socket "f\n";
	$rig{freq}=<$socket>;
	print $socket "i\n";
	$rig{split_freq}=<$socket>;
	print $socket "c\n";
	$rig{ctcss_tone}=<$socket>;
	print $socket "r\n";
	$rig{rpt_shift}=<$socket>;
	#print $socket "w \0x00\0x00\0x00\0x00\0xE7\n";
	#FT817_READ_RX_STATE 0xE7
	#$level=<$socket>;
	#print $socket "get_dcd\n";
	#$sql_stat=<$socket>;
	chomp $rig{$_} foreach (keys %rig);

	$mhz = int($rig{freq} / 1000000);
	$khz = int(($rig{freq} % 1000000)/1000);
	$hz = int($rig{freq} % 1000);
	$rig{freqformatted} = sprintf  "%03d.%03d.%03d", $mhz, $khz, $hz;

}

sub display_text ()
{
	$freq = $rig{freq} ; #in Hz

	printf "$rig{freqformatted} Hz\nMode: $rig{mode}\nChannel: $channel\nBand: $band\nLocator: $locator\n", $mhz, $khz, $hz;
}



sub maidenhead_to_wgs () { }
sub wgs_to_maidenhead () { }
sub read_gps () {}
sub calculate_distance_wgs84() {}
sub freq_to_channel() {}
sub get_cur_band_name() {}
sub set_channel() {}
sub find_nearest_channel() {}
sub signal_detected() {}
sub watchdog() {}
sub read_rotary () {}

if ($real == FALSE)
{
	$rig{freq}=439325000;
	$rig{freqformatted}="439.325.000";
	$rig{mode}="FM";
	$locator="JO54el";
	$channel="QRP";
	$band="70cm";
}
else
{
	init_rig_socket();
	read_rig();
}
display_text();


sub read_bandplan ()
{
	$filename="bandplan.xml";
	use XML::Parser;
	my $parser = new XML::Parser( Style => 'Tree' );
	my $tree = $parser->parsefile( $filename);
	
	$xml = new XML::Simple;
	$data = $xml->XMLin($filename);
	my %B = %{$data->{band}};
	foreach my $b (keys %B)
	{
#		print "$B{$b}{min} $B{$b}{max} $B{$b}{name}\n";
		#print Dumper $B{$b};
	}

#	print Dumper $tree;
	my $B = $tree;
	foreach my $b (keys %B)
	{
		print "$b $B{$b}->{min} $B{$b}->{max}\n";
		my $r = $B{$b}->{region};
		print Dumper $r;
		foreach my $c (keys %C)
		{
			print $c;
		}
	}

}


sub update_screen
{
	return TRUE;
	if ($real == FALSE) {
		$count++;
		$l_freq->set_text("abc"); 
	}
	else{
		read_rig();
		$l_freq->set_text($rig{freqformatted});
	}
}

use Gtk2;      
use Glib;

Gtk2->init;

$timeout = 4000;
#$thr = threads->new(\&update_screen);

 
my $window = Gtk2::Window->new;
my $l_freq = Gtk2::Label->new($rig{freqformatted});
my $l_mode = Gtk2::Label->new($rig{mode});
my $l_channel = Gtk2::Label->new($channel);
my $l_band = Gtk2::Label->new($band);
my $l_locator = Gtk2::Label->new($locator);
my $button1 = Gtk2::Button->new('Button 1');
my $button2 = Gtk2::Button->new('Button 2');

 
$window->signal_connect('delete-event' => sub { Gtk2->main_quit });
my $font     = Gtk2::Pango::FontDescription->from_string("Sans Bold 42 ");
$l_freq->modify_font($font);
$l_mode->modify_font($font);
$l_channel->modify_font($font);
$l_band->modify_font($font);
$l_locator->modify_font($font);


$window->set_border_width(30);
$window->set_title("Combiner");
$window->set_default_size(656,416);

$table = Gtk2::Table->new(2, 3, TRUE);

$hbox1 = Gtk2::HBox->new($homogenous, $spacing);
$hbox1->pack_start($l_freq, $expand, $fill, $padding);
$hbox1->pack_start($l_mode, $expand, $fill, $padding);
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

my $red = Gtk2::Gdk::Color->new (0xFFFF,0,0);
my $bluel = Gtk2::Gdk::Color->new (0,0xCCCC,0xFFFF);
my $black= Gtk2::Gdk::Color->new (0,0,0);
my $white = Gtk2::Gdk::Color->new (0xFFFF,0xFFFF,0xFFFF);
$l_freq->modify_fg('normal',$red);
$l_mode->modify_fg('normal',$white);
$l_band->modify_fg('normal',$white);
$l_channel->modify_fg('normal',$white);
$l_locator->modify_fg('normal',$white);

$window->show_all();
$window->modify_bg("normal",$black);
#$window->fullscreen;
$count = 0;
#Glib::Timeout->add($timer, \&update_screen);
 Glib::Timeout->add( 1000, sub {
		 $count++;
                $l_freq->set_text((localtime(time))[0]);
					 #0;
					 return TRUE;
        });



Gtk2->main;
0;



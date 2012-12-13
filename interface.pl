#!/usr/bin/perl -I/opt/local/lib/perl5//vendor_perl/5.12.4/darwin-thread-multi-2level/
use IO::Socket;
use XML::Simple;
use Data::Dumper;

sub init_rig ()
{
	$model=120;  #ft817
	$speed=38400;
	$device="/dev/tty.usbserial";
	$port=4532;
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
}

sub display_text ()
{
	$freq = $rig{freq} ; #in Hz
	$mhz = int($freq / 1000000);
	$khz = int(($freq % 1000000)/1000);
	$hz = int($freq % 1000);

	printf "%03d.%03d.%03d Hz\nMode: $rig{mode}\nChannel: $channel\nBand: $band\nLocator: $locator", $mhz, $khz, $hz;
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


$rig{freq}=439325000;
$rig{mode}="FM";
$locator="JO54el";
$channel="QRP";
$band="70cm";
#read_rig();
display_text();


sub read_bandplan ()
{
	$filename="bandplan.xml";
	$xml = new XML::Simple;
	$data = $xml->XMLin($filename);
	my %B = %{$data->{band}};
	foreach my $b (keys %B)
	{
		print "$B{$b}{min} $B{$b}{max} $B{$b}{name}\n";
		print Dumper $B{$b};
	}
}




use Gtk2;      
use Glib;

Gtk2->init;
 
my $window = Gtk2::Window->new;
my $l_freq = Gtk2::Label->new($rig{freq});
my $l_mode = Gtk2::Label->new($rig{mode});
my $l_channel = Gtk2::Label->new($channel);
my $l_band = Gtk2::Label->new($band);
my $l_locator = Gtk2::Label->new($locator);
my $button1 = Gtk2::Button->new('Button 1');
my $button2 = Gtk2::Button->new('Button 2');

 
$window->signal_connect('delete-event' => sub { Gtk2->main_quit });
my $font     = Gtk2::Pango::FontDescription->from_string("Sans Bold 18 ");
$l_freq->modify_font($font);
$l_mode->modify_font($font);
$l_channel->modify_font($font);
$l_band->modify_font($font);
$l_locator->modify_font($font);


$window->set_border_width(30);
$window->set_title("Combiner");
$window->set_default_size(656,416);

$table = Gtk2::Table->new(2, 3, TRUE);
$window->add($table);

$table->attach_defaults($l_freq, 0, 1, 0, 1);
$table->attach_defaults($l_mode, 1, 2, 0, 1);
$l_freq->set_alignment(1.0,0.5);
$l_mode->set_alignment(0.1,0.5);
my $red = Gtk2::Gdk::Color->new (0xFFFF,0,0);
$l_freq->modify_fg('normal',$red);

$table->attach_defaults($l_band, 0, 1, 1, 2);
$table->attach_defaults($l_channel, 1, 2, 1, 2);
$l_band->set_alignment(0.0,0.5);
$l_channel->set_alignment(0.1,0.5);

$table->attach_defaults($l_locator, 0, 2, 2, 3);
$l_locator->set_alignment(0.0,0.5);

my $bluel = Gtk2::Gdk::Color->new (0,0xCCCC,0xFFFF);
$window->show_all();
#$window->fullscreen; 
Gtk2->main;




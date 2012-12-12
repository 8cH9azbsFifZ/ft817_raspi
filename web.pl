#!/usr/bin/perl -W
use CGI;
use Switch;
use IO::Socket;
use IO::Select;

#my $cmd = new CGI->param('cmd');
my $cmd = @ARGV[0];
#my $val1 = new CGI->param('val1');
my $val1 = @ARGV[1];
#my $val2 = new CGI->param('val2');
my $val2 = @ARGV[2];

if(!$cmd) {
  print "Content-type: text/plain\n\nCommand or Value is Null. Halting.";
  exit(0);
}

# Create a socket
my $socket = new IO::Socket::INET (
  PeerAddr => '127.0.0.1',
  PeerPort => '4532',
  Proto => 'tcp',
);

if(!$socket) {
  print "Content-type: text/plain\n\nCould not create socket. Halting.";
  exit(0);
}

my $s = IO::Select->new();
$s->add($socket);
#$socket->autoflush(1);

my $results = '';

# Determine what command is being passed.
switch ($cmd) {
  case "get_freq" {
    getFreq();
  }
  case "set_freq" {
    setFreq($val1);
  }
  case "set_mode" {
    setMode($val1, 0);
  }
  case "get_mode" {
    getMode();
  }
  case "dump_caps" {
    $results = sendcommand($s,$socket,"+\\dump_caps\n", "Dump capabilities", '');
  }
}

close($socket);

sub getMode {
  my $results = sendcommand($s,$socket,"m\n", "Get mode", '');
  sendResults("The current mode is: $results");
}

sub setMode {
  my $mode = shift;
  my $passBand = shift;
  my $results = sendcommand($s,$socket,"M $mode $passBand\n", "Set mode", '');
  sendResults("The mode has been changed to: $mode");
}

sub setFreq {
  my $freq = shift;
  my $results = sendcommand($s,$socket,"F $freq\n", "Set frequency", '');
  sendRedirect();
}

sub getFreq {
  my $results = sendcommand($s,$socket,"f\n", "Get frequency", '');
  sendResults("The frequency is: $results");
}

 sub sendResults {
  my $results = shift;
  print "Content-type: text/html\n\n";
  my $returned = qq^
    <html>
    <head>
    </head>
    <body>
  ^;
  $returned = $results;
#  $returned .= qq^
#    </body>
#    </html>
#  ^;
  print $returned;
}

sub sendRedirect {
  print "Content-type: text/html\n\n";
  my $redirect = qq^
    <html>
    <head>
    <meta http-equiv="Refresh" content="0;url=http://your.site.net/dir" />
    </head>
    </html>
  ^;
  print $redirect;
}

sub sendcommand {
  my $s = shift;
  my $sock = shift;
  my $cmd = shift;
  my $desc = shift;
  my $comment = shift;
  my $res = '';
  my $return = '';
  
  my $retry = 1;
      $sock->send($cmd);
      #print $sock $cmd;
      sleep 1;
      while ($s->can_read(0)) {
        $sock->sysread($result,1);
    $return .= $result;
    }
  return $return;
}






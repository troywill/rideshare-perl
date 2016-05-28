#!/usr/bin/env perl

use warnings;
use strict;
use IO::Socket::INET6;
use JSON;
###### path-block ############
use FindBin qw($Bin);        #
use File::Basename;          #
use lib "$Bin/../lib";       #
require "globalsat-perl.pm"; #
##############################
###### begin configuration-block ########### 
use AppConfig;                               
                                             
# create a new AppConfig object              
my $config = AppConfig->new;                 
                                             
# define a new variable                      
# $config->define('LOCAL_DATABASE=s');       
$config->define("VAR1=s");                   
                                             
# read configuration file                    
                                             
$config->file("$Bin/../conf/globalsat-perl.conf");            
                                             
my $VAR1 = $config->get("VAR1");             
                                             
print "VAR1 = $VAR1\n";                      
############ end configuration-block ####### 
#### BEGIN GETOPTIONS BLOCK
use Getopt::Long;
my ($verbose, $help, $calibrate); #flags
my $zoom;
my $screenshot;

GetOptions ("zoom=i" => \$zoom,            # numeric
            "screenshot=s"   => \$screenshot, # string
            "verbose"  => \$verbose,       # flag
            "help"     => \$help )       # flag
    or die("Error in command line arguments\n");
#### END GETOPTIONS BLOCK
     

my $gpsd_socket = new IO::Socket::INET6 (
    PeerAddr => 'localhost',
    PeerPort => '2947',
    Proto => 'tcp',
    Blocking => 1
    ) or die "Could not create socket: $!\n";

$gpsd_socket->send('?WATCH={"enable":true,"json":true}');
while ( my $json_line = <$gpsd_socket> ) {

  my $hashref = decode_json($json_line);
  my %hash = %$hashref;

  my $class = $hash{'class'};

  if ( $class eq 'TPV' ) {
      my ($mode,$time,$ept,$lat,$lon,$alt,$epx,$epy,$epv,$track,$speed,$climb,$epd,$eps,$epc) =
          @hash{'mode','time','ept','lat','lon','alt','epx','epy','epv','track','speed','climb','epd','eps','epc'};
      # print "time: $time\nept: $ept\nlat: $lat\nlon: $lon\nalt: $alt\nepx: $epx\nepy: $epy\nepv: $epv\ntrack: $track\nspeed: $speed\nclimb: $climb\nepd: $epd\neps: $eps\nepc: $epc\n";
      $speed *= 2.23694; # meters per second to miles per hour
      $speed = sprintf("%.1f", $speed);
      $track = sprintf("%.1f", $track);
      print "$time, $lat, $lon, $speed, $track\n";
  }
}

#!/usr/bin/env perl
my $pi = atan2(1,1) * 4;

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
use DBI;
my $dbh = DBI->connect("dbi:Pg:dbname=rideshare","","");
while ( my $json_line = <$gpsd_socket> ) {

  my $hashref = decode_json($json_line);
  my %hash = %$hashref;

  my $class = $hash{'class'};

  if ( $class eq 'TPV' ) {
      my ($mode,$time,$ept,$lat,$lon,$alt,$epx,$epy,$epv,$track,$speed,$climb,$epd,$eps,$epc) =
          @hash{'mode','time','ept','lat','lon','alt','epx','epy','epv','track','speed','climb','epd','eps','epc'};
      # print "time: $time\nept: $ept\nlat: $lat\nlon: $lon\nalt: $alt\nepx: $epx\nepy: $epy\nepv: $epv\ntrack: $track\nspeed: $speed\nclimb: $climb\nepd: $epd\neps: $eps\nepc: $epc\n";
      $speed *= 2.23694; # meters per second to miles per hour
      $speed = sprintf("%d", $speed);
      $track = sprintf("%d", $track);
      print "$time, $lat, $lon, $speed, $track\n";
      my $name = "";
      my $sql_statement = "INSERT INTO gpspoint VALUES(DEFAULT,\'$time\',\'$name\',$lat,$lon,$epx,$epy,$epv,$speed,$track);";
      print "==> $sql_statement <==\n";
      my $rv = $dbh->do($sql_statement);

  }
}

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::                                                                         :::
#:::  This routine calculates the distance between two points (given the     :::
#:::  latitude/longitude of those points). It is being used to calculate     :::
#:::  the distance between two locations using GeoDataSource(TM) products    :::
#:::                                                                         :::
#:::  Definitions:                                                           :::
#:::    South latitudes are negative, east longitudes are positive           :::
#:::                                                                         :::
#:::  Passed to function:                                                    :::
#:::    lat1, lon1 = Latitude and Longitude of point 1 (in decimal degrees)  :::
#:::    lat2, lon2 = Latitude and Longitude of point 2 (in decimal degrees)  :::
#:::    unit = the unit you desire for results                               :::
#:::           where: 'M' is statute miles (default)                         :::
#:::                  'K' is kilometers                                      :::
#:::                  'N' is nautical miles                                  :::
#:::                                                                         :::
#:::  Worldwide cities and other features databases with latitude longitude  :::
#:::  are available at http://www.geodatasource.com	                         :::
#:::                                                                         :::
#:::  For enquiries, please contact sales@geodatasource.com                  :::
#:::                                                                         :::
#:::  Official Web site: http://www.geodatasource.com                        :::
#:::                                                                         :::
#:::            GeoDataSource.com (C) All Rights Reserved 2015               :::
#:::                                                                         :::
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


sub distance {
	my ($lat1, $lon1, $lat2, $lon2, $unit) = @_;
	my $theta = $lon1 - $lon2;
	my $dist = sin(deg2rad($lat1)) * sin(deg2rad($lat2)) + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * cos(deg2rad($theta));
  $dist  = acos($dist);
  $dist = rad2deg($dist);
  $dist = $dist * 60 * 1.1515;
  if ($unit eq "K") {
  	$dist = $dist * 1.609344;
  } elsif ($unit eq "N") {
  	$dist = $dist * 0.8684;
		}
	return ($dist);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::  This function get the arccos function using arctan function   :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sub acos {
	my ($rad) = @_;
	my $ret = atan2(sqrt(1 - $rad**2), $rad);
	return $ret;
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::  This function converts decimal degrees to radians             :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sub deg2rad {
	my ($deg) = @_;
	return ($deg * $pi / 180);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::  This function converts radians to decimal degrees             :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sub rad2deg {
	my ($rad) = @_;
	return ($rad * 180 / $pi);
}

print distance(32.9697, -96.80322, 29.46786, -98.53506, "M") . " Miles\n";
print distance(32.9697, -96.80322, 29.46786, -98.53506, "K") . " Kilometers\n";
print distance(32.9697, -96.80322, 29.46786, -98.53506, "N") . " Nautical Miles\n";

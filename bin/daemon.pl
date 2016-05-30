#!/usr/bin/env perl

#################################################################
#
# daemon.pl                                         
# Programmer: Shawn Holland
# I am not responsible for anything.
#
#################################################################
         
use POSIX qw(setsid);
my $proc;
my $error;
my $file = "daemon.pl";
my $pidfile = ">/var/run/daemon.pid";
my $pid2check = "/var/run/daemon.pid";
my $pid;

#Make it a daemon
$proc = Daemonize();

if (!$error) {
        LogMessage("$file : PID $proc : Begin");
}

#Write Pid Information
if (!$error) {
        if (-e $pid2check) {
                LogMessage("$file : PID File $pid2check already exists. Exiting");
                exit(0);
        } else {
                unless (open (FILE, $pidfile)) {
                        $error .= "Error opening file for writing " . $!;
                }
        }
}
if (!$error) {
        LogMessage("$file : PID $proc : Writing pid information to $pidfile");
        print FILE $proc . "\n";
        close (FILE);
}

#Main loop of Daemon
while (!$error) {
        sleep(1);
        LogMessage("Hello World");
}

if ($error) {
        LogMessage("$file : PID $proc : Error $error");
}

LogMessage("$file : PID $proc : END");

exit(0);

#
#Subs
#
#################################################################
#
#       Daemonize
#
#################################################################
#       
#       Used to make this program a daemon
#       Also to redirect STDIN, STDERR, STDOUT
#       Returns PID
#
#################################################################
sub Daemonize {

        unless (chdir '/') {
                $error .= "Can't chdir to /: $!";
        }
        unless (umask 0) {
                $error .= "Unable to umask 0";
        }

        unless (open STDIN, '/dev/null') {
                $error .= "Can't read /dev/null: $!";
        }

        #All print statments will now be sent to our log file
        unless (open STDOUT, '>>/var/log/daemon.log') {
                $error .= "Can't read /var/log/daemon.log: $!";
        }
        #All error messages will now be sent to our log file
        unless (open STDERR, '>>/var/log/daemon.log') {
                $error .= "Can't write to /var/log/daemon.log: $!";
        }

        defined($pid = fork);
        #Exit if $pid exists (parent)
        exit(0) if $pid;

        #As Child
        setsid();
        $proc = $$;
        return ($proc);
}

#################################################################
#
#       LogMessage
#
#################################################################
#
#       Used to log messages 
#
#################################################################
sub LogMessage {
        my $message = $_[0];
        print localtime() . " $message\n";
}

#!/usr/bin/perl

#
# ansrvr-grp-cap.pl
# v0.0 -- aplpha --
#
# Mike Cleckner, KD2FDX
#
# Perl script using Ham::APRS::FAP to grab APRS packets.
# You need to get it from CPAN and maybe other dependencies.
# This will grab only messages sent to ANSRVR which are CQ command and for a specific group.
#
# Takes one command line argument for the ANSRVR Group to monitor.
#
# Wake up fellow human resource and tune into The No Agenda Show Sundays and Thursdays.
# http://noagendashow.com
#


use strict;
use warnings;

use Ham::APRS::IS;
use Ham::APRS::FAP qw(parseaprs);

use Date::Manip;

my $debugON = 0;

# APRS-IS config
my $IShost = "noam.aprs2.net:14580";
my $ISmycall = "N0CALL";
my $ISfilter = "g/ANSRVR"; # other tries "t/poimqstunw" "t/m g/ANSRVR"
my $ISclient = "ansrvr-grp-cap v0.0 --alpha--";

my ($GMTTime,$Time);


# ANSRVR Command to watch for
my $targetCMD = "CQ";
my $targetGRP = ""; # Get from command line

print "\n";
print "ansrvr-grp-cap.pl\n";

my $num_args = $#ARGV + 1;
if ($num_args != 1) 
{
   print "\nUsage: ansrvr-grp-cap.pl ansrvr_group_name\n\n";
   exit;
}
$targetGRP = uc($ARGV[0]);

my $is = new Ham::APRS::IS($IShost, $ISmycall, 'filter' => $ISfilter, 'appid' => $ISclient);
$is->connect('retryuntil' => 3) || die "Failed to connect: $is->{error}";

print "Connected $IShost monitoring '$targetGRP' on 'ANSRVR' ...\n";
print "Ctrl-C to stop\n";

# Be a spinner ... and just spin and spin grabbing packets
for (;;)
{
   my $l = $is->getline_noncomment();
   next if (!defined $l);

   debug("\n--- new packet ---\n$l\n");

   my %packetdata;
   my $retval = parseaprs($l, \%packetdata);

   if ($retval == 1) 
   {
      # For ANSRVR messages, format "command group blah"
      my @msgpcs = split(' ', $packetdata{message});
      my $msglst = scalar @msgpcs;
      my $msgcmd = $msgpcs[0];
      my $msggrp = $msgpcs[1];


      # check that command+group is the one we are looking
      # Watch out for one word and no word messages.
      # Don't show no word messages!
      if ( (uc($targetCMD) eq uc($msgcmd)) 
           && (uc($targetGRP) eq uc($msggrp)) 
           && ($msglst > 2)
         )
      {
         # These are the droids you are looking for ...
         debug("MATCH! CMD = $msgcmd\t GRP = $msggrp\n");


         my $msgslc = "";
         if ($msglst > 3) 
         { 
            $msgslc = join(' ',@msgpcs[2..$msglst-1]);
         } 
         else
         { 
            $msgslc = $msgpcs[2]; 
         }

         print "\n---\n";

         # What time is it!?!?
         $GMTTime = gmtime(time);
         $Time = &UnixDate($GMTTime, '%Y-%m-%d %H:%M:%S');

         # Print something out. Your choices for packetdata appear to be:
         #    destination, dstcallsign, digipeaters, messageid, message, body,
         #    origpacket, type, srccallsign, header


         # Format it like other APRS clients do
         print "$Time UTC ";
         print "$packetdata{srccallsign}\n";
         print "N:" . uc($msggrp) ." $msgslc\n";

         debug("$packetdata{origpacket}\n");
      }

      if ($debugON) { print "---\n"; while (my ($key, $value) = each (%packetdata)) { print "\t$key: $value\n"; } print "---\n"; }
   }

}

$is->disconnect() || die "Failed to disconnect: $is->{error}";

sub debug {
   my $dtxt = $_[0];
   if ($debugON) { print $dtxt; }
   return;
}

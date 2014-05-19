#!/usr/bin/perl

#
# ansrvr-grp-2rss.pl
# v0.1
#
# Mike Cleckner, KD2FDX
#
# Perl script using Ham::APRS::FAP to grab APRS packets.
# You need to get it from CPAN and maybe other dependencies.
# This will grab only messages sent to ANSRVR which are CQ command and for a specific group.
# Writes the messages to an RSS formated file specified by $rssFile
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
use XML::RSS;

use Date::Manip;

my $debugON = 0;

# APRS-IS config
my $IShost = "noam.aprs2.net:14580";
my $ISmycall = "N0CALL";
my $ISfilter = "g/ANSRVR"; # other tries "t/poimqstunw" "t/m g/ANSRVR"
my $ISclient = "ansrvr-grp-2rss.pl v0.1";

my ($GMTTime,$Time,$rssTime);


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

# Where do you want the file stored and it's name
my $rssFile = "/var/www/APRS/ANSRVR-$targetGRP.rss";

$GMTTime = gmtime(time);
$Time = &UnixDate($GMTTime, '%Y-%m-%d %H:%M:%S');
$rssTime = &UnixDate($GMTTime, '%a, %d %b %Y %H:%M:%S UT');

print "Connected $IShost at $Time UTC\n";
print "Monitoring '$targetGRP' on 'ANSRVR' ...\n";
print "Ctrl-C to stop\n";

# RSS Things you can customize for yourself
my $rssMoreDescription = "\nCheck out \"The No Agenda Show\" http://noagendashow.com. ITM!"
                       . "\nGet your HAM license or upgrade -- http://hamstudy.org";


my $rss = new XML::RSS(version => '2.0');

if (-e $rssFile )
{
   # Read in the existing file
   $rss->parsefile($rssFile);
}
else
{
   # Create file
   $rss->channel (
      title		=> "APRS-IS ANSRVR group ${targetGRP} Feed",
      language		=> "en",
      description	=> "Messages sent to ANSRVR which are CQ command and for group ${targetGRP}"
                         . ${rssMoreDescription},
      docs 		=> "http://blogs.law.harvard.edu/tech/rss",
      pubDate		=> "${rssTime}",
   );
   $rss->image (
      title		=> "APRS",
      url		=> "http://www.aprs.org/logos/aprs.gif",
      link		=> "http://www.aprs.org/",
      description	=> "APRS is not a vehicle tracking system. It is a two-way tactical real-time digital communications system between all assets in a network sharing information about everything going on in the local area.",
   );
   $rss->save($rssFile);
}

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
         $rssTime = &UnixDate($GMTTime, '%a, %d %b %Y %H:%M:%S UT');

         # Print something out. Your choices for packetdata appear to be:
         #    destination, dstcallsign, digipeaters, messageid, message, body,
         #    origpacket, type, srccallsign, header


         # Format it like other APRS clients do
         print "$Time UTC ";
         print "$packetdata{srccallsign}\n";
         print "N:" . uc($msggrp) ." $msgslc\n";
         print "$packetdata{origpacket}\n";

         # create the rss item
         my $iTitle = "$Time UTC $packetdata{srccallsign}";
         my $iDesc = 
                     "<A HREF=\"http://aprs.fi/info/a/$packetdata{srccallsign}\">"
                   . "<B>$packetdata{srccallsign}</B>"
                   . "</A>"
                   . " to "
                   . "<I>ANSRVR>" . uc($msggrp) . "</I>"
                   . "<BR>$msgslc\n"
                   . "<UL><I>$packetdata{origpacket}</I></UL>"
                   ;

         # Update pubDate
         $rss->channel (
            pubDate		=> "$rssTime",
            description	=> "Messages sent to ANSRVR which are CQ command and for group ${targetGRP}"
                         . ${rssMoreDescription},
         );

         $rss->add_item(
         	 title		=> "$iTitle",
         	 description	=> "$iDesc",
                 pubDate	=> "$rssTime",
                 mode		=> 'insert'
         	 );
         debug ($rss->as_string);

	 $rss->save($rssFile);
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

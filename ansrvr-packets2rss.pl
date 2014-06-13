#!/usr/bin/perl

#
# ansrvr-packets2rss.pl
# v0.2
#
# Mike Cleckner, KD2FDX
#
# This script will read the RSS file created by ansrvr-rss2packets.pl and 
# create an rss file.
#

use strict;
use warnings;

use Ham::APRS::FAP qw(parseaprs);
use XML::RSS;

use Date::Manip;


my ($GMTTime,$Time,$rssTime);

my $targetGRP = ""; # Get from command line

print "\n";
print "ansrvr-packets2rss.pl\n";

my $num_args = $#ARGV + 1;
if ($num_args != 1) 
{
   print "\nUsage: ansrvr-packets2rss.pl ansrvr_group_name\n\n";
   exit;
}

$targetGRP = uc($ARGV[0]);

# Where do you want the file stored and it's name -- you can customize it yourself
my $rssFile = "/var/www/APRS/ANSRVR-${targetGRP}.rss";
my $packetFile = "/var/www/APRS/ANSRVR-${targetGRP}-packets.txt";

$GMTTime = gmtime(time);
$Time = &UnixDate($GMTTime, '%Y-%m-%d %H:%M:%S');
$rssTime = &UnixDate($GMTTime, '%a, %d %b %Y %H:%M:%S UT');

# RSS Things you can customize for yourself
my $rssMoreDescription = "\nCheck out \"The No Agenda Show\" -- noagendashow.com -- ITM!"
                       . "\nGet your HAM license or upgrade -- hamstudy.org";


my $rss = new XML::RSS(version => '2.0');
$rss->channel (
	title			=> "APRS-IS ANSRVR group ${targetGRP} Feed",
	language		=> "en",
	description		=> "Messages sent to ANSRVR which are CQ command and for group ${targetGRP}"
					 . ${rssMoreDescription},
	docs 			=> "http://blogs.law.harvard.edu/tech/rss",
	pubDate			=> "${rssTime}",
);
$rss->image (
	title		=> "APRS",
	url		=> "http://www.aprs.org/logos/aprs.gif",
	link		=> "http://www.aprs.org/",
	description	=> "APRS is not a vehicle tracking system. It is a two-way tactical real-time digital communications system between all assets in a network sharing information about everything going on in the local area.",
	width		=> "200",
	height		=> "112",
);

open (PACKETFILE, "< $packetFile") || die "problem opening $packetFile\n";
while (my $line = <PACKETFILE>)
{
	print "line = $line\n";
	my ($timeStamp, $aprspacket) = split('#',$line,2);
	my %packetdata;
	my $retval = parseaprs($aprspacket, \%packetdata);
	if ($retval == 1)
	{
		# decoding ok do something with the data
		my @msgpcs = split(' ', $packetdata{message});
		my $msglst = scalar @msgpcs;
		my $msgcmd = $msgpcs[0];
		my $msggrp = $msgpcs[1];
		
		my $msgslc = "";
		if ( $msglst > 3)
		{
			$msgslc = join(' ',@msgpcs[2..$msglst-1]);
		}
		else
		{
			$msgslc = $msgpcs[2];
		}

      
		my $cTime = &UnixDate($timeStamp, '%Y-%m-%d %H:%M:%S');
		my $iTitle = "$cTime UTC $packetdata{srccallsign}";
		my $iDesc =
			"<A HREF=\"http://aprs.fi/info/a/$packetdata{srccallsign}\">"
			   . "<B>$packetdata{srccallsign}</B>"
			   . "</A>"
			   . " to "
			   . "<I>$packetdata{destination}>" . uc($msggrp) . "</I>"
			   . "<BR>$msgslc\n"
			   . "<UL><I>$packetdata{origpacket}</I></UL>"
			   ;
		$rss->add_item (
			title 			=> "$iTitle",
			description	=> "$iDesc",
			pubDate		=> "$timeStamp",
			mode		=> 'insert',
		);
	}
	else
	{
		warn "Parsing failed: $packetdata{resultmsg} ($packetdata{resultcode})\n";
	}
}
$rss->save($rssFile);
close (PACKETFILE);



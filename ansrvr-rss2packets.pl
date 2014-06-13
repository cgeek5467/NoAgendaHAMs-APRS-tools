#!/usr/bin/perl

#
# ansrvr-rss2packets.pl
# v0.2
#
# Mike Cleckner, KD2FDX
#
# This script will read the RSS file created by ansrvr-grp-2rss and create a file
# of the APRS packets.
#

use strict;
use warnings;

use XML::RSS;

use Date::Manip;


my ($GMTTime,$Time,$rssTime);

my $targetGRP = ""; # Get from command line

print "\n";
print "ansrvr-rss2packets.pl\n";

my $num_args = $#ARGV + 1;
if ($num_args != 1) 
{
   print "\nUsage: ansrvr-rss2packets.pl ansrvr_group_name\n\n";
   exit;
}

$targetGRP = uc($ARGV[0]);

# Where do you want the file stored and it's name -- you can customize it yourself
my $rssFile = "/var/www/APRS/ANSRVR-${targetGRP}.rss";
my $htmlFile = "/var/www/APRS/ANSRVR-${targetGRP}.html";
my $packetFile = "/var/www/APRS/ANSRVR-${targetGRP}-packets.txt";

$GMTTime = gmtime(time);
$Time = &UnixDate($GMTTime, '%Y-%m-%d %H:%M:%S');
$rssTime = &UnixDate($GMTTime, '%a, %d %b %Y %H:%M:%S UT');


my $rss = new XML::RSS(version => '2.0');

if (-e $rssFile )
{
   # Read in the existing file
   $rss->parsefile($rssFile);
   
   open (PACKETFILE, "> $packetFile") || die "problem opening $packetFile\n";
   foreach my $item (@{$rss->{'items'}})
   {
      #print PACKETFILE "$item->{description}\n";
      my $itemDate=$item->{pubDate};
      $item=$item->{description};

      # HMMM &#x3C;UL&#x3E;&#x3C;I&#x3E; = <UL><I>
      #      &#x3C;/I&#x3E;&#x3C;/UL&#x3E; = </I></UL>
      my @A = split ('<UL><I>', $item);
      my @B = split ('</I>', $A[1]);

      print PACKETFILE "$itemDate#$B[0]\n";
   }
   close (PACKETFILE);
}
else { print "No existing RSS file $rssFile"; }




Wanted something to capture APRS-IS packets for our specific ANSRVR Group.
Use PERL and CPAN module Ham::APRS::FAP (http://search.cpan.org/dist/Ham-APRS-FAP/).

It will be a collection of PERL scripts.

ansrvr-grp-cap.pl : grab packets for an ANSRVR group (specfied on command line) and display the CQs.

ansrvr-grp-2rss.pl : grab packets for an ANSRVR group and create / append to an RSS feed. Display CQs.

ansrvr-packets2rss.pl : take date from packets file (generated by ansrvr-grp-cap.pl) and create a rss file.

ansrvr-rss2packets.pl : take a rss file and create a packets file. (utility)

------------------------------------------------------------
Wake up fellow human resource and check out The No Agenda Show -- noagendashow.com

Get your HAM license or upgrade --  hamstudy.org

GitHub Repo short URL itm.im/4gsjq

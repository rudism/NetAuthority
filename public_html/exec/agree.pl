#!/usr/bin/perl -w

use strict;
use CGI qw(:standard);

my $q = new CGI;

my $file = $q->param('certificate') . ".tmp";

if (-e "/home/netauthority/data/temp/$file"){

if ($q->param('action') eq 'Agree'){
	#log the reporter
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900;
	
	open(LOG, ">>/home/netauthority/data/netauthority.log");
	open(FILE, "</home/netauthority/data/temp/$file");
	my @email = <FILE>;
	close(FILE);
	my $addr = $email[0];
	$addr =~ s/To\: //g;
	$addr =~ s/\n//g;
	my $date = "$mon/$mday/$year $hour:$min:$sec";
	my $ip = $ENV{'REMOTE_ADDR'};
	print LOG "$date $ip $addr\n";
	close(LOG);
	
	#update the database values
	if($q->param('_hate')){
		&inc_db('hate');
	}
	if($q->param('_porn')){
		&inc_db('porn');
	}
	if($q->param('_childporn')){
		&inc_db('childporn');
	}
	if($q->param('_bestiality')){
		&inc_db('bestiality');
	}
	if($q->param('_gayporn')){
		&inc_db('gayporn');
	}
	if($q->param('_irporn')){
		&inc_db('irporn');
	}
	if($q->param('_blasphemy')){
		&inc_db('blasphemy');
	}
	
	if(lc($addr) =~ /\@telus.*/ || lc($addr) =~ /abuse\@.*/ || lc($addr) =~/ucalgary/){
		unlink "/home/netauthority/data/temp/$file";
		#print confirmation
		print "Content-type: text/html\n\n";
		require "header.pl";
		
		print "<P>Thank you for your submission. The Net Authority Investigations Department will look into your submission as soon as possible, at which point the offender may be added to our databases.</P>\n";
	
		open(FOOTER,"</home/netauthority/public_html/footer.html");
		print <FOOTER>;
		close(FOOTER);
	} else {

		#send the email
		open(MAIL, "|/usr/sbin/sendmail -t");
		foreach my $line(@email){
			print MAIL "$line";
		}
		close(MAIL);
		
		#delete the temp file
		unlink "/home/netauthority/data/temp/$file";
		
		#print confirmation
		print "Content-type: text/html\n\n";
		require "header.pl";
		
		print "<P>Thank you for your submission. The Net Authority Investigations Department will look into your submission as soon as possible, at which point the offender may be added to our databases.</P>\n";
		
		open(FOOTER,"</home/netauthority/public_html/footer.html");
		print <FOOTER>;
		close(FOOTER);
	}

} else {
	my $file = $q->param('certificate') . ".tmp";
	unlink "/home/netauthority/data/temp/$file";
	print "Location: http://www.netauthority.org/\n\n";
}

}

sub inc_db {
	my $db = shift;
	open (DB, "</home/netauthority/data/$db.db");
	my $num = <DB>;
	close(DB);
	$num++;
	open (DB, ">/home/netauthority/data/$db.db");
	print DB "$num";
	close(DB);
}

1;

#!/usr/bin/perl -w

use strict;
use CGI qw(:standard);

print "Content-type: text/html\n\n";
require "header.pl";

my $q = new CGI;

#first check that the email is valid
my $email = &strip_html($q->param('email'));
if(&valid_email($email) == 1){
	
	#now check if their name is at least there
	my $name = &strip_html($q->param('name'));
	if($name ne ''){
		
		#get the other inputs
		my $url = &strip_html($q->param('url'));
		my $comments = &strip_html($q->param('comments'));
		
		#check to make sure they checked off at least one violation
		my %dbhash = {};
		my @inputs = $q->param;
		foreach my $input(@inputs){
			if($input =~ /^_/ && $q->param($input) == 1){
				$dbhash{$input} = 1;
			}
		}
		my @dbcount = keys(%dbhash);
		if($#dbcount > 0){
			
			#compose the email
			
			my $webcheck = "";
			if($url =~ /^http\:\/\// && $url ne 'http://'){
				$webcheck = " by checking your webpage at $url";
			}
			
			my $lower=1000; 
			my $upper=2000000; 
			my $certificate = int(rand( $upper-$lower+1 ) ) + $lower;
			
			open(MAIL, ">/home/netauthority/data/temp/$certificate.tmp");
			print MAIL "To: \"$name\" <$email>\n";
			#if(!($email =~ /netauthority\.org/)){
			    #print MAIL "Bcc: \"Net Authority Investigations\" <investigations\@netauthority.org>\n";
			#}
			print MAIL "From: \"Net Authority Investigations\" <investigations\@netauthority.org>\n";
			print MAIL "Return-Path: investigations\@netauthority.org\n";
			print MAIL "Reply-To: \"Net Authority Investigations\" <investigations\@netauthority.org>\n";
			print MAIL "Subject: Notification of Internet Violations\n\n";
			
			print MAIL "Dear $name,\n\n";
			print MAIL "It has recently been brought to our attention that you are, or have been, in violation of the Net Authority Acceptable Internet Usage Guidelines. It has been reported that you distribute and/or view offensive materials over the Internet.\n\n";
			print MAIL "Net Authority has investigated these claims$webcheck and verified that they are true.\n\n";
			print MAIL "As a result, your personal information has been added to one or more Net Authority Internet offender databases. Your information will be stored in the databases until enough evidence has been gathered against you to warrant further actions. To help avoid such a situation, it is strongly recommended that you cease your immoral actions on the Internet at once.\n\n";
			print MAIL "You have been added to the following databases:\n";
			if($q->param('_hate') == 1){
				print MAIL " - Hate Literature Offenders\n";
			}
			if($q->param('_porn') == 1){
				print MAIL " - Pornography Offenders\n";
			}
			if($q->param('_childporn') == 1){
				print MAIL " - Child Pornography Offenders\n";
			}
			if($q->param('_bestiality') == 1){
				print MAIL " - Bestiality Offenders\n";
			}
			if($q->param('_gayporn') == 1){
				print MAIL " - Homosexual Pornography Offenders\n";
			}
			if($q->param('_irporn') == 1){
				print MAIL " - Interracial Pornography Offenders\n";
			}
			if($q->param('_blasphemy') == 1){
				print MAIL " - General Blasphemy Offenders\n";
			}
			print MAIL "\nIf you would like more information about Net Authority or the Net Authority Acceptable Internet Usage Guidelines, you may read the details at http://www.netauthority.org/. It is imperative that you fully understand the guidelines if you wish to avoid further prosecution.\n\n";
			if($comments){
				print MAIL "While the individual who reported your actions to us will remain anonymous, he or she wished to pass these words on to you:\n\n";
				$comments =~ s/\n/ /g;
				$comments =~ s/\r/ /g;
				$comments =~ s/"/'/g;
				print MAIL "\"$comments\"\n\n";
			}
			print MAIL "May God be with you as you struggle to overcome these evil impulses. You will be in our prayers at night.\n\n";
			print MAIL "God speed,\n\n";
			print MAIL "Net Authority Investigations Department\n";
			print MAIL "investigations\@netauthority.org\n";
			print MAIL "http://www.netauthority.org/";
			close(MAIL);
			
			
			#print disclaimer and point to agree.pl
			
			print "<DIV ALIGN=\"center\">\n";
			print "<FORM METHOD=\"POST\" ACTION=\"exec/agree.pl\">\n";
			print "<INPUT TYPE=\"hidden\" NAME=\"certificate\" VALUE=\"$certificate\">\n";
			
			my @names = $q->param;
			foreach my $name(@names){
				if($name =~ /^_/ && $q->param($name) == 1){
					print "<INPUT TYPE=\"hidden\" NAME=\"$name\" VALUE=\"1\">\n";
				}
			}
			
			print "<P>By clicking \"Agree\" below, you are agreeing to the following:</P>\n";
			print "<P><TEXTAREA COLS=\"40\" ROWS=\"10\" READONLY>";
			
			open(AGREE, "</home/netauthority/public_html/agree.txt");
			print <AGREE>;
			close(AGREE);
			
			print "</TEXTAREA></P>\n";
			print "<P CLASS=\"small\"><A HREF=\"agree.txt\" TARGET=\"_blank\">Open In New Window</A></P>\n";
			
			print "<BR>\n";
			print "<P><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Agree\">\&nbsp;<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Disagree\"></P>\n";
			
			print "</FORM>\n";
			print "</DIV>\n";
			
		}
		else {
			print "<P>Our algorithms have determined that there is a reasonable chance that the suspected offender is not in violation of the <a href=\"guidelines.html\">Net Authority Acceptable Internet Usage Guidelines</a>. We still recomment that you keep an eye on the individual, however, in case any other signs begin to show.</P>\n";
		}
	}
	else {
		print "<P>You must provide the suspected offender's full name. Please use your browser's back button and fill in the appropriate information.</P>\n";
	}
} else {
	print "<P>The suspected offender's email address you have entered is not a valid email address. Please use your browser's back button to go back and check over the information you have entered.</P>\n";
}

open(FOOTER,"</home/netauthority/public_html/footer.html");
print <FOOTER>;
close(FOOTER);

sub valid_email {
	my $str = shift;
	if($str =~ /^[\w-\.]{1,}\@([\da-zA-Z-]{1,}\.){1,}[\da-zA-Z-]{2,3}$/){
	    if(lc($str) =~ /netauthority\.org$/ || lc($str) =~ /\@.*\.gov$/){
		return 0;
	    } else {
		return 1;
	    }
	} else {
		return 0;
	}
}

sub strip_html {
	my $str = shift;
	$str =~ s/<SCRIPT.+?<\/SCRIPT>//gsi;
	$str =~ s/<!--.+?-->//gs;
	$str =~ s/<([^>])*>//gs;
	return $str;
}

1;



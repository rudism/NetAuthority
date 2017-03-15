############################################
##                                        ##
##                 WebBBS                 ##
##           by Darryl Burgdorf           ##
##       (e-mail burgdorf@awsd.com)       ##
##                                        ##
##             version:  4.33             ##
##         last modified:  6/8/00         ##
##           copyright (c) 2000           ##
##                                        ##
##    latest version is available from    ##
##        http://awsd.com/scripts/        ##
##                                        ##
############################################

sub WebBBS {
	&Parse_Form;
	&Initialize_Data;
	if ($ENV{'QUERY_STRING'} =~ /addresslist/i) { &UpdateAddressList; }
	elsif ($ENV{'QUERY_STRING'} =~ /delete/i) {
		if ($DBMType==2) { dbmclose (%MessageList); }
		else { untie %MessageList; }
		unless ($UseLocking) { &MasterLockOpen; }
		&LockOpen (DBLOCK,"$dir/dblock.txt");
		&MessageDBMWrite;
		&Delete;
	}
	elsif ($ENV{'QUERY_STRING'} =~ /reconfigure/i) { &Reconfigure; }
	elsif ($ENV{'QUERY_STRING'} =~ /search/i) { &Search; }
	elsif ($ENV{'QUERY_STRING'} =~ /subscribe/i) { &Subscribe; }
	else { &TopStats; }
}

sub TopStats {
	foreach $message (@sortedmessages) {
		$date=$sub=$poster=$prev=$next=$count=$admin=$ip="";
		($date,$sub,$poster,$prev,$next,$count,$admin,$ip) =
		  split(/\|/,$MessageList{$message});
		$poster =~ s/&pipe;/\|/g;
		unless ($PosterCount{$poster}) {
			$PosterCount++;
		}
		$PosterCount{$poster}++;
		if ($date > $LastDate{$poster}) {
			$LastPost{$poster} = $message;
			$LastDate{$poster} = $date;
		}
	}
	&Header($text{'3001'},$MessageHeaderFile);
	&Header2;
	print "<div align=\"center\">\n";
	if ($AdminRun) {
		print "<P><BIG><BIG><STRONG>$text{'3001'}</STRONG></BIG></BIG>\n";
	}
	else {
		print "<P><BIG><BIG><STRONG>$text{'3000'} $TopNPosters $text{'3001'}</STRONG></BIG></BIG>\n";
	}
	print "<P><STRONG>$text{'3002'}:</STRONG> $TotalMessages ";
	print "<STRONG>| $text{'3003'}:</STRONG> $PosterCount\n";
	if ($PosterCount == 0) {
		&Footer($MessageFooterFile,"credits");
	}
	$average = int(($TotalMessages/$PosterCount)+.5);
	print "<BR><STRONG>$text{'3004'}:</STRONG> $average\n";
	print "<P><TABLE BORDER=0 CELLSPACING=0 CELLPADDING=3>\n";
	print "<TR VALIGN=BOTTOM><TH ALIGN=LEFT>";
	print "$text{'3005'}<BR><HR NOSHADE></TH><TD>&nbsp;</TD>";
	print "<TH ALIGN=RIGHT>";
	print "$text{'3006'}<BR><HR NOSHADE></TH><TD>&nbsp;</TD>";
	print "<TH ALIGN=RIGHT>";
	print "$text{'3007'}<BR><HR NOSHADE></TH><TD>&nbsp;</TD>";
	print "<TH ALIGN=LEFT>";
	print "$text{'3008'}<BR><HR NOSHADE></TH></TR>\n";
	if ($AdminRun && $UserProfileDir) {
		opendir (PROFILES,$UserProfileDir);
		@profiles = readdir(PROFILES);
		closedir (PROFILES);
		foreach $profile (@profiles) {
			if ($profile =~ /^(.*)\.txt$/) { $ProfileList{$1} = 1; }
		}
	}
	foreach $key (sort ByPostCount keys(%PosterCount)) {
		unless ($AdminRun) {
			$postercounter++;
			last if ($postercounter > $TopNPosters);
		}
		print "<TR><TD NOWRAP>";
		$ProfileCheck = $key;
		$ProfileCheck =~ s/[^\w\.\-\']/\+/g;
		$ProfileCheck =~ tr/A-Z/a-z/;
		if (-e "$UserProfileDir/$ProfileCheck.txt") {
			print "<A HREF=\"$DestinationURL$BBSquery";
			if ($AdminRun) {
				print "profileedit=$ProfileCheck\"$BBStargettop";
			}
			else {
				print "profile=$ProfileCheck\" TARGET=\"_blank\"";
			}
			print ">$key</A>";
			$ProfileList{$ProfileCheck} = 0;
		}
		else { print "$key"; }
		print "</TD><TD>&nbsp;</TD>";
		print "<TD ALIGN=RIGHT>";
		print "$PosterCount{$key}</TD><TD>&nbsp;</TD>";
		$percent = (($PosterCount{$key}/$TotalMessages)*100)+0.0051;
		if ($percent < 10) { $percent =~ s/(....).*/$1/; }
		else { $percent =~ s/(.....).*/$1/; }
		print "<TD ALIGN=RIGHT>";
		print "${percent}%</TD><TD>&nbsp;</TD>";
		print "<TD NOWRAP><A HREF=\"$DestinationURL$BBSquery";
		print "read=$LastPost{$key}\"$BBStarget>";
		print &PrintDate($LastDate{$key}),"</A></TD></TR>\n";
	}
	if ($AdminRun) {
		foreach $key (keys(%ProfileList)) {
			next if ($ProfileList{$key} < 1);
			print "<TR><TD NOWRAP>";
			print "<A HREF=\"$DestinationURL$BBSquery";
			print "profileedit=$key\"$BBStargettop>";
			print "$key</A>";
			print "</TD><TD>&nbsp;</TD>";
			print "<TD ALIGN=RIGHT>";
			print "0</TD><TD>&nbsp;</TD>";
			print "<TD ALIGN=RIGHT>";
			print "</TD><TD>&nbsp;</TD>";
			print "<TD NOWRAP></A></TD></TR>\n";
		}
	}
	print "</TABLE></div>\n";
	&Footer($MessageFooterFile,"credits");
}

sub ByPostCount {
	$PosterCount{$b}<=>$PosterCount{$a};
}

sub Delete {
	$PassCheck = 0;
	unless ($FORM{'newpassword'}) { &Error("9600","9601"); }
	$newpassword = crypt($FORM{'newpassword'},"aa");
	$message = $FORM{'delete'};
	$subdir = "bbs".int($message/1000);
	unless (-e "$dir/$subdir/$message") { &Error("9600","9601"); }
	$oldpassword = "";
	open (FILE,"$dir/$subdir/$message");
	@message = <FILE>;
	close (FILE);
	foreach $line (@message) {
		if ($line =~ /^PASSWORD>(.*)/i) {
			$oldpassword = $1;
			last;
		}
	}
	if ((($oldpassword) && ($newpassword eq $oldpassword)) || ($newpassword eq crypt($admin_password,"aa"))) {
		$PassCheck = 1;
	}
	if ($oldpassword && !($PassCheck)) {
		$oldpassword = "";
		@message = ();
		$ProfileCheck = $Cookies{'name'};
		$ProfileCheck =~ s/[^\w\.\-\']/\+/g;
		$ProfileCheck =~ tr/A-Z/a-z/;
		if (-e "$UserProfileDir/$ProfileCheck.txt") {
			open (FILE,"$UserProfileDir/$ProfileCheck.txt");
			@message = <FILE>;
			close (FILE);
			foreach $line (@message) {
				if ($line =~ /^PASSWORD>(.*)/i) {
					$oldpassword = $1;
					last;
				}
			}
		}
		if ((($oldpassword) && ($newpassword eq $oldpassword)) || ($newpassword eq crypt($admin_password,"aa"))) {
			$PassCheck = 1;
		}
	}
	unless ($PassCheck == 1) {
		unless (-e "$dir/password.txt") {
			&Error("9600","9601");
		}
		open (PASSWORD, "$dir/password.txt");
		$password = <PASSWORD>;
		close (PASSWORD);
		chop ($password) if ($password =~ /\n$/);
		unless ($newpassword eq $password) {
			&Error("9600","9601");
		}
	}
	unlink "$dir/$subdir/$message";
	delete ($MessageList{$message});
	if ($DisplayViews) {
		&LockOpen (COUNTLOCK,"$dir/countlock.txt");
		unless ($NoCountLock) {
			&CountDBMWrite;
		}
		if ($CountList{$message}) { delete ($CountList{$message}); }
	}
	open (SEARCH,"$dir/searchterms.idx");
	&LockOpen (NEWSEARCH,"$dir/newsearchterms.idx");
	while (<SEARCH>) {
		if (/^(\d+) /) {
			$message = $1;
			$subdir = "bbs".int($message/1000);
			if (-e "$dir/$subdir/$message") {
				print NEWSEARCH "$_";
			}
		}
	}
	close (SEARCH);
	&LockOpen (SEARCH,"$dir/searchterms.idx");
	rename ("$dir/newsearchterms.idx","$dir/searchterms.idx");
	&LockClose (NEWSEARCH,"$dir/newsearchterms.idx");
	&LockClose (SEARCH,"$dir/searchterms.idx");
	&Header($text{'0212'},$MessageHeaderFile,"refresh");
	&Header2("refresh");
	print "<P ALIGN=CENTER><BIG><BIG><STRONG>$text{'0212'}</STRONG></BIG></BIG>\n";
	print "<P ALIGN=CENTER>$text{'0200'}\n";
	&Footer($MessageFooterFile,"return","refresh");
}

sub Subscribe {
	&Header($text{'4000'},$MessageHeaderFile);
	&Header2;
	print "<P ALIGN=CENTER><BIG><BIG><STRONG>";
	print "$text{'4000'}</STRONG></BIG></BIG>\n";
	print "<P>$text{'4001'} ";
	if ($email_list == 1) { print "$text{'4002'} "; }
	else { print "$text{'4003'} "; }
	print "$text{'4004'}\n";
	print "<FORM METHOD=POST ACTION=\"$DestinationURL$BBSquery";
	print "addresslist\"$BBStarget>\n";
	print "<P><div align=\"center\">$text{'4005'}: ";
	print "<INPUT TYPE=TEXT NAME=\"email\" SIZE=30";
	if ($Cookies{'email'}) {
		print " VALUE=\"$Cookies{'email'}\"";
	}
	print "> <INPUT TYPE=SUBMIT VALUE=\"$text{'4008'}\">\n";
	print "<BR><INPUT TYPE=RADIO NAME=\"action\" ";
	print "VALUE=\"add\" CHECKED> $text{'4006'} ";
	print "<INPUT TYPE=RADIO NAME=\"action\" ";
	print "VALUE=\"delete\"> $text{'4007'}";
	print "</div></FORM>\n";
	&Footer($MessageFooterFile,"credits");
}

sub SetCookieData {
	%Cookie_Encode_Chars = (
	  '\%','%25','\+','%2B','\;','%3B','\,','%2C',
	  '\=','%3D','\&','%26','\:\:','%3A%3A','\s','+'
	  );
	%Cookie_Decode_Chars = (
	  '\+',' ','\%3A\%3A','::','\%26','&','\%3D','=',
	  '\%2C',',','\%3B',';','\%2B','+','\%25','%'
	  );
	&GetCookie($boardname);
	unless ($FORM{'ListType'}) {
		$FORM{'ListType'} = $Cookies{'listtype'};
	}
	unless ($FORM{'ListTime'}) {
		$FORM{'ListTime'} = $Cookies{'listtime'};
	}
	unless ($FORM{'password'}) {
		$FORM{'password'} = $Cookies{'password'};
	}
	if (!$email) { $email = $Cookies{'email'}; }
}

sub Search {
	&Header("$boardname - $text{'6000'}",$MessageHeaderFile);
	&Header2;
	print "<P ALIGN=CENTER><BIG><BIG><STRONG>$text{'6001'}</STRONG></BIG></BIG>\n";
	print "<P>$text{'6002'}\n";
	print "<FORM METHOD=POST ACTION=\"$DestinationURL$BBSquery";
	print "index\"$BBStargetidx>\n";
	print "<div align=\"center\">";
	if ($FORM{'ListTime'} =~ /(\d+) ([\w\(\)]+)/) {
		$FORM{'ListTimeA'} = $1;
		$FORM{'ListTimeB'} = $2;
	}
	else {
		$FORM{'ListTimeA'} = 2;
		$FORM{'ListTimeB'} = "$text{'0062'}";
	}
	print "<P><EM>$text{'6003'}:</EM>";
	unless ($ArchiveOnly) {
		print "<BR><INPUT TYPE=RADIO NAME=ListSize VALUE=Recent";
		print " CHECKED> $text{'6004'} ";
		print "<INPUT TYPE=TEXT NAME=\"ListTimeA\" SIZE=2 ";
		print "VALUE=$FORM{'ListTimeA'}> ";
		print "<SELECT NAME=\"ListTimeB\"><OPTION";
		if ($FORM{'ListTimeB'} eq "$text{'0060'}") {
			print " SELECTED";
		}
		print ">$text{'0060'}<OPTION";
		if ($FORM{'ListTimeB'} eq "$text{'0061'}") {
			print " SELECTED";
		}
		print ">$text{'0061'}<OPTION";
		if ($FORM{'ListTimeB'} eq "$text{'0062'}") {
			print " SELECTED";
		}
		print ">$text{'0062'}<OPTION";
		if ($FORM{'ListTimeB'} eq "$text{'0063'}") {
			print " SELECTED";
		}
		print ">$text{'0063'}</SELECT>\n";
		print "<BR><INPUT TYPE=RADIO NAME=ListSize VALUE=Range>";
	}
	else {
		print "<BR><INPUT TYPE=HIDDEN NAME=ListSize VALUE=Range>";
	}
	print " $text{'6005'} ";
	($mday,$mon,$year) =
	  (localtime(int($MessageList{$sortedmessages[0]})+($HourOffset*3600)))[3,4,5];
	print "<INPUT TYPE=TEXT NAME=\"StartDateA\" SIZE=2 VALUE=$mday> ";
	print "<SELECT NAME=\"StartDateB\">";
	foreach $key (0..11) {
		print "<OPTION VALUE=\"$key\"";
		if ($key == $mon) { print " SELECTED"; }
		print ">$months[$key]";
	}
	print "</SELECT> ";
	print "<INPUT TYPE=TEXT NAME=\"StartDateC\" SIZE=4 VALUE=",$year+1900,">";
	print " $text{'6006'} ";
	($mday,$mon,$year) =
	  (localtime(int($MessageList{$sortedmessages[@sortedmessages-1]})+($HourOffset*3600)))[3,4,5];
	print "<INPUT TYPE=TEXT NAME=\"EndDateA\" SIZE=2 VALUE=$mday> ";
	print "<SELECT NAME=\"EndDateB\">";
	foreach $key (0..11) {
		print "<OPTION VALUE=\"$key\"";
		if ($key == $mon) { print " SELECTED"; }
		print ">$months[$key]";
	}
	print "</SELECT> ";
	print "<INPUT TYPE=TEXT NAME=\"EndDateC\" SIZE=4 VALUE=",$year+1900,">\n";
	print "<P><SMALL>$text{'6007'}: ";
	($mday,$mon,$year) =
	  (localtime(int($MessageList{$sortedmessages[0]})+($HourOffset*3600)))[3,4,5];
	print "$mday $months[$mon] ",$year+1900;
	print "<BR>$text{'6008'}: ";
	($mday,$mon,$year) =
	  (localtime(int($MessageList{$sortedmessages[@sortedmessages-1]})+($HourOffset*3600)))[3,4,5];
	print "$mday $months[$mon] ",$year+1900;
	print "\n</SMALL>\n";
	print "<P><EM>$text{'6009'}:</EM>",
	  "<BR><INPUT TYPE=RADIO NAME=\"KeySearch\" ",
	  "VALUE=\"All\"> $text{'6010'}\n",
	  "<BR><INPUT TYPE=RADIO NAME=\"KeySearch\" ",
	  "VALUE=\"Yes\" CHECKED> $text{'6011'} <SELECT ",
	  "NAME=\"Boolean\"><OPTION SELECTED>$text{'0051'}",
	  "<OPTION>$text{'0050'}</SELECT> $text{'6012'}:",
	  "<BR><INPUT TYPE=TEXT NAME=\"Keywords\" ",
	  "SIZE=50>\n",
	  "<BR><INPUT TYPE=RADIO NAME=\"KeySearch\" ",
	  "VALUE=\"Author\"> $text{'6013'}: <INPUT TYPE=TEXT ",
	  "NAME=\"Author\" SIZE=25>\n";
	if ($AdminRun) {
		print "<BR><INPUT TYPE=RADIO NAME=\"KeySearch\" ",
		  "VALUE=\"Domain\"> $text{'6013'} $text{'6015'}: <INPUT TYPE=TEXT ",
		  "NAME=\"Domain\" SIZE=10>\n";
	}
	print "<P><INPUT TYPE=SUBMIT VALUE=\"$text{'6014'}\"></div></FORM>\n";
	&Footer($MessageFooterFile,"credits");
}

sub Reconfigure {
	&Header("$boardname - $text{'6500'}",$MessageHeaderFile);
	&Header2;
	print "<P ALIGN=CENTER><BIG><BIG><STRONG>$text{'6501'}</STRONG></BIG></BIG>\n";
	print "<P>$text{'6502'} ";
	if ($UseCookies) { print "$text{'6503'}\n"; }
	else { print "$text{'6504'}\n"; }
	print "<FORM METHOD=POST ACTION=\"$DestinationURL$BBSquery";
	print "index\"$BBStargetidx>\n";
	print "<INPUT TYPE=HIDDEN NAME=\"KeySearch\" ";
	print "VALUE=\"No\">\n";
	print "<div align=\"center\">";
	unless ($ArchiveOnly) {
		if ($FORM{'ListTime'} =~ /(\d+) ([\w\(\)]+)/) {
			$FORM{'ListTimeA'} = $1;
			$FORM{'ListTimeB'} = $2;
		}
		else {
			$FORM{'ListTimeA'} = 2;
			$FORM{'ListTimeB'} = "$text{'0062'}";
		}
		if ($UseCookies) {
			print "<P><EM>$text{'6505'}:</EM>";
			print "<BR><INPUT TYPE=RADIO NAME=ListSize VALUE=Recent";
			unless ($FORM{'ListTime'} eq "New Only") {
				print " CHECKED";
			}
			print "> $text{'6506'} ";
		}
		else {
			print "<P>$text{'6507'} ";
		}
		print "<INPUT TYPE=TEXT NAME=\"ListTimeA\" SIZE=2 ";
		print "VALUE=$FORM{'ListTimeA'}> ";
		print "<SELECT NAME=\"ListTimeB\"><OPTION";
		if ($FORM{'ListTimeB'} eq "$text{'0060'}") {
			print " SELECTED";
		}
		print ">$text{'0060'}<OPTION";
		if ($FORM{'ListTimeB'} eq "$text{'0061'}") {
			print " SELECTED";
		}
		print ">$text{'0061'}<OPTION";
		if ($FORM{'ListTimeB'} eq "$text{'0062'}") {
			print " SELECTED";
		}
		print ">$text{'0062'}<OPTION";
		if ($FORM{'ListTimeB'} eq "$text{'0063'}") {
			print " SELECTED";
		}
		print ">$text{'0063'}</SELECT>\n";
		if ($UseCookies) {
			print "<BR><INPUT TYPE=RADIO NAME=ListSize VALUE=New";
			if ($FORM{'ListTime'} eq "New Only") {
				print " CHECKED";
			}
			print "> $text{'6508'}\n";
		}
	}
	unless (!($AdminRun) && ($ENV{'HTTP_USER_AGENT'} =~ /Lynx/i)) {
		print "<P>$text{'6509'}: <SELECT NAME=\"ListType\"><OPTION";
		print " VALUE=\"Chronologically\"";
		if ($FORM{'ListType'} eq "Chronologically") {
			print " SELECTED";
		}
		print ">$text{'0601'}<OPTION VALUE=\"Chronologically, Reversed\"";
		if ($FORM{'ListType'} eq "Chronologically, Reversed") {
			print " SELECTED";
		}
		print ">$text{'0602'}<OPTION VALUE=\"Alphabetically\"";
		if ($FORM{'ListType'} eq "Alphabetically") {
			print " SELECTED";
		}
		print ">$text{'0603'}<OPTION VALUE=\"Alphabetically, Reversed\"";
		if ($FORM{'ListType'} eq "Alphabetically, Reversed") {
			print " SELECTED";
		}
		print ">$text{'0604'}<OPTION VALUE=\"By Threads\"";
		if ($FORM{'ListType'} eq "By Threads") {
			print " SELECTED";
		}
		print ">$text{'0613'}<OPTION VALUE=\"By Threads, Reversed\"";
		if ($FORM{'ListType'} eq "By Threads, Reversed") {
			print " SELECTED";
		}
		print ">$text{'0611'}<OPTION VALUE=\"By Threads, Mixed\"";
		if ($FORM{'ListType'} eq "By Threads, Mixed") {
			print " SELECTED";
		}
		print ">$text{'0612'}";
		unless ($AdminRun) {
			print "<OPTION VALUE=\"Compressed\"";
			if ($FORM{'ListType'} eq "Compressed") {
				print " SELECTED";
			}
			print ">$text{'0605'}<OPTION VALUE=\"Compressed, Reversed\"";
			if ($FORM{'ListType'} eq "Compressed, Reversed") {
				print " SELECTED";
			}
			print ">$text{'0606'}<OPTION VALUE=\"Guestbook-Style\"";
			if ($FORM{'ListType'} eq "Guestbook-Style") {
				print " SELECTED";
			}
			print ">$text{'0607'}<OPTION VALUE=\"Guestbook-Style, Reversed\"";
			if ($FORM{'ListType'} eq "Guestbook-Style, Reversed") {
				print " SELECTED";
			}
			print ">$text{'0608'}<OPTION VALUE=\"Guestbook-Style, Threaded\"";
			if ($FORM{'ListType'} eq "Guestbook-Style, Threaded") {
				print " SELECTED";
			}
			print ">$text{'0609'}<OPTION VALUE=\"Guestbook-Style, Threaded, Reversed\"";
			if ($FORM{'ListType'} eq "Guestbook-Style, Threaded, Reversed") {
				print " SELECTED";
			}
			print ">$text{'0610'}<OPTION VALUE=\"Guestbook-Style, Threaded, Mixed\"";
			if ($FORM{'ListType'} eq "Guestbook-Style, Threaded, Mixed") {
				print " SELECTED";
			}
			print ">$text{'0615'}";
		}
		print "</SELECT></div>\n",
		  "<P><EM>$text{'5000'}</EM>\n";
	}
	print "<P><div align=\"center\"><INPUT TYPE=SUBMIT VALUE=\"$text{'5001'}\"></div></FORM>\n";
	&Footer($MessageFooterFile,"credits");
}

sub UpdateAddressList {
	unless ($email) {
		&Error("9300","9301");
	}
	unless (-w "$dir") { &Error("9410","9411"); }
	&LockOpen (LIST,"$dir/addresses.txt");
	@list = <LIST>;
	$listcheck = 0;
	seek (LIST, 0, 0);
	foreach $address (@list) {
		if ($address =~ /$email/i) {
			if ($FORM{'action'} eq "delete") {
				&Error("9850","9851");
				$listcheck = 1;
			}
			else {
				&Error("9700","9701");
				print LIST "$address";
				$listcheck = 1;
			}
		}
		else {
			print LIST "$address";
		}
	}
	if ($listcheck < 1) {
		if ($FORM{'action'} eq "delete") {
			&Error("9750","9751");
		}
		else {
			&Error("9800","9801");
			print LIST "$email\n";
		}
	}
	truncate (LIST, tell(LIST));
	&LockClose (LIST,"$dir/addresses.txt");
	&Footer($MessageFooterFile,"return");
}

1;

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

sub Startup {
	if ($BannedIPsFile && ($BanLevel == 2)) {
		if ($ResolveIPs) {
			if (($ENV{'REMOTE_ADDR'} =~ /\d+\.\d+\.\d+\.\d+/)
			  && (!($ENV{'REMOTE_HOST'})
			  || ($ENV{'REMOTE_HOST'} =~ /\d+\.\d+\.\d+\.\d+/))) {
				@domainbytes = split(/\./,$ENV{'REMOTE_ADDR'});
				$packaddr = pack("C4",@domainbytes);
				$resolvedip = (gethostbyaddr($packaddr, 2))[0];
				unless ($resolvedip =~
				  /^[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,3}|[0-9]{1,3})$/) {
					$resolvedip = "";
				}
				if ($resolvedip) {
					$ENV{'REMOTE_HOST'} = $resolvedip;
				}
			}
		}
		else {
			$ENV{'REMOTE_HOST'} = "";
		}
		unless ($ENV{'REMOTE_HOST'}) { $ENV{'REMOTE_HOST'} = $ENV{'REMOTE_ADDR'}; }
		open (BANNED,"$BannedIPsFile");
		@bannedips = <BANNED>;
		close (BANNED);
		foreach $bannedip (@bannedips) {
			chomp ($bannedip);
			next if (length($bannedip) < 2);
			if (($ENV{'REMOTE_HOST'} =~ /$bannedip/i)
			  || ($ENV{'REMOTE_ADDR'} =~ /$bannedip/i)) {
				require $webbbs_read;
				&Initialize_Data;
				&Error("9520","9521");
			}
		}
	}
	if ($ENV{'QUERY_STRING'} =~ /noframes/i) { $UseFrames = ""; }
	if ((!($UseFrames) && ($ENV{'QUERY_STRING'} =~ /review=(\d+)/i)) 
	  || (!($UseFrames) && ($ENV{'QUERY_STRING'} =~ /rev=(\d+)/i)) 
	  || ($ENV{'QUERY_STRING'} =~ /read=(\d+)/i)
	  || ($ENV{'QUERY_STRING'} =~ /form=(\d+)/i)) {
		require $webbbs_read;
	}
	elsif ($ENV{'QUERY_STRING'} =~ /post/i) {
		require $webbbs_post;
	}
	elsif (($ENV{'QUERY_STRING'} =~ /addresslist/i)
	  || ($ENV{'QUERY_STRING'} =~ /delete/i)
	  || ($ENV{'QUERY_STRING'} =~ /reconfigure/i)
	  || ($ENV{'QUERY_STRING'} =~ /search/i)
	  || ($ENV{'QUERY_STRING'} =~ /subscribe/i)
	  || ($ENV{'QUERY_STRING'} =~ /topstats/i)) {
		require $webbbs_misc;
	}
	elsif ($ENV{'QUERY_STRING'} =~ /profile/i) {
	  	require $webbbs_profile;
	}
	else { require $webbbs_index; }
}

sub Parse_Form {
	read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
	@pairs = split(/&/, $buffer);
	foreach $pair (@pairs){
		($val1, $val2) = split(/=/, $pair);
		$val1 =~ tr/+/ /;
		$val1 =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$val2 =~ tr/+/ /;
		$val2 =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$val2 =~ s/\cM\n*/\n/g;
		$val2 =~ s/<!--([^>]|\n)*-->/ /g;
		$val2 =~ s/<([^>]|\n)*>/ /g;
		$val2 =~ s/\&/\&amp\;/g;
		$val2 =~ s/"/\&quot\;/g;
		$val2 =~ s/</\&lt\;/g;
		$val2 =~ s/>/\&gt\;/g;
		if (($val1 eq "listitems")) {
			@listitems = split(/\n/,$val2);
		}
		$val2 =~ s/\n/ /g;
		$val2 =~ s/\s+/ /g;
		$val2 =~ s/^\s+//g;
		$val2 =~ s/\s+$//g;
		if ($FORM{$val1}) {
			$FORM{$val1} = "$FORM{$val1} $val2";
		}
		else {
			$FORM{$val1} = $val2;
		}
	}
}

sub Initialize_Data {
	umask (0111);
	if ($AdminRun) { $version = "Admin 4.32"; }
	else { $version = "4.33"; }
	$time = time;
	$todaydate = $time;
	$rebuildflag = 0;
	unless ($InputColumns) { $InputColumns = 80; }
	if ($InputColumns < 25) { $InputColumns = 25; }
	unless ($InputRows) { $InputRows = 15; }
	if ($InputRows < 5) { $InputRows = 5; }
	$InputLength = int($InputColumns/2);
	$TotalMessages = 0;
	$DisplayedMessages = 0;
	@messages = ();
	@sortedmessages = ();
	@keywordmatches = ();
	if (($ENV{'QUERY_STRING'} =~ /noframes/i)
	  || ($ENV{'DOCUMENT_URI'} && ($cgiurl !~ /$ENV{'DOCUMENT_URI'}/))
	  || ($ENV{'QUERY_STRING'} =~ /quickinfo/i)) {
		$UseFrames = "";
		$BBSquery = "?noframes;";
	}
	else { $BBSquery = "?"; }
	if ($UseFrames) {
		$BBStarget = " TARGET=\"msgtxt\"";
		$BBStargetidx = " TARGET=\"msgidx\"";
		$BBStargettop = " TARGET=\"$BBSFrame\"";
		$SepPostFormIndex = 1;
		$SepPostFormRead = 1;
	}
	else {
		$BBStarget = "";
		$BBStargetidx = "";
		$BBStargettop = "";
	}
	$maillist_link = "<A HREF=\"mailto:$maillist_address\">";
	$maillist_link .= "$maillist_address<\/A>";
	if ($AdminRun) { $DestinationURL = $adminurl; }
	else { $DestinationURL = $cgiurl; }
	foreach $key (keys %text) {
		$text{$key} =~ s/<!--boardname-->/$boardname/g;
		$text{$key} =~ s/<!--boardurl-->/$cgiurl/g;
		$text{$key} =~ s/<!--email-->/$maillist_address/g;
		$text{$key} =~ s/<!--emaillink-->/$maillist_link/g;
		$text{$key} =~ s/<!--NoFramesURL-->/<A HREF="$DestinationURL?noframes">/g;
	}
	if (($ENV{'QUERY_STRING'} =~ /blank/i)
	  || ($UseFrames && !($ENV{'QUERY_STRING'}))
	  || ($UseFrames && ($ENV{'QUERY_STRING'} =~ /moderate=0/i))
	  || ($UseFrames && ($ENV{'QUERY_STRING'} =~ /review=/i))
	  || ($UseFrames && ($ENV{'QUERY_STRING'} =~ /rev=/i))
	  || ($UseFrames && ($ENV{'QUERY_STRING'} =~ /rebuild/i))) {
		print "Content-type: text/html\n\n";
		return;
	}
	if ($ArchiveOnly) {
		$AllowUserPrefs = 0;
		$UseCookies = 0;
	}
	if ($ListBullets) { $ul_dl = "UL"; $li_dd = "LI"; }
	else { $ul_dl = "DL"; $li_dd = "DD"; }
	$TableCellStart = "";
	$TableInputCellStart = "";
	$NavBarStart = "<div align=\"center\"><P><TABLE $navbarspec><TR><TD ALIGN=CENTER>";
	$NavBarStart .= "<SMALL>";
	$NavBarEnd = " </SMALL></TD></TR></TABLE></div>\n";
	$navbar = "";
	$printbar = 0;
	$CreditLink = "<P ALIGN=CENTER><SMALL><EM>$boardname $text{'9000'} ";
	unless ($admin_name) { $admin_name = $maillist_address; }
	if ($admin_name) {
		$CreditLink .= "$text{'9001'} ";
		if ($maillist_address) {
			$CreditLink .= "<A HREF=\"mailto:$maillist_address\">";
		}
		$CreditLink .= "$admin_name";
		if ($maillist_address) { $CreditLink .= "</A>"; }
		$CreditLink .= " ";
	}
	$CreditLink .= "$text{'9002'} <STRONG>";
	$CreditLink .= "<A HREF=\"http://awsd.com/scripts/webbbs/\" TARGET=\"_blank\">";
	$CreditLink .= "WebBBS $version</A></STRONG>.</EM></SMALL>\n";
	print "Content-type: text/html\n";
	use Fcntl;
	use AnyDBM_File;
	if ($AdminRun) {
		unless ($UseLocking) { &MasterLockOpen; }
		&LockOpen (DBLOCK,"$dir/dblock.txt");
		&MessageDBMWrite;
		if ($DisplayViews) {
			&LockOpen (COUNTLOCK,"$dir/countlock.txt");
			unless ($NoCountLock) {
				&CountDBMWrite;
			}
		}
	}
	else {
		&MessageDBMRead;
	}
	@messages = (keys %MessageList);
	$TotalMessages = @messages;
	@sortedmessages = (sort {$a<=>$b} @messages);
	@messages = ();
	$lastmessage = $sortedmessages[@sortedmessages-1];
	if ($FORM{'ListTimeB'} && $FORM{'ListType'} && !($AllowUserPrefs)) {
		$FORM{'ListTimeA'}=$FORM{'ListTimeB'}="";
		$FORM{'ListType'}=$FORM{'ListSize'}="";
	}
	if ($FORM{'ListTimeB'}) {
		$FORM{'ListTimeA'} = int($FORM{'ListTimeA'});
		if ($FORM{'ListTimeA'} < 1) { $FORM{'ListTimeA'} = 1; }
		$FORM{'ListTime'} = "$FORM{'ListTimeA'} $FORM{'ListTimeB'}";
	}
	if ($FORM{'ListSize'} eq "New") {
		$FORM{'ListTime'} = "New Only";
	}
	$email = "";
	$FORM{'email'} =~ s/\s//g;
	unless ($FORM{'email'} =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)|,|;/
	  || $FORM{'email'} !~
	  /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,3}|[0-9]{1,3})(\]?)$/)
	  {
		$email = "$FORM{'email'}";
	}
	if (length($email) > 100) { $email = ""; }
	$name = "";
	if ($LockRemoteUser && $ENV{'REMOTE_USER'}) {
		$name = $ENV{'REMOTE_USER'};
	}
	else {
		if ($FORM{'name'}) { $name = "$FORM{'name'}"; }
		$name = substr($name,0,$MaxInputLength);
	}
	$FORM{'url'} =~ s/\&amp\;/\&/g;
	$FORM{'url'} =~ s/\s//g;
	$FORM{'imageurl'} =~ s/\&amp\;/\&/g;
	$FORM{'imageurl'} =~ s/\s//g;
	unless ($FORM{'url'} =~ /\*|(\.\.)|(^\.)|(\/\/\.)/
	  || $FORM{'url'} !~ /.*\:\/\/.*\..*/) {
		$message_url = "$FORM{'url'}";
		if ($FORM{'url_title'}) {
			$message_url_title = "$FORM{'url_title'}";
		}
		else {
			$message_url_title = "$FORM{'url'}";
		}
	}
	unless ($FORM{'imageurl'} =~ /\*|(\.\.)|(^\.)|(\/\/\.)/
	  || $FORM{'imageurl'} !~ /.*\:\/\/.*\..*/
	  || $FORM{'imageurl'} =~ /script:/) {
		$image_url = "$FORM{'imageurl'}";
	}
	if (length($message_url) > 250) { $message_url = ""; }
	if (length($image_url) > 250) { $image_url = ""; }
	if ($UseCookies) {
		if ($AdminRun) { &SetAdminCookieData; }
		else { &SetCookieData; }
	}
	unless ($FORM{'ListTime'}) { $FORM{'ListTime'} = $DefaultTime; }
	unless ($FORM{'ListTime'}) { $FORM{'ListTime'} = "2 $text{'0062'}"; }
	unless ($FORM{'ListType'}) {
		if (!($AdminRun) && ($ENV{'HTTP_USER_AGENT'} =~ /Lynx/i )) {
			$FORM{'ListType'} = "Compressed";
		}
		else {
			$FORM{'ListType'} = $DefaultType;
		}
	}
	unless ($FORM{'ListType'}) { $FORM{'ListType'} = "Chronologically"; }
	if ((($FORM{'ListType'} =~ /Guestbook/)
	  || ($FORM{'ListType'} =~ /Compress/))
	  && ($IndexEntryLines eq "news")) {
		$IndexEntryLines = 2;
	}
	unless ($DateConfig) {
		$DateConfig = "%DY%, %dy% %MO% %YR%, at %hr%:%mn% %am%";
	}
	unless ($NewOpenCode || $NewCloseCode) {
		$NewOpenCode = "<EM>NEW:</EM>";
	}
	unless ($AdminOpenCode || $AdminCloseCode) {
		$AdminOpenCode = "<EM>ADMIN!</EM>";
	}
	unless ($AutoQuoteChar) { $AutoQuoteChar = ":"; }
	$FormCount = 0;
}

sub PrintDate {
	unless ($_[0] =~ /^\d+$/) {
		return $_[0];
	}
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
	  localtime($_[0]+($HourOffset*3600));
	if ($sec < 10) { $sec = "0$sec"; }
	if ($min < 10) { $min = "0$min"; }
	$hour24 = $hour;
	if ($hour24 < 10) { $hour24 = "0$hour24"; }
	$ampm = "a.m.";
	if ($hour eq 12) { $ampm = "p.m."; }
	if ($hour eq 0) { $hour = "12"; }
	if ($hour > 12) { $hour = ($hour - 12); $ampm = "p.m."; }
	$month = $months[$mon];
	$mon ++;
	$yearlong = $year+1900;
	if ($year > 99) { $year = $year-100; }
	if ($year < 10) { $year = "0$year"; }
	$wday = $days[$wday];
	$datestring = $DateConfig;
	$datestring =~ s/%mo%/$mon/g;
	$datestring =~ s/%MO%/$month/g;
	$datestring =~ s/%dy%/$mday/g;
	$datestring =~ s/%DY%/$wday/g;
	$datestring =~ s/%yr%/$year/g;
	$datestring =~ s/%YR%/$yearlong/g;
	$datestring =~ s/%am%/$ampm/g;
	$datestring =~ s/%sc%/$sec/g;
	$datestring =~ s/%mn%/$min/g;
	$datestring =~ s/%hr%/$hour/g;
	$datestring =~ s/%HR%/$hour24/g;
	return $datestring;
}

sub ThreadList {
	local (@threadresponses);
	local (@reversethread);
	local ($date,$sub,$poster,$prev,$next,$count,$admin,$ip) = "";
	($date,$sub,$poster,$prev,$next,$count,$admin,$ip) =
	  split(/\|/,$MessageList{$_[0]});
	&PrintMessageDesc($_[0]);
	if ($IndexEntryLines eq "news") {
		$indexspacer .= " &nbsp; &nbsp; &nbsp;";
	}
	else {
		print "<$ul_dl>\n";
	}
	@threadresponses = split(/ /,$next);
	if ($FORM{'ListType'} eq "By Threads, Reversed") {
		@reversethread = reverse(@threadresponses);
		@threadresponses = @reversethread;
	}
	$lastresponse = "";
	foreach $threadresponse (@threadresponses) {
		next unless ($threadresponse > $_[0]);
		next if ($threadresponse eq $lastresponse);
		if (($MessageList{$threadresponse}>0)
		  && !($DontUse{$threadresponse})) {
			&ThreadList($threadresponse);
			$lastresponse = $threadresponse;
		}
	}
	if ($IndexEntryLines eq "news") {
		$indexspacer =~ s/ &nbsp; &nbsp; &nbsp;$//;
	}
	else {
		print "</$ul_dl>\n";
	}
	$already{$_[0]} = 1;
}

sub PrintMessageDesc {
	local ($date,$sub,$poster,$prev,$next,$count,$admin,$ip) = "";
	($date,$sub,$poster,$prev,$next,$count,$admin,$ip) =
	  split(/\|/,$MessageList{$_[0]});
	$sub =~ s/&pipe;/\|/g;
	$poster =~ s/&pipe;/\|/g;
	if ($IndexEntryLines eq "news") {
		print "<TR><TD>$TableCellStart";
		print "$indexspacer";
		if ($AdminRun) {
			if ($DeleteSelect) {
				print "<INPUT TYPE=CHECKBOX ";
				print "NAME=\"delete\" VALUE=\"$_[0]\"> ";
			}
			$ToBeDeleted .= " $_[0]";
		}
		if ($admin eq "AdminPost") { print "$AdminOpenCode "; }
		if (($Cookies{'lastmessage'}
		  && ($Cookies{'lastmessage'} < $_[0]))
		  || ($newcount{$_[0]} > 0)) {
			print "$NewOpenCode ";
		}
		unless ($messagenumber == $_[0]) {
			print "<A NAME=$_[0] HREF=\"$DestinationURL$BBSquery";
			print "read=$_[0]\"$BBStarget>";
		}
		print "$sub";
		unless ($messagenumber == $_[0]) {
			print "</A>";
		}
		if (($CountList{$_[0]} > 0) && ($DisplayViews == 1)) {
			unless (($FORM{'ListType'} =~ /Compress/)
			  || ($FORM{'ListType'} =~ /Guestbook-Style, Thread/)) {
				print " <SMALL>($text{'1010'}: $CountList{$_[0]})</SMALL>";
			}
		}
		if (($Cookies{'lastmessage'}
		  && ($Cookies{'lastmessage'} < $_[0]))
		  || ($newcount{$_[0]} > 0)) {
			print " $NewCloseCode";
		}
		if ($admin eq "AdminPost") { print " $AdminCloseCode"; }
		print "</TD><TD>$TableCellStart";
		print "$poster ";
		if ($DisplayIPs && $ip) {
			print " <SMALL><EM>($ip)</EM></SMALL> ";
		}
		print "</TD><TD>$TableCellStart",&PrintDate($date);
		print "</TD></TR>\n";
	}
	else {
		print "<$li_dd>";
		if ($AdminRun) {
			if ($DeleteSelect) {
				print "<INPUT TYPE=CHECKBOX ";
				print "NAME=\"delete\" VALUE=\"$_[0]\"> ";
			}
			$ToBeDeleted .= " $_[0]";
		}
		print "<STRONG>";
		if ($admin eq "AdminPost") { print "$AdminOpenCode "; }
		if (($Cookies{'lastmessage'}
		  && ($Cookies{'lastmessage'} < $_[0]))
		  || ($newcount{$_[0]} > 0)) {
			print "$NewOpenCode ";
		}
		unless ($messagenumber == $_[0]) {
			print "<A NAME=$_[0] HREF=\"$DestinationURL$BBSquery";
			print "read=$_[0]\"$BBStarget>";
		}
		print "$sub";
		unless ($messagenumber == $_[0]) {
			print "</A>";
		}
		print "</STRONG>";
		if (($CountList{$_[0]} > 0) && ($DisplayViews == 1)) {
			unless (($FORM{'ListType'} =~ /Compress/)
			  || ($FORM{'ListType'} =~ /Guestbook-Style, Thread/)) {
				print " <SMALL>($text{'1010'}: $CountList{$_[0]})</SMALL>";
			}
		}
		if ($IndexEntryLines == 1) {
			print " -- ";
		}
		else {
			print "<BR>";
		}
		print "$poster ";
		if ($DisplayIPs && $ip) {
			print " <SMALL><EM>($ip)</EM></SMALL> ";
		}
		print "-- ",&PrintDate($date);
		if (($Cookies{'lastmessage'}
		  && ($Cookies{'lastmessage'} < $_[0]))
		  || ($newcount{$_[0]} > 0)) {
			print " $NewCloseCode";
		}
		if ($admin eq "AdminPost") { print " $AdminCloseCode"; }
		print "\n";
	}
}

sub PrintGuestbookDesc {
	unless ($NotFirstEntry) {
		print "$GuestbookSpacer";
		$NotFirstEntry = 1;
	}
	$messagenumber = $_[0];
	local($date,$sub,$poster,$prev,$next,$count,$admin,$ip) = "";
	($date,$sub,$poster,$prev,$next,$count,$admin,$ip) =
	  split(/\|/,$MessageList{$messagenumber});
	if ($DisplayViews) {
		unless ($CountList{$messagenumber}) { $CountList{$messagenumber} = 0; }
		$CountList{$messagenumber}++;
	}
	$subdir = "bbs".int($messagenumber/1000);
	open (FILE,"$dir/$subdir/$messagenumber") || return;
	@message = <FILE>;
	close (FILE);
	$startup = 0;
	$admin=$subject=$poster=$email=$date=$image_url=$linkname=$linkurl="";
	foreach $line (@message) {
		if ($line =~ /^SUBJECT>(.*)/i) { $subject = $1; }
		elsif ($line =~ /^ADMIN>AdminPost/i) { $admin = "AdminPost"; }
		elsif ($line =~ /^ADMIN>/i) { next; }
		elsif ($line =~ /^POSTER>(.*)/i) { $poster = $1; }
		elsif ($line =~ /^EMAIL>(.*)/i) { $email = $1; }
		elsif ($line =~ /^DATE>(.*)/i) { $date = $1; }
		elsif ($line =~ /^EMAILNOTICES>/i) { next; }
		elsif ($line =~ /^IP_ADDRESS>(.*)/i) { $ipaddress = $1; }
		elsif ($line =~ /^<!--/i) { next; }
		elsif ($line =~ /^PASSWORD>(.*)/i) { $oldpassword = $1; }
		elsif ($line =~ /^PREVIOUS>(.*)/i) { $previous = $1; }
		elsif ($line =~ /^NEXT>(.*)/i) { $next = $1; }
		elsif ($line =~ /^IMAGE>(.*)/i) { $image_url = $1; }
		elsif ($line =~ /^LINKNAME>(.*)/i) { $linkname = $1; }
		elsif ($line =~ /^LINKURL>(.*)/i) { $linkurl = $1; }
		elsif (!$startup) {
			$startup = 1;
			print "<P ALIGN=CENTER>";
			print "<STRONG><BIG>";
			if ($admin eq "AdminPost") { print "$AdminOpenCode "; }
			if (($Cookies{'lastmessage'}
			  && ($Cookies{'lastmessage'} < $_[0]))
			  || ($newcount{$_[0]} > 0)) {
				print "$NewOpenCode ";
			}
			print "$subject";
			print "</BIG></STRONG>";
			print "<BR>";
			$ProfileCheck = $poster;
			$ProfileCheck =~ s/[^\w\.\-\']/\+/g;
			$ProfileCheck =~ tr/A-Z/a-z/;
			if (-e "$UserProfileDir/$ProfileCheck.txt") {
				print "<A HREF=\"$DestinationURL$BBSquery";
				print "profile=$ProfileCheck\" TARGET=\"_blank\">";
				print "$poster</A>";
			}
			else { print "$poster"; }
			if ($DisplayEmail && $email) {
				$mailsubject = $subject;
				if (%SmileyCode) {
					foreach $key (keys %SmileyCode) {
						$key2 = $SmileyCode{$key};
						$key2 =~ s/([\[\]\(\)\\\*\+\?\\\|])/\\$1/g;
						$mailsubject =~ s/$key2/$key/g;
					}
				}
				$mailsubject =~ s/"/'/g;
				print " &lt;<A HREF=\"mailto:$email?subject=$mailsubject\">";
				print "$email</A>&gt;";
			}
			if ($DisplayIPs && $ipaddress) {
				print " <SMALL><EM>($ipaddress)</EM></SMALL> ";
			}
			print " -- <EM>",&PrintDate($date),"</EM>";
			if (($Cookies{'lastmessage'}
			  && ($Cookies{'lastmessage'} < $_[0]))
			  || ($newcount{$_[0]} > 0)) {
				print " $NewCloseCode\n";
			}
			if ($admin eq "AdminPost") { print " $AdminCloseCode"; }
			print "$MessageOpenCode\n";
			print $line;
		}
		else { print $line; }
	}
	print "$MessageCloseCode\n";
	if ($image_url) {
		print "<P ALIGN=CENTER>";
		print "<IMG SRC=\"$image_url\">\n";
	}
	if ($linkurl) {
		print "<P ALIGN=CENTER>";
		print "<EM><A HREF=\"$linkurl\" ";
		print "TARGET=\"_blank\">";
		print "$linkname</A></EM>\n";
	}
	unless ($ArchiveOnly || (!($AllowResponses))) {
		print "$NavBarStart <A HREF=\"$cgiurl$BBSquery";
		print "form=$messagenumber\"";
		print "$BBStargettop>$text{'0003'}</A> $NavBarEnd";
	}
	print "$GuestbookSpacer";
}

sub GetCookie {
	local($cookie_name) = @_;
	local($cookie,$value);
	if ($ENV{'HTTP_COOKIE'}) {
		foreach (split(/; /,$ENV{'HTTP_COOKIE'})) {
			($cookie,$value) = split(/=/);
			foreach $char ('\+','\%3A\%3A','\%26','\%3D','\%2C','\%3B','\%2B','\%25') {
				$cookie =~ s/$char/$Cookie_Decode_Chars{$char}/g;
				$value =~ s/$char/$Cookie_Decode_Chars{$char}/g;
			}
			if ($cookie_name eq $cookie) {
				$Cookies{$cookie} = $value;
			}
		}
	}
	if ($Cookies{$cookie_name}) {
		foreach (split(/&/,$Cookies{$cookie_name})) {
			($cookie,$value) = split(/::/);
			foreach $char ('\+','\%3A\%3A','\%26','\%3D','\%2C','\%3B','\%2B','\%25') {
				$cookie =~ s/$char/$Cookie_Decode_Chars{$char}/g;
				$value =~ s/$char/$Cookie_Decode_Chars{$char}/g;
			}
			$Cookies{$cookie} = $value;
		}
	}
	delete ($Cookies{$cookie_name});
}

sub SendCookie {
	local($cookie_name,@cookies) = @_;
	local($cookie,$value,$cookie_value,$char);
	while (($cookie,$value) = @cookies) {
		foreach $char ('\%','\+','\;','\,','\=','\&','\:\:','\s') {
			$cookie =~ s/$char/$Cookie_Encode_Chars{$char}/g;
			$value =~ s/$char/$Cookie_Encode_Chars{$char}/g;
		}
		if ($cookie_value) {
			$cookie_value .= '&' . $cookie . '::' . $value;
		}
		else {
			$cookie_value = $cookie . '::' . $value;
		}
		shift(@cookies); shift(@cookies);
	}
	foreach $char ('\%','\+','\;','\,','\=','\&','\:\:','\s') {
		$cookie_name =~ s/$char/$Cookie_Encode_Chars{$char}/g;
		$cookie_value =~ s/$char/$Cookie_Encode_Chars{$char}/g;
	}
	print 'Set-Cookie: ' . $cookie_name . '=' . $cookie_value . "; expires=Fri, 31-Dec-2010 00:00:00 GMT; path=/;\n";
	
	my $tempname = $name;
	
	@cookies = split(/\; /, "$ENV{HTTP_COOKIE}");
	foreach $cookie(@cookies){
		($name, $value) = split(/\=/, $cookie);
		$chash{$name} = $value;
	}
	
	$name = $tempname;
	
	if ($chash{'VisitedMikeyComics'} ne "Yes"){
		print "Set-cookie: VisitedMikeyComics=Yes; expires=Fri, 31-Dec-2010 00:00:00 GMT; path=/;\n";
		$countit = 1;
	}
}

sub Error {
	local ($error_title, $error_text, $error_file) = @_;
	if (($error_title eq "9120")
	  || ($error_title eq "9200") || ($error_title eq "9250")
	  || ($error_title eq "9500") || ($error_title eq "9510")) {
		$SpellCheckerMeta = 1;
		$PreviewForm = 1;
		&Header($text{$error_title},$MessageHeaderFile);
		&Header2;
	}
	else {
		&Header($text{$error_title},$MessageHeaderFile,"refresh");
		&Header2("refresh");
	}
	if ($error_title eq "9150") {
		opendir (MESSAGES,$dir);
		@messagedir = readdir(MESSAGES);
		closedir (MESSAGES);
		foreach $message (@messagedir) {
			if ($message =~ /^messagelist/) {
				unlink "$dir/$message";
			}
		}
	}
	print "<P ALIGN=CENTER><BIG><BIG><STRONG>$text{$error_title}</STRONG></BIG></BIG>\n";
	if (length($error_file) > 2) {
		print "<P ALIGN=CENTER>$error_file\n";
	}
	print "<P>$text{$error_text} $text{'9999'}\n";
	return unless ($error_title < 9700);
	if ($PreviewForm) {
		$body = $BodyPreview;
		$body =~ s/\& /\&amp\; /g;
		$body =~ s/"/\&quot\;/g;
		$body =~ s/</\&lt\;/g;
		$body =~ s/>/\&gt\;/g;
		if ($realsubject) {
			$subject = $realsubject;
			$subject =~ s/\& /\&amp\; /g;
			$subject =~ s/"/\&quot\;/g;
			$subject =~ s/</\&lt\;/g;
			$subject =~ s/>/\&gt\;/g;
		}
		require $webbbs_form;
		&Print_Form(-1);
		print "<P>&nbsp;";
	}
	if ($PreviewForm) { &Footer($MessageFooterFile,"return"); }
	else { &Footer($MessageFooterFile,"return","refresh"); }
}

sub Header {
	local ($header_title, $header_file,$refresh,$destname) = @_;
	#print "\n<HTML><HEAD>";
	#if ($RefreshTime && (($refresh eq "refreshalways")
	#  || (($refresh eq "refresh") && !($UseFrames)))) {
	#	print "<META HTTP-EQUIV=\"Refresh\" CONTENT=\"$RefreshTime; URL=$DestinationURL$BBSquery";
	#	if ($AdminRun
	#	  && (($FORM{'delete'} =~ /tmp/) || $FORM{'ApprovePost'} || $EditApproval)) {
	#		print "moderate=0;";
	#	}
	#	if ($destname) {
	#		if ($UseFrames) { print "review=$destname"; }
	#		else { print "#$destname"; }
	#	}
	#	print "\">";
	#}
	#print "<TITLE>$header_title</TITLE>\n";
	#if (!($SkipHF) && $SpellCheckerID && $SpellCheckerPath && $SpellCheckerMeta) {
	#	if ($SpellCheckerJS) {
	#		print "<SCRIPT TYPE=\"text/javascript\" LANGUAGE=\"javascript\" ";
	#		print "SRC=\"$SpellCheckerJS\"></SCRIPT>\n";
	#	}
	#	else {
	#		print "<SCRIPT LANGUAGE=\"javascript\" ";
	#		print "SRC=\"http://www.spellchecker.net/spellcheck/lf/spch.cgi?";
	#		print "customerid=$SpellCheckerID\"></SCRIPT>\n";
	#	}
	#}
	#if (!($SkipHF) && $MetaFile) {
	#	open (HEADLN,"$MetaFile");
	#	@headln = <HEADLN>;
	#	close (HEADLN);
	#	foreach $line (@headln) {
	#		print "$line";
	#	}
	#}
	#print "</HEAD><BODY $bodyspec><FONT $fontspec>\n";
	if (!($SkipHF) && $header_file) {
		#open (HEADER,"$header_file");
		#@header = <HEADER>;
		#close (HEADER);
		#foreach $line (@header) {
		#	if ($line =~ /<!--#include\s+(virtual|file)\s*=\s*"*([^"\s]*)"*\s*-->/i) {
		#		$SSIFile = $SSIRootDir.$2;
		#		open (SSIFILE,"<$SSIFile");
		#		while (<SSIFILE>) { print "$_"; }
		#		close (SSIFILE);
		#	}
		#	elsif (!($AdminRun) && ($line =~ /<!--InsertAdvert\s*(.*)-->/i)) {
		#		&insertadvert($1);
		#	}
		#	else { print "$line"; }
		#}
		
		my($blahtemp, $blahtemp2) = ($num, $name);
		
		$ENV{'QUERY_STRING'} = "$header_title";
		require "$header_file";
		
		$num = $blahtemp;
		$name = $blahtemp2;
	}
}

sub Header2 {
	local ($refresh) = @_;
	if (($refresh eq "refresh") || !($UseFrames)) {
		if ($AdminRun) {
			$navbar = $NavBarStart;
			if ($FORM{'delete'} =~ /tmp/) {
				$navbar .= " <A HREF=\"$adminurl$BBSquery";
				$navbar .= "moderate=0\"";
				if ($UseFrames) { $navbar .= "$BBStargettop>"; }
				else { $navbar .= ">"; }
				$navbar .= "$text{'0025'}</A> |";
			}
			$navbar .= " <A HREF=\"$adminurl$BBSquery\"";
		}
		else {
			$navbar = $NavBarStart." <A HREF=\"$cgiurl$BBSquery\"";
		}
		if ($UseFrames) { $navbar .= "$BBStargettop>"; }
		else { $navbar .= ">"; }
		$navbar .= "$text{'0004'}</A>";
		$navbar .= $NavBarEnd;
		print "$navbar";
		if ($printboardname && !($UseFrames)) {
			print "<P ALIGN=CENTER><BIG><STRONG>";
			print "$boardname</STRONG></BIG>\n";
		}
	}
}

sub Footer {
	local ($footer_file,$footer_type,$refresh) = @_;
	if ($RefreshTime && (($refresh eq "refreshalways")
	  || (($refresh eq "refresh") && !($UseFrames)))) {
		print "<P ALIGN=CENTER><EM>\n<SMALL>$text{'0150'}</SMALL>\n</EM>\n";
	}
	elsif ($navbar && !$refresh) { print "$navbar"; }
	if ($footer_type eq "credits") {
		print "$CreditLink";
	}
	if (!($SkipHF) && $footer_file) {
	#	open (FOOTER,"$footer_file");
	#	@footer = <FOOTER>;
	#	close (FOOTER);
	#	foreach $line (@footer) {
	#		if ($line =~ /<!--#include\s+(virtual|file)\s*=\s*"*([^"\s]*)"*\s*-->/i) {
	#			$SSIFile = $SSIRootDir.$2;
	#			open (SSIFILE,"<$SSIFile");
	#			while (<SSIFILE>) { print "$_"; }
	#			close (SSIFILE);
	#		}
	#		elsif (!($AdminRun) && ($line =~ /<!--InsertAdvert\s*(.*)-->/i)) {
	#			&insertadvert($1);
	#		}
	#		else { print "$line"; }
	#	}
		
		require "$footer_file";
	}
	#print "</FONT></BODY></HTML>\n";
	if ($DBMType==2) {
		dbmclose (%MessageList);
		dbmclose (%CountList);
	}
	else {
		untie %MessageList;
		untie %CountList;
	}
	&LockClose (DBLOCK,"$dir/dblock.txt");
	&LockClose (COUNTLOCK,"$dir/countlock.txt");
	unless ($UseLocking) { &MasterLockClose; }
	reset 'A-Za-z';
	exit;
}

sub MessageDBMRead {
	if ($DBMType==1) {
		tie (%MessageList,'AnyDBM_File',"$dir/messagelist",O_RD,0666,$DB_HASH);
	}
	elsif ($DBMType==2) {
		dbmopen(%MessageList,"$dir/messagelist",0666);
	}
	else {
		tie (%MessageList,'AnyDBM_File',"$dir/messagelist",O_RD,0666);
	}
}

sub MessageDBMWrite {
	if ($DBMType==1) {
		tie (%MessageList,'AnyDBM_File',"$dir/messagelist",O_RDWR|O_CREAT,0666,$DB_HASH)
		  || &Error("9150","9151");
	}
	elsif ($DBMType==2) {
		dbmopen(%MessageList,"$dir/messagelist",0666)
		  || &Error("9150","9151");
	}
	else {
		tie (%MessageList,'AnyDBM_File',"$dir/messagelist",O_RDWR|O_CREAT,0666)
		  || &Error("9150","9151");
	}
}

sub CountDBMRead {
	if ($DBMType==1) {
		tie (%CountList,'AnyDBM_File',"$dir/countlist",O_RD,0666,$DB_HASH);
	}
	elsif ($DBMType==2) {
		dbmopen(%CountList,"$dir/countlist",0666);
	}
	else {
		tie (%CountList,'AnyDBM_File',"$dir/countlist",O_RD,0666);
	}
}

sub CountDBMWrite {
	if ($DBMType==1) {
		tie (%CountList,'AnyDBM_File',"$dir/countlist",O_RDWR|O_CREAT,0666,$DB_HASH)
		  || &Error("9150","9151");
	}
	elsif ($DBMType==2) {
		dbmopen(%CountList,"$dir/countlist",0666)
		  || &Error("9150","9151");
	}
	else {
		tie (%CountList,'AnyDBM_File',"$dir/countlist",O_RDWR|O_CREAT,0666)
		  || &Error("9150","9151");
	}
}

sub LockOpen {
	local(*FILE,$lockfilename,$append) = @_;
	unless (-e "$lockfilename") {
		open (FILE,">$lockfilename");
		print FILE "\n";
		close (FILE);
	}
	if ($append) {
		open (FILE,">>$lockfilename") || &Error("9400","9401",$lockfilename);
	}
	else {
		open (FILE,"+<$lockfilename") || &Error("9400","9401",$lockfilename);
	}
	if ($UseLocking) {
		local($TrysLeft) = 3000;
		while ($TrysLeft--) {
			select(undef,undef,undef,0.01);
			(flock(FILE,6)) || next;
			last;
		}
		unless ($TrysLeft >= 0) {
			if ($lockfilename =~ /countlock.txt/) {
				$NoCountLock = 1;
			}
			else {
				&Error("9400","9401",$lockfilename);
			}
		}
	}
}

sub LockClose {
	local(*FILE,$lockfilename) = @_;
	close (FILE);
}

sub MasterLockOpen {
	local($TrysLeft) = 6000;
	if ((-e "$dir/masterlockfile.lok")
	  && ((stat("$dir/masterlockfile.lok"))[9]+15<$time)) {
		unlink ("$dir/masterlockfile.lok");
	}
	while ($TrysLeft--) {
		if (-e "$dir/masterlockfile.lok") {
			select(undef,undef,undef,0.01);
		}
		else {
			open (MASTERLOCKFILE,">$dir/masterlockfile.lok");
			print MASTERLOCKFILE "\n";
			close (MASTERLOCKFILE);
			last;
		}
	}
	unless ($TrysLeft >= 0) {
		$UseLocking = 1;
		&Error("9400","9401","$dir/masterlockfile.lok");
	}
}

sub MasterLockClose {
	unlink ("$dir/masterlockfile.lok");
}

1;

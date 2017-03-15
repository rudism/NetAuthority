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
	if ($ARGV[0] && !($ENV{'QUERY_STRING'})) {
		$ENV{'QUERY_STRING'} = $ARGV[0];
		$UseFrames = "";
		$SkipHF = 1;
	}
	&Parse_Form;
	&Initialize_Data;
	if (($ENV{'DOCUMENT_URI'} && ($cgiurl !~ /$ENV{'DOCUMENT_URI'}/))
	  || ($ENV{'QUERY_STRING'} =~ /quickinfo/i)) {
		&QuickInfo;
	}
	if ($ENV{'QUERY_STRING'} =~ /blank/i) {
		&BlankPage;
	}
	elsif ($UseFrames && ($ENV{'QUERY_STRING'} !~ /index/i)) {
		if (($ENV{'QUERY_STRING'} =~ /review=(\d+)/i)
		  || ($ENV{'QUERY_STRING'} =~ /rev=(\d+)/i)) {
			$message = $1;
			if ($message < 1) { $message = "00"; }
		}
		&SetupFrames;
	}
	else {
		if ($DisplayViews) {
			if ($FORM{'ListType'} =~ /Guestbook/) {
				unless ($UseLocking) { &MasterLockOpen; }
				&LockOpen (COUNTLOCK,"$dir/countlock.txt");
				unless ($NoCountLock) {
					&CountDBMWrite;
				}
			}
			else {
				&CountDBMRead;
			}
		}
		if (($ENV{'QUERY_STRING'} =~ /rebuilt/)
		  || (!($UseFrames) && $ENV{'QUERY_STRING'} =~ /rebuild/)) {
			unless ($DisplayViews && ($FORM{'ListType'} =~ /Guestbook/)) {
				if ($DBMType==2) { dbmclose (%CountList); }
				else { untie %CountList; }
				unless ($UseLocking) { &MasterLockOpen; }
				&LockOpen (COUNTLOCK,"$dir/countlock.txt");
				unless ($NoCountLock) {
					&CountDBMWrite;
				}
			}
			$rebuildflag = 1;
			if ($DBMType==2) { dbmclose (%MessageList); }
			else { untie %MessageList; }
			require $webbbs_rebuild;
			&Rebuild_Database;
			@messages = (keys %MessageList);
			$TotalMessages = @messages;
			@sortedmessages = (sort {$a<=>$b} @messages);
			$lastmessage = $sortedmessages[@sortedmessages-1];
		}
		@messages = ();
		if ($FORM{'ListType'} =~ /Alpha/) {
			foreach $message (@sortedmessages) {
				$sortsubject{$message} = $MessageList{$message};
				$sortsubject{$message} =~ s/^[^\|]*\|([^\|]*).*/$1/;
				$sortsubject{$message} =~ s/^$text{'1513'} //;
				$sortsubject{$message} =~ s/&pipe;/\|/g;
				$sortsubject{$message} =~ tr/A-Z/a-z/;
			}
		}
		if ($ArchiveOnly && !($FORM{'KeySearch'}) && !($UseFrames)) {
			require $webbbs_misc;
			&Search;
		}
		&DisplayIndex;
	}
}

sub SetupFrames {
	print "<HTML><HEAD><TITLE>$boardname</TITLE>\n";
	if ($MetaFile) {
		open (HEADLN,"$MetaFile");
		@headln = <HEADLN>;
		close (HEADLN);
		foreach $line (@headln) { print "$line"; }
	}
	print "</HEAD>\n";
	if ($UseFrames =~ /h/i) { print "<FRAMESET ROWS=\"50%,*\">\n"; }
	else { print "<FRAMESET COLS=\"33%,*\">\n"; }
	print "<FRAME NAME=\"msgidx\" SCROLLING=auto ";
	print "SRC=\"$DestinationURL";
	if ($ENV{'QUERY_STRING'} =~ /moderate/i) { print "?moderate"; }
	else { print "?index"; }
	if ($ENV{'QUERY_STRING'} =~ /rebuild/) { print "rebuilt"; }
	if ($message) { print "#$message"; }
	print "\">\n";
	print "<FRAME NAME=\"msgtxt\" SCROLLING=auto ";
	if ($message) { print "SRC=\"$DestinationURL?read=$message\">\n"; }
	elsif ($ArchiveOnly && !($FORM{'KeySearch'})) {
		print "SRC=\"$DestinationURL?search\">\n";
	}
	elsif ($WelcomePage) { print "SRC=\"$WelcomePage\">\n"; }
	else { print "SRC=\"$DestinationURL?blank\">\n"; }
	print "<NOFRAME>\n";
	print "<BODY $bodyspec>\n";
	if ($HeaderFile) {
		open (HEADER,"$HeaderFile");
		@header = <HEADER>;
		close (HEADER);
		foreach $line (@header) {
			if ($line =~ /<!--#include\s+(virtual|file)\s*=\s*"*([^"\s]*)"*\s*-->/i) {
				$SSIFile = $SSIRootDir.$2;
				open (SSIFILE,"<$SSIFile");
				while (<SSIFILE>) { print "$_"; }
				close (SSIFILE);
			}
			else { print "$line"; }
		}
	}
	if ($printboardname) {
		print "<P ALIGN=CENTER>";
		print "<BIG><STRONG>$boardname</STRONG></BIG>\n";
	}
	print "$text{'0100'}\n";
	print "$CreditLink";
	if ($FooterFile) {
		open (FOOTER,"$FooterFile");
		@footer = <FOOTER>;
		close (FOOTER);
		foreach $line (@footer) {
			if ($line =~ /<!--#include\s+(virtual|file)\s*=\s*"*([^"\s]*)"*\s*-->/i) {
				$SSIFile = $SSIRootDir.$2;
				open (SSIFILE,"<$SSIFile");
				while (<SSIFILE>) { print "$_"; }
				close (SSIFILE);
			}
			else { print "$line"; }
		}
	}
	print "</BODY></NOFRAME></FRAMESET></HTML>\n";
	reset 'A-Za-z';
	exit;
}

sub BlankPage {
	print "<HTML><BODY $bodyspec>\n";
	print "</BODY></HTML>\n";
	reset 'A-Za-z';
	exit;
}

sub QuickInfo {
	print "\n";
	print "$text{'0075'}: ",&PrintDate(int($MessageList{$lastmessage}));
	if ($Cookies{'lastmessage'} && $Cookies{'lastvisit'}) {
		if ($Cookies{'lastmessage'} < $lastmessage) {
			$NewCount = 0;
			$startcount = $Cookies{'lastmessage'}+1;
			foreach $messagecount ($startcount..$lastmessage) {
				if ($MessageList{$messagecount}>0) { $NewCount++; }
			}
			print "<BR>($NewCount ";
			if ($NewCount > 1) { print "$text{'0506'}"; }
			else { print "$text{'0507'}"; }
		}
		else {
			print "<BR>($text{'0508'}";
		}
		print " $text{'0509'})";
	}
	print "\n";
	if ($DBMType==2) { dbmclose (%MessageList); }
	else { untie %MessageList; }
	&LockClose (DBLOCK,"$dir/dblock.txt");
	unless ($UseLocking) { &MasterLockClose; }
	reset 'A-Za-z';
	exit;
}

sub DisplayIndex {
	unless ($ArchiveOnly || !($AllowNewThreads) || $SepPostFormIndex) {
		$SpellCheckerMeta = 1;
	}
	&Header("$boardname - $text{'0500'}",$HeaderFile);
	$navbar = $NavBarStart;
	if ($AdminRun) { &DisplayIndexAdmin1; }
	else {
		unless ($ArchiveOnly || !($AllowNewThreads)) {
			if ($SepPostFormIndex) {
				$navbar .= " <A HREF=\"$cgiurl$BBSquery";
				$navbar .= "form=0\"";
				$navbar .= "$BBStargettop>";
			}
			else {
				$navbar .= " <A HREF=\"#PostMessage\">";
			}
			$navbar .= "$text{'0007'}</A> |";
		}
		if ($mailprog && $email_list && !($private_list)) {
			$navbar .= " <A HREF=\"$cgiurl$BBSquery";
			$navbar .= "subscribe\"$BBStarget> $text{'0008'}</A> |";
		}
		unless ($FORM{'KeySearch'}) {
			$FORM{'KeySearch'} = "No";
		}
		if ($FORM{'KeySearch'} ne "No") {
			$navbar .= " <A HREF=\"$cgiurl$BBSquery\" ";
			$navbar .= "$BBStargettop>";
			$navbar .= "$text{'0004'}</A> |";
		}
		if ($SearchURL) { $navbar .= " <A HREF=\"$SearchURL\">"; }
		else {
			$navbar .= " <A HREF=\"$cgiurl$BBSquery";
			$navbar .= "search\"$BBStarget>";
		}
		$navbar .= "$text{'0009'}</A>";
		if ($AllowUserPrefs) {
			$navbar .= " | <A HREF=\"$cgiurl$BBSquery";
			$navbar .= "reconfigure\"$BBStarget>$text{'0010'}</A>";
		}
		if ($TopNPosters) {
			$navbar .= " | <A HREF=\"$cgiurl$BBSquery";
			$navbar .= "topstats\"$BBStarget>$text{'0501'}&nbsp;$TopNPosters</A>";
		}
		if ($UserProfileDir) {
			$navbar .= " | <A HREF=\"$cgiurl$BBSquery";
			$navbar .= "profiles\"$BBStarget>$text{'2510'}</A>";
			unless ($ArchiveOnly || (!($AllowNewThreads) && !($AllowResponses))) {
				$navbar .= " | <A HREF=\"$cgiurl$BBSquery";
				$ProfileCheck = $Cookies{'name'};
				$ProfileCheck =~ s/[^\w\.\-\']/\+/g;
				$ProfileCheck =~ tr/A-Z/a-z/;
				if (-e "$UserProfileDir/$ProfileCheck.txt") {
					$navbar .= "profileedit\"$BBStargettop>$text{'2503'}</A>";
				}
				else {
					$navbar .= "profileedit\"$BBStargettop>$text{'2506'}</A>";
				}
			}
		}
		if (%Navbar_Links) {
			foreach $key (keys %Navbar_Links) {
				$navbar .= " | ";
				($NavLinkURL,$NavLinkTarget) = split(/\|/,$Navbar_Links{$key});
				$navbar .= "<A HREF=\"$NavLinkURL\"";
				if ($NavLinkTarget) { $navbar .= " TARGET=\"$NavLinkTarget\""; }
				else { $navbar .= " $BBStarget"; }
				$navbar .= ">$key</A>";
			}
		}
	}
	$navbar .= $NavBarEnd;
	print "$navbar";
	if ($AdminRun) { &DisplayIndexAdmin2; }
	if ($printboardname) {
		print "<P ALIGN=CENTER><BIG><STRONG>";
		print "$boardname</STRONG></BIG>\n";
	}
	print "<P ALIGN=CENTER><BIG><BIG><STRONG>$text{'0500'}</STRONG></BIG></BIG>\n";
	if ($rebuildflag) { print "<SMALL>\n<P ALIGN=CENTER>$text{'0525'}\n</SMALL>\n"; }
	print "<P><div align=\"center\"><TABLE BORDER=0 CELLSPACING=0 CELLPADDING=6>";
	print "<TR><TH COLSPAN=3><SMALL>";
	if ($ArchiveOnly || ($FORM{'KeySearch'} ne "No")) {
		$FORM{'ListType'} = "Chronologically, Reversed";
		print "<EM>$text{'0503'}</EM>";
	}
	elsif ($Cookies{'lastmessage'} && $Cookies{'lastvisit'}) {
		print "<EM>$text{'0504'}";
		if ($Cookies{'name'}) { print ", $Cookies{'name'}"; }
		print "!<BR>$text{'0505'}, ";
		if ($Cookies{'lastmessage'} < $lastmessage) {
			$NewCount = 0;
			$startcount = $Cookies{'lastmessage'}+1;
			foreach $messagecount ($startcount..$lastmessage) {
				if ($MessageList{$messagecount}>0) { $NewCount++; }
			}
			print "$NewCount ";
			if ($NewCount > 1) { print "$text{'0506'}"; }
			else { print "$text{'0507'}"; }
		}
		else {
			print "$text{'0508'}";
		}
		print " $text{'0509'}!</EM>";
	}
	else {
		print "<EM>$text{'0510'}!</EM>";
	}
	print "</SMALL></TH></TR><TR><TD VALIGN=TOP ALIGN=LEFT class=\"content\"><SMALL>";
	$endday = $time+60;
	if ($FORM{'ListSize'} eq "Range") {
		if ($FORM{'StartDateC'} < 1990) { $FORM{'StartDateC'} = 1990; }
		if ($FORM{'EndDateC'} < $FORM{'StartDateC'}) { $FORM{'EndDateC'} = $FORM{'StartDateC'}; }
		$searchrange = "$FORM{'StartDateA'} $months[$FORM{'StartDateB'}] ";
		$searchrange .= "$FORM{'StartDateC'} $text{'0511'} $FORM{'EndDateA'} ";
		$searchrange .= "$months[$FORM{'EndDateB'}] $FORM{'EndDateC'}";
		$startday = &rangedate($FORM{'StartDateB'}+1,$FORM{'StartDateA'},$FORM{'StartDateC'}-1900);
		$endday = &rangedate($FORM{'EndDateB'}+1,$FORM{'EndDateA'}+1,$FORM{'EndDateC'}-1900);
	}
	elsif ($FORM{'ListTime'} =~ /(\d+) ([\w\(\)]+)/) {
		$FORM{'ListTimeA'} = $1;
		$FORM{'ListTimeB'} = $2;
		if ($FORM{'ListTimeB'} eq "$text{'0060'}") {
			$startday = ($FORM{'ListTimeA'} * 3600);
		}
		elsif ($FORM{'ListTimeB'} eq "$text{'0061'}") {
			$startday = ($FORM{'ListTimeA'} * 86400);
		}
		elsif ($FORM{'ListTimeB'} eq "$text{'0062'}") {
			$startday = ($FORM{'ListTimeA'} * 604800);
		}
		elsif ($FORM{'ListTimeB'} eq "$text{'0063'}") {
			$startday = ($FORM{'ListTimeA'} * 2635200);
		}
		else {
			$FORM{'ListTime'} = "2 $text{'0062'}";
			$startday = 1209600;
		}
	}
	elsif ($FORM{'ListTime'} eq "New Only") {
		if ($Cookies{'lastmessage'}) {
			$startday = int($MessageList{$Cookies{'lastmessage'}})+1;
		}
		else {
			$startday = $time;
		}
	}
	unless ($startday) { $startday = 500000000; }
	if ($FORM{'ListSize'} eq "Range") {
		print "$text{'0514'}<BR>$searchrange\n";
	}
	elsif ($ArchiveOnly || ($startday eq 500000000)) {
		$startday = ($time-$startday);
		if ($FORM{'KeySearch'} eq "No") {
			if ($ArchiveOnly) {
				$startday = $time;
				print "$text{'0514'}<BR>";
				($mday,$mon,$year) =
				  (localtime(int($MessageList{$sortedmessages[0]})+($HourOffset*3600)))[3,4,5];
				print "$mday $months[$mon] ",$year+1900," $text{'0511'} ";
				($mday,$mon,$year) =
				  (localtime(int($MessageList{$sortedmessages[@sortedmessages-1]})+($HourOffset*3600)))[3,4,5];
				print "$mday $months[$mon] ",$year+1900,"\n";
			}
			else { print "$text{'0512'}\n"; }
		}
		else {
			print "$text{'0513'}\n";
		}
	}
	else {
		print "$text{'0515'}<BR>";
		if ($FORM{'ListTime'} eq "New Only") {
			print "$text{'0516'}\n";
		}
		else {
			$startday = ($time-$startday);
			print "$text{'0517'} $FORM{'ListTime'}\n";
		}
	}
	$SearchString = "";
	if ($FORM{'KeySearch'} eq "Yes") {
		$FORM{'Keywords'} =~ s/&[^;\s]*;/ /g;
		$FORM{'Keywords'} =~ s/[^\w\.\-\']/ /g;
		$FORM{'Keywords'} =~ s/(\s)+/ /g;
		$FORM{'Keywords'} =~ s/^\s//g;
		@keywords = split(/\s+/, $FORM{'Keywords'});
		$SearchString = "$text{'0518'} ";
		$SearchString .= "<STRONG>$FORM{'Boolean'}</STRONG> ";
		$SearchString .= "$text{'0519'}:<BR>";
		foreach $keyword (@keywords) {
			$SearchString .= "<STRONG>$keyword</STRONG>";
			$i++;
			unless ($i == @keywords) { $SearchString .= ", "; }
		}
		open (SEARCH,"$dir/searchterms.idx");
		while (<SEARCH>) {
			if (/^(\d+) (.*)/) {
				$message = $1;
				$string = $2;
				if ((int($MessageList{$message}) >= $startday) && (int($MessageList{$message}) <= $endday)) {
					$value = 0;
					if ($FORM{'Boolean'} eq $text{'0050'}) {
						foreach $term (@keywords) {
							$test = ($string =~ s/$term//ig);
							if ($test < 1) {
								$value = 0;
								last;
							}
							else {
								$value = $value+$test;
							}
						}
					}
					elsif ($FORM{'Boolean'} eq $text{'0051'}) {
						foreach $term (@keywords) {
							$test = ($string =~ s/$term//ig);
							$value = $value+$test;
						}
					}
					if ($value > 0) {
						push (@keywordmatches, $message);
					}
					else {
						$DontUse{$message} = 1;
					}
				}
				else {
					$DontUse{$message} = 1;
				}
			}
		}
		close (SEARCH);
		@sortedmessages = (sort {$a<=>$b} @keywordmatches);
	}
	elsif ($FORM{'KeySearch'} eq "Author") {
		$SearchString = "$text{'0520'} ";
		$SearchString .= "<STRONG>&quot;$FORM{'Author'}&quot;</STRONG>";
		foreach $message (@sortedmessages) {
			if ((int($MessageList{$message}) >= $startday) && (int($MessageList{$message}) <= $endday)) {
				$date=$sub=$poster=$prev=$next=$count=$admin=$ip="";
				($date,$sub,$poster,$prev,$next,$count,$admin,$ip) =
				  split(/\|/,$MessageList{$message});
				if ($poster =~ /$FORM{'Author'}/i) {
					push (@keywordmatches, $message);
				}
				else {
					$DontUse{$message} = 1;
				}
			}
			else {
				$DontUse{$message} = 1;
			}
		}
		@sortedmessages = (sort {$a<=>$b} @keywordmatches);
	}
	elsif ($FORM{'KeySearch'} eq "Domain") { &DisplayIndexAdmin3; }
	elsif ($FORM{'KeySearch'} eq "All") {
		$SearchString = "$text{'0521'}";
		foreach $message (@sortedmessages) {
			if ((int($MessageList{$message}) >= $startday) && (int($MessageList{$message}) <= $endday)) {
				push (@keywordmatches, $message);
			}
			else {
				$DontUse{$message} = 1;
			}
		}
		@sortedmessages = (sort {$a<=>$b} @keywordmatches);
	}
	foreach $message (@sortedmessages) {
		if ((int($MessageList{$message}) >= $startday) && (int($MessageList{$message}) <= $endday)) {
			$DisplayedMessages ++;
		}
		else {
			$DontUse{$message} = 1;
		}
	}
	print "</SMALL></TD><TD>";
	print "&nbsp; &nbsp;</TD><TD VALIGN=TOP ALIGN=RIGHT class=\"content\"><SMALL>";
	unless (($FORM{'ListType'} =~ /Compress/)
	  || ($FORM{'ListType'} =~ /Guestbook-Style, Thread/)) {
		print "$DisplayedMessages $text{'0522'} ";
		print "$TotalMessages $text{'0523'}<BR>";
	}
	if ($FORM{'ListType'} eq "Chronologically") {
		print "($text{'0601'})";
	}
	elsif ($FORM{'ListType'} eq "Chronologically, Reversed") {
		print "($text{'0602'})";
	}
	elsif ($FORM{'ListType'} eq "Alphabetically") {
		print "($text{'0603'})";
	}
	elsif ($FORM{'ListType'} eq "Alphabetically, Reversed") {
		print "($text{'0604'})";
	}
	elsif ($FORM{'ListType'} eq "Compressed") {
		print "($text{'0605'})";
	}
	elsif ($FORM{'ListType'} eq "Compressed, Reversed") {
		print "($text{'0606'})";
	}
	elsif ($FORM{'ListType'} eq "Guestbook-Style") {
		print "($text{'0607'})";
	}
	elsif ($FORM{'ListType'} eq "Guestbook-Style, Reversed") {
		print "($text{'0608'})";
	}
	elsif ($FORM{'ListType'} eq "Guestbook-Style, Threaded") {
		print "($text{'0609'})";
	}
	elsif ($FORM{'ListType'} eq "Guestbook-Style, Threaded, Reversed") {
		print "($text{'0610'})";
	}
	elsif ($FORM{'ListType'} eq "Guestbook-Style, Threaded, Mixed") {
		print "($text{'0615'})";
	}
	elsif ($FORM{'ListType'} eq "By Threads, Reversed") {
		print "($text{'0611'})";
	}
	elsif ($FORM{'ListType'} eq "By Threads, Mixed") {
		print "($text{'0612'})";
	}
	else { print "($text{'0613'})"; }
	print "</SMALL></TD></TR>";
	if ($SearchString) {
		print "<TR><TD COLSPAN=3 ALIGN=CENTER class=\"content\"><SMALL>$SearchString</SMALL></TD></TR>";
	}
	print "</TABLE></div>\n";
	$messagecount = 0;
	if ($AdminRun) {
		$DeleteSelect = 1;
		$ToBeDeleted = "";
		print "<FORM METHOD=POST ACTION=\"$adminurl$BBSquery",
		  "delete\"$BBStarget>\n";
	}
	unless (($FORM{'ListType'} =~ /Guestbook/)
	  && ($FORM{'ListType'} !~ /Threaded/)) {
		if ($IndexEntryLines eq "news") {
			print "<P><div align=\"center\"><TABLE $tablespec>\n";
		}
		else {
			print "<P><$ul_dl>\n";
		}
	}
	if (($FORM{'ListType'} =~ /Compress/)
	  || ($FORM{'ListType'} =~ /Guestbook-Style, Thread/)) {
		foreach $message (@sortedmessages) {
			unless ($already{$message}) {
				$respcount = -1;
				$respdate = 0;
				$showthread = 0;
				$newcount = 0;
				if ($Cookies{'lastmessage'}
				  && ($Cookies{'lastmessage'} < $message)) {
					$newcount--;
				}
				&CompressList($message);
				if ($showthread > 0) {
					push (@messages,$message);
					$messagecount ++;
					$respcount{$message} = $respcount;
					$respdate{$message} = $respdate;
					$newcount{$message} = $newcount;
				}
			}
		}
		if (($FORM{'ListType'} =~ /Reversed/)
		  || ($FORM{'ListType'} =~ /Mixed/)) {
			@sortedmessages = reverse(@messages);
		}
		else {
			@sortedmessages = @messages;
		}
		foreach $message (@sortedmessages) {
			if ($NotFirstEntry) { print "$ThreadSpacer"; }
			else { $NotFirstEntry = 1; }
			&PrintMessageDesc($message);
			print "<BR><SMALL><EM>$respcount{$message} ";
			if ($respcount{$message} == 1) {
				print "$text{'0550'}";
			}
			else {
				print "$text{'0551'}";
			}
			if ($newcount{$message} > 0) {
				print " ($newcount{$message} $text{'0552'})";
			}
			if ($respcount{$message} > 0) {
				print " -- ",&PrintDate($respdate{$message});
			}
			print "</EM></SMALL>\n";
		}
	}
	elsif (($FORM{'ListType'} =~ /Chrono/)
	  || ($FORM{'ListType'} =~ /Guestbook/)) {
		if ($FORM{'ListType'} =~ /Reversed/) {
			@messages = reverse(@sortedmessages);
		}
		else {
			@messages = @sortedmessages;
		}
		foreach $message (@messages) {
			unless ($DontUse{$message}) {
				if ($FORM{'ListType'} =~ /Guestbook/) {
					&PrintGuestbookDesc($message);
				}
				else {
					&PrintMessageDesc($message);
				}
				$messagecount ++;
			}
		}
	}
	elsif ($FORM{'ListType'} =~ /Alpha/) {
		if ($FORM{'ListType'} =~ /Reversed/) {
			foreach $key (sort ByAlphaReversed @sortedmessages) {
				push (@messages,$key);
			}
		}
		else {
			foreach $key (sort ByAlpha @sortedmessages) {
				push (@messages,$key);
			}
		}
		foreach $message (@messages) {
			unless ($DontUse{$message}) {
				&PrintMessageDesc($message);
				$messagecount ++;
			}
		}
	}
	elsif ($FORM{'ListType'} eq "By Threads") {
		foreach $message (@sortedmessages) {
			unless ($already{$message} || $DontUse{$message}) {
				if ($NotFirstEntry) { print "$ThreadSpacer"; }
				else { $NotFirstEntry = 1; }
				&ThreadList($message);
				$messagecount ++;
			}
		}
	}
	else {
		@reversedmessages = reverse(@sortedmessages);
		foreach $message (@reversedmessages) {
			unless ($already{$message} || $DontUse{$message}) {
				$date=$sub=$poster=$prev=$next=$count=$admin=$ip="";
				($date,$sub,$poster,$prev,$next,$count,$admin,$ip) =
				  split(/\|/,$MessageList{$message});
				unless (($MessageList{$prev}>0) && !($DontUse{$prev})) {
					if ($NotFirstEntry) { print "$ThreadSpacer"; }
					else { $NotFirstEntry = 1; }
					&ThreadList($message);
					$messagecount ++;
				}
			}
		}
	}
	unless (($FORM{'ListType'} =~ /Guestbook/)
	  && ($FORM{'ListType'} !~ /Threaded/)) {
		if ($IndexEntryLines eq "news") {
			print "</TABLE></div>\n";
		}
		else {
			print "</$ul_dl>\n";
		}
	}
	if ($AdminRun) { &DisplayIndexAdmin4; }
	elsif ($messagecount < 1) {
		print "<P ALIGN=CENTER><STRONG>$text{'0524'}</STRONG>\n";
	}
	unless ($ArchiveOnly || !($AllowNewThreads) || $SepPostFormIndex) {
		require $webbbs_form;
		print "<A NAME=\"PostMessage\"></A>\n";
		&Print_Form;
		print "<P>&nbsp;";
	}
	&Footer($FooterFile,"credits");
}

sub rangedate {
	($perp_mon,$perp_day,$perp_year) = @_;
	%day_counts =
	  (1,0,2,31,3,59,4,90,5,120,6,151,7,181,
	  8,212,9,243,10,273,11,304,12,334);
	$perp_days = (($perp_year-69)*365)+(int(($perp_year-69)/4));
	$perp_days += $day_counts{$perp_mon};
	if ((int(($perp_year-68)/4) eq (($perp_year-68)/4))
	  && ($perp_mon>2)) {
		$perp_days++;
	}
	$perp_days += $perp_day;
	$perp_days -= 366;
	$perp_secs = ($perp_days*86400)+18000;
	$hour = (localtime($perp_secs))[2];
	if ($hour>0) { $perp_secs-=3600; }
	$perp_secs -= ($HourOffset*3600);
	return $perp_secs;
}

sub ByAlpha {
	$sortsubject{$a} cmp $sortsubject{$b};
}

sub ByAlphaReversed {
	$sortsubject{$b} cmp $sortsubject{$a};
}

sub CompressList {
	local (@threadresponses);
	local ($date,$sub,$poster,$prev,$next,$count,$admin,$ip) = "";
	($date,$sub,$poster,$prev,$next,$count,$admin,$ip) =
	  split(/\|/,$MessageList{$_[0]});
	$respcount++;
	if ($date > $respdate) { $respdate = $date; }
	unless ($DontUse{$_[0]}) { $showthread = 1; }
	if ($Cookies{'lastmessage'}
	  && ($Cookies{'lastmessage'} < $_[0])) {
		$newcount++;
	}
	@threadresponses = split(/ /,$next);
	foreach $threadresponse (@threadresponses) {
		next unless ($threadresponse > $_[0]);
		if ($MessageList{$threadresponse}>0) {
			&CompressList($threadresponse);
		}
	}
	$already{$_[0]} = 1;
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
	unless ($AllowUserPrefs) {
		$Cookies{'listtype'} = "";
		$Cookies{'listtime'} = "";
	}
	unless ($FORM{'ListType'}) { $FORM{'ListType'} = $Cookies{'listtype'}; }
	unless ($FORM{'ListTime'}) { $FORM{'ListTime'} = $Cookies{'listtime'}; }
	unless ($FORM{'password'}) { $FORM{'password'} = $Cookies{'password'}; }
	if ($FORM{'KeySearch'} eq "No") {
		$listtype = $FORM{'ListType'};
		$listtime = $FORM{'ListTime'};
	}
	if (!$name) { $name = $Cookies{'name'}; }
	if (!$email) { $email = $Cookies{'email'}; }
	if (!$message_url) { $message_url = $Cookies{'linkurl'}; }
	if (!$message_url_title) { $message_url_title = $Cookies{'linkname'}; }
	if (!$image_url) {$image_url = $Cookies{'imageurl'}; }
	if (!$listtype) { $listtype = $Cookies{'listtype'}; }
	if (!$listtime) { $listtime = $Cookies{'listtime'}; }
	unless ($Cookies{'thisvisit'}) {
		$Cookies{'thisvisit'} = $Cookies{'lastvisit'};
	}
	unless ($Cookies{'thismessage'}) {
		$Cookies{'thismessage'} = $Cookies{'lastmessage'};
	}
	if (($time - $Cookies{'timestamp'}) < 1800) {
		$lastvisit = $Cookies{'lastvisit'};
		$lastseen = $Cookies{'lastmessage'};
		$thisvisit = $Cookies{'thisvisit'};
		$thisseen = $Cookies{'thismessage'};
	}
	else {
		$lastvisit = $Cookies{'thisvisit'};
		$lastseen = $Cookies{'thismessage'};
		$Cookies{'lastvisit'} = $Cookies{'thisvisit'};
		$Cookies{'lastmessage'} = $Cookies{'thismessage'};
		$thisvisit = $todaydate;
		$thisseen = $lastmessage;
	}
	unless ($Cookies{'lastmessage'}) {
		$Cookies{'lastmessage'} = $lastmessage;
	}
	if (($ENV{'DOCUMENT_URI'} && ($cgiurl !~ /$ENV{'DOCUMENT_URI'}/))
	  || ($ENV{'QUERY_STRING'} =~ /quickinfo/i)) {
		return;
	}
	if ($SaveLinkInfo) {
		&SendCookie($boardname,'name',$name,'email',$email,
		  'listtype',$listtype,'listtime',$listtime,
		  'lastmessage',$lastseen,'lastvisit',$lastvisit,
		  'thismessage',$thisseen,'thisvisit',$thisvisit,
		  'timestamp',$time,'wantnotice',$Cookies{'wantnotice'},
		  'linkurl',$message_url,'linkname',$message_url_title,
		  'imageurl',$image_url,'password',$FORM{'password'});
	}
	else {
		&SendCookie($boardname,'name',$name,'email',$email,
		  'listtype',$listtype,'listtime',$listtime,
		  'lastmessage',$lastseen,'lastvisit',$lastvisit,
		  'thismessage',$thisseen,'thisvisit',$thisvisit,
		  'timestamp',$time,'wantnotice',$Cookies{'wantnotice'},
		  'password',$FORM{'password'});
	}
}

1;

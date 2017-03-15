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
	&Initialize_Data;
	if ($DisplayViews) {
		unless ($UseLocking) { &MasterLockOpen; }
		&LockOpen (COUNTLOCK,"$dir/countlock.txt");
		unless ($NoCountLock) {
			&CountDBMWrite;
		}
	}
	if ((!($UseFrames) && ($ENV{'QUERY_STRING'} =~ /review=(\d+)/i)) 
	  || (!($UseFrames) && ($ENV{'QUERY_STRING'} =~ /rev=(\d+)/i)) 
	  || ($ENV{'QUERY_STRING'} =~ /read=(\d+)/i)) {
		$messagenumber = $1;
		if ($messagenumber < 1) { $messagenumber = $lastmessage; }
		if ($FORM{'ListType'} =~ /Guestbook-Style, Thread/) {
			&DisplayThread;
		}
		else {
			&DisplayMessage;
		}
	}
	elsif ($ENV{'QUERY_STRING'} =~ /form=(\d+)/i) {
		$messagenumber = $1;
		require $webbbs_form;
		&PostForm;
	}
}

sub DisplayMessage {
	unless (($ArchiveOnly || (!($AllowResponses))) || $SepPostFormRead) {
		$SpellCheckerMeta = 1;
	}
	foreach $message (@sortedmessages) {
		if ($message < $messagenumber) {
			$prevmessage = $message;
		}
		elsif ($message > $messagenumber) {
			$nextmessage = $message;
			last;
		}
	}
	$subdir = "bbs".int($messagenumber/1000);
	open (FILE,"$dir/$subdir/$messagenumber") || &Error("9100","9101");
	@message = <FILE>;
	close (FILE);
	if ($DisplayViews) {
		unless ($CountList{$messagenumber}) { $CountList{$messagenumber} = 0; }
		$CountList{$messagenumber}++;
	}
	($admin,$subject,$poster,$email,$date,$image_url,$linkname,$linkurl) = "";
	foreach $line (@message) {
		if ($line =~ /^SUBJECT>(.*)/i) { $subject = $1; }
		elsif ($line =~ /^ADMIN>AdminPost/i) { $admin = "AdminPost"; }
		elsif ($line =~ /^ADMIN>/i) { next; }
		elsif ($line =~ /^POSTER>(.*)/i) { $poster = $1; }
		elsif ($line =~ /^EMAIL>(.*)/i) { $email = $1; }
		elsif ($line =~ /^DATE>(.*)/i) { $date = $1; }
		elsif ($line =~ /^EMAILNOTICES>/i) { next; }
		elsif ($line =~ /^IP_ADDRESS>(.*)/i) { $ipaddress = $1; }
		elsif ($line =~ /^<!--(.*)-->/i) { $remoteuser = $1; }
		elsif ($line =~ /^PASSWORD>(.*)/i) { $oldpassword = $1; }
		elsif ($line =~ /^PREVIOUS>(.*)/i) { $previous = $1; }
		elsif ($line =~ /^NEXT>(.*)/i) { $next = $1; }
		elsif ($line =~ /^IMAGE>(.*)/i) { $image_url = $1; }
		elsif ($line =~ /^LINKNAME>(.*)/i) { $linkname = $1; }
		elsif ($line =~ /^LINKURL>(.*)/i) { $linkurl = $1; }
		elsif (!$startup) {
			$startup = 1;
			$title = $subject;
			$title =~ s/<[^>]*\s+ALT\s*=\s*"(([^>"])*)"[^>]*>/$1/ig;
			$title =~ s/<([^>]|\n)*>//g;
			&Header($title,$MessageHeaderFile);
			if ($AdminRun && ($FORM{'ListType'} =~ /Chrono/)) {
				$FORM{'ListType'} = "Threaded";
			}
			unless (((($FORM{'ListType'} =~ /Chrono/)
			  || ($previous == 0)) && ($next == 0))
			  && ($prevmessage == 0) && ($nextmessage == 0)
			  && ($ArchiveOnly || (!($AllowResponses))) && ($UseFrames)) {
				$navbar = $NavBarStart;
				unless ((($FORM{'ListType'} =~ /Chrono/)
				  || ($previous == 0)) && ($next == 0)) {
					$navbar .= " <A HREF=\"#Responses\">";
					if ($FORM{'ListType'} =~ /Chrono/) {
						$navbar .= "$text{'0001'}</A>";
					}
					else {
						$navbar .= "$text{'0002'}</A>";
					}
					$printbar = 1;
				}
				unless ($ArchiveOnly || (!($AllowResponses))) {
					if ($printbar) { $navbar .= " |"; }
					if ($SepPostFormRead) {
						$navbar .= " <A HREF=\"$DestinationURL$BBSquery";
						$navbar .= "form=$messagenumber\"";
						$navbar .= "$BBStargettop>";
					}
					else {
						$navbar .= " <A HREF=\"#PostResponse\">";
					}
					$navbar .= "$text{'0003'}</A>";
					$printbar = 1;
				}
				if ($AdminRun) {
					if ($printbar) { $navbar .= " |"; }
					if ($SepPostFormRead) {
						$navbar .= " <A HREF=\"$adminurl$BBSquery";
						$navbar .= "edit=$messagenumber\"";
						$navbar .= "$BBStargettop>";
					}
					else {
						$navbar .= " <A HREF=\"#EditPost\">";
					}
					$navbar .= "$text{'1504'}</A>";
					$printbar = 1;
				}
				unless ($UseFrames) {
					if ($printbar) { $navbar .= " |"; }
					$navbar .= " <A HREF=\"$DestinationURL$BBSquery#$messagenumber\">";
					$navbar .= "$text{'0004'}</A>";
					$printbar = 1;
				}
				if ($prevmessage > 0) {
					if ($printbar) { $navbar .= " |"; }
					$navbar .= " <A HREF=\"$DestinationURL$BBSquery";
					$navbar .= "read=$prevmessage\"$BBStarget>";
					$navbar .= "$text{'0005'}</A>";
					$printbar = 1;
				}
				if ($nextmessage > 0) {
					if ($printbar) { $navbar .= " |"; }
					$navbar .= " <A HREF=\"$DestinationURL$BBSquery";
					$navbar .= "read=$nextmessage\"$BBStarget>";
					$navbar .= "$text{'0006'}</A>";
				}
				$navbar .= $NavBarEnd;
				print "$navbar";
			}
			unless ($UseFrames) {
				if ($printboardname) {
					print "<P ALIGN=CENTER><BIG><STRONG>";
					print "$boardname</STRONG></BIG>\n";
				}
			}
			print "<P ALIGN=CENTER><BIG><BIG><STRONG>";
			print "$subject</STRONG></BIG></BIG>\n";
			print "<P ALIGN=CENTER><STRONG>";
			print "$text{'1000'}: <BIG>";
			$ProfileCheck = $poster;
			$ProfileCheck =~ s/[^\w\.\-\']/\+/g;
			$ProfileCheck =~ tr/A-Z/a-z/;
			if (-e "$UserProfileDir/$ProfileCheck.txt") {
				print "<A HREF=\"$DestinationURL$BBSquery";
				print "profile=$ProfileCheck\" TARGET=\"_blank\">";
				print "$poster</A>";
			}
			else { print "$poster"; }
			print "</BIG>";
			if ($AdminRun && $remoteuser && ($remoteuser ne $poster)) {
				print " <EM>($remoteuser)</EM>";
			}
			if ($DisplayEmail && $email) {
				$mailsubject = $subject;
				if (%SmileyCode) {
					foreach $key (keys %SmileyCode) {
						$key2 = $SmileyCode{$key};
						$key2 =~ s/([\[\]\(\)\\\*\+\?\\\|])/\\$1/g;
						$mailsubject =~ s/$key2/$key/g;
					}
				}
				$mailsubject =~ s/<[^>]*\s+ALT\s*=\s*"(([^>"])*)"[^>]*>/$1/ig;
				$mailsubject =~ s/<([^>]|\n)*>//g;
				$mailsubject =~ s/"/'/g;
				print " &lt;<A HREF=\"mailto:$email?subject=$mailsubject\">";
				print "$email</A>&gt;";
			}
			if ($DisplayIPs && $ipaddress) {
				print " <SMALL><EM>($ipaddress)</EM></SMALL>\n";
			}
			print "<BR>$text{'1001'}: ",&PrintDate($date),"</STRONG>\n";
			if ($MessageList{$previous}>0) {
				$pdate=$psub=$pposter=$pprev=$pnext=$pcount=$padmin=$pip="";
				($pdate,$psub,$pposter,$pprev,$pnext,$pcount,$padmin,$pip) =
				  split(/\|/,$MessageList{$previous});
				$psub =~ s/&pipe;/\|/g;
				$pposter =~ s/&pipe;/\|/g;
				print "<P ALIGN=CENTER><STRONG><EM>$text{'1002'}: ";
				print "<A HREF=\"$DestinationURL$BBSquery";
				print "read=$previous\"$BBStarget>";
				print "$psub</A> ";
				print "($pposter)</EM></STRONG>\n";
			}
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
	if ($AdminRun) {
		&DisplayMessageAdmin;
	}
	else {
		if ($AllowUserDeletion) {
			print "<FORM METHOD=POST ACTION=\"$cgiurl$BBSquery",
			  "delete\"$BBStarget>\n",
			  "$NavBarStart<INPUT TYPE=HIDDEN NAME=\"password\" ",
			  "VALUE=\"$oldpassword\">\n",
			  "<INPUT TYPE=HIDDEN NAME=\"delete\" ",
			  "VALUE=\"$messagenumber\">\n",
			  "<INPUT TYPE=SUBMIT VALUE=\"$text{'0201'}\"> ",
			  "$text{'0205'}: ",
			  "<INPUT TYPE=PASSWORD NAME=\"newpassword\" ",
			  "SIZE=15>$NavBarEnd</FORM>\n";
			$FormCount++;
		}
		unless ((($FORM{'ListType'} =~ /Chrono/)
		  || ($previous == 0))
		  && ($next == 0)) {
			print "<P ALIGN=CENTER><BIG><STRONG>";
			print "<A NAME=\"Responses\">";
			@responses = split(/ /,$next);
			$responsecount = 0;
			if ($FORM{'ListType'} =~ /Chrono/) {
				print "$text{'1003'}</A></STRONG></BIG>\n";
				if ($IndexEntryLines eq "news") {
					print "<P><div align=\"center\"><TABLE BORDER=0 CELLSPACING=0 CELLPADDING=3>\n";
				}
				else {
					print "<P><$ul_dl>";
				}
				if ($FORM{'ListType'} =~ /Reversed/) {
					@sortedresponses = reverse(@responses);
				}
				else {
					@sortedresponses = @responses;
				}
				foreach $response (@sortedresponses) {
					if ($MessageList{$response}>0) {
						&PrintMessageDesc($response);
						$responsecount ++;
					}
				}
				if ($IndexEntryLines eq "news") {
					print "</TABLE></div>\n";
				}
				else {
					print "</$ul_dl>\n";
				}
				if ($responsecount eq 0) {
					print "<P ALIGN=CENTER>";
					print "$text{'1004'}\n";
				}
			}
			else {
				print "$text{'1005'}</A></STRONG></BIG>\n";
				if ($IndexEntryLines eq "news") {
					print "<P><div align=\"center\"><TABLE BORDER=0 CELLSPACING=0 CELLPADDING=3>\n";
				}
				else {
					print "<P><$ul_dl>";
				}
				&FindStart($messagenumber);
				&ThreadList($threadstart);
				if ($IndexEntryLines eq "news") {
					print "</TABLE></div>\n";
				}
				else {
					print "</$ul_dl>\n";
				}
			}
		}
	}
	unless (($ArchiveOnly || (!($AllowResponses))) || $SepPostFormRead) {
		require $webbbs_form;
		print "<A NAME=\"PostResponse\"></A>\n";
		&Print_Form($messagenumber);
		if ($AdminRun) {
			print "<A NAME=\"EditPost\"></A>\n";
			&Print_EditForm($messagenumber);
		}
		print "<P>&nbsp;";
	}
	&Footer($MessageFooterFile,"credits");
}

sub DisplayThread {
	unless (($ArchiveOnly || (!($AllowResponses))) || $SepPostFormRead) {
		$SpellCheckerMeta = 1;
	}
	&FindStart($messagenumber);
	$title = $subject;
	$title =~ s/<([^>]|\n)*>/ /g;
	&Header($title,$MessageHeaderFile);
	unless (($ArchiveOnly || (!($AllowResponses))) && ($UseFrames)) {
		unless ($UseFrames) {
			$navbar = $NavBarStart;
			$navbar .= " <A HREF=\"$cgiurl$BBSquery\">";
			$navbar .= "$text{'0004'}</A>";
			$navbar .= $NavBarEnd;
			print "$navbar";
		}
	}
	unless ($UseFrames) {
		if ($printboardname) {
			print "<P ALIGN=CENTER><BIG><STRONG>";
			print "$boardname</STRONG></BIG>\n";
		}
	}
	@guestbookthread = ();
	&ThreadGuestbook($threadstart);
	@sortedguestbookthread = (sort {$a<=>$b} @guestbookthread);
	if ($FORM{'ListType'} =~ /Reversed/) {
		@guestbookthread = reverse(@sortedguestbookthread);
		@sortedguestbookthread = @guestbookthread;
	}
	if ($PaginateGuestbook) {
		foreach $key (0..@sortedguestbookthread) {
			if ($sortedguestbookthread[$key] eq $messagenumber) {
				$CurrentPage = $key;
				last;
			}
		}
		$FirstPage = $sortedguestbookthread[0];
		if (@sortedguestbookthread > $PaginateGuestbook) {
			$LastPage = $sortedguestbookthread[@sortedguestbookthread-$PaginateGuestbook];
		}
		if ($CurrentPage > $PaginateGuestbook) {
			$PreviousPage = $sortedguestbookthread[$CurrentPage-$PaginateGuestbook];
		}
		if ($FORM{'ListType'} =~ /Reversed/) {
			unless ($PreviousPage < $FirstPage) { $PreviousPage = ""; }
			unless ($FirstPage > $messagenumber) { $FirstPage = ""; }
			unless (@sortedguestbookthread < ($CurrentPage+$PaginateGuestbook)) {
				$NextPage = $sortedguestbookthread[$CurrentPage+$PaginateGuestbook];
			}
			unless ($LastPage < $NextPage) { $LastPage = $NextPage; $NextPage = ""; }
			unless ($LastPage < $messagenumber) { $LastPage = ""; }
		}
		else {
			unless ($PreviousPage > $FirstPage) { $PreviousPage = ""; }
			unless ($FirstPage < $messagenumber) { $FirstPage = ""; }
			unless (@sortedguestbookthread < ($CurrentPage+$PaginateGuestbook)) {
				$NextPage = $sortedguestbookthread[$CurrentPage+$PaginateGuestbook];
			}
			unless ($LastPage > $NextPage) { $LastPage = $NextPage; $NextPage = ""; }
			unless ($LastPage > $messagenumber) { $LastPage = ""; }
		}
	}
	print "<P ALIGN=CENTER><BIG><BIG><STRONG>";
	$date=$sub=$poster=$prev=$next=$count=$admin=$ip="";
	($date,$sub,$poster,$prev,$next,$count,$admin,$ip) =
	  split(/\|/,$MessageList{$threadstart});
	$sub =~ s/&pipe;/\|/g;
	print "$sub</STRONG></BIG></BIG>\n";
	$PageCounter = 0;
	foreach $message (@sortedguestbookthread) {
		if ($PaginateGuestbook) {
			if ($FORM{'ListType'} =~ /Reversed/) {
				next if ($message>$messagenumber);
			}
			else {
				next if ($message<$messagenumber);
			}
			$PageCounter++;
			last if ($PageCounter > $PaginateGuestbook);
		}
		&PrintGuestbookDesc($message);
	}
	if ($FirstPage || $PreviousPage || $NextPage || $LastPage) {
		print "$NavBarStart $text{'1005'}:<BR>";
		if ($FirstPage) {
			print "<A HREF=\"$DestinationURL$BBSquery";
			print "read=$FirstPage\"$BBStarget>$text{'1100'}</A>";
			$PrintBar = 1;
		}
		if ($PreviousPage) {
			if ($PrintBar) { print " | "; } 
			print "<A HREF=\"$DestinationURL$BBSquery";
			print "read=$PreviousPage\"$BBStarget>$text{'1101'}</A>";
			$PrintBar = 1;
		}
		if ($NextPage) {
			if ($PrintBar) { print " | "; } 
			print "<A HREF=\"$DestinationURL$BBSquery";
			print "read=$NextPage\"$BBStarget>$text{'1102'}</A>";
			$PrintBar = 1;
		}
		if ($LastPage) {
			if ($PrintBar) { print " | "; } 
			print "<A HREF=\"$DestinationURL$BBSquery";
			print "read=$LastPage\"$BBStarget>$text{'1103'}</A>";
		}
		print "$NavBarEnd\n";
	}
	&Footer($MessageFooterFile,"credits");
}

sub FindStart {
	$threadstart = $_[0];
	local ($date,$sub,$poster,$prev,$next,$count,$admin,$ip) = "";
	($date,$sub,$poster,$prev,$next,$count,$admin,$ip) =
	  split(/\|/,$MessageList{$threadstart});
	if ($prev && ($MessageList{$prev}>0)) {
		&FindStart($prev);
	}
}

sub ThreadGuestbook {
	local (@threadresponses);
	local ($date,$sub,$poster,$prev,$next,$count,$admin,$ip) = "";
	($date,$sub,$poster,$prev,$next,$count,$admin,$ip) =
	  split(/\|/,$MessageList{$_[0]});
	push (@guestbookthread,$_[0]);
	@threadresponses = split(/ /,$next);
	foreach $threadresponse (@threadresponses) {
		next unless ($threadresponse > $_[0]);
		if ($MessageList{$threadresponse}>0) {
			&ThreadGuestbook($threadresponse);
		}
	}
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
	$FORM{'ListType'} = $Cookies{'listtype'};
	$FORM{'password'} = $Cookies{'password'};
}

1;

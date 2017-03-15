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

sub PostForm {
	$SpellCheckerMeta = 1;
	if ($messagenumber > 0) {
		&Header($text{'0003'},$MessageHeaderFile);
	}
	else {
		&Header($text{'0007'},$MessageHeaderFile);
	}
	$navbar = $NavBarStart." <A HREF=\"$DestinationURL$BBSquery\" $BBStargettop>";
	$navbar .= "$text{'0004'}</A>";
	$navbar .= $NavBarEnd;
	print "$navbar";
	if ($printboardname) {
		print "<P ALIGN=CENTER><BIG><STRONG>";
		print "$boardname</STRONG></BIG>\n";
	}
	if ($messagenumber > 0) {
		$subdir = "bbs".int($messagenumber/1000);
		open (FILE,"$dir/$subdir/$messagenumber");
		@message = <FILE>;
		close (FILE);
		&Print_Form($messagenumber);
	}
	else {
		&Print_Form(0);
	}
	print "<P>&nbsp;";
	&Footer($MessageFooterFile,"credits");
}

sub Print_Form {
	unless ($_[0] == -1) {
		if ($ArchiveOnly || ($_[0] && !($AllowResponses))) { return; }
	}
	print "<P><FORM METHOD=POST ACTION=\"$DestinationURL$BBSquery";
	print "post\" TARGET=\"_self\">\n";
	if ($_[0] > 0) {
		print "<INPUT TYPE=HIDDEN NAME=\"followup\" ";
		print "VALUE=\"$_[0]\">\n";
	}
	elsif ($FORM{'followup'}) {
		print "<INPUT TYPE=HIDDEN NAME=\"followup\" ";
		print "VALUE=\"$FORM{'followup'}\">\n";
	}
	print "<P>&nbsp;";
	print "<P><div align=\"center\"><TABLE $tablespec><TR>\n";
	print "<TH COLSPAN=2>$TableCellStart<BIG>";
	if ($_[0] == -1) { print "$text{'1504'}"; }
	elsif ($_[0]) { print "$text{'0003'}"; }
	else { print "$text{'0007'}"; }
	print "</BIG></TH></TR><TR><TD COLSPAN=2>$TableCellStart";
	print "<HR WIDTH=\"75%\" NOSHADE></TR><TR>\n";
	print "<TD ALIGN=RIGHT>$TableCellStart";
	print "<STRONG>$text{'1510'}:</STRONG></TD>";
	print "<TD>$TableInputCellStart";
	if (!($AdminRun) && $LockRemoteUser && $ENV{'REMOTE_USER'}) {
		print "<INPUT TYPE=HIDDEN NAME=\"name\" ";
		print " VALUE=\"$ENV{'REMOTE_USER'}\">";
		print "<STRONG>$ENV{'REMOTE_USER'}</STRONG>";
	}
	else {
		print "<INPUT TYPE=TEXT NAME=\"name\" ";
		print "SIZE=$InputLength MAXLENGTH=$MaxInputLength";
		if ($_[0] == -1) {
			print " VALUE=\"$name\"";
		}
		elsif ($Cookies{'name'}) {
			print " VALUE=\"$Cookies{'name'}\"";
		}
		print ">";
	}
	print "</TD></TR><TR>\n";
	print "<TD ALIGN=RIGHT>$TableCellStart";
	print "<STRONG>$text{'1511'}:</STRONG>";
	print "</TD><TD>$TableInputCellStart<INPUT TYPE=TEXT NAME=\"email\" ";
	print "SIZE=$InputLength MAXLENGTH=100";
	if ($_[0] == -1) {
		print " VALUE=\"$email\"";
	}
	elsif ($Cookies{'email'}) {
		print " VALUE=\"$Cookies{'email'}\"";
	}
	print "></TD></TR><TR>\n";
	print "<TD ALIGN=RIGHT>$TableCellStart";
	print "<STRONG>$text{'1512'}:</STRONG></TD>";
	print "<TD>$TableInputCellStart";
	if (@SubjectPrefixes && ($_[0] < 1)) {
		print "<SELECT NAME=\"subjectprefix\">";
		print "<OPTION VALUE=\"\">$text{'1530'}";
		foreach $subjectprefix (@SubjectPrefixes) {
			print "<OPTION";
			if ($FORM{'subjectprefix'} eq $subjectprefix) {
				print " SELECTED";
			}
			print ">$subjectprefix";
		}
		print "</SELECT><BR>";
	}
	print "<INPUT TYPE=TEXT NAME=\"subject\" ";
	print "SIZE=$InputLength MAXLENGTH=$MaxInputLength";
	if ($_[0] == -1) {
		print " VALUE=\"$subject\"";
	}
	elsif ($_[0]) {
		foreach $line (@message) {
			if ($line =~ /^SUBJECT>(.*)/i) {
				$subject = $1;
				last;
			}
		}
		print " VALUE=\"";
		if (%SmileyCode) {
			foreach $key (keys %SmileyCode) {
				$key2 = $SmileyCode{$key};
				$key2 =~ s/([\[\]\(\)\\\*\+\?\\\|])/\\$1/g;
				$subject =~ s/$key2/$key/g;
			}
		}
		if ($NM_Telltale) {
			$NM_Telltale =~ s/([\[\]\(\)\\\*\+\?\\\|])/\\$1/g;
			$subject =~ s/ $NM_Telltale//g;
		}
		if ($Pic_Telltale) {
			$Pic_Telltale =~ s/([\[\]\(\)\\\*\+\?\\\|])/\\$1/g;
			$subject =~ s/ $Pic_Telltale//g;
		}
		unless ($subject =~ /^$text{'1513'}/) { print "$text{'1513'} "; }
		$subject =~ s/"/&quot;/g;
		print "$subject\"";
	}
	print "></TD></TR><TR>\n";
	print "<TD COLSPAN=2 ALIGN=CENTER>$TableCellStart";
	print "<STRONG>$text{'1514'}:</STRONG>\n";
	print "<BR><TEXTAREA COLS=$InputColumns ROWS=$InputRows ";
	print "NAME=\"body\">";
	if ($_[0] == -1) {
		print "$body";
	}
	elsif ($_[0] && $AutoQuote) {
		$quotedtext = "";
		foreach $line (@message) {
			unless (($line =~ /^SUBJECT>/i)
			  || ($line =~ /^ADMIN>/i)
			  || ($line =~ /^POSTER>/i)
			  || ($line =~ /^EMAIL>/i)
			  || ($line =~ /^DATE>/i)
			  || ($line =~ /^EMAILNOTICES>/i)
			  || ($line =~ /^IP_ADDRESS>/i)
			  || ($line =~ /^<!--/i)
			  || ($line =~ /^PASSWORD>/i)
			  || ($line =~ /^PREVIOUS>/i)
			  || ($line =~ /^NEXT>/i)
			  || ($line =~ /^IMAGE>/i)
			  || ($line =~ /^LINKNAME>/i)
			  || ($line =~ /^LINKURL>/i)
			  || ($line =~ /^<([^>])*>&gt;/i)
			  || ($line =~ /^<([^>])*>$AutoQuoteChar/i)
			  || ($line =~ /^<([^>])*>$/i)) {
				$quotedtext .= $line;
			}
		}
		if (%SmileyCode) {
			foreach $key (keys %SmileyCode) {
				$key2 = $SmileyCode{$key};
				$key2 =~ s/([\[\]\(\)\\\*\+\?\\\|])/\\$1/g;
				$quotedtext =~ s/$key2/$key/g;
			}
		}
		if (%FormatCode) {
			foreach $key (keys %FormatCode) {
				$key2 = $FormatCode{$key};
				$key2 =~ s/([\[\]\(\)\\\*\+\?\\\|])/\\$1/g;
				$quotedtext =~ s/$key2/$key/ig;
			}
		}
		$quotedtext =~ s/\n/ /g;
		$quotedtext =~ s/<P>/\n\n$AutoQuoteChar /g;
		$quotedtext =~ s/<BR>/\n$AutoQuoteChar /g;
		$quotedtext =~ s/$AutoQuoteChar\s*\n*$AutoQuoteChar /$AutoQuoteChar /g;
		$quotedtext =~ s/^\n*//g;
		$quotedtext =~ s/<([^>]|\n)*>/ /g;
		$quotedtext =~ s/\& /\&amp\; /g;
		$quotedtext =~ s/"/\&quot\;/g;
		$quotedtext =~ s/</\&lt\;/g;
		$quotedtext =~ s/>/\&gt\;/g;
		@quotedlines = split(/\n/,$quotedtext);
		foreach $quotedline (@quotedlines) {
			$quotewrap = 0;
			@quotedwords = split(/\s/,$quotedline);
			foreach $quotedword (@quotedwords) {
				$quotewrap += length($quotedword)+1;
				if ($quotewrap > $InputColumns) {
					print "\n$AutoQuoteChar $quotedword ";
					$quotewrap = length($quotedword)+6;
				}
				else {
					print "$quotedword ";
				}
			}
			print "\n";
		}
	}
	print "</TEXTAREA></TD></TR><TR>\n";
	if ($AllowURLs) {
		print "<TD COLSPAN=2 ALIGN=CENTER>$TableCellStart";
		print "$text{'1500'}";
		print "</TD></TR><TR>\n";
		print "<TD ALIGN=RIGHT>$TableCellStart";
		print "<STRONG>$text{'1515'}:</STRONG></TD>";
		print "<TD>$TableInputCellStart<INPUT TYPE=TEXT ";
		print "NAME=\"url\" SIZE=$InputLength MAXLENGTH=250";
		if ($_[0] == -1) {
			print " VALUE=\"$message_url\"";
		}
		elsif ($Cookies{'linkurl'}) {
			print " VALUE=\"$Cookies{'linkurl'}\"";
		}
		else {
			print " VALUE=\"http://\"";
		}
		print "></TD></TR><TR>\n";
		print "<TD ALIGN=RIGHT>$TableCellStart";
		print "<STRONG>$text{'1516'}:</STRONG></TD>";
		print "<TD>$TableInputCellStart<INPUT TYPE=TEXT ";
		print "NAME=\"url_title\" SIZE=$InputLength MAXLENGTH=$MaxInputLength";
		if ($_[0] == -1) {
			print " VALUE=\"$message_url_title\"";
		}
		elsif ($Cookies{'linkname'}) {
			print " VALUE=\"$Cookies{'linkname'}\"";
		}
		print "></TD></TR><TR>\n";
	}
	if ($AllowPics) {
		print "<TD COLSPAN=2 ALIGN=CENTER>$TableCellStart";
		print "$text{'1501'}";
		print "</TD></TR><TR>\n";
		print "<TD ALIGN=RIGHT>$TableCellStart";
		print "<STRONG>$text{'1517'}:</STRONG></TD>";
		print "<TD>$TableInputCellStart<INPUT TYPE=TEXT ";
		print "NAME=\"imageurl\" SIZE=$InputLength MAXLENGTH=250";
		if ($_[0] == -1) {
			print " VALUE=\"$image_url\"";
		}
		elsif ($Cookies{'imageurl'}) {
			print " VALUE=\"$Cookies{'imageurl'}\"";
		}
		else {
			print " VALUE=\"http://\"";
		}
		print "></TD></TR><TR>\n";
	}
	if ($AllowUserDeletion) {
		print "<TD COLSPAN=2 ALIGN=CENTER>$TableCellStart";
		print "$text{'1502'}";
		print "</TD></TR><TR>\n";
	}
	elsif ($UserProfileDir) {
		print "<TD COLSPAN=2 ALIGN=CENTER>$TableCellStart";
		print "$text{'1505'}";
		print "</TD></TR><TR>\n";
	}
	if ($AllowUserDeletion || $UserProfileDir) {
		print "<TD ALIGN=RIGHT>$TableCellStart";
		print "<STRONG>$text{'0205'}:</STRONG></TD>";
		print "<TD>$TableInputCellStart<INPUT TYPE=PASSWORD NAME=\"password\"";
		if ($FORM{'password'}) {
			print " VALUE=\"$FORM{'password'}\"";
		}
		print " SIZE=$InputLength></TD></TR><TR>\n";
	}
	if ($mailprog && $AllowEmailNotices) {
		print "<TD COLSPAN=2 ALIGN=CENTER>$TableCellStart";
		print "$text{'1503'} ";
		print "<INPUT TYPE=CHECKBOX NAME=\"wantnotice\"";
		unless ($Cookies{'wantnotice'} eq "no") {
			print " CHECKED";
		}
		print " VALUE=\"yes\"></TD></TR><TR>\n";
	}
	if ($AdminRun) { &Print_AdminForm; }
	print "<TD COLSPAN=2>$TableCellStart";
	print "<HR WIDTH=\"75%\" NOSHADE></TD></TR><TR>\n";
	print "<TD COLSPAN=2 ALIGN=CENTER>$TableCellStart";
	if ($SpellCheckerID && $SpellCheckerPath) {
		print "<INPUT TYPE=BUTTON VALUE=\"$text{'1552'}\" ";
		print "onclick=\"var f = document.forms[$FormCount]; ";
		print "doSpell( '$SpellCheckerLang', f.body, ";
		print "document.location.protocol + '//' + ";
		print "document.location.host + '$SpellCheckerPath', true);\">"; 
		print "&nbsp;"; 
	}
	if ($AllowPreview) {
		print "<INPUT TYPE=SUBMIT NAME=\"Preview\" ";
		print "VALUE=\"$text{'1550'}\">&nbsp;";
	}
	print "<INPUT TYPE=SUBMIT NAME=\"Post\" ";
	print "VALUE=\"$text{'1551'}\"></TD>";
	print "</TR></TABLE></div></FORM>\n";
	$FormCount++;
}

1;

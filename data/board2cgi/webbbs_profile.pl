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
	if ($ENV{'QUERY_STRING'} =~ /profilesave/i) { &Parse_Profile; }
	else { &Parse_Form; }
	&Initialize_Data;
	if ($ENV{'QUERY_STRING'} =~ /profile=(.*)/i) {
		$UserProfile = $1;
		&UserProfile;
	}
	elsif ($ENV{'QUERY_STRING'} =~ /profileedit=(.*)/i) {
		$Cookies{'name'} = $1;
		$Cookies{'email'} = $Cookies{'imageurl'} = "";
		$Cookies{'linkname'} = $Cookies{'linkurl'} = "";
		$FORM{'password'} = "";
		&EditProfile;
	}
	elsif ($ENV{'QUERY_STRING'} =~ /profileedit/i) {
		&EditProfile;
	}
	elsif ($ENV{'QUERY_STRING'} =~ /profilesave/i) {
		if ($FORM{'Delete'}) { &DeleteProfile; }
		else { &SaveProfile; }
	}
	else {
		&ListProfiles;
	}
}

sub Parse_Profile {
	if ($ENV{'CONTENT_TYPE'} =~ /boundary=(\"?([^\";,]+)\"?)*/) { $boundary = $1; }
	binmode STDIN;
	read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
	@buffer = split(/\r\n/,$buffer);
	foreach $line (@buffer) {
		if ($line =~ /$boundary/) { $Current = ""; next; }
		if ($line =~ /Content-Disposition/) {
			if ($line =~ /^.+name\s*=\s*"*([^\s"]+).+$/) { $Current = $1; }
			$FORM{$Current} = ""; next;
		}
		if ($line =~ /Content-Type/) {
			if ($line =~ /gif/) { $PicType = "GIF"; }
			elsif (($line =~ /jpeg/) || ($line =~ /jpg/)) { $PicType = "JPG"; }
			$Current = "ProfileGraphic"; $FORM{'ProfileGraphic'} = ""; next;
		}
		if (($line eq "")
		  && ($Current ne "ProfileGraphic") && ($Current ne "body")) { next; }
		$FORM{$Current} .= $line;
		if ($Current eq "body") { $FORM{$Current} .= "\n"; }
	}
	if ($NaughtyWordsFile) {
		open (NAUGHTY,"$NaughtyWordsFile");
		@naughtywords = <NAUGHTY>;
		close (NAUGHTY);
	}
	foreach $entry (keys %FORM){
		next if ($entry eq "ProfileGraphic");
		unless (($AllowProfileHTML > 1) && ($entry eq "body")) {
			$FORM{$entry} =~ s/<!--([^>]|\n)*-->/ /g;
		}
		if (($AllowProfileHTML < 1) || ($entry ne "body")) {
			$FORM{$entry} =~ s/<([^>]|\n)*>/ /g;
		}
		$HTMLConvert = 0;
		unless (($AllowProfileHTML eq "1") && ($entry eq "body")) {
			$FORM{$entry} =~ s/\&/\&amp\;/g;
			$FORM{$entry} =~ s/"/\&quot\;/g;
			$FORM{$entry} =~ s/</\&lt\;/g;
			$FORM{$entry} =~ s/>/\&gt\;/g;
			$HTMLConvert = 1;
		}
		if ($entry eq "body") {
			$FORM{$entry} =~ s/\n/<BR>/g;
			$FORM{$entry} = "<P>$FORM{$entry}";
			if ($AutoHotlink) {
				unless ($AllowProfileHTML eq "2") {
					$FORM{$entry} =~ s/\&amp\;/\&/g;
					$FORM{$entry} =~ s/\&quot\;/"/g;
					$FORM{$entry} =~ s/\&lt\;/</g;
					$FORM{$entry} =~ s/\&gt\;/>/g;
					$HTMLConvert = 0;
				}
				$FORM{$entry} =~ s/([ <>])([\w]+:\/\/[\w-?&;,#~=\.\/\@]+[\w\/])/$1<A HREF="$2">$2<\/A>/g;
				$FORM{$entry} =~ s/([ <>])(www\.[\w-?&;,#~=\.\/\@]+[\w\/])/$1<A HREF="http:\/\/$2">$2<\/A>/g;
				$FORM{$entry} =~ s/([ <>])([^\s"<>]+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,3}|[0-9]{1,3})(\]?))/$1<A HREF="mailto:$2">$2<\/A>/g;
			}
			if (%SmileyCode) {
				foreach $key (keys %SmileyCode) {
					$key2 = $key;
					$key2 =~ s/([\[\]\(\)\\\*\+\?\\\|])/\\$1/g;
					if ($HTMLConvert) {
						$key2 =~ s/\&/\&amp\;/g;
						$key2 =~ s/"/\&quot\;/g;
						$key2 =~ s/</\&lt\;/g;
						$key2 =~ s/>/\&gt\;/g;
					}
					$FORM{$entry} =~ s/([ <>])($key2)/$1$SmileyCode{$key}/g;
				}
			}
			if (%FormatCode) {
				foreach $key (keys %FormatCode) {
					$key2 = $key;
					$key2 =~ s/([\[\]\(\)\\\*\+\?\\\|])/\\$1/g;
					if ($HTMLConvert) {
						$key2 =~ s/\&/\&amp\;/g;
						$key2 =~ s/"/\&quot\;/g;
						$key2 =~ s/</\&lt\;/g;
						$key2 =~ s/>/\&gt\;/g;
					}
					$FORM{$entry} =~ s/$key2/$FormatCode{$key}/ig;
				}
			}
			unless ($FORM{$entry} =~ /<pre>/i) {
				$FORM{$entry} =~ s/<BR>\s\s\s+/<BR><BR>/g;
				$FORM{$entry} =~ s/<BR>\t/<BR><BR>/g;
				$FORM{$entry} =~ s/\s+/ /g;
				$FORM{$entry} =~ s/<BR>\s/<BR>/g;
				$FORM{$entry} =~ s/\s<BR>/<BR>/g;
				$FORM{$entry} =~ s/<BR><BR>/<P>/g;
				$FORM{$entry} =~ s/<P><BR>/<P>/g;
				unless ($SingleLineBreaks) {
					$FORM{$entry} =~ s/<BR>/ /g;
				}
			}
		}
		else {
			$FORM{$entry} =~ s/\n/ /g;
		}
		if ($FORM{$entry} =~ /<pre>/i) {
			$FORM{$entry} =~ s/<P>/\n<P>/g;
			$FORM{$entry} =~ s/<BR>/\n<BR>/g;
		}
		else {
			$FORM{$entry} =~ s/\s+/ /g;
			$FORM{$entry} =~ s/^\s+//g;
			$FORM{$entry} =~ s/\s+$//g;
			$FORM{$entry} =~ s/<P>/\n<P>/g;
			$FORM{$entry} =~ s/<BR>/\n<BR>/g;
			$FORM{$entry} =~ s/<P>\n//g;
			$FORM{$entry} =~ s/<BR>\n//g;
		}
		$FORM{$entry} =~ s/^\n//g;
		if ($NaughtyWordsFile) {
			unless (($entry eq "email") || ($entry eq "url") || ($entry eq "imageurl")) {
				if ($CensorPosts) {
					foreach $naughtyword (@naughtywords) {
						chomp ($naughtyword);
						next if (length($naughtyword) < 2);
						$FORM{$entry} =~ s/$naughtyword/#####/ig;
					}
				}
				else {
					foreach $naughtyword (@naughtywords) {
						chomp ($naughtyword);
						next if (length($naughtyword) < 2);
						if ($FORM{$entry} =~ /$naughtyword/) {
							$NaughtyFlag = 1;
						}
					}
				}
			}
		}
	}
}

sub ListProfiles {
	foreach $message (@sortedmessages) {
		$date=$sub=$poster=$prev=$next=$count=$admin=$ip="";
		($date,$sub,$poster,$prev,$next,$count,$admin,$ip) =
		  split(/\|/,$MessageList{$message});
		$poster =~ s/&pipe;/\|/g;
		$Posters{$poster} = 1;
	}
	$ProfileCounter = 0;
	foreach $key (keys %Posters) {
		$ProfileCheck = $key;
		$ProfileCheck =~ s/[^\w\.\-\']/\+/g;
		$ProfileCheck =~ tr/A-Z/a-z/;
		if (-e "$UserProfileDir/$ProfileCheck.txt") {
			unless ($ProfileList{$ProfileCheck}) {
				$ProfileList{$ProfileCheck} = $key;
				$ProfileCounter++;
			}
		}
	}
	&Header($text{'2511'},$MessageHeaderFile);
	&Header2;
	print "<div align=\"center\">\n";
	print "<P><BIG><BIG><STRONG>$text{'2511'}</STRONG></BIG></BIG>\n";
	print "<P><TABLE BORDER=0 CELLSPACING=0 CELLPADDING=3>\n";
	print "<TR><TD VALIGN=TOP>";
	$ColumnSplit = int(($ProfileCounter/2)+.9);
	$ProfileCounter = 0;
	foreach $key (sort keys(%ProfileList)) {
		print "<BR><A HREF=\"$DestinationURL$BBSquery";
		print "profile=$key\" TARGET=\"_blank\"";
		print ">$ProfileList{$key}</A>\n";
		$ProfileCounter++;
		if ($ProfileCounter == $ColumnSplit) {
			print "</TD><TD>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</TD>";
			print "<TD VALIGN=TOP>\n";
			$ColumnSplit = 100000;
		}
	}
	print "</TD></TR></TABLE></div>\n";
	&Footer($MessageFooterFile,"credits");
}

sub UserProfile {
	open (FILE,"$UserProfileDir/$UserProfile.txt") || &Error("9110","9111");
	@message = <FILE>;
	close (FILE);
	($name,$email,$image_url,$linkname,$linkurl) = "";
	foreach $line (@message) {
		if ($line =~ /^NAME>(.*)/i) { $name = $1; }
		elsif ($line =~ /^EMAIL>(.*)/i) { $email = $1; }
		elsif ($line =~ /^IP_ADDRESS>(.*)/i) { $ipaddress = $1; }
		elsif ($line =~ /^<!--(.*)-->/i) { $remoteuser = $1; }
		elsif ($line =~ /^PASSWORD>(.*)/i) { next; }
		elsif ($line =~ /^IMAGE>(.*)/i) { $image_url = $1; }
		elsif ($line =~ /^LINKNAME>(.*)/i) { $linkname = $1; }
		elsif ($line =~ /^LINKURL>(.*)/i) { $linkurl = $1; }
		elsif (!$startup) {
			$startup = 1;
			$title = $text{'2500'};
			&Header($title,$MessageHeaderFile);
			if ($ReturnFromSave) {
				$navbar = $NavBarStart." <A HREF=\"$DestinationURL$BBSquery\"";
				if ($UseFrames) { $navbar .= "$BBStargettop>"; }
				else { $navbar .= ">"; }
				$navbar .= "$text{'0004'}</A>";
				$navbar .= $NavBarEnd;
				print "$navbar";
			}
			if ($printboardname) {
				print "<P ALIGN=CENTER><BIG><STRONG>";
				print "$boardname</STRONG></BIG>\n";
			}
			foreach $message (@sortedmessages) {
				$date=$sub=$poster=$prev=$next=$count=$admin=$ip="";
				($date,$sub,$poster,$prev,$next,$count,$admin,$ip) =
				  split(/\|/,$MessageList{$message});
				$poster =~ s/&pipe;/\|/g;
				if ($poster eq $name) {
					$PosterCount++;
					if ($date > $LastDate) {
						$LastPost = $message;
						$LastDate = $date;
					}
				}
			}
			print "<P ALIGN=CENTER><BIG><STRONG>";
			print "$text{'2500'}</STRONG></BIG>\n";
			print "<P ALIGN=CENTER><BIG><BIG><STRONG>";
			print "$name</STRONG></BIG></BIG>\n";
			if ($AdminRun && (($remoteuser && ($remoteuser ne $poster))
			  || ($DisplayIPs && $ipaddress))) {
				print "<P ALIGN=CENTER><EM>";
				if ($remoteuser && ($remoteuser ne $poster)) {
					print "$remoteuser ";
				}
				if ($DisplayIPs && $ipaddress) {
					print "($ipaddress)";
				}
				print "</EM>\n";
			}
			if ($DisplayEmail && $email) {
				print "<P ALIGN=CENTER>&lt;<A HREF=\"mailto:$email\">";
				print "$email</A>&gt;\n";
			}
			unless ($PosterCount) { $PosterCount = "0"; }
			print "$NavBarStart $text{'2501'} ($boardname): ";
			print "<STRONG>$PosterCount</STRONG>\n";
			unless ($PosterCount eq "0") {
				print "<BR>$text{'2502'}: ";
				print &PrintDate($LastDate),"</A>";
			}
			print "$NavBarEnd\n";
			print "$MessageOpenCode\n";
			print $line;
		}
		else { print $line; }
	}
	print "$MessageCloseCode\n";
	if ($image_url) {
		print "<P ALIGN=CENTER><IMG SRC=\"$image_url\">\n";
	}
	if ($linkurl) {
		print "<P ALIGN=CENTER>";
		print "<EM><A HREF=\"$linkurl\">";
		print "$linkname</A></EM>\n";
	}
	&Footer($MessageFooterFile,"credits");
}

sub EditProfile {
	$SpellCheckerMeta = 1;
	$ProfileCheck = "";
	if ($Cookies{'name'}) {
		$ProfileCheck = $Cookies{'name'};
		$ProfileCheck =~ s/[^\w\.\-\']/\+/g;
		$ProfileCheck =~ tr/A-Z/a-z/;
		if (-e "$UserProfileDir/$ProfileCheck.txt") {
			open (FILE,"$UserProfileDir/$ProfileCheck.txt") || &Error("9110","9111");
			@message = <FILE>;
			close (FILE);
			($name,$email,$image_url,$linkname,$linkurl,$body) = "";
			foreach $line (@message) {
				if ($line =~ /^NAME>(.*)/i) { $Cookies{'name'} = $1; }
				elsif ($line =~ /^EMAIL>(.*)/i) { $email = $1; }
				elsif ($line =~ /^IP_ADDRESS>(.*)/i) { $ipaddress = $1; }
				elsif ($line =~ /^<!--(.*)-->/i) { $remoteuser = $1; }
				elsif ($line =~ /^PASSWORD>(.*)/i) { next; }
				elsif ($line =~ /^IMAGE>(.*)/i) { $image_url = $1; }
				elsif ($line =~ /^LINKNAME>(.*)/i) { $linkname = $1; }
				elsif ($line =~ /^LINKURL>(.*)/i) { $linkurl = $1; }
				else { $body .= $line; }
			}
		}
	}
	&Header($text{'2503'},$MessageHeaderFile);
	$navbar = $NavBarStart." <A HREF=\"$DestinationURL$BBSquery\" $BBStargettop>";
	$navbar .= "$text{'0004'}</A>";
	$navbar .= $NavBarEnd;
	print "$navbar";
	if ($printboardname) {
		print "<P ALIGN=CENTER><BIG><STRONG>";
		print "$boardname</STRONG></BIG>\n";
	}
	print "<P>$text{'2550'}\n";
	if ($UserProfileURL) { print "<P>$text{'2551'}\n"; }
	print "<P><FORM ENCTYPE=\"multipart/form-data\" METHOD=POST ";
	print "ACTION=\"$DestinationURL$BBSquery";
	print "profilesave\" TARGET=\"_self\">\n";
	if ($ipaddress) {
		print "<INPUT TYPE=HIDDEN NAME=\"ipaddress\" ";
		print "VALUE=\"$ipaddress\">\n";
	}
	if ($remoteuser) {
		print "<INPUT TYPE=HIDDEN NAME=\"remote\" ";
		print "VALUE=\"$remoteuser\">\n";
	}
	print "<P>&nbsp;";
	print "<P><div align=\"center\"><TABLE $tablespec><TR>\n";
	print "<TH COLSPAN=2>$TableCellStart<BIG>$text{'2503'}";
	print "</BIG></TH></TR><TR><TD COLSPAN=2>$TableCellStart";
	print "<HR WIDTH=75% NOSHADE></TR><TR>\n";
	print "<TH ALIGN=RIGHT>$TableCellStart";
	print "$text{'1510'}:</TH>";
	print "<TD>$TableInputCellStart";
	if (!($AdminRun) && $LockRemoteUser && $ENV{'REMOTE_USER'}) {
		print "<INPUT TYPE=HIDDEN NAME=\"name\" ";
		print " VALUE=\"$ENV{'REMOTE_USER'}\">";
		print "<STRONG>$ENV{'REMOTE_USER'}</STRONG>";
	}
	else {
		print "<INPUT TYPE=TEXT NAME=\"name\" ";
		print "SIZE=$InputLength MAXLENGTH=$MaxInputLength";
		if ($Cookies{'name'}) { print " VALUE=\"$Cookies{'name'}\""; }
		print ">";
	}
	print "</TD></TR><TR>\n";
	print "<TH ALIGN=RIGHT>$TableCellStart";
	print "$text{'1511'}:";
	print "</TH><TD>$TableInputCellStart<INPUT TYPE=TEXT NAME=\"email\" ";
	print "SIZE=$InputLength MAXLENGTH=100";
	if ($email) { print " VALUE=\"$email\""; }
	elsif ($Cookies{'email'}) { print " VALUE=\"$Cookies{'email'}\""; }
	print "></TD></TR><TR>\n";
	print "<TD COLSPAN=2 ALIGN=CENTER>$TableCellStart";
	print "<STRONG>$text{'2500'}:</STRONG>\n";
	print "<BR><TEXTAREA COLS=$InputColumns ROWS=$InputRows ";
	print "NAME=\"body\" WRAP=VIRTUAL>";
	if (%SmileyCode) {
		foreach $key (keys %SmileyCode) {
			$key2 = $SmileyCode{$key};
			$key2 =~ s/([\[\]\(\)\\\*\+\?\\\|])/\\$1/g;
			$body =~ s/$key2/$key/g;
		}
	}
	if (%FormatCode) {
		foreach $key (keys %FormatCode) {
			$key2 = $FormatCode{$key};
			$key2 =~ s/([\[\]\(\)\\\*\+\?\\\|])/\\$1/g;
			$body =~ s/$key2/$key/ig;
		}
	}
	$body =~ s/\n/ /g;
	$body =~ s/<P>/\n\n/g;
	$body =~ s/<BR>/\n/g;
	$body =~ s/^\n*//g;
	$body =~ s/<([^>]|\n)*>/ /g;
	$body =~ s/\& /\&amp\; /g;
	$body =~ s/"/\&quot\;/g;
	$body =~ s/</\&lt\;/g;
	$body =~ s/>/\&gt\;/g;
	print "$body\n";
	print "</TEXTAREA></TD></TR><TR>\n";
	if ($AllowProfileURLs) {
		print "<TH ALIGN=RIGHT>$TableCellStart";
		print "$text{'1515'}:</TH>";
		print "<TD>$TableInputCellStart<INPUT TYPE=TEXT ";
		print "NAME=\"url\" SIZE=$InputLength MAXLENGTH=250";
		if ($linkurl) { print " VALUE=\"$linkurl\""; }
		elsif ($Cookies{'linkurl'}) { print " VALUE=\"$Cookies{'linkurl'}\""; }
		else { print " VALUE=\"http://\""; }
		print "></TD></TR><TR>\n";
		print "<TH ALIGN=RIGHT>$TableCellStart";
		print "$text{'1516'}:</TH>";
		print "<TD>$TableInputCellStart<INPUT TYPE=TEXT ";
		print "NAME=\"url_title\" SIZE=$InputLength MAXLENGTH=$MaxInputLength";
		if ($linkname) { print " VALUE=\"$linkname\""; }
		elsif ($Cookies{'linkname'}) { print " VALUE=\"$Cookies{'linkname'}\""; }
		print "></TD></TR><TR>\n";
	}
	if ($AllowProfilePics) {
		print "<TH ALIGN=RIGHT>$TableCellStart";
		print "$text{'1517'}:</TH>";
		print "<TD>$TableInputCellStart<INPUT TYPE=TEXT ";
		print "NAME=\"imageurl\" SIZE=$InputLength MAXLENGTH=250";
		if ($image_url) { print " VALUE=\"$image_url\""; }
		elsif ($Cookies{'imageurl'}) { print " VALUE=\"$Cookies{'imageurl'}\""; }
		else { print " VALUE=\"http://\""; }
		print "></TD></TR><TR>\n";
		if ($UserProfileURL) {
			print "<TH ALIGN=RIGHT>$TableCellStart";
			print "$text{'2505'}:</TH>";
			print "<TD>$TableInputCellStart";
			print "<INPUT TYPE=FILE NAME=\"profilegraphic\" SIZE=$InputLength>";
			print "</TD></TR><TR>\n";
		}
	}
	if ($AdminRun && $image_url) {
		print "<TD COLSPAN=2 ALIGN=CENTER>$TableCellStart";
		print "<P ALIGN=CENTER><IMG SRC=\"$image_url\">\n";
		print "</TD></TR><TR>\n";
	}
	$PassBoxSize = int($InputLength/3);
	print "<TH ALIGN=RIGHT>$TableCellStart";
	print "$text{'0205'}:</TH>";
	print "<TD>$TableInputCellStart<INPUT TYPE=PASSWORD NAME=\"password\"";
	if ($FORM{'password'}) { print " VALUE=\"$FORM{'password'}\""; }
	print " SIZE=$PassBoxSize></TD></TR><TR>\n";
	print "<TH ALIGN=RIGHT>$TableCellStart";
	print "$text{'0208'}:</TH>";
	print "<TD>$TableInputCellStart<INPUT TYPE=PASSWORD NAME=\"newpass1\"";
	print " SIZE=$PassBoxSize>&nbsp;<INPUT TYPE=PASSWORD NAME=\"newpass2\"";
	print " SIZE=$PassBoxSize>";
	print "</TD></TR><TR>\n";
	print "<TD COLSPAN=2>$TableCellStart";
	print "<HR WIDTH=75% NOSHADE></TD></TR><TR>\n";
	print "<TD COLSPAN=2 ALIGN=CENTER>$TableCellStart";
	if ($SpellCheckerID && $SpellCheckerPath) {
		print "<INPUT TYPE=BUTTON VALUE=\"$text{'1552'}\" ";
		print "onclick=\"var f = document.forms[$FormCount]; ";
		print "doSpell( '$SpellCheckerLang', f.body, ";
		print "document.location.protocol + '//' + ";
		print "document.location.host + '$SpellCheckerPath', true);\">"; 
		print "&nbsp;"; 
	}
	print "<INPUT TYPE=SUBMIT NAME=\"Post\" ";
	print "VALUE=\"$text{'2503'}\">&nbsp;";
	print "<INPUT TYPE=SUBMIT NAME=\"Delete\" ";
	print "VALUE=\"$text{'2504'}\"></TD>";
	print "</TR></TABLE></div></FORM>\n";
	&Footer($MessageFooterFile,"credits");
}

sub CheckPassword {
	unless ($name) { &Error("9610","9611"); }
	$profilename = $name;
	$profilename =~ s/[^\w\.\-\']/\+/g;
	$profilename =~ tr/A-Z/a-z/;
	if ($FORM{'oldpassword'}) { $CheckPass = $FORM{'oldpassword'}; }
	else { $CheckPass = $FORM{'password'}; }
	unless ($CheckPass) { &Error("9610","9611"); }
	$newpassword = crypt($CheckPass,"aa");
	if (-e "$UserProfileDir/$profilename.txt") {
		$PassCheck = 0;
		$oldpassword = "";
		open (FILE,"$UserProfileDir/$profilename.txt");
		@message = <FILE>;
		close (FILE);
		foreach $line (@message) {
			if ($line =~ /^PASSWORD>(.*)/i) {
				$oldpassword = $1;
				last;
			}
		}
		if ($oldpassword) {
			if ($newpassword eq $oldpassword) {
				$PassCheck = 1;
			}
		}
		unless ($PassCheck == 1) {
			unless (-e "$dir/password.txt") {
				&Error("9610","9611");
			}
			open (PASSWORD, "$dir/password.txt");
			$password = <PASSWORD>;
			close (PASSWORD);
			chop ($password) if ($password =~ /\n$/);
			unless ($newpassword eq $password) {
				&Error("9610","9611");
			}
		}
	}
	if ($FORM{'oldpassword'}) { 
		$newpassword = crypt($FORM{'password'},"aa");
	}
}

sub SaveProfile {
	&CheckPassword;
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
	if ($BannedIPsFile) {
		open (BANNED,"$BannedIPsFile");
		@bannedips = <BANNED>;
		close (BANNED);
		foreach $bannedip (@bannedips) {
			chomp ($bannedip);
			next if (length($bannedip) < 2);
			if (($ENV{'REMOTE_HOST'} =~ /$bannedip/i)
			  || ($ENV{'REMOTE_ADDR'} =~ /$bannedip/i)) {
				&Error("9520","9521");
			}
		}
	}
	if ($NaughtyFlag) {
		&Error("9512","9513");
	}
	if ($FORM{'ProfileGraphic'}) {
		if ($PicType eq "GIF") { $picname = "$profilename.gif"; }
		elsif ($PicType eq "JPG") { $picname = "$profilename.jpg"; }
		else { &Error("9650","9651"); }
		if (length($FORM{'ProfileGraphic'}) > ($MaxGraphicSize*1024)) {
			&Error("9652","9653");
		}	
		unless (open (GRAPHIC,">$UserProfileDir/$picname")) {
			&Error("9654","9655");
		}
		binmode GRAPHIC;
		print GRAPHIC $FORM{'ProfileGraphic'};
		close (GRAPHIC);
		$image_url = "$UserProfileURL/$picname";
	}
	open (FILE,">$UserProfileDir/$profilename.txt") || &Error("9110","9111");
	print FILE "NAME>$name\n";
	print FILE "EMAIL>$email\n";
	if ($AdminRun && $oldpassword) { print FILE "PASSWORD>$oldpassword\n"; }
	else { print FILE "PASSWORD>$newpassword\n"; }
	if ($AdminRun) {
		print FILE "IP_ADDRESS>$FORM{'ipaddress'}\n";
		if ($FORM{'remote'}) {
			print FILE "<!--$FORM{'remote'}-->\n";
		}
	}
	else {
		print FILE "IP_ADDRESS>$ENV{'REMOTE_HOST'}\n";
		if ($ENV{'REMOTE_USER'}) {
			print FILE "<!--$ENV{'REMOTE_USER'}-->\n";
		}
	}
	print FILE "IMAGE>$image_url\n";
	print FILE "LINKNAME>$message_url_title\n";
	print FILE "LINKURL>$message_url\n";
	print FILE "$FORM{'body'}\n";
	close (FILE);
	$UserProfile = $profilename;
	$ReturnFromSave = 1;
	&UserProfile;
}

sub DeleteProfile {
	&CheckPassword;
	unlink "$UserProfileDir/$profilename.txt";
	unlink "$UserProfileDir/$profilename.gif";
	unlink "$UserProfileDir/$profilename.jpg";
	&Header($text{'2600'},$MessageHeaderFile,"refresh");
	&Header2("refresh");
	print "<P ALIGN=CENTER><BIG><BIG><STRONG>$text{'2600'}</STRONG></BIG></BIG>\n";
	print "<P ALIGN=CENTER>$text{'2601'}\n";
	&Footer($MessageFooterFile,"return","refresh");
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
	unless ($FORM{'password'}) { $FORM{'password'} = $Cookies{'password'}; }
	if (($FORM{'newpass1'}) || ($FORM{'newpass2'})) {
		unless ($FORM{'newpass1'} eq $FORM{'newpass2'}) {
			&Error("9602","9603");
		}
		$FORM{'oldpassword'} = $FORM{'password'};
		$FORM{'password'} = $FORM{'newpass1'};
	}
	return if (($ENV{'QUERY_STRING'} !~ /profilesave/i)
	  || $FORM{'Delete'} || $AdminRun);
	$listtype = $Cookies{'listtype'};
	$listtime = $Cookies{'listtime'};
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

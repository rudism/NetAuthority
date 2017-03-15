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
	&Parse_Post;
	&Initialize_Data;
	unless ($shortboardname) { $shortboardname = $boardname; }
	if ($DBMType==2) { dbmclose (%MessageList); }
	else { untie %MessageList; }
	unless ($UseLocking) { &MasterLockOpen; }
	&LockOpen (DBLOCK,"$dir/dblock.txt");
	&MessageDBMWrite;
	&PostMessage;
}

sub Parse_Post {
	if ($NaughtyWordsFile) {
		open (NAUGHTY,"$NaughtyWordsFile");
		@naughtywords = <NAUGHTY>;
		close (NAUGHTY);
	}
	read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
	@pairs = split(/&/, $buffer);
	foreach $pair (@pairs){
		($val1, $val2) = split(/=/, $pair);
		$val1 =~ tr/+/ /;
		$val1 =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$val2 =~ tr/+/ /;
		$val2 =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$val2 =~ s/\cM\n*/\n/g;
		if ($val1 eq "body") {
			$bodytest = 0;
			@bodytext = split(/\n/,$val2);
			foreach $bodyline (@bodytext) {
				next if length($bodyline) < 2;
				next unless (($bodyline !~ /^$AutoQuoteChar/i)
				  || (length($bodyline) > ($InputColumns+1)));
				$bodytest = 1;
				last;
			}
			unless ($bodytest) { $val2 = ""; }
		}
		unless (($AllowHTML > 1) && ($val1 eq "body")) {
			$val2 =~ s/<!--([^>]|\n)*-->/ /g;
		}
		if (($AllowHTML < 1) || ($val1 ne "body")) {
			$val2 =~ s/<([^>]|\n)*>/ /g;
		}
		$HTMLConvert = 0;
		unless (($AllowHTML eq "1") && ($val1 eq "body")) {
			$val2 =~ s/\&/\&amp\;/g;
			$val2 =~ s/"/\&quot\;/g;
			$val2 =~ s/</\&lt\;/g;
			$val2 =~ s/>/\&gt\;/g;
			$HTMLConvert = 1;
		}
		if ($val1 eq "body") {
			$BodyPreview = $val2;
			$val2 =~ s/\n/<BR>/g;
			$val2 = "<P>$val2";
			if ($AutoHotlink) {
				unless ($AllowHTML eq "2") {
					$val2 =~ s/\&amp\;/\&/g;
					$val2 =~ s/\&quot\;/"/g;
					$val2 =~ s/\&lt\;/</g;
					$val2 =~ s/\&gt\;/>/g;
					$HTMLConvert = 0;
				}
				$val2 =~ s/([ <>])([\w]+:\/\/[\w-?&;,#~=\.\/\@]+[\w\/])/$1<A HREF="$2">$2<\/A>/g;
				$val2 =~ s/([ <>])(www\.[\w-?&;,#~=\.\/\@]+[\w\/])/$1<A HREF="http:\/\/$2">$2<\/A>/g;
				$val2 =~ s/([ <>])([^\s"<>]+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,3}|[0-9]{1,3})(\]?))/$1<A HREF="mailto:$2">$2<\/A>/g;
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
					$val2 =~ s/([ <>])($key2)/$1$SmileyCode{$key}/g;
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
					$val2 =~ s/$key2/$FormatCode{$key}/ig;
				}
			}
			unless ($val2 =~ /<pre>/i) {
				$val2 =~ s/<BR>\s\s\s+/<BR><BR>/g;
				$val2 =~ s/<BR>\t/<BR><BR>/g;
				$val2 =~ s/\s+/ /g;
				$val2 =~ s/<BR>\s/<BR>/g;
				$val2 =~ s/\s<BR>/<BR>/g;
				$val2 =~ s/<BR><BR>/<P>/g;
				$val2 =~ s/<P><BR>/<P>/g;
				unless ($SingleLineBreaks) {
					$val2 =~ s/<BR>$AutoQuoteChar/<BRR>/g;
					$val2 =~ s/<BR>&gt;/<BRR>/g;
					$val2 =~ s/<BR>>/<BRR>/g;
					$val2 =~ s/<BR>/ /g;
					$val2 =~ s/<BRR>/<BR>$AutoQuoteChar/g;
				}
			}
		}
		else {
			$val2 =~ s/\n/ /g;
		}
		if ($val2 =~ /<pre>/i) {
			$val2 =~ s/<P>/\n<P>/g;
			$val2 =~ s/<BR>/\n<BR>/g;
		}
		else {
			$val2 =~ s/\s+/ /g;
			$val2 =~ s/^\s+//g;
			$val2 =~ s/\s+$//g;
			$val2 =~ s/<P>/\n<P>/g;
			$val2 =~ s/<BR>/\n<BR>/g;
			$val2 =~ s/<P>\n//g;
			$val2 =~ s/<BR>\n//g;
		}
		$val2 =~ s/^\n//g;
		if ($NaughtyWordsFile) {
			unless (($val1 eq "email") || ($val1 eq "url") || ($val1 eq "imageurl")) {
				if ($CensorPosts) {
					foreach $naughtyword (@naughtywords) {
						chomp ($naughtyword);
						next if (length($naughtyword) < 2);
						$val2 =~ s/$naughtyword/#####/ig;
					}
				}
				else {
					foreach $naughtyword (@naughtywords) {
						chomp ($naughtyword);
						next if (length($naughtyword) < 2);
						if ($val2 =~ /$naughtyword/) {
							$NaughtyFlag = 1;
						}
					}
				}
			}
		}
		if ($FORM{$val1}) { $FORM{$val1} = "$FORM{$val1} $val2"; }
		else { $FORM{$val1} = $val2; }
	}
}

sub PostMessage {
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
	if ($ArchiveOnly
	  || ($FORM{'followup'} && !($AllowResponses))
	  || (!($FORM{'followup'}) && !($AllowNewThreads))) {
		&Error("9520","9521");
	}
	if ($BannedIPsFile) {
		open (BANNED,"$BannedIPsFile");
		@bannedips = <BANNED>;
		close (BANNED);
		foreach $bannedip (@bannedips) {
			chomp ($bannedip);
			next if (length($bannedip) < 2);
			if (($ENV{'REMOTE_HOST'} =~ /$bannedip/i)
			  || ($ENV{'REMOTE_ADDR'} =~ /$bannedip/i)) {
				if ($BanLevel == 1) {
					$Moderated = 1;
					$email_list = 1;
				}
				else {
					&Error("9520","9521");
				}
			}
		}
	}
	if ($FORM{'followup'}) { $followup = "$FORM{'followup'}"; }
	if ($FORM{'subject'}) { $subject = "$FORM{'subject'}"; }
	$subject =~ s/\&quot\;/"/g;
	$subject =~ s/\&lt\;/</g;
	$subject =~ s/\&gt\;/>/g;
	$subject =~ s/\&amp\;/\&/g;
	$subject = substr($subject,0,$MaxInputLength);
	if ($subject && (%SmileyCode || $NM_Telltale || $Pic_Telltale)) {
		$realsubject = $subject;
		if (%SmileyCode) {
			foreach $key (keys %SmileyCode) {
				$key2 = $key;
				$key2 =~ s/([\[\]\(\)\\\*\+\?\\\|])/\\$1/g;
				$subject =~ s/(^$key2)|([ \n]$key2)/ $SmileyCode{$key}/g;
			}
		}
		if ($NM_Telltale && (length($FORM{'body'})<4) && !($message_url)) {
			$subject .= " $NM_Telltale";
		}
		if ($Pic_Telltale && $image_url) {
			$subject .= " $Pic_Telltale";
		}
	}
	else {
		$subject =~ s/\&/\&amp\;/g;
		$subject =~ s/>/\&gt\;/g;
		$subject =~ s/</\&lt\;/g;
		$subject =~ s/"/\&quot\;/g;
	}
	if (@SubjectPrefixes && !($followup)) {
		if ($FORM{'subjectprefix'}) {
			$subject = $FORM{'subjectprefix'}." ".$subject;
		}
		else { $subject = ""; }
	}
	if ($FORM{'body'}) { $body = "$FORM{'body'}"; }
	if ($NaughtyFlag) {
		&Error("9510","9511");
	}
	$profilename = $name;
	$profilename =~ s/[^\w\.\-\']/\+/g;
	$profilename =~ tr/A-Z/a-z/;
	if (-e "$UserProfileDir/$profilename.txt") {
		if ($FORM{'password'}) {
			$password = crypt($FORM{'password'},"aa");
			open (FILE,"$UserProfileDir/$profilename.txt") || &Error("9110","9111");
			@profile = <FILE>;
			close (FILE);
			foreach $line (@profile) {
				if ($line =~ /^PASSWORD>(.*)/i) { $profilepassword = $1; last; }
			}
		}
		else { &Error("9120","9121"); }
		if ($profilepassword) {
			unless ($password eq $profilepassword) {
				&Error("9120","9121");
			}
		}
	}
	unless ($name && $subject) { &Error("9200","9201"); }
	if (length($body) > ($MaxMessageSize*1024)) {
		&Error("9250","9251");
	}
	if ($FORM{'Preview'}) {
		&PreviewPost;
	}
	$new_body =
	  $name.$email.$subject.$body.$image_url.$message_url_title.$message_url;
	$new_body =~ s/\n/ /g;
	unless (-w "$dir") { &Error("9410","9411"); }
	open (DUPEDATA,"$dir/dupecheck.txt");
	$last_body = <DUPEDATA>;
	close (DUPEDATA);
	if ($last_body eq $new_body) { &Error("9500","9501"); }
	else {
		open (DUPEDATA,">$dir/dupecheck.txt");
		print DUPEDATA "$new_body";
		close (DUPEDATA);
	}
	unless (-e "$dir/data.txt") {
		open (NUMBER,">$dir/data.txt");
		print NUMBER "0";
		close (NUMBER);
	}
	&LockOpen (NUMBER,"$dir/data.txt");
	$num = <NUMBER>;
	$num++;
	seek (NUMBER, 0, 0);
	print NUMBER "$num";
	truncate (NUMBER, tell(NUMBER));
	&LockClose (NUMBER,"$dir/data.txt");
	$subdir = "bbs".int($num/1000);
	unless (-d "$dir/$subdir") {
		mkdir ("$dir/$subdir",0777);
		chmod 0777,"$dir/$subdir";
	}
	if ($Moderated) {
		$num = "$num.tmp";
	}
	open (MESSAGE,">$dir/$subdir/$num") || &Error("9400","9401","$dir/$subdir/$num");
	print MESSAGE "SUBJECT>$subject\n";
	print MESSAGE "POSTER>$name\n";
	print MESSAGE "EMAIL>$email\n";
	print MESSAGE "DATE>$todaydate\n";
	unless ($FORM{'wantnotice'}) {
		print MESSAGE "EMAILNOTICES>no\n";
	}
	print MESSAGE "IP_ADDRESS>$ENV{'REMOTE_HOST'}\n";
	if ($ENV{'REMOTE_USER'}) {
		print MESSAGE "<!--$ENV{'REMOTE_USER'}-->\n";
	}
	if ($FORM{'password'}) {
		$password = crypt($FORM{'password'},"aa");
		print MESSAGE "PASSWORD>$password\n";
	}
	print MESSAGE "PREVIOUS>$followup\n";
	print MESSAGE "NEXT>\n";
	print MESSAGE "IMAGE>$image_url\n";
	print MESSAGE "LINKNAME>$message_url_title\n";
	print MESSAGE "LINKURL>$message_url\n";
	print MESSAGE "$body\n";
	close (MESSAGE);
	unless ($Moderated) {
		%wordlist = ();
		@words = ();
		&LockOpen (SEARCH,"$dir/searchterms.idx","a");
		print SEARCH "$num ";
		$line = "$subject $name $body";
		$line =~ s/<([^>]|\n)*>/ /g;
		$line =~ s/&[^;\s]*;/ /g;
		$line =~ s/[^\w\.\-\']/ /g;
		$line =~ s/(\s)+/ /g;
		$line =~ tr/A-Z/a-z/;
		@words = split (/\s/,$line);
		foreach $word (@words) {
			next if ($wordlist{$word});
			$wordlist{$word} = 1;
			print SEARCH "$word ";
		}
		print SEARCH "\n";
		&LockClose (SEARCH,"$dir/searchterms.idx");
	}
	if ($followup) {
		if ($Moderated) {
			$fudate=$fusub=$fuposter=$fuprev=$funext=$fucount=$fuadmin=$fuip="";
			($fudate,$fusub,$fuposter,$fuprev,$funext,$fucount,$fuadmin,$fuip) =
			  split(/\|/,$MessageList{$followup});
		}
		else {
			$subdir = "bbs".int($followup/1000);
			open (FOLLOWUP,"$dir/$subdir/$followup");
			@followup_lines = <FOLLOWUP>;
			close (FOLLOWUP);
			open (FOLLOWUP,">$dir/$subdir/$followup");
			foreach $line (@followup_lines) {
				chop $line;
				if ($line =~ /^EMAILNOTICES>/i) {
					$fuwantnotice = "no";
				}
				elsif ($line =~ /^EMAIL>(.*)/i) {
					$fuemail = $1;
				}
				if ($line =~ /^NEXT>/) {
					print FOLLOWUP "$line $num\n";
				}
				else {
					print FOLLOWUP "$line\n";
				}
			}
			close (FOLLOWUP);
			$fudate=$fusub=$fuposter=$fuprev=$funext=$fucount=$fuadmin=$fuip="";
			($fudate,$fusub,$fuposter,$fuprev,$funext,$fucount,$fuadmin,$fuip) =
			  split(/\|/,$MessageList{$followup});
			$funext .= " $num";
			delete ($MessageList{$followup});
			foreach $key ($fudate,$fusub,$fuposter,$fuprev,$funext,$fucount,$fuadmin,$fuip) {
				$MessageList{$followup} .= "$key|";
			}
		}
		$fusub =~ s/&pipe;/\|/g;
		$fuposter =~ s/&pipe;/\|/g;
	}
	if ($mailprog) {
		$FORM{'subject'} = &UnWebify($FORM{'subject'});
		$FORM{'subject'} = substr($FORM{'subject'},0,50);
		$FORM{'name'} = &UnWebify($FORM{'name'});
		$FORM{'name'} = substr($FORM{'name'},0,15);
		$FORM{'body'} .= "\n";
		$FORM{'body'} = &UnWebify($FORM{'body'});
		$message_url_title = &UnWebify($message_url_title);
		if ($Moderated) {
			$body = $text{'7005'}."\n\n".$text{'7001'}."\n\n";
		}
		else {
			$body = $text{'7000'}."\n\n".$text{'7001'}."\n\n";
		}
		$body .= "$text{'7600'} (#$num) $FORM{'subject'}\n";
		unless ($Moderated) {
			$body .= "$text{'7603'} <$cgiurl?rev=$num>\n";
		}
		$body .= "$text{'7601'} $FORM{'name'}";
		$body .= "\n";
		$body .= "$text{'7602'} ";
		$body .= &PrintDate($todaydate)."\n\n";
		if ($followup) {
			$subjectfu = &UnWebify($fusub);
			$subjectfu = substr($subjectfu,0,50);
			$posterfu = &UnWebify($fuposter);
			$posterfu = substr($posterfu,0,15);
			$body .= "$text{'7604'} (#$followup) $subjectfu\n";
			$body .= "$text{'7605'} $posterfu\n";
			$body .= "$text{'7606'} ";
			$body .= &PrintDate($fudate)."\n\n";
		}
		unless ($HeaderOnly) {
			$body .= $FORM{'body'}."\n";
			if ($message_url && $message_url_title) {
				$body .= "$text{'7607'} $message_url_title\n";
				$body .= "$text{'7608'} <$message_url>\n\n";
			}
		}
		$body .= $text{'7001'}."\n\n".$text{'7002'};
		unless ($ArchiveOnly) {
			$body .= "  ".$text{'7003'};
		}
		$body .= "\n\n";
		@bodylines = split(/\n/,$body);
		$body = "";
		foreach $bodyline (@bodylines) {
			if ($bodyline =~ /^\./) {
				$bodyline = ".".$bodyline;
			}
			$quotewrap = 0;
			@quotedwords = split(/\s/,$bodyline);
			foreach $quotedword (@quotedwords) {
				$quotewrap += length($quotedword)+1;
				if ($quotewrap > 79) {
					if ($quotedword =~ /^\./) {
						$body .= "\n.$quotedword ";
					}
					else {
						$body .= "\n$quotedword ";
					}
					$quotewrap = length($quotedword)+1;
				}
				else {
					$body .= "$quotedword ";
				}
			}
			$body .= "\n";
		}
		$bcc = "";
		if ($Moderated) {
			&SendMail("");
		}
		else {
			if (($email_list == 1) || $private_list) {
				if (-e "$dir/addresses.txt") {
					open (ADDRESSES,"$dir/addresses.txt");
					@addresses = <ADDRESSES>;
					close (ADDRESSES);
					foreach $address (@addresses) {
						chop $address;
						unless (($address =~
						  /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)|,|;/
						  || $address !~
						  /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,3}|[0-9]{1,3})(\]?)$/)
						  || ($email && ($address =~ /$email/i))
						  || ($fuemail
						  && ($address =~ /$fuemail/i))) {
							$bcc .= ", ".$address;
						}
						if ($fuemail
						  && ($address =~ /$fuemail/i)) {
							$onrecipientlist = 1;
						}
					}
					$bcc =~ s/^, //;
				}
				&SendMail("");
			}
			if ($fuemail) {
				$bcc = "";
				unless ((($fuwantnotice eq "no")
				  && !$onrecipientlist)
				  || ($fuemail eq $email)) {
					&SendMail($fuemail);
				}
			}
		}
	}
	$next = "";
	$count = "";
	unless ($FORM{'Admin'} eq "AdminPost") { $FORM{'Admin'} = ""; }
	delete ($MessageList{$num});
	unless ($Moderated) {
		$subject =~ s/\|/&pipe;/g;
		$name =~ s/\|/&pipe;/g;
		foreach $key ($todaydate,$subject,$name,$followup,$next,$count,$FORM{'Admin'},$ENV{'REMOTE_HOST'}) {
			$MessageList{$num} .= "$key|";
		}
	}
	if ($Moderated) { &Header($text{'1600'},$MessageHeaderFile,"refreshalways"); }
	else { &Header($text{'1600'},$MessageHeaderFile,"refreshalways","$num"); }
	$navbar = $NavBarStart;
	if ($UseFrames) {
		if ($Moderated) {
			$navbar .= "<A HREF=\"$DestinationURL$BBSquery\" $BBStargettop>";
			$navbar .= "$text{'0004'}</A>";
		}
		else {
			$navbar .= " <A HREF=\"$DestinationURL$BBSquery";
			$navbar .= "review=$num\" $BBStargettop>$text{'0004'} / ";
			$navbar .= "$text{'0011'}</A>";
		}
	}
	else {
		unless ($Moderated) {
			$navbar .= " <A HREF=\"$DestinationURL$BBSquery";
			$navbar .= "read=$num\">$text{'0011'}</A> |";
		}
		$navbar .= " <A HREF=\"$DestinationURL$BBSquery#$num\">";
		$navbar .= "$text{'0004'}</A>";
	}
	$navbar .= $NavBarEnd;
	print "$navbar";
	if ($printboardname) {
		print "<P ALIGN=CENTER><BIG><STRONG>";
		print "$boardname</STRONG></BIG>\n";
	}
	print "<P ALIGN=CENTER><BIG><BIG><STRONG>";
	print "$text{'1600'}</STRONG></BIG></BIG>\n";
	if ($ShowPosterIP) {
		print "<P ALIGN=CENTER>\n<EM>\n<SMALL>$text{'1602'}: $ENV{'REMOTE_ADDR'}";
		unless ($ENV{'REMOTE_HOST'} eq $ENV{'REMOTE_ADDR'}) {
			$ENV{'REMOTE_HOST'} =~ s/[^\.]*\.(.*)/$1/;
			print "<BR>$text{'1603'}: $ENV{'REMOTE_HOST'}";
		}
		print "</SMALL>\n</EM>\n";
	}
	print "<P ALIGN=CENTER>$text{'1601'}\n";
	if ($Moderated) {
		print "<P ALIGN=CENTER>$text{'1700'}\n";	
	}
	&Footer($MessageFooterFile,"return","refreshalways");
}

sub PreviewPost {
	$SpellCheckerMeta = 1;
	&Header($text{'2000'},$MessageHeaderFile);
	&Header2;
	print "<P ALIGN=CENTER><BIG><BIG><STRONG>$text{'2000'}</STRONG></BIG></BIG><P>$text{'2001'}\n";
	print "<P ALIGN=CENTER><BIG><BIG><STRONG>";
	print "$subject</STRONG></BIG></BIG>\n";
	print "<P ALIGN=CENTER><STRONG>";
	print "$text{'1000'}: <BIG>$name</BIG>";
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
		print "$email</A>&gt;</STRONG>";
	}
	print "\n";
	print "<BR>$text{'1001'}: ",&PrintDate($todaydate),"\n";
	if ($MessageList{$followup}>0) {
		$pdate=$psub=$pposter=$pprev=$pnext=$pcount=$padmin=$pip="";
		($pdate,$psub,$pposter,$pprev,$pnext,$pcount,$padmin,$pip) =
		  split(/\|/,$MessageList{$followup});
		$psub =~ s/&pipe;/\|/g;
		$pposter =~ s/&pipe;/\|/g;
		print "<P ALIGN=CENTER><STRONG><EM>$text{'1002'}: ";
		print "<A HREF=\"$DestinationURL$BBSquery";
		print "read=$followup\"$BBStarget>";
		print "$psub</A> ";
		print "($pposter)</EM>\n";
	}
	print "</STRONG>$MessageOpenCode\n";
	print "$body$MessageCloseCode\n";
	if ($image_url) {
		print "<P ALIGN=CENTER>";
		print "<IMG SRC=\"$image_url\">\n";
	}
	if ($message_url) {
		print "<P ALIGN=CENTER>";
		print "<EM><A HREF=\"$message_url\" ";
		print "TARGET=\"_blank\">";
		print "$message_url_title</A></EM>\n";
	}
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
	&Footer($MessageFooterFile,"credits");
}

sub UnWebify {
	$texttoconvert = $_[0];
	$texttoconvert =~ s/<P>/\n\n/g;
	$texttoconvert =~ s/<[^>]*\s+ALT\s*=\s*"(([^>"])*)"[^>]*>/$1/ig;
	$texttoconvert =~ s/<([^>]|\n)*>//g;
	$texttoconvert =~ s/\&quot\;/"/g;
	$texttoconvert =~ s/\&lt\;/</g;
	$texttoconvert =~ s/\&gt\;/>/g;
	$texttoconvert =~ s/\&amp\;/\&/g;
	$texttoconvert =~ s/\n(\n)+/\n\n/g;
	$texttoconvert =~ s/^\n*//g;
	$texttoconvert =~ s/\n+$/\n/g;
	return $texttoconvert;
}

sub SendMail {
	if ($Moderated && !($AdminRun)) { $ModMail = 1; }
	local($To) = $_[0];
	if ($ModMail || !($To)) { $To = $notification_address; }
	return unless $To;
	if ($ModMail) { $email_subject = $text{'0703'}; }
	else { $email_subject = $FORM{'subject'}; }
	if ($mailprog eq "SMTP") {
		unless ($WEB_SERVER) { $WEB_SERVER = $ENV{'SERVER_NAME'}; }
		if (!$WEB_SERVER) { &Error("9450","9451"); }
		unless ($SMTP_SERVER) {
			$SMTP_SERVER = "smtp.$WEB_SERVER";
			$SMTP_SERVER =~ s/^smtp\.[^.]+\.([^.]+\.)/smtp.$1/;
		}
		local($AF_INET) = ($] > 5 ? AF_INET : 2);
		local($SOCK_STREAM) = ($] > 5 ? SOCK_STREAM : 1);
		$, = ', ';
		$" = ', ';
		local($local_address) = (gethostbyname($WEB_SERVER))[4];
		local($local_socket_address) = pack('S n a4 x8', $AF_INET, 0, $local_address);
		local($server_address) = (gethostbyname($SMTP_SERVER))[4];
		local($server_socket_address) = pack('S n a4 x8', $AF_INET, '25', $server_address);
		local($protocol) = (getprotobyname('tcp'))[2];
		if (!socket(SMTP, $AF_INET, $SOCK_STREAM, $protocol)) { &Error("9450","9451"); }
		bind(SMTP, $local_socket_address);
		if (!(connect(SMTP, $server_socket_address))) { &Error("9450","9451"); }
		local($old_selected) = select(SMTP); 
		$| = 1; 
		select($old_selected);
		$* = 1;
		select(undef, undef, undef, .75);
		sysread(SMTP, $_, 1024);
		print SMTP "HELO $WEB_SERVER\r\n";
		sysread(SMTP, $_, 1024);
		while (/(^|(\r?\n))[^0-9]*((\d\d\d).*)$/g) { 
			$status = $4;
			$message = $3;
		}
		if ($status != 250) { &Error("9450","9451"); }
		print SMTP "MAIL FROM:<$maillist_address>\r\n";
		sysread(SMTP, $_, 1024);
		if (!/[^0-9]*250/) { &Error("9450","9451"); }
		local($good_addresses) = 0;
		$To = "<$To>";
		print SMTP "RCPT TO:$To\r\n";
		sysread(SMTP, $_, 1024);
		/[^0-9]*(\d\d\d)/;
		if ($1 eq '250') { $good_addresses++; }
		if ($bcc) {
			local(@bcc) = split(/, */, $bcc);
			foreach $address (@bcc) {
				if ($address) {
					$address = "<$address>";
					print SMTP "RCPT TO:$address\r\n";
					sysread(SMTP, $_, 1024);
					/[^0-9]*(\d\d\d)/;
					if ($1 eq '250') { $good_addresses++; }
				}
			}
		}
		if (!$good_addresses) { &Error("9450","9451"); }
		print SMTP "DATA\r\n";
		sysread(SMTP, $_, 1024);
		if (!/[^0-9]*354/) { &Error("9450","9451"); }
		print SMTP "To: $To\r\n";
		print SMTP "From: $maillist_address\r\n";
		print SMTP "Return-Path: $maillist_address\r\n";
		if ($ModMail && $email) {
			print SMTP "Reply-To: $email\r\n";
		}
		else {
			print SMTP "Reply-To: PleaseRespond\@TheBulletinBoard\r\n";
		}
		print SMTP "Subject: [$shortboardname:] $email_subject\r\n\r\n";
		print SMTP "$body";
		print SMTP "\r\n\r\n.\r\n";
		sysread(SMTP, $_, 1024);
		shutdown(SMTP, 2);
	}
	elsif ($mailprog eq "libnet"){
		$smtp = Net::SMTP->new("$SMTP_SERVER");
		$smtp->mail( "$maillist_address");
		$smtp->to("$To");
		if ($bcc) {
			local(@bcc) = split(/, */, $bcc);
			foreach $address (@bcc) {
				if ($address) {
					$address = "<$address>";
					$smtp->to("$address");
				}
			}
		}
		$smtp->data();
		$smtp->datasend("To: $To\n");
		$smtp->datasend("From: $maillist_address\n");
		$smtp->datasend("Return-Path: $maillist_address\n");
		if ($ModMail && $email) {
			$smtp->datasend("Reply-To: $email\n");
		}
		else {
			$smtp->datasend("Reply-To: PleaseRespond\@TheBulletinBoard\n");
		}
		$smtp->datasend("Subject: [$shortboardname:] $email_subject\n\n");
		$smtp->datasend("$body");
		$smtp->quit;
	}
	elsif ($mailprog) {
		open (MAIL, "|$mailprog -t") || &Error("9450","9451");
		print MAIL "To: $To\n";
		if ($bcc) { print MAIL "Bcc: $bcc\n"; }
		print MAIL "From: $maillist_address\n",
		  "Return-Path: $maillist_address\n";
		if ($ModMail && $email) {
			print MAIL "Reply-To: $email\n";
		}
		else {
			print MAIL "Reply-To: PleaseRespond\@TheBulletinBoard\n";
		}
		print MAIL "Subject: [$shortboardname:] $email_subject\n\n",
		  "$body";
		close (MAIL);
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
	unless ($FORM{'password'}) { $FORM{'password'} = $Cookies{'password'}; }
	unless ($FORM{'wantnotice'}) { $Cookies{'wantnotice'} = "no"; }
	else { $Cookies{'wantnotice'} = "yes"; }
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

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

sub Rebuild_Database {
	&LockOpen (NEWDBLOCK,"$dir/newdblock.txt");
	opendir (MESSAGES,$dir);
	@messagedir = readdir(MESSAGES);
	closedir (MESSAGES);
	foreach $message (@messagedir) {
		if ($message =~ /^newmessagelist/) {
			unlink "$dir/$message";
		}
	}
	if ($DBMType==1) {
		tie (%NewMessageList,'AnyDBM_File',"$dir/newmessagelist",O_RDWR|O_CREAT,0666,$DB_HASH)
		  || &Error("9150","9151");
	}
	elsif ($DBMType==2) {
		dbmopen(%NewMessageList,"$dir/newmessagelist",0666)
		  || &Error("9150","9151");
	}
	else {
		tie (%NewMessageList,'AnyDBM_File',"$dir/newmessagelist",O_RDWR|O_CREAT,0666)
		  || &Error("9150","9151");
	}
	%MonthToNumber =
	  ('Jan',1,'Feb',2,'Mar',3,'Apr',4,'May',5,'Jun',6,
	  'Jul',7,'Aug',8,'Sep',9,'Oct',10,'Nov',11,'Dec',12);
	%day_counts =
	  (1,0,2,31,3,59,4,90,5,120,6,151,7,181,
	  8,212,9,243,10,273,11,304,12,334);
	opendir (MESSAGES,$dir);
	@messagedir = readdir(MESSAGES);
	closedir (MESSAGES);
	@messagecount = ();
	@physicalmessages = ();
	%is_real = ();
	foreach $message (@messagedir) {
		next if ($message =~ /^\./);
		if ((-d "$dir/$message") && ($message =~ /^bbs\d+/)) {
			opendir (COUNT,"$dir/$message");
			push (@messagecount,readdir(COUNT));
			closedir (COUNT);
		}
		else {
			push (@messagecount,"$message");
		}
	}
	foreach $message (@messagecount) {
		unless (($message =~ /\.tmp$/) || ($message == 0)) {
			push (@physicalmessages,$message);
			$is_real{$message} = 1;
			$subdir = "bbs".int($message/1000);
			unless (-d "$dir/$subdir") {
				mkdir ("$dir/$subdir",0777);
				chmod 0777,"$dir/$subdir";
			}
			unless (-e "$dir/$subdir/$message") {
				rename ("$dir/$message","$dir/$subdir/$message");
			}
		}
	}
	if (-e "$dir/messages.idx") {
		open (INDEX,"$dir/messages.idx");
		while (<INDEX>) {
			chop;
			if (($message,$timestamp,$sub,$poster,$date,$prev,$next,$count,$admin,$ip) =
			  split(/\|/)) {
			  	$count = "";
				unless (($date =~ /^\d+$/)
				  && ($date > 500000000) && ($date < 1500000000)) {
					&ConvertOldDate;
				}
				unless ($admin eq "AdminPost") { $admin = ""; }
				foreach $key ($date,$sub,$poster,$prev,$next,$count,$admin,$ip) {
					$NewMessageList{$message} .= "$key|";
					if ($message>$lastmessage) { $lastmessage = $message; }
				}
			}
		}
		close (INDEX);
		unlink "$dir/messages.idx";
		while (($key,$value) = each(%NewMessageList)) {
			unless ($is_real{$key}>0) {
				delete ($NewMessageList{$key});
			}
		}
	}
	open (SEARCH,"$dir/searchterms.idx");
	while (<SEARCH>) { if (/^(\d+) /) { $searched{$1}=1; } }
	close (SEARCH);
	&LockOpen (SEARCH,"$dir/searchterms.idx","a");
	foreach $message (@physicalmessages) {
		next if ($NewMessageList{$message} && $searched{$message});
		unless ($searched{$message}) { print SEARCH "$message "; }
		$subdir = "bbs".int($message/1000);
		open (FILE,"$dir/$subdir/$message");
		@message = <FILE>;
		close (FILE);
		%wordlist = ();
		$firstline = 0;
		$date=$sub=$poster=$prev=$next=$count=$admin=$ip="";
		foreach $line (@message) {
			@words = ();
			if ($line =~ /^SUBJECT>(.*)/i) { $sub=$1; }
			elsif ($line =~ /^ADMIN>(.*)/i) { $admin=$1; }
			elsif ($line =~ /^POSTER>(.*)/i) { $poster=$1; }
			elsif ($line =~ /^EMAIL>/i) { next; }
			elsif ($line =~ /^DATE>(.*)/i) { $date=$1; }
			elsif ($line =~ /^EMAILNOTICES>/i) { next; }
			elsif ($line =~ /^IP_ADDRESS>(.*)/i) { $ip=$1; }
			elsif ($line =~ /^<!--/i) { next; }
			elsif ($line =~ /^PASSWORD>/i) { next; }
			elsif ($line =~ /^PREVIOUS>(.*)/i) { $prev=$1; }
			elsif ($line =~ /^NEXT>(.*)/i) { $next=$1; }
			elsif ($line =~ /^IMAGE>/i) { next; }
			elsif ($line =~ /^LINKNAME>/i) { next; }
			elsif ($line =~ /^LINKURL>/i) { next; }
			else {
				last if ($searched{$message});
				chop $line;
				unless ($firstline) {
					$line = "$sub $poster $line";
					$firstline = 1;
				}
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
			}
		}
		unless ($searched{$message}) { print SEARCH "\n"; }
		next if ($NewMessageList{$message});
		unless (($date =~ /^\d+$/)
		  && ($date > 500000000) && ($date < 1500000000)) {
			&ConvertOldDate;
		}
		unless ($admin eq "AdminPost") { $admin = ""; }
		unless ($sub) {
			unlink "$dir/$subdir/$message";
			$is_real{$message} = 0;
			next;
		}
		foreach $key ($date,$sub,$poster,$prev,$next,$count,$admin,$ip) {
			$sub =~ s/\|/&pipe;/g;
			$poster =~ s/\|/&pipe;/g;
			$NewMessageList{$message} .= "$key|";
		}
		if ($message>$lastmessage) { $lastmessage = $message; }
	}
	if (%CountList) {
		foreach $key (keys %CountList) {
			unless ($is_real{$key}) {
				delete ($CountList{$key});
			}
		}
	}
	&LockClose (SEARCH,"$dir/searchterms.idx");
	open (SEARCH,"$dir/searchterms.idx");
	&LockOpen (NEWSEARCH,"$dir/newsearchterms.idx");
	while (<SEARCH>) {
		if (/^(\d+) /) {
			$message = $1;
			if ($is_real{$message}) {
				print NEWSEARCH "$_";
				$is_real{$message} = 0;
			}
		}
	}
	close (SEARCH);
	&LockOpen (SEARCH,"$dir/searchterms.idx");
	rename ("$dir/newsearchterms.idx","$dir/searchterms.idx");
	&LockClose (NEWSEARCH,"$dir/newsearchterms.idx");
	&LockClose (SEARCH,"$dir/searchterms.idx");
	$number = 0;
	if (-e "$dir/data.txt") {
		open (NUMBER,"$dir/data.txt");
		$number = <NUMBER>;
		close (NUMBER);
	}
	unless ($number > $lastmessage) {
		&LockOpen (NUMBER,"$dir/data.txt");
		$lastmessage++;
		seek (NUMBER, 0, 0);
		print NUMBER "$lastmessage";
		truncate (NUMBER, tell(NUMBER));
		&LockClose (NUMBER,"$dir/data.txt");
	}
	if ($DBMType==2) { dbmclose (%NewMessageList); }
	else { untie %NewMessageList; }
	&LockOpen (DBLOCK,"$dir/dblock.txt");
	opendir (MESSAGES,$dir);
	@messagedir = readdir(MESSAGES);
	closedir (MESSAGES);
	foreach $message (@messagedir) {
		if ($message =~ /^messagelist/) {
			unlink "$dir/$message";
		}
	}
	foreach $message (@messagedir) {
		if ($message =~ /^newmessagelist.(.*)/) {
			rename ("$dir/$message","$dir/messagelist.$1");
		}
		elsif ($message = "newmessagelist") {
			rename ("$dir/newmessagelist","$dir/messagelist");
		}
	}
	&LockClose (NEWDBLOCK,"$dir/newdblock.txt");
	$MessageDBMWrite;
}	

sub ConvertOldDate {
	if ($date =~ /\w+, (\d+) (\w+) (\d+), at (\d+):(\d+) (\w+)/) {
		$mday = int($1);
		$mon = $2;
		$year = int($3);
		$hour = int($4);
		$min = int($5);
		$ampm = $6;
		if ($ampm =~ /p/) { $hour += 12; }
		if ($year > 19000) { $year -= 17100; }
		$year -= 1900;
		$mon = substr($mon,0,3);
		$mon = int($MonthToNumber{$mon});
		$mdays = (($year-69)*365)+(int(($year-69)/4));
		$mdays += $day_counts{$mon};
		if ((int(($year-68)/4) eq (($year-68)/4)) && ($mon>2)) { $mdays++; }
		$mdays += $mday;
		$mdays -= 366;
		$date = ($mdays*86400)+18000;
		$dsthour = (localtime($date))[2];
		if ($dsthour>0) { $date-=3600; }
		$date += ($hour*3600);
		$date += ($min*60);
		if ($HourOffset) { $date -= ($HourOffset*3600); }
	}
	unless (($date =~ /^\d+$/)
	  && ($date > 500000000) && ($date < 1500000000)) {
		$date = (stat("$dir/$subdir/$message"))[9];
	}
	open (FILE,"$dir/$subdir/$message");
	@message = <FILE>;
	close (FILE);
	open (FILE,">$dir/$subdir/$message");
	foreach $line (@message) {
		if ($line =~ /^DATE>/i) { print FILE "DATE>$date\n"; }
		else { print FILE $line; }
	}
	close (FILE);
}

1;

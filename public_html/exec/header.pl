#!/usr/bin/perl

my $title = $ENV{'QUERY_STRING'};
my $style = "style.css";
if($ENV{'HTTP_USER_AGENT'} =~ /MSIE/){
	$style = "style_ie.css";
}
if($title eq ''){
    $title = "Net Authority";
}

print <<EOF;








<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
	"http://www.w3.org/TR/1999/REC-html401-19991224/strict.dtd">

<HTML>
	<HEAD>
		<TITLE>$title</TITLE>
		<BASE HREF="http://www.netauthority.org/">
		<link rel="Stylesheet" href="$style" type="text/css">
		<meta name="keywords" content="netauthority, net authority, internet authority, netpolice, net police, internet police, netcops, net cops, internet cops, net investigation, net investigations, internet investigation, internet investigations, investigate, investigations">
		<meta name="description" content="The official governing body of the internet.">
	</HEAD>
	<BODY>

<DIV ALIGN="center">
<A HREF="index.html"><IMG SRC="images/title.gif" BORDER="0" ALT="Net Authority"></A><BR><BR>
<A HREF="index.html"><IMG SRC="images/home.gif" BORDER="0" ALT="Home"></A>&nbsp;&nbsp;&nbsp;&nbsp;
<A HREF="info.html"><IMG SRC="images/info.gif" BORDER="0" ALT="Info"></A>&nbsp;&nbsp;&nbsp;&nbsp;
<A HREF="faq.html"><IMG SRC="images/faq.gif" BORDER="0" ALT="FAQ"></A>&nbsp;&nbsp;&nbsp;&nbsp;
<A HREF="reports/"><IMG SRC="images/reports.gif" BORDER="0" ALT="Reports"></A>&nbsp;&nbsp;&nbsp;&nbsp;
<A HREF="database.html"><IMG SRC="images/database.gif" BORDER="0" ALT="Database"></A>&nbsp;&nbsp;&nbsp;
<A HREF="exec/forum.pl"><IMG SRC="images/forum.gif" BORDER="0" ALT="Forum"></A><BR>
<A HREF="guidelines.html"><IMG SRC="images/guidelines.gif" BORDER="0" ALT="Guidelines"></A>&nbsp;&nbsp;&nbsp;&nbsp;
<A HREF="offenders/"><IMG SRC="images/offenders.gif" BORDER="0" ALT="Report Offenders"></A><BR>
<A HREF="contest.html"><IMG SRC="images/contest.gif" BORDER="0" ALT="Contest"></A>
</DIV>

<BR><BR>
EOF
1;

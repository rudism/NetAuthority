#!/usr/local/bin/perl

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

# COPYRIGHT NOTICE:
#
# Copyright 2000 Darryl C. Burgdorf.  All Rights Reserved.
#
# This program is being distributed as shareware.  It may be used and
# modified by anyone, so long as this copyright notice and the header
# above remain intact, but any usage should be registered.  (See the
# program documentation for registration information.)  Selling the
# code for this program without prior written consent is expressly
# forbidden.  Obtain permission before redistributing this program
# over the Internet or in any other medium.  In all cases copyright
# and header must remain intact.
#
# This program is distributed "as is" and without warranty of any
# kind, either express or implied.  (Some states do not allow the
# limitation or exclusion of liability for incidental or consequential
# damages, so this notice may not apply to you.)  In no event shall
# the liability of Darryl C. Burgdorf and/or Affordable Web Space
# Design for any damages, losses and/or causes of action exceed the
# total amount paid by the user for this software.

#################################################
## Define your forum's configuration settings! ##
#################################################

## (1) Specify the location of your webbbs_settings.pl script:

require "/home/netauthority/data/board2cgi/webbbs_settings.pl";

## (2) Locate the files and directories unique to this forum:

$dir = "/home/netauthority/data/board2";
$cgiurl = "http://www.netauthority.org/exec/forum.pl";

$boardname = "NetAuth BBS";
$shortboardname = "NABBS";

## (3) Define variables you want changed from webbbs_settings.pl:

#############################################
## Do NOT change anything in this section! ##
#############################################

require $webbbs_text;
require $webbbs_basic;

&Startup;
&WebBBS;

###################################################################
## If necessary, set up the WebAdverts configuration subroutine! ##
###################################################################

sub insertadvert {
	local($adzone) = @_;
	$ADVNoPrint = 1;
	if ($adzone) { $ADVQuery = "zone=$adzone"; }
	else { $ADVQuery = ""; }
	require "/usr/foo/cgi-bin/ads.pl";
}

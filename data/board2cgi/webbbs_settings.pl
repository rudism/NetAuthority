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

# In the sections below, define the configuration variables which
# will determine how your forum(s) will look and function.  If you're
# running more than one forum, this file should contain the "default"
# settings common to the majority; specific settings can, of course,
# be redefined in the configuration files for specific forums, in
# cases where you don't want them all behaving identically.

##############################################
## You MUST define the following variables! ##
##############################################

$admin_password = "***REMOVED***";

## (1) Specify the locations of your WebBBS files:

$scripts_dir = "/home/netauthority/data/board2cgi";

$webbbs_basic = "$scripts_dir/webbbs_basic.pl";
$webbbs_form = "$scripts_dir/webbbs_form.pl";
$webbbs_index = "$scripts_dir/webbbs_index.pl";
$webbbs_misc = "$scripts_dir/webbbs_misc.pl";
$webbbs_post = "$scripts_dir/webbbs_post.pl";
$webbbs_profile = "$scripts_dir/webbbs_profile.pl";
$webbbs_read = "$scripts_dir/webbbs_read.pl";
$webbbs_rebuild = "$scripts_dir/webbbs_rebuild.pl";
$webbbs_text = "$scripts_dir/webbbs_text.pl";

## (2) Define your e-mail notification features:

$mailprog = '/usr/sbin/sendmail';
$WEB_SERVER = "";
$SMTP_SERVER = "";

$admin_name = "Net Authority Admin";
$maillist_address = "forum\@netauthority.org";
$notification_address = "forum\@netauthority.org";
$email_list = 0;
$private_list = 0;

$HeaderOnly = 0;

# use Socket;
# use Net::SMTP;

#################################################################
## You MAY define the following variables, but do not have to! ##
#################################################################

## (3) Tailor the appearance and functionality of your BBS:

# BEGIN { @AnyDBM_File::ISA = qw (DB_File) }
$DBMType = 0;

$SpellCheckerID = "";
$SpellCheckerPath = "";
$SpellCheckerJS = "";
$SpellCheckerLang = "";

$UserProfileDir = "";

$UserProfileURL = "";
$MaxGraphicSize = 20;

$MetaFile = "";
$HeaderFile = "/home/netauthority/public_html/exec/header.pl";
$FooterFile = "/home/netauthority/public_html/exec/footer.pl";
$MessageHeaderFile = "/home/netauthority/public_html/exec/header.pl";
$MessageFooterFile = "/home/netauthority/public_html/exec/footer.pl";
$SSIRootDir = "";

$bodyspec = "BGCOLOR=\"#ffffff\" TEXT=\"#000000\"";
$fontspec = "FACE=\"Arial\"";
$navbarspec = "BORDER=0 CELLSPACING=0 CELLPADDING=6 BGCOLOR=\"#eeeeee\"";
$navbarfontspec = "FACE=\"Arial\"";
$tablespec = "BORDER=0 CELLSPACING=0 CELLPADDING=3 BGCOLOR=\"#eeeeee\"";
$tablefontspec = "FACE=\"Arial\"";

$ListBullets = 1;

@SubjectPrefixes = ();

$MessageOpenCode = "<BLOCKQUOTE>";
$MessageCloseCode = "</BLOCKQUOTE>";

$NewOpenCode = "<EM><font color=\"#FF0000\">NEW:</FONT></EM>";
$NewCloseCode = "";
$AdminOpenCode = "<EM>ADMIN!</EM>";
$AdminCloseCode = "";

$UseLocking = 1;
$RefreshTime = 5;

$UseFrames = "";
$BBSFrame = "_parent";
$WelcomePage = "";

$Moderated = 0;
$SearchURL = "";

$TopNPosters = 0;

%Navbar_Links = ();

$SepPostFormIndex = 1;
$SepPostFormRead = 1;

$DefaultType = "By Threads, Mixed";
$DefaultTime = "2 Day(s)";

$PaginateGuestbook = 0;

$printboardname = 1;

$DateConfig = "";
$IndexEntryLines = 2;

$InputColumns = 50;
$InputRows = 10;

$HourOffset = 0;

$ArchiveOnly = 0;
$SingleLineBreaks = 1;

$AutoQuote = 1;
$AutoQuoteChar = "&gt;";

$AutoHotlink = 1;

%SmileyCode = ();

%FormatCode = ();

$NM_Telltale = "*NM*";
$Pic_Telltale = "*PIC*";

$ThreadSpacer = "";
$GuestbookSpacer = "";

$DisplayEmail = 1;
$ResolveIPs = 1;
$DisplayIPs = 0;
$DisplayViews = 1;

$UseCookies = 1;

## (4) Define your visitors' capabilities:

$MaxMessageSize = 50;
$MaxInputLength = 50;

$LockRemoteUser = 0;

$AllowUserDeletion = 1;
$AllowEmailNotices = 0;
$AllowPreview = 1;

$AllowHTML = 0;
$AllowURLs = 1;
$AllowPics = 1;

$AllowProfileHTML = 0;
$AllowProfileURLs = 1;
$AllowProfilePics = 1;

$SaveLinkInfo = 0;

$AllowUserPrefs = 1;
$AllowNewThreads = 1;
$AllowResponses = 1;

$NaughtyWordsFile = "";
$CensorPosts = 0;

$ShowPosterIP = 1;
$BannedIPsFile = "/home/netauthority/data/banlist";
$BanLevel = 1;

#######################################
## Do NOT remove the following line! ##
#######################################

1;



















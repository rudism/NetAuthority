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

#################
# General Stuff #
#################

@days = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
@months = ('January','February','March','April','May','June','July','August','September','October','November','December');

$text{'0001'} = "Read Responses";
$text{'0002'} = "View Thread";
$text{'0003'} = "Post Response";
$text{'0004'} = "Return to Index";
$text{'0005'} = "Read Prev Msg";
$text{'0006'} = "Read Next Msg";
$text{'0007'} = "Post New Message";
$text{'0008'} = "(Un)Subscribe";
$text{'0009'} = "Search";
$text{'0010'} = "Set Preferences";
$text{'0011'} = "Review Your Message";
$text{'0025'} = "Approve Posts";
$text{'0026'} = "&quot;Naughty&quot; Words List";
$text{'0027'} = "Banned IPs List";
$text{'0028'} = "Edit List";
$text{'0029'} = "Subscriber List";

$text{'0030'} = "Define here -- one per line -- any words or phrases that you want to ban from messages on the forum. (Depending upon your configuration settings, posts containing these words or phrases will either be edited to remove the offending material, or won't be posted at all.) Be careful not to include material of too general a nature, though; banning &quot;ass,&quot; for example, would cause problems for posts containing words like &quot;assign&quot; or &quot;assist.&quot; Also, be aware that this list is only a &quot;first defense.&quot; If you really want to monitor the content of your forum, you need to actually <EM>do</EM> so. No automatic list could possibly catch every &quot;creative&quot; spelling of the words you consider offensive. And, of course, it's possible for posts to be quite offensive without actually using any &quot;naughty&quot; language at all.";

$text{'0031'} = "Define here -- one per line -- any IP addresses or domain names you want banned from the forum. Depending upon your configuration settings, those whose addresses match the ones listed here might have their messages submitted for administrative approval before they're posted, might simply be unable to post at all, or might not even be able to <EM>read</EM> messages posted by others.) Do not use &quot;wildcard&quot; characters; if you want to ban all IP addresses beginning with &quot;215.215.215.&quot; for example, simply enter that much of the address. (In other words, matches are handled on a &quot;partial string&quot; basis.) However, bear in mind that banning specific visitors by banning IP addresses or domain names is <EM>very</EM> difficult. Since most systems use dynamic IP addressing, a given user won't always have the same number; thus, in order to keep the visitor away, you'd have to ban everyone from his ISP. Obviously, in the case of larger ISPs such as AOL, that's not even remotely practical. As well, if an individual has more than one access account, even banning an entire ISP won't necessarily get rid of him. The sad truth is   that if you start banning IP addresses, you're far more likely to end up banning innocent bystanders than to successfully get rid of a troublemaker.";

$text{'0032'} = "Listed below are the e-mail addresses in the forum's &quot;subscriber&quot; list. These are the people to whom notices of new messages are sent.";

$text{'0050'} = "All";
$text{'0051'} = "Any";

$text{'0060'} = "Hour(s)";
$text{'0061'} = "Day(s)";
$text{'0062'} = "Week(s)";
$text{'0063'} = "Month(s)";

$text{'0075'} = "Most Recent Post";

$text{'0100'} = "<P ALIGN=CENTER><BIG><BIG><STRONG>&quot;No Frames&quot; Page</STRONG></BIG></BIG><P>This site utilizes frames, which apparently either your browser doesn't support or you've disabled. However, a <!--NoFramesURL-->plain text version</A> is also available.";
$text{'0150'} = "Hit the Return to Index link to<BR>take you back to the message index page.";

#######################################
# Message Deletion & Password Updates #
#######################################

$text{'0200'} = "The designated message(s) are no longer on the board. If you have any questions, please send a note to <!--emaillink-->. Thanks!";
$text{'0201'} = "Delete This Message";
$text{'0202'} = "Delete Selected Messages";
$text{'0203'} = "Delete All Listed Messages";
$text{'0204'} = "Delete Entire Thread";
$text{'0205'} = "Password";
$text{'0206'} = "Admin Password";
$text{'0207'} = "Current Password";
$text{'0208'} = "New Password (Enter Twice)";
$text{'0209'} = "Delete Confirmation Request";
$text{'0210'} = "Are you certain that you wish to delete all of the following messages?";
$text{'0211'} = "Delete Messages";
$text{'0212'} = "Message(s) Deleted!";
$text{'0213'} = "Password Updated!";
$text{'0214'} = "Your administrative password has been updated!";
$text{'0215'} = "Reset Administrative Password";

$text{'0300'} = "The designated message(s) have been archived!";
$text{'0301'} = "Archive This Message";
$text{'0302'} = "Archive Selected Messages";
$text{'0303'} = "Archive All Listed Messages";
$text{'0304'} = "Archive Entire Thread";
$text{'0309'} = "Archive Confirmation Request";
$text{'0310'} = "Are you certain that you wish to archive all of the following messages?";
$text{'0311'} = "Archive Messages";
$text{'0312'} = "Message(s) Archived!";

#################
# Message Index #
#################

$text{'0500'} = "Message Index";
$text{'0501'} = "Top";
$text{'0502'} = "Poster Stats";
$text{'0503'} = "Search Results";
$text{'0504'} = "Welcome back";
$text{'0505'} = "Since your last visit began";
$text{'0506'} = "new messages have";
$text{'0507'} = "new message has";
$text{'0508'} = "no new messages have";
$text{'0509'} = "been posted";
$text{'0510'} = "Welcome";
$text{'0511'} = "and";
$text{'0512'} = "All Messages";
$text{'0513'} = "Messages of Any Age";
$text{'0514'} = "Messages Posted Between";
$text{'0515'} = "Messages Posted";
$text{'0516'} = "Since Your Last Visit Began";
$text{'0517'} = "Within the Last";
$text{'0518'} = "Messages Containing";
$text{'0519'} = "of the Keywords";
$text{'0520'} = "Messages Posted By";
$text{'0521'} = "All Messages in Date Range";
$text{'0522'} = "of";
$text{'0523'} = "Messages Displayed";
$text{'0524'} = "No messages matched your search criteria! Please try again....";
$text{'0525'} = "(Index Rebuilt)";

$text{'0550'} = "response";
$text{'0551'} = "responses";
$text{'0552'} = "new";

$text{'0601'} = "Chronological Listing";
$text{'0602'} = "Reversed Chronological Listing";
$text{'0603'} = "Alphabetical Listing";
$text{'0604'} = "Reversed Alphabetical Listing";
$text{'0605'} = "Compressed Listing";
$text{'0606'} = "Reversed Compressed Listing";
$text{'0607'} = "Guestbook-Style Listing";
$text{'0608'} = "Reversed Guestbook-Style Listing";
$text{'0609'} = "Threaded Guestbook-Style Listing";
$text{'0610'} = "Reversed Threaded Guestbook-Style Listing";
$text{'0611'} = "Reversed Threaded Listing";
$text{'0612'} = "Mixed Threaded Listing";
$text{'0613'} = "Threaded Listing";
$text{'0615'} = "Mixed Threaded Guestbook-Style Listing";

$text{'0700'} = "Messages Awaiting Approval";
$text{'0701'} = "No messages are currently awaiting approval!";
$text{'0702'} = "Approve This Message";
$text{'0703'} = "Message Awaiting Approval";

###################
# Message Display #
###################

$text{'1000'} = "Posted By";
$text{'1001'} = "Date";
$text{'1002'} = "In Response To";
$text{'1003'} = "Responses To This Message";
$text{'1004'} = "(There are no responses to this message.)";
$text{'1005'} = "Messages In This Thread";
$text{'1010'} = "views";

$text{'1100'} = "First Page";
$text{'1101'} = "Previous Page";
$text{'1102'} = "Next Page";
$text{'1103'} = "Last Page";

#########################
# New Message Post Form #
#########################

$text{'1500'} = "<P><SMALL>If you'd like to include a link to another page with your message,<BR>please provide both the URL address and the title of the page:</SMALL>";
$text{'1501'} = "<P><SMALL>If you'd like to include an image (picture) with your message,<BR>please provide the URL address of the image file:</SMALL>";
$text{'1502'} = "<P><SMALL>If you'd like to have the option of deleting your post later,<BR>please provide a password (CASE SENSITIVE!):</SMALL>";
$text{'1503'} = "<P><SMALL>If you'd like e-mail notification of responses, please check this box:</SMALL>";
$text{'1504'} = "Edit Post";
$text{'1505'} = "<P><SMALL>If necessary, enter your password below:</SMALL>";

$text{'1510'} = "Your Name";
$text{'1511'} = "E-Mail Address";
$text{'1512'} = "Subject";
$text{'1513'} = "Re:";
$text{'1514'} = "Message";
$text{'1515'} = "Optional Link URL";
$text{'1516'} = "Optional Link Title";
$text{'1517'} = "Optional Image URL";
$text{'1518'} = "Post as Admin?";
$text{'1519'} = "Yes";
$text{'1520'} = "No";
$text{'1530'} = "(Select Prefix)";
$text{'1550'} = "Preview Message";
$text{'1551'} = "Post Message";
$text{'1552'} = "Check Spelling";
$text{'1560'} = "&quot;Parent&quot; Message";

$text{'1600'} = "Message Posted";
$text{'1601'} = "Thanks for contributing!";
$text{'1602'} = "Your IP Address";
$text{'1603'} = "Your Host";

$text{'1700'} = "Your post will appear in the index as soon as it's been approved by the moderator.";

###################
# Message Preview #
###################

$text{'2000'} = "Message Preview";
$text{'2001'} = "Below, you can see how your message will look. <STRONG>The message has <EM>not</EM> been posted yet!</STRONG> This is merely a preview screen. If everything looks as you intended, hit the &quot;Post Message&quot; button below. Otherwise, edit the message as necessary and try again.";

#################
# User Profiles #
#################

$text{'2500'} = "User Profile";
$text{'2501'} = "Messages Posted";
$text{'2502'} = "Most Recent Post";
$text{'2503'} = "Edit Your Profile";
$text{'2504'} = "Delete User Profile";
$text{'2505'} = "Optional Graphic Upload";
$text{'2506'} = "Create a Profile";

$text{'2510'} = "View User Profiles";
$text{'2511'} = "User Profiles";

$text{'2550'} = "Create a profile and tell the world about yourself! The information you input below will be accessible from any messages you post on the forum. Use your profile to let other visitors know whatever you want to tell them! The profile can be edited as often as you like. And as an added bonus, once you've created a profile, no one else will be able to post under your name!";
$text{'2551'} = "If you'd like to include a picture with your profile, but don't have a Web site, you can upload a graphic image directly from your own computer. Just put the path to the file in the &quot;$text{'2505'}&quot; input box, below. (Use the &quot;Browse&quot; button if you're not quite sure where to find it.) The file must be in GIF (.gif) or JPEG (.jpg or .jpeg) format, and can be no larger than $MaxGraphicSize kilobytes in size.";

$text{'2600'} = "Profile Deleted!";
$text{'2601'} = "The designated profile is no longer on the board. If you have any questions, please send a note to <!--emaillink-->. Thanks!";

#######################
# Top Posters Listing #
#######################

$text{'3000'} = "Top";
$text{'3001'} = "Most Prolific Posters";
$text{'3002'} = "Total Messages";
$text{'3003'} = "Total Posters";
$text{'3004'} = "Average Messages Per Poster";
$text{'3005'} = "Poster";
$text{'3006'} = "# of Posts";
$text{'3007'} = "% of Total";
$text{'3008'} = "Most Recent Post";

###########################
# Subscribe / Unsubscribe #
###########################

$text{'4000'} = "Subscribe / Unsubscribe";
$text{'4001'} = "If you'd like to, you may receive";
$text{'4002'} = "automatic e-mail notifications";
$text{'4003'} = "regular e-mail digests";
$text{'4004'} = "of all new posts! (If you're already on the list, and would like to be removed, you may also use this form to unsubscribe.) Simply provide your e-mail address below.";
$text{'4005'} = "Your E-Mail Address";
$text{'4006'} = "Add Address to List";
$text{'4007'} = "Delete Address from List";
$text{'4008'} = "Send Address";

####################################
# Search and Configuration Screens #
####################################

$text{'5000'} = "(<STRONG>&quot;Chronological&quot;</STRONG> displays show messages simply in the order in which they were posted; <STRONG>&quot;alphabetical&quot;</STRONG> lists arrange messages, logically enough, in alphabetical order by their subjects; <STRONG>&quot;threaded&quot;</STRONG> displays show messages in indented lists, with responses directly beneath their parent messages. In each of those style, a normal list puts the newest messages at the bottom, while a reversed list, obviously, does the reverse. The <STRONG>&quot;reversed theaded&quot;</STRONG> display, though somewhat awkward, is the &quot;default&quot; index style of many Web-based bulletin boards, including Matt Wright's &quot;WWWBoard&quot; script, and is the style with which many users are most familiar. The <STRONG>&quot;mixed threaded&quot;</STRONG> display is a bit of a half-breed; it arranges primary messages with the newest at the top, thus tending to keep newer messages toward the top of the page, but arranges responses with the newest at the bottom, thus preserving a more &quot;intuitive&quot; threading structure. <STRONG>&quot;Compressed&quot;</STRONG> displays show on the main index page only the first message of each thread; responses are available only by going to the primary message's page. This keeps the index page a bit smaller, but also, of course, makes the responses a bit more difficult to access. Finally, <STRONG>&quot;guestbook-style&quot;</STRONG> displays show the full text of messages on the main index page in a strict chronological manner; <STRONG>&quot;threaded guestbook-style&quot;</STRONG> displays show an index page very similar to that of the &quot;compressed&quot; displays, but show the full text of all messages in a thread on a single page.)";
$text{'5001'} = "View Message Index";

$text{'6000'} = "Search";
$text{'6001'} = "Message Index Keyword Search";
$text{'6002'} = "Use the form below to search for specific messages. You can search either for messages containing a certain keyword or keywords, or for messages posted by a specific individual. (All searches are based on partial-string matches and are case-insensitive.)";
$text{'6003'} = "Search messages";
$text{'6004'} = "Posted within the last";
$text{'6005'} = "Posted between";
$text{'6006'} = "and";
$text{'6007'} = "Oldest available message";
$text{'6008'} = "Newest available message";
$text{'6009'} = "Search for";
$text{'6010'} = "All messages in the date range";
$text{'6011'} = "Messages containing";
$text{'6012'} = "of the following keywords";
$text{'6013'} = "Messages posted by";
$text{'6014'} = "Search Messages";
$text{'6015'} = "IP Address/Domain";

$text{'6500'} = "Configuration";
$text{'6501'} = "Message Index Display Configuration";
$text{'6502'} = "Use the form below to select the manner in which you wish the messages in the index to be displayed.";
$text{'6503'} = "(If your browser supports and is set to accept &quot;cookies,&quot; your preferences will be remembered the next time you visit!)";
$text{'6504'} = "(Note that since this board is not set to utilize &quot;cookies,&quot; your preferences will not be remembered the next time you visit.)";
$text{'6505'} = "List messages";
$text{'6506'} = "Posted within the last";
$text{'6507'} = "List messages posted within the last";
$text{'6508'} = "Posted since your last visit began";
$text{'6509'} = "Listing style";

##################
# E-Mail Notices #
##################

$text{'7000'} = "The following new message has been posted on <!--boardname--> at <<!--boardurl-->>.";
$text{'7001'} = "***************************************************************************";
$text{'7002'} = "This is an automatically-generated notice.  If you'd like to be removed from the mailing list, please visit <!--boardname--> at <<!--boardurl-->>, or send your request to <!--email-->.";
$text{'7003'} = "If you wish to respond to this message, please post your response directly to the board.  Thank you!";
$text{'7005'} = "The following new message awaits administrative approval on <!--boardname-->.";
$text{'7500'} = "The following new messages have been posted on <!--boardname--> at <<!--boardurl-->>.";
$text{'7600'} = "  MESSAGE: ";
$text{'7601'} = "  AUTHOR:  ";
$text{'7602'} = "  DATE:    ";
$text{'7603'} = "           ";
$text{'7604'} = "  Reply To:";
$text{'7605'} = "  Author:  ";
$text{'7606'} = "  Date:    ";
$text{'7607'} = "  Link:    ";
$text{'7608'} = "  URL:     ";

############################
# Database Integrity Check #
############################

$text{'8000'} = "Check Database Integrity";
$text{'8001'} = "Rebuild Database";
$text{'8002'} = "Database Integrity Check";
$text{'8003'} = "First Message #";
$text{'8004'} = "Last Message #";
$text{'8005'} = "Total Messages";
$text{'8006'} = "(a) Physical";
$text{'8007'} = "(b) Database";
$text{'8008'} = "(c) Search";
$text{'8009'} = "The above table shows the ID numbers of the first and last messages on the forum, as well as the total number of messages in the message base, as determined (a) by a physical check of the data directories, (b) by checking the message index database, and (c) by checking the search terms index. If the three sets of numbers do not match, then you should try rebuilding the database to eliminate the inconsistencies.";

#################
# Header/Footer #
#################

$text{'9000'} = "is maintained";
$text{'9001'} = "by";
$text{'9002'} = "with";

##################
# Error Messages #
##################

$text{'9100'} = "No Message!";
$text{'9101'} = "Sorry, but the message you just tried to read doesn't exist! You may have followed an obsolete hard-coded link, or it may be that you just tried to enter the URL manually, and mis-typed it.";

$text{'9110'} = "No Profile!";
$text{'9111'} = "Sorry, but the user profile you just tried to access doesn't exist! You may have followed an obsolete hard-coded link, or it may be that you just tried to enter the URL manually, and mis-typed it.";

$text{'9120'} = "Invalid Password!";
$text{'9121'} = "The user name under which you're posting requires a valid password.";

$text{'9150'} = "Unable to Open Database File!";
$text{'9151'} = "The script was unable to open the message database file. This is most likely due to a permissions error in the data directory.";

$text{'9200'} = "Incomplete Submission!";
$text{'9201'} = "Your message is incomplete! Your enthusiasm is appreciated, but you need to make sure that you include at least <EM>your name</EM> and <EM>a subject line</EM>! Please return to the entry form and try again. Thanks!";

$text{'9250'} = "Message Too Long!";
$text{'9251'} = "Your message is longer than is allowed on this board! It may be that you included too much quoted material, or it may just be that you had too much to say! In either event, please return to the entry form and try to reduce the verbiage. Thanks!";

$text{'9300'} = "Invalid Address!";
$text{'9301'} = "Thanks for your interest, but the e-mail address you entered seems to be invalid. Please use the &quot;Back&quot; button on your browser to return and re-enter it.";

$text{'9400'} = "File Error!";
$text{'9401'} = "The server encountered a file error, and was unable to access the above-named file!";

$text{'9410'} = "Data Directory Error!";
$text{'9411'} = "The script can't write to the defined data directory!";

$text{'9450'} = "Mail System Error!";
$text{'9451'} = "The server encountered an error while trying to send out e-mail notifications. This most likely means that the e-mail program has been incorrectly defined in the program's configuration.";

$text{'9500'} = "Duplicate Submission!";
$text{'9501'} = "This error usually means that you have pressed the &quot;Post Message&quot; button more than once for the same message. If that's the case, then your message has probabably already been posted. The error could also mean that you &quot;previewed&quot; your message, but then went back to the main input form and tried to submit it from there without making any changes. If that's the case, simply go back, make a minor change, and resubmit it!";

$text{'9510'} = "Submission Not Accepted!";
$text{'9511'} = "Your submission was not accepted, due to the presence of &quot;naughty&quot; language. Please edit your post, then resubmit it!";

$text{'9512'} = "Profile Not Accepted!";
$text{'9513'} = "Your profile was not accepted, due to the presence of &quot;naughty&quot; language. Please edit and resubmit it!";

$text{'9520'} = "Submission Not Accepted!";
$text{'9521'} = "Your submission was not accepted, as unfortunately, your IP address has been banned from posting to <!--boardname-->. If you're the hapless victim of someone else's misbehavior, please contact the site administrator to see if it's possible to revise the ban.";

$text{'9600'} = "Invalid Password!";
$text{'9601'} = "Either your password was incorrect or no password was entered. Without a proper password, messages may not be deleted. Please use the &quot;Back&quot; button on your browser to return and try again.";

$text{'9602'} = "Password Mismatch!";
$text{'9603'} = "Your &quot;new&quot; passwords don't match!";

$text{'9610'} = "Invalid Password!";
$text{'9611'} = "Either your password was incorrect or no password was entered. Without a proper password, profiles may not be edited. Please use the &quot;Back&quot; button on your browser to return and try again.";

$text{'9650'} = "Invalid Graphic Format!";
$text{'9651'} = "The graphic you upload to accompany your profile must be in <STRONG>GIF</STRONG> (.gif) or <STRONG>JPEG</STRONG> (.jpg or .jpeg) format! Please use the &quot;Back&quot; button on your browser to return and try again.";

$text{'9652'} = "Graphic Too Large!";
$text{'9653'} = "The graphic you attempted to upload to accompany your profile is too large! Its file size must be no more than <STRONG>$MaxGraphicSize</STRONG> kilobytes. Please use the &quot;Back&quot; button on your browser to return and try again.";

$text{'9654'} = "File Error!";
$text{'9655'} = "The script was unable to open a file to save your profile graphic. This most likely indicates a permissions error on the upload directory.";

$text{'9700'} = "Duplicate Address Submission!";
$text{'9701'} = "Thanks for your interest, but your e-mail address is already on the e-mail notification list! You don't really need <EM>two</EM> notices of each new post, do you?";

$text{'9750'} = "Invalid Address Submission!";
$text{'9751'} = "Your e-mail address can't be removed from the e-mail notification list, since it is not currently <EM>on</EM> the list!";

$text{'9800'} = "You're On The List!";
$text{'9801'} = "Your e-mail address has been added to the e-mail notification list. Whenever a new message is posted, you'll know about it!";

$text{'9850'} = "You're Off The List!";
$text{'9851'} = "Your e-mail address has been removed from the e-mail notification list.";

$text{'9999'} = "If you have any questions, please send a note to <!--emaillink-->.";

1;

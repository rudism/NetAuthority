#!/usr/bin/perl

#clean up utility for netauthority.org
#trash all temp email files that are more than 5 minutes old
#set this as a cron job to run as often as required

opendir(TEMP,"/home/netauthority/data/temp");

while ($file = readdir(TEMP)) {
	if($file =~ /\.tmp$/){
		$staletime = (time - (stat("/home/netauthority/data/temp/$file"))[9]) / 60;
		if($staletime > 5){
			unlink "/home/netauthority/data/temp/$file";
		}
	}
} 

closedir(TEMP);

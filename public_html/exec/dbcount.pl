#!/usr/bin/perl

my $db = $ENV{'QUERY_STRING'};

print "\n";

if(-e "/home/netauthority/data/$db.db"){
open(FILE,"</home/netauthority/data/$db.db");
$num = <FILE>;
close(FILE);
print "$num";
} else {
print "ERROR";
}
1;

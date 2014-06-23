#!/usr/bin/perl

use strict;
use warnings;
use autodie;

#
# Script takes template, prompts for variables, and outputs a configuration
#
#
# check to make sure the user specified a template and output file
#
die "Syntax Error: makemyconfig templatefile configfile\n" if @ARGV != 2;

# take note of the file name for the template file
# and the configuration file
my ( $TEMPLATEFILE, $CONFIGFILE ) = @ARGV;

# read the default tags from defaults.conf
#
open my $SOURCE, '<', 'defaults.conf';
my @defaults = <$SOURCE>;
close $SOURCE;
chomp @defaults;
my %subs;
for my $line ( @defaults ) {
    my ( $key, $val ) = split /=/, $line;
    $subs{$key} = $val;
}

# read in the template
#
open my $TEMPLATE, '<', $TEMPLATEFILE;
my @lines = <$TEMPLATE>;
close $TEMPLATE;
chomp @lines;

# search for all the tags, and put them into the subs array
#
for my $line ( @lines ) {
    while ( $line =~ /(%.*?%)/g ) {
        $subs{$1} = "" if !exists $subs{$1};
    }
}

# prompt the user for the value of all tags,
# allowing them to press enter if a default
# value was specified in defaults.conf
for my $key ( sort keys %subs ) {
    print "$key ($subs{$key}): ";
    my $newval = <STDIN>;
    chomp $newval;
    $subs{$key} = $newval if $newval ne "";
}

# create the configuration file and open it for writing
open my $TARGET, ">", $CONFIGFILE;

# write the configuration file, substituting the proper
# values for each tag that is encountered
for my $line ( @lines ) {
    while ( $line =~ /(%.*?%)/g ) {
        my $val = $subs{$1};
        $line =~ s/$1/$val/g;
    }
    print $TARGET "$line\n";
}

# close the configuration file, script is complete.
close $TARGET;

#!/usr/bin/perl

use LWP::Simple qw(mirror);
use RDF::NS;
use File::Temp;

# get current version distribution
my $dist = do { local( @ARGV, $/ ) = 'dist.ini'; <> };
my $cur_version = $1 if $dist =~ /^\s*version\s*=\s*([^\s]+)/m;

# get current prefixes
$cur_version or die 'current version not found in dist.ini';
my $cur = RDF::NS->LOAD( "share/$cur_version.txt", warn => 1 );
die "share/$cur_version.txt is empty" unless %$cur;

# get new current datestamp
my @t = gmtime;
my $new_version = sprintf '%4d%02d%02d', $t[5]+1900, $t[4]+1, $t[3];

die "$new_version is not new" if $new_version eq $cur_version;

# download new prefixes
my $tmp = File::Temp->new->filename;
my $url = "http://prefix.cc/popular/all.file.txt";
mirror($url,$tmp) or die "Failed to load $url";
my $new = RDF::NS->LOAD( $tmp, warn => 1 );

open (my $txt, ">", "share/$new_version.txt") 
	or die "failed to open share/$new_version.txt";
print $txt join( "", $new->MAP( sub { "$_\t".$new->{$_}."\n" } ) );

print "$new_version (" . scalar(keys %$new) . " prefixes)\n"; 

# diff
my @changed;
foreach (keys %$new) {
    if (exists $cur->{$_}) {
		push (@changed,$_) if $cur->{$_} ne $new->{$_};
	    delete $cur->{$_};
    	delete $new->{$_};
	} 
}

print "  added: " . join(",",sort keys %$new) . "\n" if %$new;
print "  removed: " . join(",",sort keys %$cur) . "\n" if %$cur;
print "  changed: " . join(",",sort @changed) . "\n" if @changed;

# TODO: We could write new dist.ini and Changes and even push to CPAN


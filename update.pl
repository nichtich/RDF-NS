#!/usr/bin/perl

use LWP::Simple qw(mirror);
use RDF::NS;
use File::Temp;

my $dist = do { local( @ARGV, $/ ) = 'dist.ini'; <> }
	or die "Failed to read dist.ini";

$dist =~ /^\s*version\s*=\s*([^\s]+)/m 
	or die "dist.ini must include version number";

# TODO: check version number format and date to give a warning

my $file = "share/$1.txt";

( -f $file ) and die "$file already exists";

open (my $fh, ">", $file) 
	or die "faile to open $file for writing";

my $tmp = File::Temp->new->filename;

my $url = "http://prefix.cc/popular/all.file.txt";
my $prefixcc = mirror($url,$tmp) or die "Failed to load $url";

my $ns = RDF::NS->LOAD( $tmp, warn => 1 );

foreach my $prefix (sort keys %$ns) {
	print $fh "$prefix\t" . $ns->{$prefix} . "\n";
}
print "created mapping $file with " . scalar(keys %$ns) . " namespaces.\n";


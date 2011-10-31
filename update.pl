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

my (@log) = "$new_version (" . scalar(keys %$new) . " prefixes)"; 

# diff
my @changed;
foreach (keys %$new) {
    if (exists $cur->{$_}) {
        push (@changed,$_) if $cur->{$_} ne $new->{$_};
        delete $cur->{$_};
        delete $new->{$_};
    } 
}

push @log, "  added: " . join(",",sort keys %$new) if %$new;
push @log, "  removed: " . join(",",sort keys %$cur) if %$cur;
push @log, "  changed: " . join(",",sort @changed) if @changed;

print join '', map { "$_\n" } @log;

foreach my $file (qw(dist.ini lib/RDF/NS.pm lib/RDF/NS/Trine.pm README)) {
    print "$cur_version => $new_version in $file\n";
    local ($^I,@ARGV)=('.bak',$file);
    while(<>) {
        s/$cur_version/$new_version/ig;
        print;
    }
}
do {
    print "prepend modifications to Changes\n"; 
    local ($^I,@ARGV)=('.bak','Changes');
    my $line=0;
    while (<>) {
        if (!$line++) {
            print join '', map { "$_\n" } @log;
        }
        print; 
    } 
}
# $ git add Changes README dist.ini lib/RDF/NS.pm lib/RDF/NS/Trine.pm share/$new_version.txt
# $ git commit -m "update to $new_version"
# $ git tag $new_version
# $ dzil release


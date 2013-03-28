use strict;
use warnings;
use Test::More;

use RDF::NS;

my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
my $dc   = 'http://purl.org/dc/elements/1.1/';

my $ns = RDF::NS->new('20111028');

is $ns->PREFIX('http://www.w3.org/1999/02/22-rdf-syntax-ns#'), 'rdf', 'PREFIX';

my @nslist = $ns->PREFIXES($dc);
my $needs_diag = 0;
ok ((grep { $_ eq 'dc' } @nslist), 'PREFIXES has dc')
   or $needs_diag++;
ok ((grep { $_ eq 'dc11' } @nslist), 'PREFIXES has dc11')
   or $needs_diag++;
is @nslist, 2, 'PREFIXES returns two'
   or $needs_diag++;

diag sprintf "\@nslist = (%s)", join(",",map {"'$_'"} @nslist) if $needs_diag;

my $rev = $ns->REVERSE;

is $rev->{$rdfs}, 'rdfs', 'reverse';
is $rev->{$dc}, 'dc', 'reverse';

done_testing;

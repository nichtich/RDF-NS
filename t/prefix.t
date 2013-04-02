use strict;
use warnings;
use Test::More;

use RDF::NS;

my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
my $dc   = 'http://purl.org/dc/elements/1.1/';

my $ns = RDF::NS->new('20111028');

is $ns->PREFIX('http://www.w3.org/1999/02/22-rdf-syntax-ns#'), 'rdf', 'PREFIX';

is_deeply [ sort $ns->PREFIXES($dc) ], [qw(dc dc11)], 'PREFIXES has dc, dc11';

my $rev = $ns->REVERSE;

is $rev->{$rdfs}, 'rdfs', 'reverse';
is $rev->{$dc}, 'dc', 'reverse';

done_testing;

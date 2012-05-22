use strict;
use warnings;
use Test::More;

use RDF::NS;

my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';

my $ns = RDF::NS->new('20111028');

is $ns->PREFIX('http://www.w3.org/1999/02/22-rdf-syntax-ns#'), 'rdf', 'PREFIX';

my @nslist = sort $ns->PREFIXES('http://purl.org/dc/elements/1.1/');

is_deeply \@nslist, [qw(dc dc11)], 'PREFIXES';

done_testing;

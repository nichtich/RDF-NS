use strict;
use warnings;
use Test::More;

use RDF::NS;

# this should never change
my $rdf = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';

# get some prefixed URIs
my $ns = RDF::NS->new('20111028');

is( $ns->rdf, $rdf, '$ns->rdf' ); 
is( $ns->rdf_type, $rdf.'type', '$ns->rdf_type' ); 

is( $ns->URI("rdf:type"), $rdf.'type', '$ns->URI("rdf:type")' );

done_testing;

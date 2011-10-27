use strict;
use warnings;
use Test::More;

use RDF::NS;

my $trine = 'RDF::Trine::Node::Resource';
eval { require $trine };
if ( $@ ) {
	diag("RDF::Trine missing - skip tests of RDF::NS::Trine");
	exit 0;
}
    
use_ok('RDF::NS::Trine');

# TODO: check SPARQL, URI etc.

#my $ns = RDF::NS->new('20111028', as => 'trine');
#isa_ok( $ns->foaf, $trine );

done_testing;

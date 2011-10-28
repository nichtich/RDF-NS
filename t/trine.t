use strict;
use warnings;
use Test::More;

eval { require RDF::Trine::Node::Resource; 1; };
if ( $@ ) {
	diag("RDF::Trine missing - skip tests of RDF::NS::Trine");
	exit 0;
}

use_ok('RDF::NS::Trine');

my $ns = RDF::NS::Trine->new('20111028');

# should return resources
my $trine = 'RDF::Trine::Node::Resource';
isa_ok( $ns->rdf, $trine );
isa_ok( $ns->rdf_type, $trine );
isa_ok( $ns->URI('rdf:type'), $trine );

# this should never change
my $rdf  = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';

# should still return strings
is( $ns->SPARQL('rdf'), "PREFIX rdf: <$rdf>", 'SPARQL("rdf")' );
is( $ns->TTL('rdfs'), "\@prefix rdfs: <$rdfs> .", 'TTL("rdfs")' );
is( $ns->XMLNS('rdfs'), "xmlns:rdfs=\"$rdfs\"", 'XMLNS("rdfs")' );

done_testing;

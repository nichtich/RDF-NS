use strict;
use warnings;
use Test::More;

eval { require RDF::Trine::Node::Resource; };
if ( $@ or $RDF::Trine::VERSION < 0.140) {
	diag("RDF::Trine missing or too old - skip tests of RDF::NS::Trine");
	ok(1, "skip tests");
	done_testing;
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

# blank nodes
my $b = $ns->URI('_:xy');
isa_ok( $b, 'RDF::Trine::Node::Blank' );
is( $b->blank_identifier, 'xy', 'blank node' );
$b = $ns->_abc;
is( $b->blank_identifier, 'abc', 'blank node' );
isa_ok( $ns->URI('_:'), 'RDF::Trine::Node::Blank' );
isa_ok( $ns->URI('_'), 'RDF::Trine::Node::Blank' );
isa_ok( $ns->_, 'RDF::Trine::Node::Blank' );

done_testing;

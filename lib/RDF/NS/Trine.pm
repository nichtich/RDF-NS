use strict;
use warnings;
package RDF::NS::Trine;
#ABSTRACT: Popular RDF namespace prefixes from prefix.cc as RDF::Trine nodes

use v5.10;
use RDF::Trine::Node::Resource;
use RDF::Trine::Node::Blank;

use base 'RDF::NS';

sub GET {
    RDF::Trine::Node::Resource->new($_[1]);
}

sub BLANK {
    my $id = ($_[1] =~ /^_(:(.+))$/ ? $2 : undef);
    return RDF::Trine::Node::Blank->new( $id );
}

1;

=head1 SYNOPSIS

  use RDF::NS::Trine;
  use constant NS => RDF::NS::Trine->new('20130402');

  NS->foaf_Person;        # iri('http://xmlns.com/foaf/0.1/Person')
  NS->uri('foaf:Person);  #  same RDF::Trine::Node::Resource
  NS->foaf_Person->uri;   # http://xmlns.com/foaf/0.1/Person

  NS->_;                  # RDF::Trine::Node::Blank
  NS->_abc;               # blank node with id 'abc'
  NS->uri('_:abc');       # same

=head1 DESCRIPTION

RDF::NS::Trine works like L<RDF::NS> but it returns instances of
L<RDF::Trine::Node::Resource> (or L<RDF::Trine::Node::Blank>) instead of
strings.

Before using this module, make sure to install L<RDF::Trine>, which is not
installed automatically together with L<RDF::NS>!

=head1 ADDITIONAL METHODS

=head2 BLANK ( [ $short ] )

Returns a new L<RDF::Trine::Node::Blank>.

=encoding utf8

=cut

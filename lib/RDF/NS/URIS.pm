use strict;
use warnings;
package RDF::NS::URIS;
#ABSTRACT: Popular RDF namespace prefixes from prefix.cc as URI objects

use URI;
use base 'RDF::NS';

sub GET {
    URI->new($_[1]);
}

1;

=head1 SYNOPSIS

  use RDF::NS::URIS;
  use constant NS => RDF::NS::URIS->new('20120905');

  NS->foaf_Person;             # an URI object
  NS->uri('foaf:Person);       # same
  NS->foaf_Person->as_string;  # http://xmlns.com/foaf/0.1/Person

=head1 DESCRIPTION

RDF::NS::URIS works like L<RDF::NS> but it returns instances of L<URI> instead
of plain strings. You must have installed module L<URI> to use this package.

=head1 SEE ALSO

L<URI::NamespaceMap>

=encoding utf8

=cut

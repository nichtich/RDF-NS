use strict;
use warnings;
package RDF::NS::Trine;
#ABSTRACT: Popular RDF namespace prefixes from prefix.cc as RDF::Trine nodes

use RDF::Trine::Node::Resource;

use parent 'RDF::NS';

sub GET {
    RDF::Trine::Node::Resource->new($_[1]);
}

1;

=head1 SYNOPSIS

  use RDF::NS::Trine;

  my $ns = RDF::NS::Trine->new('20111031');

  $ns->foaf_Person;        # a RDF::Trine::Node::Resource
  $ns->URI('foaf:Person);  # same
  $ns->foaf_Person->uri;   # http://xmlns.com/foaf/0.1/Person

=head1 DESCRIPTION

In contrast to L<RDF::NS>, which should be consulted for documentation, this
returns no plain string URIs but instances of L<RDF::Trine::Node::Resource>.

Before using this module, make sure to install L<RDF::Trine>, which is not
automatically installed together with L<RDF::NS>!

=cut

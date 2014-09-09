use strict;
use warnings;
package RDF::SN;
#ABSTRACT: Short names for URIs with prefixes from prefix.cc

use RDF::NS;
use Scalar::Util qw(blessed);

sub new {
    my ($class, $ns) = @_;

    unless (blessed $ns) {
        $ns = $ns ? RDF::NS->new($ns) : RDF::NS->new;
    }

    my $self = bless { }, $class;
    
    while ( my ($prefix, $namespace) = each %$ns ) {
        my $has = $self->{$namespace};
        if (!$has || (length($has) > length($prefix))
                  || (length($has) == length($prefix) and $has ge $prefix)
        ) {
            $self->{$namespace} = $prefix;
        }
    }

    $self;
}

sub qname {
    my ($self, $uri, $sep) = @_;
    $sep ||= ':';

    if ($self->{$uri}) {
        return $self->{$uri}.$sep;
    }

    # regexpes copied from RDF::Trine::Node::Resource
    our $r_PN_CHARS_BASE ||= qr/([A-Z]|[a-z]|[\x{00C0}-\x{00D6}]|[\x{00D8}-\x{00F6}]|[\x{00F8}-\x{02FF}]|[\x{0370}-\x{037D}]|[\x{037F}-\x{1FFF}]|[\x{200C}-\x{200D}]|[\x{2070}-\x{218F}]|[\x{2C00}-\x{2FEF}]|[\x{3001}-\x{D7FF}]|[\x{F900}-\x{FDCF}]|[\x{FDF0}-\x{FFFD}]|[\x{10000}-\x{EFFFF}])/;
    our $r_PN_CHARS_U    ||= qr/(_|${r_PN_CHARS_BASE})/;
    our $r_PN_CHARS      ||= qr/${r_PN_CHARS_U}|-|[0-9]|\x{00B7}|[\x{0300}-\x{036F}]|[\x{203F}-\x{2040}]/;
    our $r_PN_LOCAL      ||= qr/((${r_PN_CHARS_U})((${r_PN_CHARS}|[.])*${r_PN_CHARS})?)/;

    if ($uri =~ m/${r_PN_LOCAL}$/) {
        my $ln = $1;
        my $ns = substr($uri, 0, length($uri)-length($ln));
        if ($self->{$ns}) {
            return $self->{$ns}.$sep.$ln;
        }
    }

    return;
}

sub qname_ {
    $_[0]->qname($_[1],'_');
}

=head1 SYNOPSIS

  use RDF::SN;
  $abbrev = RDF::SN->new('20140908');
  $abbrev->qname('http://www.w3.org/2000/01/rdf-schema#type'); # rdfs:type

=head1 DESCRIPTION

This module supports abbreviating URIs as short names (aka qualified names), so
its the counterpart of L<RDF::NS>.

=head2 new( [ $ns ] )

Create a lookup hash from a mapping hash of namespace URIs to prefixes
(L<RDF::NS>). If multiple prefixes exist, the shortest is used. If multiple
prefixes with same length exist, the first in alphabetical order is used.

=head2 qname( $uri [, $separator_char ] )

Returns a prefix and local name if the URI can be abbreviated with given
namespaces.  The default separator char is a colon (C<:>).

=encoding utf8

=cut

1;

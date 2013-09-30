use strict;
use warnings;
package App::rdfns;
#ABSTRACT: quickly get common URI namespaces
#VERSION

use v5.10;

use RDF::NS;

sub new {
    bless {}, shift;
}

sub run {
    my ($self, @ARGV) = @_;
    my $format = '';
    my $version = 'any';

    return $self->usage if !@ARGV or $ARGV[0] =~ /^(-[?h]|--help)$/;
    return $self->version if $ARGV[0] =~ /^(-v|--version)$/;

    foreach my $a (@ARGV) {
        if ( $a =~ /^(\d{8})$/ ) {
            $version = $a;
            next;
        }
        my $ns = RDF::NS->new($version);
        my $rev;
        if ( $a =~ qr{^https?://} ) {
            $rev ||= $ns->REVERSE;
            say $rev->{$a} if $rev->{$a};
        } elsif ( $a =~ /:/ ) {
            print map { $ns->URI($_)."\n" } split(/[|, ]+/, $a);
        } elsif ( $a =~ s/\.([^.]+)$// ) {
            my $f = $1;
            if ( $f eq 'prefix' ) {
               $rev ||= $ns->REVERSE;
               print map { "$_\n" if defined $_ } map {
                   $rev->{$_}
               } $ns->FORMAT( $format, $a );
               next;
            } elsif ( $f =~ $RDF::NS::FORMATS ) {
                $format = $f;
            } else {
                print STDERR "Unknown format: $f\n";
            }
        }
        if ( lc($format) eq 'json' ) {
            say join ",\n", $ns->FORMAT( $format, $a );
        } else {
            say $_ for $ns->FORMAT( $format, $a );
        }
    }
}

sub usage {
    print <<'USAGE';
USAGE: rdfns { [YYYYMMDD] ( <prefix[es]>[.format] | prefix:name | URL ) }+

  formats: txt, sparql, ttl, n3, xmlns, json, beacon, prefix
  options: --help | --version
 
  examples:
    rdfns 20111102 foaf,owl.ttl
    rdfns foaf.xmlns foaf.n3
    rdfns rdfs:seeAlso
    rdfns http://www.w3.org/2003/01/geo/wgs84_pos#
    rdfns wgs.prefix
USAGE
    0;
}

sub version {
    print $RDF::NS::VERSION . "\n";
    0;
}

1;

=head1 SEE ALSO

This module implements the command line client L<rdfns>.

=encoding utf8

=cut

use strict;
use warnings;
package RDF::NS;
#ABSTRACT: Just use popular RDF namespace prefixes from prefix.cc

use Scalar::Util qw(blessed);
use File::ShareDir;

our $AUTOLOAD;

sub new {
    my $class   = shift;
    my $version = shift;
	$version = $RDF::NS::VERSION if $version eq 'any';
    LOAD( $class, File::ShareDir::dist_file('RDF-NS', "$version.txt" ), @_ );
}

sub LOAD {
    my ($class, $file, %options) = @_;
    $class = ref($class) || $class;

    my $warn = $options{'warn'};

    my $ns = { };
    open (my $fh, '<', $file) or die "failed to open $file";
    foreach (<$fh>) {
        chomp;
        next if /^#/;
        my ($prefix, $namespace) = split "\t", $_;
        if ( $prefix =~ /^(isa|can|new)$/ ) {
            warn "Cannot support prefix $prefix!" if $warn;
            next;
        } elsif ( $prefix =~ /^[a-z][a-z0-9]+$/ ) {
            if ( $namespace =~ /^[a-z][a-z0-9]+:[^"<>]*$/ ) {
                $ns->{$prefix} = $namespace;
            } elsif( $warn ) {
                warn "Skipping invalid $prefix namespace $namespace";
            }
        } elsif ( $warn ) {
            warn "Skipping unusual prefix '$prefix'";
        }
    }

    bless $ns, $class;
}

sub TTL {
    my $self = shift;
    $self->MAP( sub { "\@prefix $_: <".$self->{$_}."> ." } , @_ );
}

sub SPARQL {
    my $self = shift;
    $self->MAP( sub { "PREFIX $_: <".$self->{$_}.">" } , @_ );
}

sub XMLNS {
    my $self = shift;
    $self->MAP( sub { "xmlns:$_=\"".$self->{$_}."\"" } , @_ );
}

sub SELECT {
    my $self = shift;
    $self->MAP( sub { $_ => $self->{$_} } , @_ );
}

# functional programming rulez!
sub MAP {
    my $self = shift;
    my $code = shift;
    my @ns = @_ ? (grep { $self->{$_} } map { split /[|, ]+/ } @_) 
        : keys %$self;
    if (wantarray) {
        return map { $code->() } sort @ns;
    } else {
        local $_ = $ns[0];
        return $code->();
    }
}

sub GET {
    $_[1];
}

sub URI {
    my $self = shift;
    return unless shift =~ /^([a-z][a-z0-9]+)([:_]([^:]+))?$/;
    my $ns = $self->{$1} or return;
    return $self->GET($ns) unless $3;
    return $self->GET($ns.$3);
}

sub AUTOLOAD {
    my $self = shift;
    return unless $AUTOLOAD =~ /:([a-z][a-z0-9]+)(_([^:]+))?$/;
    my $ns = $self->{$1} or return;
    my $local = defined $3 ? $3 : shift;
    return $self->GET($ns) unless defined $local;
    return $self->GET($ns.$local);
}

1;

=head1 SYNOPSIS

  use RDF::NS '20111031';              # check at compile time
  my $ns = RDF::NS->new('20111031');   # check at runtime

  $ns->foaf;               # http://xmlns.com/foaf/0.1/
  $ns->foaf_Person;        # http://xmlns.com/foaf/0.1/Person
  $ns->foaf('Person');     # http://xmlns.com/foaf/0.1/Person
  $ns->URI('foaf:Person'); # http://xmlns.com/foaf/0.1/Person

  $ns->SPAQRL('foaf');     # PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  $ns->TTL('foaf');        # @prefix foaf: <http://xmlns.com/foaf/0.1/> .
  $ns->XMLNS('foaf');      # xmlns:foaf="http://xmlns.com/foaf/0.1/"

  # To get RDF::Trine::Node::Resource instead of strings
  use RDF::NS::Trine;
  $ns = RDF::NS::Trine->new('20111031');
  $ns->foaf_Person;        # iri('http://xmlns.com/foaf/0.1/Person')

  # load your own mapping
  $ns = RDF::NS::LOAD("mapping.txt");

  # select particular mappings
  %map = $ns->SELECT('rdf,dc,foaf');
  $uri = $ns->SELECT('foo|bar|doz'); # returns first existing namespace

  # instances are just blessed hash references
  $ns->{'foaf'};           # http://xmlns.com/foaf/0.1/
  bless { foaf => 'http://xmlns.com/foaf/0.1/' }, 'RDF::NS';
  print (scalar %$ns) . "prefixes\n";

=head1 DESCRIPTION

Hardcoding URI namespaces and prefixes for RDF applications is neither fun nor
maintainable.  In the end we all use more or less the same prefix definitions,
as collected at L<http://prefix.cc>. This module includes all these prefixes as
defined at specific snapshots in time. These snapshots correspond to version
numbers of this module. By selecting particular versions, you make sure that
changes at prefix.cc won't affect your scripts.

This module does not require L<RDF::Trine> which is recommended nevertheless.
If you prefer RDF::NS to return instances of L<RDF::Trine::Node::Resource>
instead of plain strings, use L<RDF::NS::Trine>.

The code repository of this module contains an
L<update script|https://github.com/nichtich/RDF-NS/blob/master/update.pl>
to download the current prefix-namespace mappings from L<http://prefix.cc>.

=method new ( $version [, %options ] )

Create a new namespace mapping with a selected version (mandatory). The special
version string C<"any"> can be used to get the newest mapping - actually this
is C<$RDF::NS::VERSION>, but you should better select a specific version, as
mappings can change, violating backwards compatibility. Supported options 
include C<warn> to enable warnings.

=method LOAD ( $file [, %options ] )

Load namespace mappings from a particular tab-separated file. See NEW for 
supported options.

=method URI ( $short )

Expand a prefixed URI, such as C<foaf:Person>. Alternatively you can expand
prefixed URIs with method calls, such as C<$ns-E<gt>foaf_Person>.

=method TTL ( prefix[es] )

Returns a Turtle/Notation3 C<@prefix> definition or a list of such definitions
in list context. Prefixes can be passed as single arguments or separated by
commas, vertical bars, and spaces.

=method SPARQL ( prefix[es] )

Returns a SPARQL PREFIX definition or a list of such definitions in list
context. Prefixes can be passed as single arguments or separated by commas,
vertical bars, and spaces.

=method XMLNS ( prefix[es] )

Returns an XML namespace declaration or a list of such declarations in list
context. Prefixes can be passed as single arguments or separated by commas,
vertical bars, and spaces.

=method SELECT ( prefix[es] )

In list context, returns a sorted list of prefix-namespace pairs, which
can be used to assign to a hash. In scalar context, returns the namespace
of the first prefix that was found. Prefixes can be passed as single arguments
or separated by commas, vertical bars, and spaces.

=method MAP ( $code [, prefix[es] ] )

Internally used to map particular or all prefixes. Prefixes can be selected as
single arguments or separated by commas, vertical bars, and spaces. In scalar
context, C<$_> is set to the first existing prefix (if found) and C<$code> is
called. In list context, found prefixes are sorted at mapped with C<$code>.

=method GET ( $uri )

This method is used internally to create URIs as return value of the URI
method and all lowercase shortcut methods, such as C<foaf_Person>. By default
it just returns C<$uri> unmodified.

=head1 SEE ALSO

There are several other CPAN modules to deal with IRI namespaces, for instance
L<RDF::Trine::Namespace>, L<RDF::Trine::NamespaceMap>, L<RDF::Prefixes>,
L<RDF::Simple::NS>, L<RDF::RDFa::Parser::Profile::PrefixCC> etc.

=cut

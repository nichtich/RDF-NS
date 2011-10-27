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
			warn "Skipping unusual prefix $prefix";
		}
	}

	bless $ns, $class;
}

sub TTL {
	my $self = shift;
	# functional programming rulez
	my @ns = map { "\@prefix $_: <".$self->{$_}."> ." } 
		grep { $self->{$_} } sort map { split /[|, ]+/ } @_;
	return wantarray ? @ns : $ns[0];
}

sub SPARQL {
	my $self = shift;
	my @ns = map { "PREFIX $_: <".$self->{$_}.">" } 
		grep { $self->{$_} } sort map { split /[|, ]+/ } @_;
	return wantarray ? @ns : $ns[0];
}

sub XMLNS {
	my $self = shift;
	my @ns = map { "xmlns:$_=\"".$self->{$_}."\"" } 
		grep { $self->{$_} } sort map { split /[|, ]+/ } @_;
	return wantarray ? @ns : $ns[0];
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

  use RDF::NS '20111028';
  my $ns = RDF::NS->new('20111028')

  $ns->foaf                # http://xmlns.com/foaf/0.1/
  $ns->foaf_Person         # http://xmlns.com/foaf/0.1/Person
  $ns->foaf('Person')      # http://xmlns.com/foaf/0.1/Person
  $ns->URI('foaf:Person')  # http://xmlns.com/foaf/0.1/Person

  $ns->SPAQRL('foaf');     # PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  $ns->TTL('foaf');        # @prefix foaf: <http://xmlns.com/foaf/0.1/> .
  $ns->XMLNS('foaf');      # xmlns:foaf="http://xmlns.com/foaf/0.1/"

  # To get RDF::Trine::Node::Resource instead of strings
  my $ns = RDF::NS->new( '20111028', as => 'trine' );
  $ns->foaf_Person         # iri('http://xmlns.com/foaf/0.1/Person')

  # load your own mapping
  $ns = RDF::NS::LOAD("mapping.txt");

  # instances are just blessed hash references
  $ns->{'foaf'}            # http://xmlns.com/foaf/0.1/

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

=method new ( $version [, %options ] )

Create a new namespace mapping with a selected version (mandatory). 
See LOAD for supported options.

=method LOAD ( $file [, %options ] )

Load namespace mappings from a particular tab-separated file. Supported 
options include C<warn> to enable warnings.

=method URI ( $short )

Expand a prefixed URI, such as C<foaf:Person>. Alternatively you can expand
prefixed URIs with method calls, such as C<<$ns->foaf_Person>>.

=method TTL ( prefix[es] )

Returns a Turtle/Notation3 @prefix definition or a list of such definitions 
in list context. Prefixes can be passed as single arguments or separated by 
commas, vertical bars, or spaces.

=method SPARQL ( prefix[es] )

Returns a SPARQL PREFIX definition or a list of such definitions in list 
context. Prefixes can be passed as single arguments or separated by commas,
vertical bars, or spaces.

=method XMLNS ( prefix[es] )

Returns an XML namespace declaration or a list of such declarations in list 
context. Prefixes can be passed as single arguments or separated by commas,
vertical bars, or spaces.

=method GET ( $uri )

This method is used internally to create URIs. By default it returns C<$uri>.

=head1 SEE ALSO

There are several CPAN modules to deal with IRI namespaces, for instance
L<RDF::Trine::Namespace>, L<RDF::Trine::NamespaceMap<>, L<RDF::Prefixes>, 
L<RDF::Simple::NS>, L<RDF::RDFa::Parser::Profile::PrefixCC> etc.

=cut

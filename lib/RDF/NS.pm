use strict;
use warnings;
package RDF::NS;
#ABSTRACT: Just use popular RDF namespace prefixes from prefix.cc

use Scalar::Util qw(blessed);
use File::ShareDir;

our $AUTOLOAD;

sub new {
	my ($class, $version) = @_;
	LOAD( $class, File::ShareDir::dist_file('RDF-NS', "$version.txt" ) );
}

sub LOAD {
	my ($class, $file, $only, $warn) = @_;
	$class = ref($class) || $class;

	# TODO: filter $only

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
			$ns->{$prefix} = $namespace;
		} elsif ( $warn ) {
			warn "Skipping unusual prefix $prefix";
		}
	}

	bless $ns, $class;
}

sub URI {
	my $self = shift;
	return unless shift =~ /^([a-z][a-z0-9]+)(:([^:]+))?$/;
	my $ns = $self->{$1} or return;
	return $ns unless $3;
	return $ns.$3;
}

sub AUTOLOAD {
	my $self = shift;
	return unless $AUTOLOAD =~ /:([a-z][a-z0-9]+)(_([^:]+))?$/;
	my $ns = $self->{$1} or return;
	return $ns unless $3;
	return $ns.$3;
}

1;

=head1 SYNOPSIS

  use RDF::NS '20111028';
  my $ns = RDF::NS->new('20111028')

  $ns->foaf          # http://xmlns.com/foaf/0.1/
  $ns->foaf_Person   # http://xmlns.com/foaf/0.1/Person

  # load your own mapping
  $ns = RDF::NS::LOAD("mapping.txt");

  print (scalar %$ns) . "prefixes\n";

=head1 DESCRIPTION

Hardcoding URI namespaces and prefixes for RDF applications is neither fun nor
maintainable.  In the end we all use more or less the same prefix definitions,
as collected at L<http://prefix.cc>. This module ...

=head1 SEE ALSO

There are several CPAN modules to deal with IRI namespaces, for instance
L<RDF::Trine::Namespace>, L<RDF::Trine::NamespaceMap<>, L<RDF::Prefixes>, 
L<RDF::Simple::NS>, L<RDF::RDFa::Parser::Profile::PrefixCC> etc.

=cut


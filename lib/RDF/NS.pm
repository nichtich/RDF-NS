use strict;
use warnings;
package RDF::NS;
#ABSTRACT: Just use popular RDF namespace prefixes from prefix.cc

use Scalar::Util qw(blessed);
use File::ShareDir;
use Carp;

our $AUTOLOAD;
our $FORMATS = qr/ttl|n(otation)?3|sparql|xmlns|txt|beacon/;

our $DATE_REGEXP = qr/^([0-9]{4})-?([0-9][0-9])-?([0-9][0-9])$/;

sub new {
    my ($class, $from, %options) = @_;

    $from ||= 'any';
    my $at   = $options{at} || 'any';
    my $warn = $options{'warn'};

    if ( $from =~ $DATE_REGEXP ) {
        $at   = "$1$2$3";
        $from = 'any';
    } elsif( $at =~ $DATE_REGEXP ) {
        $at   = "$1$2$3";
    } elsif ( $at !~ 'any' ) {
        croak "RDF::NS expects a date as YYYY-MM-DD"; 
    }

    $from = File::ShareDir::dist_file('RDF-NS', "prefix.cc" )
        if $from eq 'any';
    croak "prefix file or date not found: $from"
        unless -f $from;

    my $ns = { };
    open (my $fh, '<', $from) or croak "failed to open $from";
    foreach (<$fh>) {
        chomp;
        next if /^#/;
        my ($prefix, $namespace, $date) = split "\t", $_;
        last if $date and $at ne 'any' and $date > $at;

        if ( $prefix =~ /^(isa|can|new|uri)$/ ) {
            warn "Cannot support prefix '$prefix'" if $warn;
            next;
        } elsif ( $prefix =~ /^[a-z][a-z0-9]*$/ ) {
            if ( $namespace =~ /^[a-z][a-z0-9]*:[^"<>]*$/ ) {
                $ns->{$prefix} = $namespace;
            } elsif( $warn ) {
                warn "Skipping invalid $prefix namespace $namespace";
            }
        } elsif ( $warn ) {
            warn "Skipping unusual prefix '$prefix'";
        }
    }
    close($fh);

    bless $ns, (ref($class) || $class);
}

*LOAD = *new;

sub COUNT {
    scalar keys %{$_[0]};
}

sub FORMAT {
    my $self = shift;
	my $format = shift || "";
    $format = 'TTL' if $format =~ /^n(otation)?3$/i;
    if (lc($format) =~ $FORMATS) {
	    $format = uc($format);
	    $self->$format( @_ );
	}
}

sub PREFIX {
	my ($self, $uri) = @_;
        my $retprefix;
	while ( my ($prefix, $namespace) = each %$self ) {
		$retprefix = $prefix if $uri eq $namespace;
	}
	return $retprefix;
}

sub PREFIXES {
	my ($self, $uri) = @_;
	my @prefixes;
	while ( my ($prefix, $namespace) = each %$self ) {
		push @prefixes, $prefix if $uri eq $namespace;
	}
	return @prefixes;
}

sub REVERSE {
    my $self = shift;
    my $lookup = { };
	while ( my ($prefix, $namespace) = each %$self ) {
        my $has = $lookup->{$namespace};
        $lookup->{$namespace} = $prefix unless
            $has and length($has) < length($prefix);
	}
	return $lookup;
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

sub TXT {
    my $self = shift;
    $self->MAP( sub { "$_\t".$self->{$_} } , @_ );
}

sub BEACON {
    my $self = shift;
    $self->MAP( sub { "#PREFIX: ".$self->{$_} } , @_ );
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

sub BLANK {
}

*URI = *uri;

sub uri {
    my $self = shift;
	return $1 if $_[0] =~ /^<([a-zA-Z][a-zA-Z+.-]*:.+)>$/;
	return $self->BLANK($_[0]) if $_[0] =~ /^_(:.*)?$/;
    return unless shift =~ /^([a-z][a-z0-9]*)?([:_]([^:]+))?$/;
    my $ns = $self->{ defined $1 ? $1 : '' };
    return unless defined $ns;
    return $self->GET($ns) unless $3;
    return $self->GET($ns.$3);
}

sub AUTOLOAD {
    my $self = shift;
    return unless $AUTOLOAD =~ /^.*::([a-z][a-z0-9]*)?(_([^:]+)?)?$/;
	return $self->BLANK( defined $3 ? "_:$3" : '_' ) unless $1;
    my $ns = $self->{$1} or return;
    my $local = defined $3 ? $3 : shift;
    return $self->GET($ns) unless defined $local;
    return $self->GET($ns.$local);
}

sub UPDATE {
    my ($self, $file, $date) = @_;

    croak "RDF::NS expects a date as YYYY-MM-DD" 
        unless $date and $date =~ $DATE_REGEXP;
    $date = "$1$2$3"; 

    my $old = RDF::NS->new($file);
    my (@create,@update,@delete);

    open (my $fh, '>>', $file) or croak "failed to open $file";
    my @lines;

    while( my ($prefix,$namespace) = each %$self ) {
        if (!exists $old->{$prefix}) {
            push @create, $prefix;
        } elsif ( $old->{$prefix} ne $namespace ) {
            push @update, $prefix;
        } else {
            next;
        }
        push @lines, "$prefix\t$namespace";
    }
    while( my ($prefix,$namespace) = each %$old ) {
        if (!exists $self->{$prefix}) {
            push @delete, $prefix;
        }
    }

    print $fh "$_\t$date\n" for sort @lines;
    close $fh;

    return {
        create => [ sort @create ],
        update => [ sort @update ],
        delete => [ sort @delete ],
    };
}


1;

=head1 SYNOPSIS

  use RDF::NS '20130327';              # check at compile time
  my $ns = RDF::NS->new('20130327');   # check at runtime

  $ns->foaf;               # http://xmlns.com/foaf/0.1/
  $ns->foaf_Person;        # http://xmlns.com/foaf/0.1/Person
  $ns->foaf('Person');     # http://xmlns.com/foaf/0.1/Person
  $ns->uri('foaf:Person'); # http://xmlns.com/foaf/0.1/Person

  use RDF::NS;             # get rid if typing '$' by defining a constant
  use constant NS => RDF::NS->new('20111208');
  NS->foaf_Person;         # http://xmlns.com/foaf/0.1/Person

  $ns->SPAQRL('foaf');     # PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  $ns->TTL('foaf');        # @prefix foaf: <http://xmlns.com/foaf/0.1/> .
  $ns->XMLNS('foaf');      # xmlns:foaf="http://xmlns.com/foaf/0.1/"

  # load your own mapping from a file
  $ns = RDF::NS->new("mapping.txt");

  # select particular mappings
  %map = $ns->SELECT('rdf,dc,foaf');
  $uri = $ns->SELECT('foo|bar|doz'); # returns first existing namespace

  # instances of RDF::NS are just blessed hash references
  $ns->{'foaf'};           # http://xmlns.com/foaf/0.1/
  bless { foaf => 'http://xmlns.com/foaf/0.1/' }, 'RDF::NS';
  print (scalar keys %$ns) . "prefixes\n";
  $ns->COUNT;              # also returns the number of prefixes

=head1 DESCRIPTION

Hardcoding URI namespaces and prefixes for RDF applications is neither fun nor
maintainable.  In the end we all use more or less the same prefix definitions,
as collected at L<http://prefix.cc>. This module includes all these prefixes as
defined at specific snapshots in time. These snapshots correspond to version
numbers of this module. By selecting particular versions, you make sure that
changes at prefix.cc won't affect your scripts.

The command line client L<rdfns> is installed automatically with this module:

  $ rdfns -ttl rdf,foaf
  @prefix foaf: <http://xmlns.com/foaf/0.1/> .
  @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

This module does not require L<RDF::Trine>, which is recommended nevertheless.
You should install at least RDF::NS 0.140.  If you prefer RDF::NS to return
instances of L<RDF::Trine::Node::Resource> instead of plain strings, use
L<RDF::NS::Trine>.

The code repository of this module also contains an
L<update script|https://github.com/nichtich/RDF-NS/blob/master/update.pl>
to download the current prefix-namespace mappings from L<http://prefix.cc>.

=head1 GENERAL METHODS

In most cases you only need the following lowercase methods.

=head2 new ( $file_or_date [, %options ] )

Create a new namespace mapping from a selected file or date. The special string
C<"any"> can be used to get the newest mapping, but you should better select a
specific version, as mappings can change, violating backwards compatibility.
Supported options include C<warn> to enable warnings and C<at> to specify a
date. 

=head2 E<prefix>

Returns the namespace for E<prefix> if namespace prefix is defined. For
instance C<< $ns->foaf >> returns C<http://xmlns.com/foaf/0.1/>.

=head2 E<prefix_name>

Returns the namespace plus local name, if namespace prefix is defined. For
instance C<< $ns->foaf_Person >> returns C<http://xmlns.com/foaf/0.1/Person>.

=head2 uri ( $short | "<$URI>" )

Expand a prefixed URI, such as C<foaf:Person> or C<foaf_Person>. Alternatively 
you can expand prefixed URIs with method calls, such as C<$ns-E<gt>foaf_Person>.
If you pass an URI wrapped in C<E<lt>> and C<E<gt>>, it will not be expanded
but returned as given.

=head1 SERIALIZATION METHODS

=head2 TTL ( prefix[es] )

Returns a Turtle/Notation3 C<@prefix> definition or a list of such definitions
in list context. Prefixes can be passed as single arguments or separated by
commas, vertical bars, and spaces.

=head2 SPARQL ( prefix[es] )

Returns a SPARQL PREFIX definition or a list of such definitions in list
context. Prefixes can be passed as single arguments or separated by commas,
vertical bars, and spaces.

=head2 XMLNS ( prefix[es] )

Returns an XML namespace declaration or a list of such declarations in list
context. Prefixes can be passed as single arguments or separated by commas,
vertical bars, and spaces.

=head2 TXT ( prefix[es] )

Returns a list of tabular-separated prefix-namespace-mappings.

=head2 BEACON ( prefix[es] )

Returns a list of BEACON format prefix definitions (not including prefixes).

=head1 LOOKUP METHODS

=head2 PREFIX ( $uri )

Get a prefix of a namespace URI, if it is defined. This method does a reverse
lookup which is less performant than the other direction. If multiple prefixes
are defined, it is not determinstic which one is returned. If you need to call
this method frequently, better create a reverse hash (method REVERSE).

=head2 PREFIXES ( $uri )

Get all known prefixes of a namespace URI.

=head2 REVERSE

Create a lookup hash from namespace URIs to prefixes. If multiple prefixes
exist, the shortes will be used.

=head2 SELECT ( prefix[es] )

In list context, returns a sorted list of prefix-namespace pairs, which
can be used to assign to a hash. In scalar context, returns the namespace
of the first prefix that was found. Prefixes can be passed as single arguments
or separated by commas, vertical bars, and spaces.

=head1 INTERNAL METHODS

=head2 MAP ( $code [, prefix[es] ] )

Internally used to map particular or all prefixes. Prefixes can be selected as
single arguments or separated by commas, vertical bars, and spaces. In scalar
context, C<$_> is set to the first existing prefix (if found) and C<$code> is
called. In list context, found prefixes are sorted at mapped with C<$code>.

=head2 GET ( $uri )

This method is used internally to create URIs as return value of the URI
method and all lowercase shortcut methods, such as C<foaf_Person>. By default
it just returns C<$uri> unmodified.

=head1 SEE ALSO

There are several other CPAN modules to deal with IRI namespaces, for instance
L<RDF::Trine::Namespace>, L<RDF::Trine::NamespaceMap>, L<URI::NamespaceMap>,
L<RDF::Prefixes>, L<RDF::Simple::NS>, L<RDF::RDFa::Parser::Profile::PrefixCC>,
L<Class::RDF::NS>, L<XML::Namespace>, L<XML::CommonNS> etc.

=cut

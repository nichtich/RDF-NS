# NAME

RDF::NS - Just use popular RDF namespace prefixes from prefix.cc

# STATUS

[![Build Status](https://travis-ci.org/nichtich/RDF-NS.png)](https://travis-ci.org/nichtich/RDF-NS)
[![Coverage Status](https://coveralls.io/repos/nichtich/RDF-NS/badge.svg?branch=master)](https://coveralls.io/r/nichtich/RDF-NS?branch=master)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/RDF-NS.png)](http://cpants.cpanauthors.org/dist/RDF-NS)

# SYNOPSIS

    use RDF::NS '20230619';              # check at compile time
    my $ns = RDF::NS->new('20230619');   # check at runtime

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

# DESCRIPTION

Hardcoding URI namespaces and prefixes for RDF applications is neither fun nor
maintainable.  In the end we all use more or less the same prefix definitions,
as collected at [http://prefix.cc](http://prefix.cc). This module includes all these prefixes as
defined at specific snapshots in time. These snapshots correspond to version
numbers of this module. By selecting particular versions, you make sure that
changes at prefix.cc won't affect your programs.

The command line client [rdfns](https://metacpan.org/pod/rdfns) is installed automatically with this module:

    $ rdfns rdf,foaf.ttl
    @prefix foaf: <http://xmlns.com/foaf/0.1/> .
    @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

This module does not require [RDF::Trine](https://metacpan.org/pod/RDF::Trine), which is recommended nevertheless.
(at least version 0.140).  If you prefer RDF::NS to return instances of 
[RDF::Trine::Node::Resource](https://metacpan.org/pod/RDF::Trine::Node::Resource) instead of plain strings, use [RDF::NS::Trine](https://metacpan.org/pod/RDF::NS::Trine).
[RDF::NS::URIS](https://metacpan.org/pod/RDF::NS::URIS) is a similar module that returns instances of [URI](https://metacpan.org/pod/URI).

The code repository of this module contains an
[update script](https://github.com/nichtich/RDF-NS/blob/master/update.pl)
to download the current prefix-namespace mappings from [http://prefix.cc](http://prefix.cc).

# GENERAL METHODS

In most cases you only need the following lowercase methods.

## new ( \[ $file\_or\_date \] \[ %options \] )

Create a new namespace mapping from a selected file, date, or hash reference.
The special string `"any"` or the value `1` can be used to get the newest
mapping, but you should better select a specific version, as mappings can
change, violating backwards compatibility.  Supported options include `warn`
to enable warnings and `at` to specify a date. 

## "_prefix_"

Returns the namespace for _prefix_ if namespace prefix is defined. For
instance `$ns->foaf` returns `http://xmlns.com/foaf/0.1/`.

## "_prefix\_name_"

Returns the namespace plus local name, if namespace prefix is defined. For
instance `$ns->foaf_Person` returns `http://xmlns.com/foaf/0.1/Person`.

## uri ( $short | "&lt;$URI>" )

Expand a prefixed URI, such as `foaf:Person` or `foaf_Person`. Alternatively 
you can expand prefixed URIs with method calls, such as `$ns->foaf_Person`.
If you pass an URI wrapped in `<` and `>`, it will not be expanded
but returned as given.

# SERIALIZATION METHODS

## TTL ( prefix\[es\] )

Returns a Turtle/Notation3 `@prefix` definition or a list of such definitions
in list context. Prefixes can be passed as single arguments or separated by
commas, vertical bars, and spaces.

## SPARQL ( prefix\[es\] )

Returns a SPARQL PREFIX definition or a list of such definitions in list
context. Prefixes can be passed as single arguments or separated by commas,
vertical bars, and spaces.

## XMLNS ( prefix\[es\] )

Returns an XML namespace declaration or a list of such declarations in list
context. Prefixes can be passed as single arguments or separated by commas,
vertical bars, and spaces.

## TXT ( prefix\[es\] )

Returns a list of tabular-separated prefix-namespace-mappings.

## BEACON ( prefix\[es\] )

Returns a list of BEACON format prefix definitions (not including prefixes).

# LOOKUP METHODS

## PREFIX ( $uri )

Get a prefix of a namespace URI, if it is defined. This method does a reverse
lookup which is less performant than the other direction. If multiple prefixes
are defined, the first in sorted order is returned. If you need to call this
method frequently and with deterministic response, better create a reverse hash
(method REVERSE).

## PREFIXES ( $uri )

Get all known prefixes of a namespace URI in sorted order.

## REVERSE

Calling `$ns->REVERSE` is equal to `RDF::SN->new($ns)`. See
[RDF::SN](https://metacpan.org/pod/RDF::SN) for details.

## SELECT ( prefix\[es\] )

In list context, returns a sorted list of prefix-namespace pairs, which
can be used to assign to a hash. In scalar context, returns the namespace
of the first prefix that was found. Prefixes can be passed as single arguments
or separated by commas, vertical bars, and spaces.

# INTERNAL METHODS

## SET ( $prefix => $namespaces \[, $warn \] )

Set or add a namespace mapping. Errors are ignored unless enabled as warnings
with the third argument. Returns true if the mapping was successfully added.

## MAP ( $code \[, prefix\[es\] \] )

Internally used to map particular or all prefixes. Prefixes can be selected as
single arguments or separated by commas, vertical bars, and spaces. In scalar
context, `$_` is set to the first existing prefix (if found) and `$code` is
called. In list context, found prefixes are sorted at mapped with `$code`.

## GET ( $uri )

This method is used internally to create URIs as return value of the URI
method and all lowercase shortcut methods, such as `foaf_Person`. By default
it just returns `$uri` unmodified.

# SEE ALSO

There are several other CPAN modules to deal with IRI namespaces, for instance
[RDF::Trine::Namespace](https://metacpan.org/pod/RDF::Trine::Namespace), [RDF::Trine::NamespaceMap](https://metacpan.org/pod/RDF::Trine::NamespaceMap), [URI::NamespaceMap](https://metacpan.org/pod/URI::NamespaceMap),
[RDF::Prefixes](https://metacpan.org/pod/RDF::Prefixes), [RDF::Simple::NS](https://metacpan.org/pod/RDF::Simple::NS), [RDF::RDFa::Parser::Profile::PrefixCC](https://metacpan.org/pod/RDF::RDFa::Parser::Profile::PrefixCC),
[Class::RDF::NS](https://metacpan.org/pod/Class::RDF::NS), [XML::Namespace](https://metacpan.org/pod/XML::Namespace), [XML::CommonNS](https://metacpan.org/pod/XML::CommonNS) etc.

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013- by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

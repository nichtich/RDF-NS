use strict;
use warnings;
use Test::More;

use App::rdfns;

sub test_run {
    my ($argv, $expect, $msg) = @_;

    my $out;
    local *STDOUT;
    open STDOUT, '>', \$out;
    App::rdfns->new->run(@$argv);
    close STDOUT;

    is $out, join("\n", @$expect, ''), $msg;
}

test_run ["geo"] => ['http://www.w3.org/2003/01/geo/wgs84_pos#'],
    "look up URI";
test_run ['http://www.w3.org/2003/01/geo/wgs84_pos#'] => ["geo"],
    "look up prefix";
test_run ['wgs.prefix'] => ["geo"], 'normalize prefix';

# TODO: more tests
    
done_testing;

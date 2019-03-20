#!perl6
use lib 'lib';
use Test;
use Test::Output;

my &test-code = sub {
    say 42;
    note 'warning!';
    say "After warning";
};

my $nl = $*DISTRO.is-win ?? "\r\n" !! "\n";

output-is   &test-code, "42{$nl}warning!{$nl}After warning{$nl}", 'testing output-is';
output-like &test-code, /42.+warning.+After/, 'testing output-like';
stdout-is   &test-code, "42{$nl}After warning{$nl}";
stdout-like &test-code, /42/;
stderr-is   &test-code, "warning!{$nl}";
stderr-like &test-code, /^ "warning!{$nl}" $/;

is output-from( &test-code ), "42{$nl}warning!{$nl}After warning{$nl}",
    'output-from works';
is stdout-from( &test-code ), "42{$nl}After warning{$nl}", 'stdout-from works';
is stderr-from( &test-code ), "warning!{$nl}", 'stderr-from works';

done-testing;

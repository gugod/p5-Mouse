#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

{
    package Bar;
    use Mouse;

    sub baz   { 'Bar::baz' }
    sub gorch { 'Bar::gorch' }

    package Foo;
    use Mouse;

    has 'bar' => (
        is      => 'ro',
        isa     => 'Bar',
        lazy    => 1,
        default => sub { Bar->new },
        handles => [qw[ baz gorch ]]
    );

    package Foo::Extended;
    use Mouse;

    extends 'Foo';

    has 'test' => (
        is      => 'rw',
        isa     => 'Bool',
        default => sub { 0 },
    );

    around 'bar' => sub {
        my $next = shift;
        my $self = shift;

        $self->test(1);
        $self->$next();
    };
}

my $foo = Foo::Extended->new;
isa_ok($foo, 'Foo::Extended');
isa_ok($foo, 'Foo');

ok(!$foo->test, '... the test value has not been changed');

is($foo->baz, 'Bar::baz', '... got the right delegated method');

ok($foo->test, '... the test value has now been changed');









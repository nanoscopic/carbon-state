#!/usr/bin/perl -w

use strict;

use Test::More qw(no_plan);

use_ok( 'Framework::Core' );

is( 'a', 'a', 'simple - normal node value reading' );


#!/usr/bin/perl -w
use strict;
use lib '../../';
use Framework::Core;
my $core = new Framework::Core();

my $mode = $ARGV[0] || '';
$core->run( config => 'config.xml', mode => $mode );
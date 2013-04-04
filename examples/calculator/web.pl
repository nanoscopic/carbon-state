#!/usr/bin/perl -w
use strict;
use lib '../../';
use App::Core;
my $core = new App::Core();

my $mode = $ARGV[0] || '';
$core->run( config => 'config.xml', mode => $mode );
#!/usr/bin/perl -w
use strict;
use lib '../../lib';
use Ginger::Reference::Core;
my $core = new Ginger::Reference::Core();

my $mode = $ARGV[0] || '';
$core->run( config => 'config.xml', mode => $mode );
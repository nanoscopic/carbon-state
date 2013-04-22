#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;
require 5.006;
my @basics = ( AUTHOR       => 'David Helkowski <cpan@codechild.com>',
               ABSTRACT     => 'Application server with modules, logs, sessions, api, and more.',
               NAME         => 'Framework::Core',
               VERSION_FROM => 'Core.pm',
               PREREQ_PM    => {
                    Carp => 0, 
                    Exporter => 0, 
                    "Test::More" => 0, 
                    "XML::Bare" => "0.48", 
                    "Class::Core" => "0.04",
                    "Term::ANSIColor" => 0,
                    "URI::Escape" => 0
               }
             );
if( $ExtUtils::MakeMaker::VERSION >= 6.31 ) {
  push( @basics, LICENSE => 'perl' );
}

WriteMakefile( @basics );

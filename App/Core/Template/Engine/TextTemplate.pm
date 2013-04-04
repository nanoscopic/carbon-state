# App::Core::Template::Engine::TextTemplate
# Version 0.01
# Copyright (C) 2013 David Helkowski

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.  You may also can
# redistribute it and/or modify it under the terms of the Perl
# Artistic License.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

=head1 NAME

App::Core::Template::Engine::TextTemplate - App::Core Component

=head1 VERSION

0.01

=cut

package App::Core::Template::Engine::TextTemplate;
use Class::Core 0.03 qw/:all/;
use strict;
use Carp;
use vars qw/$VERSION/;
use XML::Bare qw/forcearray xval/;
$VERSION = "0.01";
use Data::Dumper;
use App::Core::Template::Default;

# This module should be registered as tpl_engine in the configuration so that other modules can depend upon it properly

sub init {
    my ( $core, $self ) = @_;
    my $conf = $core->getconf(); # get the root of the configuration
    my $tpls = forcearray( $conf->{'tpl'} );
    
    #my $log = $core->getmod('log');
    #$core->dumperx( 'tpls', $tpls );
    
    $self->{'tpls'} = {};
    if( @$tpls ) {
        for my $tpl ( @$tpls ) {
            $self->load_xml( xml => $tpl );
        }
    }
    
}

# In some sense we need to load up all the templates specified in the system configuration
# Templates for pages may be specified either by using a direct filename or using a short template name
# Either way all of the templates should be loaded into memory as objects from the getgo
sub load_all {
    my ( $core, $self ) = @_;
}

sub load_xml { # load a template from it's xml definition
    my ( $core, $self ) = @_;
    if( $self->{'src'} ) { $self = $self->{'src'}; }
    my $xml = $core->get('xml');
    
    #$core->dumperx( 'xml', $xml );
    
    my $tpls = $self->{'tpls'};
    my $name = xval $xml->{'name'};
    
    # If we are just fetching a module fetch and return it
    if( $tpls->{ $name } ) {
        return $tpls->{ $name };
    }
    if( !$xml->{'file'} ) { 
        return $self->get( name => $name ); 
    }
    
    # instantiate a template object and return it
    my $file = xval $xml->{'file'};
    
    my $log = $core->getmod('log');
    $log->note( text => "Loaded template $name from file $file" );
    
    my $tpl = $tpls->{ $name } = App::Core::Template::Default->new( file => $file );
    
    return $tpl;
}

sub load { # given a short name and a path load a template
    # should return the loaded template object at the end
}

sub start { # get and start a template
    my ( $core, $self ) = @_;
    my $name = $core->get('name');
    my $tpl = $self->get( name => $name );
    return $core->requestify( $tpl );
}

sub get { # fetch a loaded template by its short name
    my ( $core, $self ) = @_;
    if( $self->{'src'} ) { $self = $self->{'src'}; }
    my $name = $core->get('name');
    
    my $tpls = $self->{'tpls'};
    #$core->dumper( 'tpls', $tpls );
    if( !$tpls->{$name} ) {
        confess "Cannot fetch template named $name";
    }
    return $tpls->{ $name };
}

1;

__END__

=head1 SYNOPSIS

Component of L<App::Core>

=head1 DESCRIPTION

Component of L<App::Core>

=head1 LICENSE

  Copyright (C) 2013 David Helkowski
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 2 of the
  License, or (at your option) any later version.  You may also can
  redistribute it and/or modify it under the terms of the Perl
  Artistic License.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

=cut
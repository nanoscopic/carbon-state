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

our $spec = "<func name='init_request'/>";

sub init {
    my ( $core, $self ) = @_;
    my $conf = $core->get_conf(); # get the root of the configuration
    my $tpls = forcearray( $conf->{'tpl'} );
    my $xml = $self->{'_xml'};
    my $modrefs = forcearray( $xml->{'moduleref'} );
    my $refs = $self->{'modrefs'} = {};
    for my $modref ( @$modrefs ) {
        my $name = xval $modref->{'name'};
        my $mod = xval $modref->{'mod'};
        $refs->{ $name } = $mod;
    }
    
    #my $log = $core->get_mod('log');
    #$core->dumperx( 'tpls', $tpls );
    
    my $app = $core->get_app();
    $app->register_class( name => 'tpl', file => 'App::Core::Template::Default' ); 
    
    $self->{'tpls'} = {};
    if( @$tpls ) {
        for my $tpl ( @$tpls ) {
            $self->load_xml( xml => $tpl );
        }
    }
    
    
    
}

sub init_request {
    my ( $core, $self ) = @_;
    $self->{'tpls'} = {};
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
    
    my $log = $core->get_mod('log');
    $log->note( text => "Loaded template $name from file $file" );
    
    my $tpl = $tpls->{ $name } = $core->create( 'tpl', file => $file, modulerefs => $self->{'modrefs'} );
    #App::Core::Template::Default->new( file => $file, modulerefs => $self->{'modrefs'} );
    
    return $tpl;
}

sub load { # given a short name and a path load a template
    # should return the loaded template object at the end
}

sub start { # get and start a template
    my ( $core, $self ) = @_;
    my $name = $core->get('name');
    my $tpl = $self->get( name => $name );
    my $tplr = $core->requestify( $tpl );
    my $base = $core->get_base();
    $tplr->set_vars( { tple => $self, base => $base } );
    my $obj = $core->get('obj');
    $tplr->{'mod_to_use'} = $obj;
    return $tplr;
}

sub run_map {
    my ( $core, $self) = @_;
    my $maps = $core->get('map');
    #$core->dumper( 'maps', $maps );
    $maps = forcearray( $maps );
    my $tpls = $self->{'src'}{'tpls'};
    my $ltpls = $self->{'tpls'};
    for my $map ( @$maps ) {
        my $alias = $map->{'alias'};
        my $tpl = $map->{'tpl'};
        $ltpls->{ $alias } = $tpls->{ $tpl };
    }
    #$core->dumper( 'tpls', $tpls,1 );
}

sub run {
    my ( $core, $self ) = @_;
    my $tplname = $core->get('tpl');
    my $vars = $core->get('vars');
    my $tpl = $self->start( name => $tplname );
    $tpl->set_vars( $vars );
    return $tpl->run();
}

sub get { # fetch a loaded template by its short name
    my ( $core, $self ) = @_;
    #if( $self->{'src'} ) { $self = $self->{'src'}; }
    my $name = $core->get('name');
    
    my $tpls = $self->{'src'}{'tpls'};
    my $ltpls = $self->{'tpls'};
    #$core->dumper( 'tpls', $tpls );
    my $ret = $tpls->{ $name } || $ltpls->{ $name };
    if( !$ret ) {
        confess "Cannot fetch template named $name";
    }
    return $ret;
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
# App::Core::File::Server::Default
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

App::Core::File::Server::Default - App::Core Component

=head1 VERSION

0.01

=cut

package App::Core::File::Server::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use vars qw/$VERSION/;
use XML::Bare qw/xval forcearray/;
use Carp;
$VERSION = "0.01";

sub init {
    my ( $core, $self ) = @_; # this self is src
    my $conf = $self->{'conf'} = $core->get_conf();
    my $base = $self->{'base'} = $core->get_base();
    my $types = $conf->{'types'};
    $self->{'cache'} = {};
    $self->register_types( $types );
}

# <types>
#        <type ext='png'      type='image/png'  life='8h' cacheLimit='40k' cacheTotal='4m' />
#        <type ext='jpg,jpeg' type='image/jpeg' life='8h'/>
#        <type ext='gif'      type='image/gif'  life='8h' cacheLimit='10k' cacheTotal='4m' />
#        <type ext='html,htm' type='text/html' />
#        <type ext='js'       type='application/javascript' />
#        <type ext='json'     type='application/json' />
#    </types>

sub register_types {
    my ( $core, $self, $types ) = @_;
    my $typearr = forcearray( $types->{'type'} );
    my $hash = $self->{'exthash'} = {};
    for my $type ( @$typearr ) {
        my $exts = xval $type->{'ext'};
        my $type = xval $type->{'type'};
        my @extarr = split( ',',$exts );
        for my $ext ( @extarr ) {
            $hash->{ $ext } = $type;
        }
    }
}

#<base>/var/web</base>
#    <folder web='static' sys='/blah' allow='\.jpg$'/>
sub register_folders {
    my ( $core, $self ) = @_;
    my $folders = $core->get('folders');
    my $conf = $core->get('conf');
    my $log = $core->get_mod('log');
    my $router = $core->get_mod( 'web_router' );
    my $session = xval $conf->{'session'};
    
    for my $folder ( @$folders ) {
        my $mux = App::Core::mux_dup( $conf, $folder );
        
        my $web = xval $mux->{'url'};
        my $sys = xval $mux->{'sys'};
        my $fileroot = xval $mux->{'fileroot'};
        
        my $from = $fileroot ? "$fileroot/$web" : $web;
        $sys = $fileroot ? "$fileroot/$sys" : $sys;
        
        $log->note( text => "Folder map $session - $from -> $sys" );
        
        $router->route_path( path => $from, obj => 'file_server', func => 'handle_file_req', session => $session, file => 1, extra => { conf => $mux, from => $from, sys => $sys } );
    }
}

sub handle_file_req {
    my ( $core, $self ) = @_;
    my $src = $self->{'src'};
    my $r = $self->{'r'};
    my $conf = $core->get('conf');
    my $from = $core->get('from');
    my $sys = $core->get('sys');
    
    my $base = $src->{'base'};
    
    my $url = $r->{'path'};
    my $log = $core->get_mod('log');
    $log->note(text => "url: $url" );
    $url =~ s|^/$base/||; # first strip off the base
    $log->note(text => "after base removal: $url" );
    if( $url =~ s|^$from/|| ) {
        $log->note( text => "after from removal: $url" );
    
        my $ctype = "text/html";
        if( $url =~ m/\.([a-z]+)$/ ) {
            my $ext = $1;
            my $types = $src->{'exthash'};
            $ctype = $types->{ $ext } || 'text/html';
        }
        
        #my $cache = $self->{'cache'};
        my $file = "$sys/$url";
        if( -e $file ) {
            $r->{'content_type'} = $ctype;
           
            my $data = App::Core::slurp( $file );
            
            #$r->out( text => $data );
            $r->{'body'} = $data;
        }
        else {
            $r->out( text => "File does not exist $file" );
        }
        
    }
    else {
        $r->out( text => 'error' );
    }
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
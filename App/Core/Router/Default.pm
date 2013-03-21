# App::Core::Router::Default
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

App::Core::Router::Default - App::Core Component

=head1 VERSION

0.02

=cut

package App::Core::Router::Default;
use strict;
use Class::Core 0.03 qw/:all/;
use Data::Dumper;
use XML::Bare qw/xval/;
use vars qw/$VERSION/;
$VERSION = "0.02";

sub init {
    my ( $core, $self_src ) = @_;
    $self_src->{'path_routes'} = {};
    my $base = $self_src->{'base'} = xval( $core->getconf()->{'base'} );
    my $app = $core->getapp();
    my $log = $self_src->{'log'} = $app->getmod( mod => 'log' );
    $self_src->{'perm'} = $app->getmod( mod => 'perm_man' );
    $log->note( text => "Routing with web base of: $base" );
}

sub route {
    my ( $core, $self ) = @_;
    my $sman  = $core->get('session_man');
    my $r     = $self->{'r'};
    my $path  = $r->{'path'};
    my $query = $r->{'query'};
    my $post  = $r->{'post'};
    my $app   = $self->{'obj'}{'_app'}; # perhaps $core->getapp() would be better here
    my $rs    = $self->{'src'}{'path_routes'};
    my $perm  = $self->{'src'}{'perm'};
    
    my $base = $self->{'src'}{'base'};
    if( $base ne '' && $path =~ m|^/$base/(.+)| ) {
        $path = $1;
    }
    else {
        $r->out( text => 'error' );
        $r->notfound(); 
        return;
    }
    
    my $opath = $path;
    $path =~ s|^/||g;
    $path =~ s|/$||g;
    
    my $resolved = 0;
    my $full = 1;
    my @parts = split('/',$path );
    while( @parts ) {
        my $joined = join('/', @parts );
        print "Testing $joined\n";
        my $info;
        if( $info = $rs->{ $joined } ) {
            my $objname      = $info->{'obj'};
            my $obj          = $r->getmod( mod => $objname );
            my $func         = $info->{'func'};
            my $session_name = $info->{'session'} || 'DEFAULT';
            my $bounce       = $info->{'bounce'};
            
            my $session      = $sman->get_session( r => $r, cookie => $session_name );
            if( $session ) {
                print "Loaded a session\n";
                $session->show();
                $r->set_permissions( perms => $perm->user_get_permissions( user => $session->get_user() ) );
            }
            if( $bounce && !$session ) {
                print "Bounce to $bounce\n";
                $r->redirect( url => $bounce );
                return;
            }
            
            if( $full && $info->{'folder'} && $opath !~ m|/$| ) {
                $r->redirect( url => "$path/" );
                return;
            }
            
            my $res = $obj->$func();
            $resolved = 1;
            last;
        }
        $full = 0;
        pop @parts;
    }
    
    if( !$resolved ) {
        $r->notfound();
        my $out = '';
        $out .= "<h2>Unhandled URL</h2>";
        $out .= "Path: $path<br>";
        $out .= "Query: ".Dumper($query)."<br>";
        $post ||= '';
        $out .= "Post: $post<br>";
        $r->out( text => $out );
    }
}

# Note that this should only be called from init functions
sub route_path {
    my ( $core, $self_src ) = @_;
    # path, obj, func
    my ( $path, $obj, $func, $session, $bounce ) = $core->getarr( qw/path obj func session bounce/ );
    
    #print "Adding path to $path\n";
    $self_src->{'path_routes'}{ $path } = {
        obj => $obj, 
        func => $func, 
        session => $session, 
        bounce => $bounce,
        folder => 1
    };
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
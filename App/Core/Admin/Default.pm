# App::Core::Admin::Default
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

App::Core::Admin::Default - App::Core Component

=head1 VERSION

0.02

=cut

package App::Core::Admin::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use Data::Dumper;
use XML::Bare qw/xval/;

use vars qw/$VERSION/;
$VERSION = "0.02";

sub init {
    my ( $core, $self ) = @_; # this self is src
    my $conf = $self->{'conf'} = $core->get('conf');
    my $router = $core->getmod( 'web_router' );
    $router->route_path( path => "login", obj => 'core_admin', func => 'login', session => 'ADMIN' );
    $router->route_path( path => "admin", obj => 'core_admin', func => 'admin', session => 'ADMIN', bounce => 'login' );
    $self->{'base'} = xval( $core->getconf()->{'base'} );
}

sub admin {
    my ( $core, $self ) = @_;
    #$core->set('html', 'test' );
    $self->{'r'}->out( text => "
        <h2>App::Core Admin</h2>
        <ul>
        <li>test
        </ul>
        " );
}

sub login {
    my ( $core, $self ) = @_;
    my $base = $self->{'src'}{'base'};
    my $r = $self->{'r'};
    my $cookieman = $r->getmod( mod => 'cookie_man' );
    
    if( $r->{'notice'} ) {
        #my $tmp = $r->{'tmp_notice'};
        #$core->set( 'html', $tmp );
        #print "Temp notice: $tmp\n";
        return;
    }
    print Dumper( $r->{'postvars'} );
    
    $r->out( text => '<h2>App::Core Admin Login</h2>' );
    if( $r->{'type'} eq 'post' ) {
        my $postvars = $r->{'postvars'};
        my $user = $postvars->{'user'};
        my $pw = $postvars->{'pw'};
        $r->out( text => "Login attempt by $user<br>" );
        my $perm_man = $r->getmod( mod => 'perm_man' );
        
        my $res = $perm_man->check( user => $user, password => $pw );
        if( $res->getres('ok') ) {
            $r->out( text => "Admin login success<br>" );
            
            my $sessionman = $r->getmod( mod => 'session_man' );
            $sessionman = $sessionman->{'src'}; # we want the global one, not the request specific one
            my $session = $sessionman->create_session();
            my $sid = $session->getid();
            
            my $cookie = $cookieman->create( name => 'ADMIN', content => { session_id => $sid }, path => '/', expires => 'Tue, 28-Mar-2013 19:51:45 GMT' );
            $cookieman->clear();
            $cookieman->add( cookie => $cookie );
            
            $r->redirect( url => "admin" );
        }
    }
    
    $r->out( text => "
    <form method='post' enctype='multipart/form-data' action='/$base/login/?postid=10'>
    <table>
        <tr>
            <td>User</td>
            <td><input type='text' name='user'></td>
        </tr>
        <tr>
            <td>Password</td>
            <td><input type='password' name='pw'></td>
        </tr>
        <!--<tr>
            <td>File</td>
            <td><input type='file' name='myfile'></td>
        </tr>-->
    </table>
    <input type='submit' value='Login'>
    </form>" );
    #$core->set( 'html', $html );
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
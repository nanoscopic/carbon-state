# Framework::Core::Admin::Default
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

Framework::Core::Admin::Default - Framework::Core Component

=head1 VERSION

0.01

=cut

package Framework::Core::Admin::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use Data::Dumper;

sub init {
    my ( $core, $self ) = @_;
    my $conf = $self->{'conf'} = $core->get('conf');
    my $router = $core->getmod( 'web_router' )->{'ret'};
    $router->route_path( path => "perl/login", obj => 'core_admin', func => 'login' );
}

sub login {
    my ( $core, $self ) = @_;
    my $r = $self->{'r'};
    print Dumper( $r->{'post'} );
    $core->set( 'html', "
    <h2>Login</h2>
    <form method='post' enctype='multipart/form-data'>
    <table>
        <tr>
            <td>User</td>
            <td><input type='text' name='user'></td>
        </tr>
        <tr>
            <td>Password</td>
            <td><input type='password' name='pw'></td>
        </tr>
        <tr>
            <td>File</td>
            <td><input type='file' name='myfile'></td>
        </tr>
    </table>
    <input type='submit' value='Login'>
    </form>
    
    " );
    $core->set('cookie','2');
}

1;

__END__

=head1 SYNOPSIS

Component of L<Framework::Core>

=head1 DESCRIPTION

Component of L<Framework::Core>

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
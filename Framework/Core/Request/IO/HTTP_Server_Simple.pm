# Framework::Core::Request::IO::HTTP_Server_Simple
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

Framework::Core::Request::IO::HTTP_Server_Simple - Framework::Core Component

=head1 VERSION

0.02

=cut

package Framework::Core::Request::IO::HTTP_Server_Simple;
use strict;
use Class::Core 0.03 qw/:all/;
use Framework::Core::Shared::HTTP_Server_Simple_Wrapper;
use Data::Dumper;

use vars qw/$VERSION/;
$VERSION = "0.02";

sub init {
    my ( $core, $self ) = @_;
}

sub run {
    my ( $core, $self ) = @_;
    my $app = $self->{'obj'}{'_app'};
    $self->{'router'} = $app->get_mod( mod => 'web_router' );
    $self->{'log'} = $app->get_mod( mod => 'log' );
    #print Dumper( $self->{'router'}{'route'} );
    #print Dumper( $self->{'router'} );
    my $server = Framework::Core::Shared::HTTP_Server_Simple_Wrapper->new( 8083 );
    $server->set_handler( \&go, $self );
    $server->run();
}

sub go {
    my ( $cgi, $self ) = @_;
    my $app = $self->{'obj'}{'_app'};
    my $path = $cgi->path_info();
    my $log = $self->{'log'};
    $log->note( text => "Recieved web request for $path" );
    my $router = $self->{'router'};
    $router->route( blah => 'test');
    print "$path test\n";
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



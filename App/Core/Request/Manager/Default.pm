# App::Core::Request::Manager::Default
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

App::Core::Request::Manager::Default - App::Core Component

=head1 VERSION

0.02

=cut

package App::Core::Request::Manager::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use vars qw/$VERSION/;
use App::Core::Request::Default 0.01;
$VERSION = "0.02";

sub init {
    my ( $core, $self ) = @_;
    #my $app = $core->get('app');
    #$self->{'app'};
}

sub new_request {
    my ( $core, $manager ) = @_;
    my $app = $core->get_app();
    my $path = $core->get( 'path' );
    # query post cookies
    my $query = $core->get('query');
    my $post = $core->get('post');
    my $cookies = $core->get('cookies');
    my $ip = $core->get('ip');
    my $postvars = $core->get('postvars');
    my $type = $core->get('type');
    #print Dumper( $cookies );
    
    my $req = App::Core::Request::Default->new( 
        app => $app,
        path => $path,
        query => $query,
        post => $post,
        cookies => $cookies,
        ip => $ip,
        postvars => $postvars,
        type => $type );
    
    $req->init();
    
    return $req;
    #app
    #  conf
    #  obj
    #  r
    #  session
    #  modhash ( modules by name )
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
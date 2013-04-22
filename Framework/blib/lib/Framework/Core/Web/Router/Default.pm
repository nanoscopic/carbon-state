# Framework::Core::Web::Router::Default
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

Framework::Core::Web::Router::Default - Framework::Core Component

=head1 VERSION

0.01

=cut

package Framework::Core::Web::Router::Default;
use strict;
use Class::Core 0.03 qw/:all/;
use Data::Dumper;

sub init {
    my ( $core, $self_src ) = @_;
    $self_src->{'path_routes'} = {};
    
}

#my $body = $router->route( path => $path, query => $uri->{'query'}, post => $post )->{'ret'};
sub route {
    my ( $core, $self ) = @_;
    my $r = $self->{'r'};
    my $path = $r->{'path'};
    my $query = $r->{'query'};
    my $post = $r->{'post'};
    
    my $app = $self->{'obj'}{'_app'};
    #my $cookieman = $app->getmod( mod => 'cookie_man')->{'ret'};
    
    #print ref( $cookieman );
    
    #my $b = $cookieman->get( name => 'B' )->{'ret'};
    #print Dumper( $b );
    my $cookies = $r->{'cookies'};
    #print Dumper( $cookies );
    
    my $out = '';
    
    
    my $rs = $self->{'src'}{'path_routes'};
    $path =~ s|^/||g;
    $path =~ s|/$||g;
    my @parts = split('/',$path );
    while( @parts ) {
        my $joined = join('/', @parts );
        my $info;
        if( $info = $rs->{ $joined } ) {
            my $objname = $info->[0];
            my $obj = $r->getmod( mod => $objname )->{'ret'};
            my $func = $info->[1];
            # print "Found func $func to call\n";
            my $res = $obj->$func();
            my $html = $res->getres('html');
            $out .= $html;
            my $newcookie = $res->getres('cookie');
            print "Trying to add a cookie\n";
            last;
        }
        shift @parts;
    }
    
    if( !$out ) {
        $out .= "<h2>Unhandled URL</h2>";
        $out .= "Path: $path<br>";
        $out .= "Query: ".Dumper($query)."<br>";
        $out .= "Post: $post<br>";
    }
    
    #print "route got called\n";
    return $out;
}

# Note that this should only be called from init functions
sub route_path {
    my ( $core, $self_src ) = @_;
    # path, obj, func
    my ( $path, $obj, $func ) = $core->getarr( qw/path obj func/ );
    #print "Adding path to $path\n";
    $self_src->{'path_routes'}{ $path } = [ $obj, $func ];
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
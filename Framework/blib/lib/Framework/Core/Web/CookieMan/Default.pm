# Framework::Core::Web::CookieMan::Default
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

Framework::Core::Web::CookieMan::Default - Framework::Core Component

=head1 VERSION

0.01

=cut

package Framework::Core::Web::CookieMan::Default;
use strict;
use Class::Core 0.03 qw/:all/;
use Data::Dumper;
#use URI::Encode;
use URI::Escape qw/uri_escape uri_unescape/;

sub init {
    my ( $core, $self ) = @_;
    $self->{'cookies'} = [];
    $self->{'byname'} = {};
}

sub parse {
    my ( $core, $self ) = @_;
    my $raw = $core->get('raw');
    #'MY_COOKIE=BEST_COOKIE%3Dchocolatechip; B=BEST_COOKIE%3Dchocolatechip',
    my @rawcookies = split( '; ', $raw );
    my @cookies;
    my $byname = $self->{'byname'};
    for my $rawcookie ( @rawcookies ) {
        $rawcookie =~ m/^([A-Z_]+)=(.+)/;
        my $name = $1;
        my $cookie = { name => $name, content => uri_unescape( $2 ) };
        $byname->{ $name } = $cookie;
        push( @cookies, $cookie );
    }
    #return \@cookies;
    #print Dumper( \@cookies );
    return $self->{'cookies'} = \@cookies;
}

sub clear {
    my ( $core, $self ) = @_;
    $self->{'cookies'} = [];
    $self->{'byname'} = {};
}

sub get {
    my ( $core, $self ) = @_;
    my $name = $core->get('name');
    #print Dumper( $self->{'byname'} );
    return $self->{'byname'}{$name};
}

sub add {
    my ( $core, $self ) = @_;
    my $cookie = $core->get('cookie');
    my $name = $cookie->{'name'};
    $self->{'byname'}{$name} = $cookie;
    my $cookies = $self->{'cookies'};
    push( @$cookies, $cookie );
}

sub create {
    my ( $core, $self ) = @_;
    my $name    = $core->get('name');
    my $content = $core->get('content');
    my $path    = $core->get('path');
    my $expires = $core->get('expires');
     
    #my $raw = uri_escape( $content );
    
    #my $c1 = $cookieman->create( name => 'MY_COOKIE', content => 'a=test1', path => '/', expires => 'Tue, 12-Feb-2013 19:51:45 GMT' );
    #$headers .= "Set-Cookie: MY_COOKIE=BEST_COOKIE\%3Dchocolatechip; path=/; expires=Tue, 12-Feb-2013 19:51:45 GMT\r\n";
    #    $headers .= "Set-Cookie: B=BEST_COOKIE\%3Dchocolatechip; path=/; expires=Tue, 12-Feb-2013 19:51:45 GMT\r\n";
    return { name => $name, content => $content, path => $path, expires => $expires };
}

sub toraw {
    my $info = shift;
    my $rawcontent = uri_escape( $info->{'content'} );
    my $path = $info->{'path'};
    my $expires = $info->{'expires'};
    return $info->{'name'}."=$rawcontent; path=$path; expires=$expires";
}

sub setheader {
    my ( $core, $self ) = @_;
    #my $cookies = $core->get('cookies');
    my $cookies = $self->{'cookies'};
    #print Dumper( $cookies );
    my $headers = '';
    for my $cookie ( @$cookies ) {
        my $raw = toraw( $cookie );
        $headers .= "Set-Cookie: $raw\r\n";
    }
    return $headers;
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



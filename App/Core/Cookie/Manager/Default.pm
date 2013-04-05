# App::Core::Cookie::Manager::Default
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

App::Core::Cookie::Manager::Default - App::Core Component

=head1 VERSION

0.02

=cut

# my $c1 = $cookieman->create( name => 'MY_COOKIE', content => 'a=test1', path => '/', expires => 'Tue, 16-Feb-2013 19:51:45 GMT' );
            # my $c2 = $cookieman->create( name => 'B'        , content => 'b=test2', path => '/', expires => 'Tue, 16-Feb-2013 19:51:45 GMT' );
            # $cookieman->add( cookie => $c1 );
            # $cookieman->add( cookie => $c2 );

package App::Core::Cookie::Manager::Default;
use strict;
use Class::Core 0.03 qw/:all/;
use Data::Dumper;
#use URI::Encode;
use URI::Escape qw/uri_escape uri_unescape/;
use Carp;

use vars qw/$VERSION/;
$VERSION = "0.02";

sub init {
    my ( $core, $self ) = @_;
    $self->{'cookies'} = [];
    $self->{'byname'} = {};
}

sub parse {
    my ( $core, $self ) = @_;
    #print "Parsing cookies\n";
    my $raw = $core->get('raw');
    #'MY_COOKIE=BEST_COOKIE%3Dchocolatechip; B=BEST_COOKIE%3Dchocolatechip',
    my @rawcookies = split( '; ', $raw );
    my @cookies;
    $self->{'byname'} ||= {};
    my $byname = $self->{'byname'};
    for my $rawcookie ( @rawcookies ) {
        if( $rawcookie =~ m/^([A-Z_]+)=(.+)/ ) {
            my $name = $1;
            my $cookie = { name => $name, content => decode( uri_unescape( $2 ) ) };
            #print "Decoded cookie:\n";
            #print Dumper( $cookie );
            print "Found cookie named $name\n";
            $byname->{ $name } = $cookie;
            push( @cookies, $cookie );
        }
        elsif( $rawcookie =~ m/^([A-Z_]+)=/ ) {
            my $name = $1;
            my $cookie = { name => $name, content => {} };
            #$byname->{ $name } = $cookie;
            #push( @cookies, $cookie );
        }
        else {
            die "cookie is not of form: ([A-Z_]+)=(.+)\nIs: $rawcookie";
        }
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

sub showall {
    my ( $core, $self ) = @_;
    print Dumper( $self->{'byname'} );
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
    #print "Adding cookie:\n";
    #print Dumper( $cookie );
    $self->{'byname'}{$name} = $cookie;
    my $cookies = $self->{'cookies'};
    push( @$cookies, $cookie );
}

sub decode {
    #my ( $core, $self ) = @_;
    #my $raw = $core->get('raw');
    my $raw = shift;
    if( !$raw ) { confess( 'raw not set' ); }
    my $hash = {};
    while( $raw =~ m'([a-z_]+)=(.+[^\\])(\&|$)'g ) {
        my $key = $1;
        my $val = $2;
        $val =~ s/\\(.)/$1/g;
        print "$key = $val\n";
        $hash->{ $key } = $val;                  
    }
    return $hash;
}

sub create {
    my ( $core, $self ) = @_;
    my $name    = $core->get('name');
    my $content = $core->get('content'); # ( can be text or a hash ref )
    my $path    = $core->get('path');
    my $expires = $core->get('expires');
    #if( ref( $content ) eq 'HASH' ) {
    #    my @set;
    #    for my $key ( keys %$content ) {
    #        my $str = "$key=";
    #        my $val = $content->{ $key };
    #        $val =~ s|([=&\\])|\\$1|g;
    #        $str .= $val;
    #        push( @set, $str );
    #    }
    #    $content = join( '&', @set );
    #}
     
    #my $raw = uri_escape( $content );
    
    #my $c1 = $cookieman->create( name => 'MY_COOKIE', content => 'a=test1', path => '/', expires => 'Tue, 12-Feb-2013 19:51:45 GMT' );
    #$headers .= "Set-Cookie: MY_COOKIE=BEST_COOKIE\%3Dchocolatechip; path=/; expires=Tue, 12-Feb-2013 19:51:45 GMT\r\n";
    #    $headers .= "Set-Cookie: B=BEST_COOKIE\%3Dchocolatechip; path=/; expires=Tue, 12-Feb-2013 19:51:45 GMT\r\n";
    return { name => $name, content => $content, path => $path, expires => $expires };
}

sub flatten {
    my $cookie = shift;
    my $content = $cookie->{'content'};
    if( ref( $content ) eq 'HASH' ) {
        my @set;
        for my $key ( keys %$content ) {
            my $str = "$key=";
            my $val = $content->{ $key };
            $val =~ s|([=&\\])|\\$1|g;
            $str .= $val;
            push( @set, $str );
        }
        $content = join( '&', @set );
    }
    return $content;
}

sub to_raw {
    my $info = shift;
    #print Dumper( $info );
    my $rawcontent = uri_escape( flatten( $info ) );
    my $path = $info->{'path'};
    my $expires = $info->{'expires'};
    if( !$expires ) {
        return 0;
    }
    return $info->{'name'}."=$rawcontent; path=$path; expires=$expires";
}

sub set_header {
    my ( $core, $self ) = @_;
    #my $cookies = $core->get('cookies');
    my $cookies = $self->{'cookies'};
    #print Dumper( $cookies );
    my $headers = '';
    for my $cookie ( @$cookies ) {
        my $raw = to_raw( $cookie );
        $headers .= "Set-Cookie: $raw\r\n" if( $raw );
    }
    return $headers;
}

# this returns -just- the cookie data
sub raw_cookies {
    my ( $core, $self ) = @_;
    my $cookies = $self->{'cookies'};
    my @set;
    for my $cookie ( @$cookies ) {
        #print Dumper( $cookie );
        my $raw = $cookie->{'name'}."=".uri_escape( flatten( $cookie ) );
        push( @set, $raw ) if( $raw );
    }
    return \@set;
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



# App::Core::Request::IO::Virtual
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

App::Core::Request::IO::Virtual - App::Core Component

=head1 VERSION

0.02

=cut

package App::Core::Request::IO::Virtual;
use strict;
use ZMQ::LibZMQ3;
use Class::Core 0.03 qw/:all/;
use Data::Dumper;
use ZMQ::Constants qw/ZMQ_PULL ZMQ_PUB ZMQ_IDENTITY ZMQ_RCVMORE ZMQ_POLLIN/;
use URI::Simple;
use CGI;
use Text::TNetstrings qw/:all/;
use threads;
use threads::shared;
use XML::Bare qw/xval forcearray/;
use Carp;

use vars qw/$VERSION/;
$VERSION = "0.02";

sub init {
    my ( $core, $self ) = @_;
    my $app = $self->{'obj'}{'_app'};
    my $sman = $self->{'session_man'} = $app->getmod( mod => 'session_man' );
    if( !$sman ) {
        confess( "Cannot find session manager" );
    }
}

sub end {
    my ( $core, $self ) = @_;
}

sub run {
    my ( $core, $self ) = @_;
    
    my $app = $core->getapp();
    $self->{'request_man'} = $app->getmod( mod => 'request_man' );
    my $log = $self->{'log'} = $app->getmod( mod => 'log' );
    my $conf = $self->{'_xml'};
    my $cookies = [];
    if( $conf->{'script'} ) {
        my $script = xval $conf->{'script'};
        my ( $ob, $xml ) = XML::Bare->new( file => $script );
        if( !$xml ) { die "Cannot load $script" };
        $xml = $xml->{'xml'};
        my $reqs = forcearray( $xml->{'req'} );
        for my $req ( @$reqs ) {
            my $path = xval $req->{'path'};
            my $post = {};
            my $get = {};
            if( $req->{'post'} ) {
                $post = App::Core::simplify( $req->{'post'} );
            }
            if( $req->{'get'} ) {
                $get = App::Core::simplify( $req->{'get'} );
            }
            my $resp = $self->virtual_request( path => $path, post => $post, query => $get, cookies => $cookies );
            $cookies = $resp->getres('cookies');
            #print Dumper( $cookies );
            my $body = $resp->getres('body');
            my $restype = $resp->getres('restype');
            my $r = $resp->getres('r');
            if( $restype eq 'redirect' ) {
                my $url = $r->{'url'};
                print "Redirect to $url\n";
            }
            else {
                print "Restype: $restype\n";
                print "HTML for $path:\b";
                print $body;
            }
            
        }
    }
    else {
        $log->note( text => "Virtual request module loaded, but there is no script to follow" );
    }
}

# usage
# r( path => '', post => {}, query => {} )
# r( path => '', type => 'post', query => {}, cookie => 'fsdfs' )
sub virtual_request {
    my ( $core, $self ) = @_;
    
    my $app      = $self->{'obj'}{'_app'};
    my $log      = $self->{'log'};
    my $sman     = $self->{'session_man'};
    my $rman     = $self->{'request_man'};
    my $path     = $core->get('path');
    my $postvars = $core->get('post') || {};
    my $intype   = $core->get('type');
    my $cookiet  = $core->get('cookie'); # cookie text
    my $cookies_arr = $core->get('cookies');
    my $type;
    
    if( $cookies_arr ) {
        $cookiet = join('; ',@$cookies_arr );
    }
    
    if( $intype && $intype eq 'post' ) {
        $type = 'post';
    }
    else {
        $type = %$postvars ? 'post' : 'get';
    }
    
    $log->note( text => "Virtual request to $path");
            
    my $hash = {
        'content-type' => '',
        'x-forwarded-for' => 'virtual',
        'cookie' => $cookiet
        # ...
    };
    
    # url?var=10
    my $queryhash = $core->get('query') || {};
        
    my $content_type = $hash->{'content-type'};
    
    # TODO: add a way to post files virtually
    # type = largepost_notice
    # type = largepost
        
    my $r = $rman->new_request(
        path     => $path,
        query    => $queryhash,
        postvars => $postvars,
        ip       => $hash->{'x-forwarded-for'},
        type     => $type
        );
    
    my $cookieman = $r->getmod( mod => 'cookie_man' );
    if( $hash->{'cookie'} ) {
        #print Dumper( $hash->{'cookie'} );
        $cookieman->parse( raw => $hash->{'cookie'} );
    }
    
    my $router = $r->getmod( mod => 'web_router' );

    my $res = $router->route( session_man => $sman );
    
    #print "Cookies after request\n";
    
    
    if( $type =~ m/notice/ ) {
        return { restype => 'none' };
    }
    
    my $typeinfo = $r->get_type();
    my $restype = $typeinfo->getres('type') || 'normal';
    
    my $code = $r->get_code();
    my $body = $r->get_body();
    
    my $headers = $r->get_headers();
    #$headers .= $cookieman->setheader();
    #print Dumper( $cookieman->{'cookies'} );
    my $rawcookies = $cookieman->rawcookies();
    
    #print Dumper( $rawcookies );
    $r->end();
    
    $core->set('r', $r );
    $core->set('cookies',$rawcookies);
    $core->set('restype',$restype );
    if( $restype eq 'redirect' ) {
        $core->set('url',$r->{'url'} );
    }
    $core->set('code', $code );
    $core->set('body', $body );
    $core->set('headers', $headers );
}

1;

__END__

=head1 SYNOPSIS

Component of L<App::Core> that handles created and sending virtual web requests.

=head1 DESCRIPTION

Description

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
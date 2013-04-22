# Framework::Core::Web::Request::Mongrel2
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

Framework::Core::Web::Request::Mongrel2 - Framework::Core Component

=head1 VERSION

0.01

=cut

package Framework::Core::Web::Request::Mongrel2;
use Class::Core 0.03 qw/:all/;
use strict;
use Data::Dumper;
use ZMQ::LibZMQ3;
#use ZMQ::Constants ':all';
use ZMQ::Constants qw/ZMQ_PULL ZMQ_PUB ZMQ_IDENTITY/;
use URI::Simple;
use CGI;
use Text::TNetstrings qw/:all/;
use threads;

sub wait_threads {
    while( 1 ) {
        my @joinable = threads->list(threads::joinable);
        my @running = threads->list(threads::running);
        
        for my $thr ( @joinable ) { $thr->join(); }
        last if( !@running );
        sleep(1);
    }
}

sub init {
    my ( $core, $self ) = @_;
    my $app = $self->{'obj'}{'_app'};
    my $sman = $self->{'session_man'} = $app->getmod( mod => 'session_man' )->{'ret'};
    if( !$sman ) {
        die "Cannot find session manager\n";
    }
}

sub run {
    my ( $core, $self ) = @_;
    
    #use Module::Test;
    my $t2 = $core->create("Module::test");
    print "session: ".$t2->{'session'}."\n";
    
    #for my $key ( keys %$self ) {
    #    print "  $key\n";
    #}
    my $app = $self->{'obj'}{'_app'};
    $self->{'cookieman'} = $app->getmod( mod => 'cookie_man' )->{'ret'};
    #print Dumper( $app );
    #$self->{'router'} = $app->getmod( mod => 'web_router' )->{'ret'};
    $self->{'log'} = $app->getmod( mod => 'log' )->{'ret'};
    threads->create( \&server, $self );
}

sub server {
    my $self = shift;
    my $app = $self->{'obj'}{'_app'};
    
    my $log = $self->{'log'};
    my $sman = $self->{'session_man'};
    #my $router = $self->{'router'};
    my $cookieman = $self->{'cookieman'};
    my $ctx = zmq_init();
    my $incoming = zmq_socket( $ctx, ZMQ_PULL );
    my $outgoing = zmq_socket( $ctx, ZMQ_PUB );
    zmq_connect( $incoming, "tcp://fedora:6768" );
    zmq_connect( $outgoing, "tcp://fedora:6769" );
    zmq_setsockopt( $incoming, ZMQ_IDENTITY, 'blah' );
    zmq_setsockopt( $outgoing, ZMQ_IDENTITY, 'blah2' );
    my $q = new CGI;
    for( my $i=0;$i<100;$i++ ) {
        my $buffer;
        zmq_recv( $incoming, $buffer, 10000 );
        
        $buffer =~ m/^([^ ]+) ([^ ]+) ([^ ]+) (.+)$/s;
        my $sender = $1;
        my $id = $2;
        my $path = $3;
        my $data = $4;
        # $data =~ s/\0*$//; remove the null from the end for printing more easily
        
        $data =~ m/^([0-9]+):/; 
        
        my $tnetlen = $1;
        my $lenlen = length( $tnetlen );
        
        my $extra = length( $data ) - ( $tnetlen + $lenlen + 2 );
        my $post = '';
        if( $extra > 0 ) {
            my $xstr = substr( $data, $tnetlen + $lenlen + 2 );
            $xstr =~ s/,\0*$//;
            if( $xstr eq '0:' ) {
            }
            elsif( $xstr eq '21:{"type":"disconnect"}' ) {
                print "Disconnect of $id\n";
                next;
            }
            else {
                $post = $xstr;
                $post =~ s/^([0-9]+)://; 
                #$post =~ s/\0*$//;
                #print "Post: $xstr\n";
            }
        }
        
        $log->note( text => "Recieved request to $path");
        #print "sender=$sender\nid=$id\npath=$path\n";
                
        my $hash = decode_tnetstrings( $data );
        my $content_type = $hash->{'content-type'};
        if( $content_type =~ m|^multipart/form-data; boundary=(.+)$| ) {
            my $bound = "--$1";#\r\n
            my @postarr = split( $bound, $post );
            shift @postarr;
            while( @postarr ) {
                my $part = shift @postarr;
                last if( $part =~ m"^--" );
                print "Part:".Dumper( $part )."\n";
                # Example parts:
                # Content-Disposition: form-data; name="pw"
                # Content-Disposition: form-data; name="myfile"; filename="test.txt"
                # Content-Type: text/plain
            }
        }
        my $queryhash = 0;
        if( $hash && $hash->{'QUERY'} ) {
            my $query = $hash->{'QUERY'};
            my $uri = new URI::Simple( "http://test.com/?$query" );
            $queryhash = $uri->{'query'};
        }
        #print Dumper( $uri->{'query'} );
        print Dumper( $hash );
        # 'user-agent' => 'Mozilla/5.0 (Windows NT 6.1; rv:17.0) Gecko/17.0 Firefox/17.0',
        # 'connection' => 'keep-alive',
        # 'URI' => '/perl/test?fs=3',
        # 'cache-control' => 'max-age=0',
        # 'accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        # 'QUERY' => 'fs=3',
        # 'accept-language' => 'en-US,en;q=0.5',
        # 'accept-encoding' => 'gzip,deflate',
        # 'cookie' => 'MY_COOKIE=BEST_COOKIE%3Dchocolatechip; B=BEST_COOKIE%3Dchocolatechip',
        # 'host' => 'fedora:6767',
        # 'PATH' => '/perl/test',
        # 'PATTERN' => '/perl/',
        # 'x-forwarded-for' => '127.0.0.3',
        # 'VERSION' => 'HTTP/1.1',
        # 'METHOD' => 'GET'
        my $cookies = 0;
        my $session = 0;
        #print Dumper( $hash );
        if( $hash->{'cookie'} ) {
            $cookies = $cookieman->parse( raw => $hash->{'cookie'} )->{'ret'};
            #print Dumper( $cookies );
        }
        
        my $r = $app->new_request(
            path => $path,
            query => $queryhash,
            post => $post,
            cookies => $cookies,
            ip => $hash->{'x-forwarded-for'}
            )->{'ret'};
        #print Dumper( $sman->{'obj'} );
        $r->{'session'} = $sman->get_session( r => $r )->{'ret'};
        
        my $router = $r->getmod( mod => 'web_router' )->{'ret'};
        my $body = $router->route()->{'ret'};
        #print "Got $body back from router\n";
        
        #my $body = "test<br>$i";
        my $headers = "Content-Type: text/html; charset=ISO-8859-1\r\n";
        my $blen = length( $body );
        $headers .= "Content-Length: $blen\r\n";
        
        my $c1 = $cookieman->create( name => 'MY_COOKIE', content => 'a=test1', path => '/', expires => 'Tue, 16-Feb-2013 19:51:45 GMT' )->{'ret'};
        my $c2 = $cookieman->create( name => 'B'        , content => 'b=test2', path => '/', expires => 'Tue, 16-Feb-2013 19:51:45 GMT' )->{'ret'};
        #print Dumper( $c1 );
        $cookieman->clear();
        $cookieman->add( cookie => $c1 );
        $cookieman->add( cookie => $c2 );
        $headers .= $cookieman->setheader()->{'ret'};# cookies => [ $c1, $c2 ] );
        
        my $raw = "$headers\r\n$body";
        
        #print $raw;
    
        my $idlen = length( $id );
        my $msg = "blah2 $idlen:$id, HTTP/1.1 200 OK\r\n$raw";
        zmq_send( $outgoing, $msg );
        
        $r->end();
    }
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
# App::Core::Request::Default
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

App::Core::Request::Default - App::Core Component

=head1 VERSION

0.02

=cut

package App::Core::Request::Default;
use Class::Core 0.03 qw/:all/;
use Carp;
use strict;
use vars qw/$VERSION/;
use Data::Dumper;
$VERSION = "0.02";

our $spec;
$spec = <<DONE;
DONE

sub init {
    my ( $core, $r ) = @_;
    my $app = $r->{'app'};
    my $modhash = $app->{'modhash'};
    my %rmods;
    for my $modname ( keys %$modhash ) {
        my $mod = $modhash->{ $modname };
        my $dup = $mod->_duplicate( r => $r, _extend => $mod->{'_extend'} );
        if( $dup->_hasfunc('init_request') ) {
            $dup->init_request();
        }
        $rmods{$modname} = $dup;
    }
    $r->{'mods'} = \%rmods;
    $r->{'body'} = '';
    $r->{'otype'} = '';
    #print "Request was init'ed\n";
}

sub out {
    my ( $core, $r ) = @_;
    $r->{'body'} .= $core->get('text');
}

sub end {
    my ( $core, $r ) = @_;
    my $mods = $r->{'mods'};
    for my $modname ( keys %$mods ) {
        my $mod = $mods->{ $modname };
        if( $mod->_hasfunc('end_request') ) {
            $mod->end_request();
        }
    }
    undef $r->{'mods'};
    #print "Request was ended\n";
}

sub get_mod {
    my ( $core, $r ) = @_;
    #my $glob = $app->{'_glob'};
    my $modname = $core->get('mod');
    #print "Attempting to get mod $modname\n";
    return $r->{'mods'}{ $modname } || confess( "Cannot find mod $modname\n" );
}

sub content_type_as_header {
    my ( $core, $r ) = @_;
    my $type = $r->{'content_type'} || 'text/html';
    my $charset = $r->{'charset'} || 'ISO-8859-1';
    return "Content-Type: $type; charset=$charset\r\n" if( $type =~ m/text/ );
    return "Content-Type: $type\r\n";
}

sub get_headers {
    my ( $core, $r ) = @_;
    if( $r->{'otype'} eq 'redirect' ) {
        return "Location: /".$r->{'url'}."\r\n";
    }
    elsif( $r->{'otype'} eq 'notfound' ) {
        return "";
    }
    else {
        return $r->content_type_as_header();
    }
    
}

sub get_body {
    my ( $core, $r ) = @_;
    if( $r->{'otype'} eq 'redirect' ) {
        return "";
    }
    elsif( $r->{'otype'} eq 'notfound' ) {
        return $r->{'body'};
    }
    else {
        return $r->{'body'};
    }
    
}

sub redirect {
    my ( $core, $r ) = @_;
    my $url = $core->get('url');
    $r->{'url'} = $r->{'app'}->get_base()."/$url";
    $r->{'otype'} = 'redirect';
}

sub not_found {
    my ( $core, $r ) = @_;
    $r->{'otype'} = 'notfound';
}

# get the type of the output
sub get_type {
    my ( $core, $r ) = @_;
    # redirect or 
    $core->set('type',$r->{'otype'});
    if( $r->{'otype'} eq 'redirect' ) {
        $core->set('url', $r->{'url'} );
    }
}

# http://www.w3.org/Protocols/rfc2616/rfc2616.html
sub get_code {
    my ( $core, $r ) = @_;
    if( $r->{'otype'} eq '' ) {
        return "200 OK";
    }
    elsif( $r->{'otype'} eq 'notfound' ) {
        return "404 Not Found";
    }
    elsif( $r->{'otype'} eq 'redirect' ) {
        return "302 Found";
    }
}

sub set_permissions {
    my ( $core, $r ) = @_;
    my $perms = $core->get('perms');
    $r->{'perms'} = $perms;
}

1;
# Framework::Core::API::Default
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

Framework::Core::API::Default - Framework::Core Component

=head1 VERSION

0.01

=cut

package Framework::Core::API::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use vars qw/$VERSION/;
use XML::Bare qw/xval/;
use Carp;
use JSON qw/to_json/;
$VERSION = "0.01";

sub init {
    my ( $core, $self ) = @_; # this self is src
    my $conf = $self->{'conf'} = $core->get('conf');
    my $base = $self->{'base'} = xval( $core->get_conf()->{'base'}, 'api' );
    my $sess_name = $self->{'sess_name'} = xval( $core->get_conf()->{'session'}, 'APP' );
    #my $router = $core->get_mod( 'web_router' );
    #$router->route_path( path => $base, obj => 'api', func => 'api_call', session => 'APP' );
    $self->{'group_hash'} = {};
    $self->{'path_hash'} = {};
}

sub api_call {
    my ( $core, $self ) = @_;
    
    # We need to split apart the url to figure out where we are trying to go
    # Then we need to convert the api call into a regular function call
    
    # group_hash
    #     base
    #         1
    #             test_func
    #                 { session => $session, mod => $mod, func => $funcname };
    
    # Check if we have a matching valid session
    # Grab the module in question
    # Convert get/post into parameters to pass to the function
    # Call the named function
    # Convert the return value of the function into json and/or xml and pass it back through
    
    #$core->set('html', 'test' );
    #my $dump = Dumper( $self->{'r'}{'perms'} );
    $self->{'r'}->out( text => "
        <h2>API test</h2>
        <ul>
        <li>test
        </ul>
        " );
}

sub register_via_spec {
    my ( $core, $self ) = @_;
    my $mod = $core->get('mod');
    
    # way to call: register( mod => $self )
    # way to call: register( mod => $self, session  => 'CORE', func_list => ['test'] )
    
    my $session = $core->get('session') || $self->{ 'sess_name' }; 
    my $log = $core->get_mod('log');
    
    # Right now api functions are -not- namespaced via session.
    # If you want to split api stuff up you need to split it up by group, not by session
    
    # use the spec contained in mod to register
    
    my $specx = $mod->{'obj'}{'_specx'};
    if( !$specx ) {
        confess( "No spec set" );
    }
    
    #$core->dumper("specx",Framework::Core::simplify($specx));
    
    my $spec = $mod->{'obj'}{'_spec'};
    
    # pull from specx: group='base', session='APP' 
    my $basegroup = xval $specx->{'group'}, 'base';
    
    my $gphash = $self->{'group_hash'};
    
    my $cur_base_group = $gphash->{ $basegroup };
    
    my $funcs = $spec->{'funcs'};
    
    my @flist = keys %$funcs;
    my $fref = \@flist;
    my $these_funcs = $core->get('func_list');
    if( $these_funcs ) {
        $fref = $these_funcs;
    }
    
    #$core->dumper( "Refs", $fref );
    #$core->dumper( "Funcs", $funcs );
    
    my $router = $core->get_mod( 'web_router' );

    my $pathhash = $self->{'path_hash'};
    
    for my $funcname ( @$fref ) {
        my $func = $funcs->{ $funcname };
        my $xml = $func->{'x'};
        my $api;
        if( $api = $xml->{'api'} ) {
            #$core->dumper( "API", $api );
            if( !$api->{'v'} ) {
                die "Version is not defined";
            }
            my $v_str = xval $api->{'v'};
            my @vs = split(',', $v_str );
            my $apiname = xval $api->{'name'};
            my $cur_group;
            my $gpname = xval $api->{'group'}, $basegroup;
            
            if( $api->{'group'} ) {
                $cur_group = $gphash->{ xval( $api->{'group'} ) };
            }
            else {
                $cur_group = $cur_base_group;
            }
            
            for my $v ( @vs ) {
                $cur_group->{ $v } ||= {};
                my $apinames = $cur_group->{ $v };
                my $modname = $mod->{'obj'}{'_class'};
                my $modshort = $mod->{'obj'}{'_name'};
                my $path = "api/$gpname/$v/$apiname";
                $log->note( text => "API Register $session - $path -> $modname/$funcname($modshort)" );
                $apinames->{ $apiname } = { session => $session, mod => $mod, func => $funcname };
                $router->route_path( path => $path, obj => 'api', func => 'handle_api_call', session => $session, file => 1, extra => { mod => $modshort, func => $funcname } );
                $pathhash->{ $path } = {
                    session => $session,
                    mod => $modshort,
                    func => $funcname
                };
                # todo enable bouncing from api locations
            }
            # example function registration: <api v='1,2' name='apiname'/>
        }
    }
}

sub call {
    my ( $core, $self ) = @_;
    my $parms = $core->get_all();
    my $path = $parms->{'path'};
    # in theory subpath is passed
    my $src = $self->{'src'};
    my $pathhash = $src->{'path_hash'};
    my $info = $pathhash->{ $path };
    if( !$info ) {
        my $log = $core->get_mod('log');
        $log->error( text => "Cannot find a registered api path '$path'" );
        $core->dumper( "Available paths", $pathhash );
    }
    my $mod = $core->get_mod( $info->{'mod'} );
    my $func = $info->{'func'};
    return $mod->$func( %$parms );
}

sub handle_api_call {
    my ( $core, $self ) = @_;
    my $r = $self->{'r'};
    my $modname = $core->get('mod');
    my $mod = $r->get_mod( mod => $modname );
    my $func = $core->get('func');
    my $params = $self->parse_params();
    return if( $r->{'type'} eq 'disconnect_notice' );
    my $data = $mod->$func( %$params );
    #$core->dumper( 'data', $data );
    
    my $url = $r->{'path'};
    if( $url =~ m|/xml| ) {
        $r->{'content_type'} = 'text/xml';
        $r->out( text => "<xml>".Class::Core::_hash2xml( $data )."</xml>" );
    }
    elsif( $url =~ m|/dump| ) {
        use Data::Dumper;
        my $dump = Dumper( $data );
        $dump = "<pre>$dump</pre>";
        $r->out( text => $dump );
    }
    else {
        $r->{'content_type'} = 'text/javascript';
        #$JSON::Pretty = 1;
        #$r->out( text => to_json( $data ) );
        my $json = JSON->new->pretty;
        $r->out( text => $json->encode( $data ) );
    }
}

sub parse_params {
    my ( $core, $self ) = @_;
    my $r = $self->{'r'};
    my $type = $r->{'type'};
    my %parms;
    if( $type eq 'post' ) {
      %parms = ( %{$r->{'postvars'}} );  
    }
    if( $type eq 'get' ) {
      %parms = ( %{$r->{'query'}} );
    }
    $parms{'subpath'} = $r->{'leftover'};
    return \%parms;
    #    path => $path,
    #    id => $id,
    #    ip => $hash->{'x-forwarded-for'},
}

sub register_function {
    my ( $mod, $func ) = @_;
   
    
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
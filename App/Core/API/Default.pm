# App::Core::API::Default
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

App::Core::API::Default - App::Core Component

=head1 VERSION

0.01

=cut

package App::Core::API::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use vars qw/$VERSION/;
use XML::Bare qw/xval/;
use Carp;
$VERSION = "0.01";

sub init {
    my ( $core, $self ) = @_; # this self is src
    my $conf = $self->{'conf'} = $core->get('conf');
    my $base = $self->{'base'} = xval( $core->getconf()->{'base'}, 'api' );
    my $sess_name = $self->{'sess_name'} = xval( $core->getconf()->{'session'}, 'APP' );
    #my $router = $core->getmod( 'web_router' );
    #$router->route_path( path => $base, obj => 'core_api', func => 'api_call', session => 'APP' );
    $self->{'group_hash'} = {};
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
    # way to call: register( mod => $self, session  => 'ADMIN', func_list => ['test'] )
    
    my $session = $core->get('session') || $self->{ 'sess_name' }; 
    my $log = $core->getmod('log');
    
    # Right now api functions are -not- namespaced via session.
    # If you want to split api stuff up you need to split it up by group, not by session
    
    # use the spec contained in mod to register
    
    my $specx = $mod->{'obj'}{'_specx'};
    if( !$specx ) {
        confess( "No spec set" );
    }
    $core->dumper("specx",App::Core::simplify($specx));
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
                $log->note( text => "API Register $session/$apiname -> $modname/$funcname" );
                $apinames->{ $apiname } = { session => $session, mod => $mod, func => $funcname };
            }
            # example function registration: <api v='1,2' name='apiname'/>
        }
    }
}

sub register_function {
    my ( $mod, $func ) = @_;
   
    
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
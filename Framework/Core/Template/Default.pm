# Framework::Core::Template::Default
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

Framework::Core::Template::Default - Framework::Core Component

=head1 VERSION

0.01

=cut

package Framework::Core::Template::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use vars qw/$VERSION/;
use XML::Bare qw/forcearray xval/;
$VERSION = "0.01";
use Data::Dumper;
use Text::Template;

# This is a Framework::Core class; -not- a Framework::Core module

our $spec = "<func name='init_request'/>";

sub construct {
    my ( $core, $self ) = @_;
    my $file = $self->{'file'}; # file is the actual file containing the template content
    my $xml = $self->{'base'}; # base is the base hash for static values to use in the template
    my $mod = $self->{'mod'}; # module is the module to use as context for available functions - this can be either a Framework::Core module name or a reference to a class::core object
    #$self->{'src'} = Framework::Core::slurp( $self->{'file'} );
    $self->{'tpl'} = Text::Template->new( TYPE => 'FILE', SOURCE => $self->{'file'} );
    if( !$self->{'tpl'} ) {
        my $log = $core->get_mod('log');
        my $terr = $Text::Template::ERROR;
        $log->error( text => "Template error - file $self->{'file'} - $terr" );
    }
    # modulerefs is set within self already
}

sub init_request {
    my ( $core, $self ) = @_;
    #$template = Text::Template->new(TYPE => 'STRING', SOURCE => '...' );
    $self->{'vars'} = 0;
    $self->{'tpls'} = {}; # named templates to use
}

sub set_vars {
    my ( $core, $self ) = @_;
    my $vars = $core->get('vars');
    $self->{'vars'} ||= {};
    Framework::Core::mux( $self->{'vars'}, $vars );
}

# This function should not be called outside of this module
#   It was created just to be used internally by the tpl_vars subroutine
sub set_subhash {
    my ( $core, $self ) = @_;
    my $hash = $core->get('hash');
    $self->{'tpls'} = $hash;
}

# This function creates a tree hash that contains subtemplates and the variables associated with them
# This information needs to be used automatically by the 'run' function to pass the results of the
#   templates being run into the templates being evaluated.
sub sub_tpl {
    my ( $core, $self ) = @_;
    my $tpl = $core->get('tpl');
    my $istpl = 1;
    if( !$tpl ) {
        my $name = $core->get('name');
        $istpl = 0;
        $tpl = $name;
    }
    my $vars = $core->get('vars') || {};
    my $mod = $core->get('mod');
    my $tpls = $self->{'tpls'};
    
    $self->{'vars'} ||= {};
    
    # $core->dumper('mod',$mod);
    my $ret = 0;
    if( $tpl =~ m/\./ ) {
        my @parts = split(/\./, $tpl );
        my $start_tpl_name = $parts[0];
        my $cur_info = $tpls->{ $start_tpl_name };
        if( !$cur_info ) {
            $tpls->{ $start_tpl_name } = $cur_info = { name => $tpl };
        }
        shift @parts;
        my $len = $#parts + 1;
        for( my $i=1;$i<=$len;$i++ ) {
            my $subs = $cur_info->{'subs'};
            if( !$subs ) {
                $subs = $cur_info->{'subs'} = {};
            }
            my $sub_name = shift @parts;
            my $sub_info = $subs->{ $sub_name };
            if( !$sub_info ) {
                my $tple = $core->get_mod('tpl_engine');
                $ret = $tple->start( name => $sub_name );
                $sub_info = $subs->{ $sub_name } = { name => $sub_name, tpl => $ret, istpl => $istpl };
            }
            if( $i == $len ) { # set the vars here
                if( $sub_info->{'vars'} ) {
                    Framework::Core::mux( $sub_info->{'vars'}, $vars );
                }
                else {
                    $sub_info->{'vars'} = $vars;
                }
                if( $mod ) {
                    #$core->dumper( 'test', 'setting mod' );
                    $sub_info->{'mod'} = $mod
                }
                
                
            }
            $cur_info = $sub_info;
        }
    }
    else {
        my $tpl_info = $tpls->{ $tpl };
        if( !$tpl_info ) {
            $tpls->{ $tpl } = $tpl_info = { name => $tpl, vars => $vars, istpl => $istpl };
            my $tple = $core->get_mod('tpl_engine');
            $ret = $tpl_info->{'tpl'} = $tple->start( name => $tpl );
        }
        else {
            Framework::Core::mux( $tpl_info->{'vars'}, $vars );
        }
        if( $mod ) {
            #$core->dumper( 'test', 'setting mod' );
            $tpl_info->{'mod'} = $mod
        }
    }
    return $ret;
}

# Run the template given a hash of data variables
# Should be possible to pass an array of hashes so that variables are used from the multiple hashes
sub run {
    my ( $core, $self ) = @_;
    return 0 if( !$self->{'vars'} );
    #$Data::Dumper::Maxdepth = 2;
    
    my $vars = $self->{'vars'};
    $vars->{'core'} = \$core;
    $vars->{'t'} = \$self;
    if( !$vars->{'base'} ) { $vars->{'base'} = $core->get_base(); }
    my $src = $self->{'src'};
    my $modrefs = $src->{'modulerefs'};
    if( %$modrefs ) {
        for my $varname ( keys %$modrefs ) {
            my $modname = $modrefs->{ $varname };
            my $mod = $core->get_mod( $modname );
            $vars->{ $varname } = \$mod;
        }
    }
    
    if( $self->{'mod_to_use'} ) {
        my $mod = $self->{'mod_to_use'};
        if( $mod->_hasfunc( 'init_tpl' ) ) {
            $mod->init_tpl( $self );
        }
    }
    
    my $tpls = $self->{'tpls'};
    if( $tpls && %$tpls ) { # have we defined any sub-templates
        #$core->dumper( 'tpls', $tpls );
        my $subob = {};
        my $tple = $core->get_mod('tpl_engine');
        for my $sub_name ( keys %$tpls ) {
            my $sub_info = $tpls->{ $sub_name };
            my $sub_tpl;
            if( $sub_info->{'ob'} ) {
                $sub_tpl = $sub_info->{'ob'};
            }
            elsif( $sub_info->{'istpl'} ) {
                $sub_info->{'ob'} = $sub_tpl = $tple->start( name => $sub_name );
            }
            else {
                $sub_info->{'ob'} = $sub_tpl = $tple->start( name => $sub_name );
            }
            
            if( $sub_info->{'mod'} ) {
                my $mod = $core->get_mod( $sub_info->{'mod'} );
                $sub_tpl->{'mod_to_use'} = $mod;
            }
            
            my $sub_vars = $sub_info->{'vars'};
            $sub_tpl->set_vars( vars => $sub_vars );
            if( $sub_info->{'subs'} ) {
                $sub_tpl->set_subhash( hash => $sub_info->{'subs'} );
            }
            $subob->{ $sub_name } = $sub_tpl->run();
        }
        $vars->{'tpl'} = $subob;
    }
    
    my $log = $core->get_mod('log');
    if( $self->{'mod_to_use'} ) {
        my $mod = $self->{'mod_to_use'};
        #$core->dumper( 'mod', $mod );
        my $class = $mod->{'obj'}{'_class'};
        $vars->{'m'} = \$mod;
        #$log->note( text => "Using package $class");
        return $src->{'tpl'}->fill_in( HASH => $vars, PACKAGE => $class );
    }
    else {
        return $src->{'tpl'}->fill_in( HASH => $vars );
    }
    # request needs to be passed into this, in order to grab the request version of the module that the context runs in
    #   without having this, any functions run within the template would not be able to check permissions based on the logged in user
    
    # It seems like it would be nice to be able to grab a static version of a module and then reject a request into it for usage; eg to create a request
    #   version of something on the fly.
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
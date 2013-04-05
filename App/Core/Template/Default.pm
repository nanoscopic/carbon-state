# App::Core::Template::Default
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

App::Core::Template::Default - App::Core Component

=head1 VERSION

0.01

=cut

package App::Core::Template::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use vars qw/$VERSION/;
use XML::Bare qw/forcearray xval/;
$VERSION = "0.01";
use Data::Dumper;
use Text::Template;

# This is a App::Core class; -not- a App::Core module

sub construct {
    my ( $core, $self ) = @_;
    my $file = $self->{'file'}; # file is the actual file containing the template content
    my $xml = $self->{'base'}; # base is the base hash for static values to use in the template
    my $mod = $self->{'mod'}; # module is the module to use as context for available functions - this can be either a app::core module name or a reference to a class::core object
    #$self->{'src'} = App::Core::slurp( $self->{'file'} );
    $self->{'tpl'} = Text::Template->new( TYPE => 'FILE', SOURCE => $self->{'file'} );
}

sub init_request {
    my ( $core, $self ) = @_;
    #$template = Text::Template->new(TYPE => 'STRING', SOURCE => '...' );
    $self->{'vars'} = 0;
}

sub set_vars {
    my ( $core, $self ) = @_;
    my $vars = $core->get('vars');
    $self->{'vars'} = $vars;
}

# Run the template given a hash of data variables
# Should be possible to pass an array of hashes so that variables are used from the multiple hashes
sub run {
    my ( $core, $self ) = @_;
    return 0 if( !$self->{'vars'} );
    #$Data::Dumper::Maxdepth = 2;
    
    my $vars = $self->{'vars'};
    $vars->{'core'} = \$core;
    my $src = $self->{'src'};
    my $log = $core->get_mod('log');
    if( $self->{'mod_to_use'} ) {
        my $mod = $self->{'mod_to_use'};
        #$core->dumper( 'mod', $mod );
        my $class = $mod->{'obj'}{'_class'};
        $vars->{'m'} = \$mod;
        $log->note( text => "Using package $class");
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
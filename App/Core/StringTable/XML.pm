# App::Core::StringTable::XML
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

App::Core::StringTable::XML - App::Core Component

=head1 VERSION

0.01

=cut

package App::Core::StringTable::XML;
use Class::Core 0.03 qw/:all/;
use strict;
use vars qw/$VERSION/;
use XML::Bare qw/forcearray xval/;
$VERSION = "0.01";
use Data::Dumper;

sub init {
    my ( $core, $self ) = @_;
    my $conf = $self->{'_xml'};
    my $file = xval $conf->{'store'};
    my ( $ob, $xml ) = new XML::Bare( file => $file );
    $xml = $xml->{'xml'};
    
    my $map = App::Core::simplify( $xml );
    $self->{'map'} = $map;
}

sub lookup {
    my ( $core, $self ) = @_;
    my $kw = $core->get('kw');
    return $self->{'map'}{$kw};
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
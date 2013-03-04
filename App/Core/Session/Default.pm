# App::Core::Session::Default
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

App::Core::Session::Default - App::Core Component

=head1 VERSION

0.02

=cut

package App::Core::Session::Default;
use strict;
use Class::Core qw/:all/;
use vars qw/$VERSION/;
$VERSION = "0.02";

sub construct {
    my ( $core, $self ) = @_;
    $self->{'dat'} = 'blahblah';
    print "Constructing a session\n";
}

# called at the end of a session
sub cleanup {
}

sub register_cleanup {
    
}

sub show {
    my ( $core, $self, ) = @_;
    my $dat = $self->{'dat'};
    print "Session: $dat\n";
}

sub de_serialize {
    my ( $core, $self ) = @_;
    my $raw = $core->get('raw');
    $self->{'dat'} = $raw;
    return $self;
}

sub serialize {
    my ( $core, $self ) = @_;
    return $self->{'dat'};
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
# Framework::Core::Log::Default
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

Framework::Core::Log::Default - Framework::Core Component

=head1 VERSION

0.01

=cut

package Framework::Core::Log::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use Term::ANSIColor qw/:constants color/;

sub init {
    my ( $core, $self ) = @_;
    my $conf = $self->{'conf'} = $core->get('conf');
    my $console = $self->{'console'} = $conf->{'console'} ? 1 : 0; # flag to enable logging to console
    if( $conf->{'win32color'} ) {
        eval('use Win32::Console::ANSI');
    }
    print "Logging to console\n" if( $console );
}

sub note {
    my ( $core, $self ) = @_;
    my $text = $core->get('text');
    my $msg = "note: $text\n";
    print STDERR $msg if( $self->{'console'} );
}

sub error {
    my ( $core, $self ) = @_;
    my $text = $core->get('text');
    my $msg = "error: $text\n";
    if( $self->{'console'} ) {
        print STDERR color 'bold red';
        print STDERR $msg;
        print STDERR RESET;
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
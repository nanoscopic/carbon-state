# Framework::Core::Web::SessionMan::Default
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

Framework::Core::Web::SessionMan::Default - Framework::Core Component

=head1 VERSION

0.01

=cut

package Framework::Core::Web::SessionMan::Default;
use strict;
use Class::Core 0.03 qw/:all/;
use Data::Dumper;

sub init {
    my ( $core, $self ) = @_;
    $self->{'session_count'} = 0;
    $self->{'sessions'} = {};
}

sub get_session {
    my ( $core, $self ) = @_;
    print "Call to get_session\n";
    my $r = $core->get('r');
    my $ip = $r->{'ip'};
    my $uid = '';
    if( $ip eq '172.22.27.133' ) {
        $uid = 'dhelkowski';
    }
    my $session;
    if( $session = $self->{'sessions'}{ $uid } ) {
        print "Fetched session for $uid\n";
        return $session;
    }
    #if( $uid ) {
        #print "Creating session for $uid\n";
        #return $self->create_session( uid => $uid );
    #}
    print "No existing session\n";
    return 0;
    #print "ip: $ip\n";
}

sub create_session {
    my ( $core, $self ) = @_;
    my $uid = $core->get('uid');
    my $session = Framework::Core::Web::SessionMan::Default::Session->new( uid => $uid );
    $self->{'sessions'}{$uid} = $session;
    return $session;
}

sub save_session {
}

sub expire_sessions {
    # go through sessions and end them if they are expired
}

package Framework::Core::Web::SessionMan::Default::Session;
use strict;
use Class::Core qw/:all/;

# called at the end of a session
sub cleanup {
}

sub register_cleanup {
    
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

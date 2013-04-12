# App::Core::Log::Default
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

App::Core::Log::Default - App::Core Component

=head1 VERSION

0.02

=cut

package App::Core::Log::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use Term::ANSIColor qw/:constants color/;
use vars qw/$VERSION/;
use threads::shared;
use Time::HiRes qw/time/;
use threads;
my @items :shared;

$VERSION = "0.02";

sub init {
    my ( $core, $self ) = @_;
    my $conf = $self->{'conf'} = $core->get('conf');
    my $console = $self->{'console'} = $conf->{'console'} ? 1 : 0; # flag to enable logging to console
    if( $^O eq 'MSWin32' ) {
        eval('use Win32::Console::ANSI;');
    }
    print "Logging to console\n" if( $console );
}

sub note {
    my ( $core, $self ) = @_;
    my $src = $self->{'src'} || $self;
    my $text = $core->get('text');
    my $msg = "note: $text\n";
    my $rid = '';
    if( $self->{'r'} ) {
        $rid = $self->{'r'}{'urid'};
    }
    
    my @cl = ( 1,2,3 );#, 2, 3, 4, 5, 6, 7 );
    my $trace = '';
    for my $up ( @cl ) {
        my ( $x, $file, $line ) = caller($up);
        $file ||= ''; $line ||= '';
        $file =~ s|^[./]+||g; $file =~ s|\.pm$||g;
        next if( $file =~ m|^Class| );
        next if( $file eq 'App/Core' );
        $trace .= "$file:$line,";
    }
    
    my $now = time; $now *= 1000; $now = int( $now ); $now /= 1000;
    my $raw = Class::Core::_hash2xml( { type => 'note', text => $text, time => $now, rid => $rid, trace => $trace, tid => threads->tid() } );
    {
        lock( @items );
        if( $#items > 500 ) { shift @items; }
        push( @items, $raw );
    }
    print STDERR $msg if( $src->{'console'} );
}

sub noter {
    my ( $core, $self ) = @_;
    my $src = $self->{'src'} || $self;
    my $text = $core->get('text');
    my $msg = "note: $text\n";
    my $rid = '';
    my $r = $core->get('r');
    if( $r ) {
        $rid = $r->{'urid'};
    }
    
    my @cl = ( 1,2,3 );#, 2, 3, 4, 5, 6, 7 );
    my $trace = '';
    for my $up ( @cl ) {
        my ( $x, $file, $line ) = caller($up);
        $file ||= ''; $line ||= '';
        $file =~ s|^[./]+||g; $file =~ s|\.pm$||g;
        next if( $file =~ m|^Class| );
        next if( $file eq 'App/Core' );
        $trace .= "$file:$line,";
    }
    
    my $now = time; $now *= 1000; $now = int( $now ); $now /= 1000;
    my $raw = Class::Core::_hash2xml( { type => 'note', text => $text, time => $now, rid => $rid, trace => $trace, tid => threads->tid() } );
    {
        lock( @items );
        if( $#items > 500 ) { shift @items; }
        push( @items, $raw );
    }
    print STDERR $msg if( $src->{'console'} );
}

sub error {
    my ( $core, $self ) = @_;
    my $src = $self->{'src'} || $self;
    my $text = $core->get('text');
    my $msg = "error: $text\n";
    my $rid = '';
    if( $self->{'r'} ) {
        $rid = $self->{'r'}{'urid'};
    }
    my @cl = ( 1 );
    my $trace = '';
    for my $up ( @cl ) {
        my ( $x,$file, $line ) = caller($up);
        $file =~ s|^[./]+||g; $file =~ s|\.pm$||g;
        $trace .= "$file:$line,";
    }
    my $now = time; $now *= 1000; $now = int( $now ); $now /= 1000;
    my $raw = Class::Core::_hash2xml( { type => 'note', text => $text, time => $now, rid => $rid, trace => $trace } );
    {
        lock( @items );
        if( $#items > 500 ) { shift @items; }
        push( @items, $raw );
    }
    if( $src->{'console'} ) {
        print STDERR color 'bold red';
        print STDERR $msg;
        print STDERR RESET;
    }
}

sub get_items {
    my ( $core, $self ) = @_;
    return \@items;
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
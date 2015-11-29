# Ginger::Reference::Log::Default
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

Ginger::Reference::Log::DB - Ginger::Reference Component

=head1 VERSION

0.02

=cut

package Ginger::Reference::Log::DB;
use Class::Core 0.03 qw/:all/;
use strict;
use Term::ANSIColor qw/:constants color/;
use vars qw/$VERSION/;
use threads::shared;
use Time::HiRes qw/time/;
use threads;
use DBI;
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
    
    my $database = $self->{'db_name'} = "ais_core";
    my $host     = $self->{'db_host'} = "172.22.27.152";
    my $port     = $self->{'db_port'} = 3306;
    my $dsn      = $self->{'dsn'}     = "DBI:mysql:database=$database;host=$host;port=$port";
    my $db_user  = $self->{'db_user'} = "ais_core";
    my $db_pw    = $self->{'db_pw'}   = "c0repass";
    my $dbh      = $self->{'dbh'}     = DBI->connect( $dsn, $db_user, $db_pw );
    
    # connect to the db and store dbh in self->dbh
}

# thread started
# thread ended

# request started
# request ended

sub init_thread {
    my ( $core, $self ) = @_;
    my $tid = $core->get('tid');
    my $inst_id = $self->{'inst_id'};
    # set dbh to a new connection to the db since the global one should not be used?? for now just try and reuse the same connection :(
    my $dsn = $self->{'dsn'};
    my $dbh = $self->{'dbh'} = DBI->connect( $dsn, $self->{'db_user'}, $self->{'db_pw'} );
    $dbh->do('insert into thread set server_inst_id=?,tid=?',undef, $inst_id, $tid );
    $self->{'trow'} = $dbh->{'mysql_insertid'};
}

sub server_start {
    my ( $core, $self ) = @_;
    
    my $dbh = $self->{'dbh'};
    $dbh->do('insert into server_inst set started=NOW(), num_threads=3' );
    my $inst_id = $self->{'inst_id'} = $dbh->{'mysql_insertid'};
    return $inst_id;
}

sub server_stop {
    my ( $core, $self ) = @_;
    
    my $sid = $self->{'inst_id'};
    my $dbh = $self->{'dbh'};
    $dbh->do('update server_inst set ended=NOW() where id=?',undef, $sid );
}

sub start_request {
    my ( $core, $self ) = @_;
    
    my $req_num = $core->get('req_num');
    my $url = $core->get('url');
    my $cookie_id = $core->get('cookie_id');
        
    my $src = $self->{'src'};
    
    my $r = $self->{'r'};
    
    my $dbh = $src->{'dbh'};
    my $inst_id = $src->{'inst_id'};
    my $trow = $src->{'trow'};
    $dbh->do('insert into request set req_num=?,url=?,cookie_id=?,start=NOW(),server_inst_id=?,thread_id=?', undef, $req_num, $url, $cookie_id, $inst_id, $trow );
    my $rid = $dbh->{'mysql_insertid'};
    return $rid;
}

sub stop_request {
    my ( $core, $self ) = @_;
    my $dbid = $core->get('rid');
    my $dbh = $self->{'dbh'};
    $dbh->do('update request set end=NOW() where id=?',undef,$dbid );
}

sub note {
    my ( $core, $self ) = @_;
    my $src = $self->{'src'} || $self;
    my $text = $core->get('text');
    my $msg = "note: $text\n";
    my $rnum = '';
    my $rid = 0;
    if( $self->{'r'} ) {
        $rnum = $self->{'r'}{'urid'};
        $rid = $src->{'dbid'};
    }
    
    my @cl = ( 1,2,3 );#, 2, 3, 4, 5, 6, 7 );
    my $trace = '';
    for my $up ( @cl ) {
        my ( $x, $file, $line ) = caller($up);
        $file ||= ''; $line ||= '';
        $file =~ s|^[./]+||g; $file =~ s|\.pm$||g;
        next if( $file =~ m|^Class| );
        next if( $file eq 'Ginger/Reference/Core' );
        $trace .= "$file:$line,";
    }
    
    my $now = time; $now *= 1000; $now = int( $now ); $now /= 1000;
    
    #my $raw = Class::Core::_hash2xml( { type => 'note', text => $text, time => $now, rid => $rid, trace => $trace, tid => threads->tid() } );
    #{
    #    lock( @items );
    #    if( $#items > 500 ) { shift @items; }
    #    push( @items, $raw );
    #}
    
    
    my $dbh = $src->{'dbh'};
    $dbh->do('insert into log set stamp=NOW(),type=0,msg=?,trace=?,req_id=?',undef, $text, $trace, $rid );
    
    print STDERR $msg if( $src->{'console'} );
}

sub noter {
    my ( $core, $self ) = @_;
    my $src = $self->{'src'} || $self;
    my $text = $core->get('text');
    my $msg = "note: $text\n";
    my $rnum = '';
    my $r = $core->get('r');
    my $rid = 0;
    if( $r ) {
        $rnum = $r->{'urid'};
        $rid = $r->{'dbid'};
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
    
    #my $now = time; $now *= 1000; $now = int( $now ); $now /= 1000;
    #my $raw = Class::Core::_hash2xml( { type => 'note', text => $text, time => $now, rid => $rid, trace => $trace, tid => threads->tid() } );
    #{
    #    lock( @items );
    #    if( $#items > 500 ) { shift @items; }
    #    push( @items, $raw );
    #}
    #my $rid = $src->{'rid'};
    
    my $dbh = $src->{'dbh'};
    $dbh->do('insert into log set stamp=NOW(),type=0,msg=?,trace=?,req_id=?',undef, $text, $trace, $rid );
    
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

Component of L<Ginger::Reference>

=head1 DESCRIPTION

Component of L<Ginger::Reference>

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
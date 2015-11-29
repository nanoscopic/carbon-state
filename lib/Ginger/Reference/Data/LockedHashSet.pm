# Ginger::Reference::Data::LockedHashSet
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

Ginger::Reference::Data::LockedHashSet - Ginger::Reference Component

=head1 VERSION

0.01

=cut

package Ginger::Reference::Data::LockedHashSet;
use Class::Core 0.03 qw/:all/;
use threads::shared;
use XML::Bare;
use strict;
use Time::HiRes qw/time/;

my @arrs :shared;

sub init {
}

sub construct {
    my ( $core, $self ) = @_;
    
    if( !defined $self->{'id'} ) {
        lock @arrs;
        my $id = $self->{'id'} = $#arrs + 1;
        my $newset = [];
        share @$newset;
        $arrs[ $id ] = $self->{'set'} = $newset;
    }
    else {
        lock @arrs;
        $self->{'set'} = $arrs[ $self->{'id'} ];
    }
}

sub push {
    my ( $core, $self, $hash ) = @_;
    my $set = $self->{'set'};
    my $xmltext = _hash2xml( $hash );
    {
        lock @$set;
        CORE::push( @$set, $xmltext );
        return $#$set;
    }
}

sub get {
    my ( $core, $self, $i ) = @_;
    my $set = $self->{'set'};
    my $xmltext;
    {
        lock @$set;
        return undef if( $i > $#$set );
        $xmltext = $set->[ $i ];
    }
    my ( $ob, $xml ) = XML::Bare->new( text => $xmltext );
    return simplify( $xml );
}

sub set {
    my ( $core, $self ) = @_;
    my $i = $core->get('i');
    my $hash = $core->get('hash');
    my $set = $self->{'set'};
    my $xmltext = _hash2xml( $hash );
    {
        lock @$set;
        return 0 if( $i > $#$set );
        $set->[ $i ] = $xmltext;
    }
    return 1;
}

sub shift {
    my ( $core, $self ) = @_;
    my $set = $self->{'set'};
    my $xmltext;
    {
        lock @$set;
        return undef if( $#$set == -1 );
        $xmltext = CORE::shift @$set;
    }
    my ( $ob, $xml ) = XML::Bare->new( text => $xmltext );
    return simplify( $xml );
}

sub shiftn {
    my ( $core, $self, $n ) = @_;
    my $set = $self->{'set'};
    my $xmltext;
    my @ret;
    {
        lock @$set;
        return undef if( ( $#$set + 1 ) < $n );
        $xmltext = CORE::shift @$set;
        my ( $ob, $xml ) = XML::Bare->new( text => $xmltext );
       CORE::push( @ret, simplify( $xml ) );
    }
    return \@ret;
}

sub getall {
    my ( $core, $self ) = @_;
    my $set = $self->{'set'};
    my $xmlall = '';
    {
        lock @$set;
        
        for( my $i=0;$i<=$#$set;$i++ ) {
            my $xmltext = $set->[ $i ];
            $xmlall .= "<n>$xmltext</n>";
        }
    }
    my ( $ob, $xml ) = XML::Bare->new( text => $xmlall );
    my $simple = simplify( $xml );
    my $ns = $simple->{'n'};
    if( ref( $ns ) eq 'ARRAY' ) {
        return $ns;
    }
    else {
        return [ $ns ];
    }
}

sub get_these {
    my ( $core, $self, $arr ) = @_;
    my $set = $self->{'set'};
    my $xmlall = '';
    {
        lock @$set;
        
        for( my $i=0;$i<=$#$arr;$i++ ) {
            my $id = $arr->[ $i ];
            my $text = $set->[ $id ];
            $xmlall .= "<n>$text<i>$id</i></n>";
        }
    }
    my ( $ob, $xml ) = XML::Bare->new( text => $xmlall );
    my $simple = simplify( $xml );
    my $ns = $simple->{'n'};
    if( ref( $ns ) eq 'ARRAY' ) {
        return $ns;
    }
    else {
        return [ $ns ];
    }
}

sub popall {
    my ( $core, $self ) = @_;
    my $set = $self->{'set'};
    my @ret;
    {
        lock @$set;
        for( my $i=0;$i<=$#$set;$i++ ) {
            my $xmltext = $set->[ $i ];
            my ( $ob, $xml ) = XML::Bare->new( text => $xmltext );
            my $simple = simplify( $xml );
            CORE::push( @ret, $simple );
        }
        @$set = ();
    }
    return \@ret;
}

sub getset {
    my $id = CORE::shift;
    return Ginger::Reference::Data::LockedHashSet->new( id => $id );
}

sub simplify {
    my $node = CORE::shift;
    my $ref = ref( $node );
    if( $ref eq 'ARRAY' ) {
        my @ret;
        for my $sub ( @$node ) {
            CORE::push( @ret, simplify( $sub ) );
        }
        return \@ret;
    }
    if( $ref eq 'HASH' ) {
        my %ret;
        my $cnt = 0;
        for my $key ( keys %$node ) {
            next if( $key eq 'value' || $key =~ m/^_/ );
            $cnt++;
            $ret{ $key } = simplify( $node->{ $key } );
        }
        if( $cnt == 0 ) {
            return $node->{'value'};
        }
        return \%ret;
    }
    return $node;
}

sub _hash2xml {
    my ( $node, $name ) = @_;
    my $ref = ref( $node );
    return '' if( $name && $name =~ m/^\_/ );
    my $txt = $name ? "<$name>" : '';
    if( $ref eq 'ARRAY' ) {
       $txt = '';
       for my $sub ( @$node ) {
           $txt .= _hash2xml( $sub, $name );
       }
       return $txt;
    }
    elsif( $ref eq 'HASH' ) {
       for my $key ( keys %$node ) {
           $txt .= _hash2xml( $node->{ $key }, $key );
       }
    }
    else {
        $node ||= '';
        if( $node =~ /[<]/ ) { $txt .= '<![CDATA[' . $node . ']]>'; }
        else { $txt .= $node; }
    }
    if( $name ) {
        $txt .= "</$name>";
    }
        
    return $txt;
}

1;
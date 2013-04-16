package App::Core::Data::LockedHashSet;
use Class::Core qw/:all/;
use threads::shared;
use Data::Dumper;
use XML::Bare;
use strict;

my @arrs :shared;

sub construct {
    my ( $core, $self ) = @_;
    #print Dumper( $self );
    if( defined $self->{'id'} ) {
    }
    else {
        lock @arrs;
        my $id = $self->{'id'} = $#arrs + 1;
        my $newset = [];
        share $newset;
        $arrs[ $id ] = $self->{'set'} = $newset;
    }
}

sub push {
    my ( $core, $self, $hash ) = @_;
    my $set = $self->{'set'};
    my $i;
    {
        lock $set;
        my $xmltext = _hash2xml( $hash );
        CORE::push( @$set, $xmltext );
        $i = $#$set;
    }
    return $i;    
}

sub get {
    my ( $core, $self, $i ) = @_;
    my $set = $self->{'set'};
    my $xmltext;
    {
        lock $set;
        return undef if( $i > $#$set );
        $xmltext = $set->[ $i ];
    }
    my ( $ob, $xml ) = XML::Bare->new( text => $xmltext );
    my $simple = simplify( $xml );
    return $simple;
}

sub shift {
    my ( $core, $self, $i ) = @_;
    my $set = $self->{'set'};
    my $xmltext;
    {
        lock $set;
        return undef if( $#$set == -1 );
        $xmltext = CORE::shift @$set;
    }
    my ( $ob, $xml ) = XML::Bare->new( text => $xmltext );
    my $simple = simplify( $xml );
    return $simple;
}

sub popall {
    my ( $core, $self ) = @_;
    my $set = $self->{'set'};
    my @ret;
    {
        lock $set;
        #print Dumper( $set );
        #print "Len: $#$set\n";
        for( my $i=0;$i<=$#$set;$i++ ) {
            my $xmltext = $set->[ $i ];
            #print "$xmltext\n";
            my ( $ob, $xml ) = XML::Bare->new( text => $xmltext );
            my $simple = simplify( $xml );
            CORE::push( @ret, $simple );
        }
        @$set = ();
    }
    return \@ret;
}

sub test {
    my ( $core, $self ) = @_;
    my $set = $self->{'set'};
    {
        lock $set;
        print "id: ". $self->{'id'} . "\n" . Dumper( $set );
    }
}

sub getset {
    my $id = CORE::shift;
    my $set;
    {
        lock @arrs;
        $set = $arrs[ $id ];
    }
    return App::Core::Data::LockedHashSet->new( id => $id, set => $set );
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
    my $txt = $name ? "<$name>" : '';
    if( $ref eq 'ARRAY' ) {
       for my $sub ( @$node ) {
           $txt .= _hash2xml( $sub, $name );
       }
    }
    elsif( $ref eq 'HASH' ) {
       for my $key ( keys %$node ) {
           $txt .= _hash2xml( $node->{ $key }, $key );
       }
    }
    else {
        if( $node =~ /[<]/ ) { $txt .= '<![CDATA[' . $node . ']]>'; }
        else { $txt .= $node; }
    }
    if( $name ) {
        $txt .= "</$name>";
    }
        
    return $txt;
}

1;
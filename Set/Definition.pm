#!/usr/bin/perl -w
package Set::Definition;

use strict;
use Class::Core qw/:all/;
use Data::Dumper;

sub construct {
    my ( $core, $def ) = @_;
    my $text  = $def->{'text'};
    my $parts = expr_to_parts( $text );
    my $arr   = parse_arr( $parts );
    my $obj = $def->{'ob'} = $arr->[0];
    my $parsed     = $obj->{'parsed'};
    $def->{'groups'} = uniq_parts( {}, $parsed );
}

# Return the groups mentioned in the expression
sub expr_groups {
    my ( $core, $def ) = @_;
    return $def->{'groups'};
}

sub contains {
    my ( $core, $def ) = @_;
    my $member     = $core->get('member');
    my $obj        = $def->{'ob'};
    my $check_list = $def->{'groups'};
    my $membership = $def->check_membership( hash => $check_list, user => $member );
    return eval_hash( $membership, $obj );
}

sub members {
    my ( $core, $def ) = @_;
    
    my $obj        = $def->{'ob'};
    my $check_list = $def->{'groups'};
    
    # get the membership of the groups that we depend on
    my $membership = $def->get_membership( hash => $check_list );
    #print "Membership\n";
    #print Dumper( $membership );
    #print "Call to members\n";
    return eval_hash_members( $membership, $obj );
}

sub expr_to_parts {
    my $expr = shift;
    $expr =~ s/ //g;
    if( $expr !~ m/^\(/ || $expr !~ m/\)$/ ) { $expr = "($expr)"; }
    my @parts = split(/([&|()])/, $expr );
    my @ref;
    for my $part ( @parts ) {
        next if( !$part );
        push( @ref, $part );
    }
    return \@ref;
}

sub eval_hash {
    my ( $user_membership, $hash ) = @_;
    my $parsed = $hash->{'parsed'};
    my $join   = $hash->{'join'};
    for my $item ( @$parsed ) {
        my $cur = ( ref( $item ) eq 'HASH' ) ? eval_hash( $user_membership, $item ) : $user_membership->{ $item };
        return 0 if( $join eq '&' && $cur == 0 );
        return 1 if( $join eq '|' && $cur == 1 );
    }
    return 1;
}

sub eval_hash_members {
    my ( $membership, $hash ) = @_;
    my $parsed = $hash->{'parsed'};
    my $join   = $hash->{'join'};
    
    my $a = $parsed->[0];
    my $b = $parsed->[1];
    #print Dumper( $a );
    #print Dumper( $b );
    my $alist = ( ref( $a ) eq 'HASH' ) ? eval_hash_members( $membership, $a ) : $membership->{ $a };
    my $blist = ( ref( $b ) eq 'HASH' ) ? eval_hash_members( $membership, $b ) : $membership->{ $b };
    if( $join eq '&' ) {
        #print Dumper( $alist );
        #print Dumper( $blist );
        return intersect_groups( $alist, $blist );
    }
    if( $join eq '|' ) {
        #print Dumper( $alist );
        #print Dumper( $blist );
        return join_groups( $alist, $blist );
    }
}

sub array_to_hash {
    my $arr = shift;
    #my %hash = map { ($a, 1) } @$arr;
    my %hash;
    for my $key ( @$arr ) {
        $hash{ $key } = 1;
    }
    return \%hash;
}

sub intersect_groups {
    my ( $a, $b ) = @_;
    my $bhash = array_to_hash( $b );
    my @res;
    for my $key ( @$a ) {
        push( @res, $key ) if( $bhash->{ $key } );
    }
    return \@res;
}

sub join_groups {
    my ( $a, $b ) = @_;
    my %res;
    for my $key ( @$a ) { $res{ $key } = 1; }
    for my $key ( @$b ) { $res{ $key } = 1; }
    my @arr = keys %res;
    return \@arr;
}

sub check_membership {
    my ( $core, $def ) = @_;
    my $hash = $core->get('hash');
    my $user = $core->get('user');
    
    my $res = {};
    for my $key ( keys %$hash ) {
        my $ingroup_ref = $def->{'ingroup_callback'};
        my $temp = $res->{ $key } = &$ingroup_ref( $key, $user, $def );
        $res->{ "!$key" } = $temp ? 0 : 1;
    }
    return $res;
}

sub get_membership {
    my ( $core, $def ) = @_;
    my $hash = $core->get('hash');
    
    my $res = {};
    for my $key ( keys %$hash ) {
        my $ingroup_ref = $def->{'ingroup_callback'};
        my $members = &$ingroup_ref( $key, undef, $def );
        $res->{ $key } = $members;
    }
    return $res;
}

# Find the parts mentioned in @$arr, and put them in the hash %$res
sub uniq_parts {
    my ( $res, $arr ) = @_;
    for my $item ( @$arr ) {
        if( ref( $item ) eq 'HASH' ) {
            uniq_parts( $res, $item->{'parsed'} );
        }
        else {
            my $temp = $item; 
            $temp =~ s/^!//;
            $res->{ $temp } = 1;
        }
    }
    return $res;
}

sub parse_arr {
    my $in = shift;
    my $sub = 0;
    my $depth = 0;
    my $out = [];
    for my $part ( @$in ) {
        next if( !$part );
        my $ref = ref( $part );
         
        if( $ref ne 'HASH' ) { # is a name or a connector
            if( $part eq '(' ) {
                if( !$depth ) {
                    $sub = { parts => [] };
                    $depth++;
                    next;
                }
                
                $depth++;
            }
            elsif( $part eq ')' ) {
                $depth--;
                if( !$depth ) {
                    my $parsed = parse_arr( $sub->{'parts'} );
                    push( @$out, treat_arr( $parsed ) );
                    $sub = 0;
                    next;
                }
            }
        }
        
        if( $sub ) {
            if( $depth == 1 ) {
                if( $part eq '&' || $part eq '|' ) {
                    $sub->{'join'} = $part;
                }
            }
            push( @{$sub->{'parts'}}, $part );
        }
        else {
            push( @$out, $part );
        }
    }

    return $out;
}

sub treat_arr {
    my ( $arr, $lev ) = @_;
    my $len = $#$arr;
    return $arr->[0] if( $len == 0 );
    my @res;
    my $join = $lev ? '|' : '&';
    for( my $i = 0; $i <= $len; $i++ ) {
        my $part = $arr->[ $i ];
        if( $i % 2 && $part eq $join ) {
            push( @res, { parsed => [ pop( @res ), $arr->[ ++$i ] ], join => $join } );
            next;
        }
        push( @res, $part );
    }
    return $lev ? $res[0] : treat_arr( \@res, 1 );
}

1;
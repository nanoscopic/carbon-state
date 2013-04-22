# App::Core::Permission::Method::Flatfile
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

App::Core::Permission::Method::Flatfile - App::Core Component

=head1 VERSION

0.01

=cut

package App::Core::Permission::Method::Flatfile;
use Class::Core 0.03 qw/:all/;
use strict;
use vars qw/$VERSION/;
use XML::Bare qw/forcearray xval/;
$VERSION = "0.01";
use Data::Dumper;
use Set::Definition;
use Digest::SHA1 qw/sha1_hex/;

# TODO - currently all the code in this file does not update when permissions "change"
# Also, if things did change all objects in all threads would need to be re-created due to this simply loading everything up
# when the system is started. That is, currently the code here will -not- work for dynamic changing permissions.

sub init {
    my ( $core, $self ) = @_;
    my $conf = $self->{'_xml'};
    #print Dumper( $conf );
    my $file = xval $conf->{'store'};
    #print "file: $file\n";
    my ( $ob, $xml ) = new XML::Bare( file => $file );
    $xml = $xml->{'xml'};
    #print Dumper( $xml );
    my $perms = forcearray( $xml->{'perm'} );
    
    my $users = $self->{'users'} = {};
    my $user_arr = forcearray( $xml->{'user'} );
    for my $user ( @$user_arr ) {
        my $id = xval $user->{'id'};
        my $pw = xval $user->{'pw'};
        my $hash;
        if( $pw ) {
            $hash = $self->pass_hash( user => $id, pw => $pw );
        }
        else {
            $hash = xval $user->{'hash'};
        }
        $users->{ $id } = { hash => $hash };
    }
    
    my $permhash = $self->{'permhash'} = {};
    for my $perm ( @$perms ) {
        my $name = xval $perm->{'name'};
        $permhash->{ $name } = App::Core::simplify( $perm );
    }
    
    my $groups = forcearray( $xml->{'group'} );
    
    my $simplegroups = $self->{'sgroups'} = []; # simple groups are groups that are just composed of members
    my $definedgroups = $self->{'dgroups'} = [];
    my $statichash = $self->{'static_groups'} = {}; # groups that are ultimately only dependent on a list of users
    my $allgroups = $self->{'all_groups'} = {};
    
    for my $group ( @$groups ) {
        my $sgroup = App::Core::simplify( $group );
        my $name = $sgroup->{'name'};
        $allgroups->{ $name } = $sgroup;
        
        my $lookup = { test => 27 };
        if( $group->{'define'} ) {
            $sgroup->{'setdef'} = new Set::Definition( text => $sgroup->{'define'}, ingroup_callback => \&in_group, method => $self );
            push( @$definedgroups, $sgroup );
        }
        elsif( $group->{'member'} ) {
            $statichash->{ $name } = 1;
            push( @$simplegroups, $sgroup );
        }   
        else { # empty group
            $statichash->{ $name } = 1;
        }
    }
    
    #print "Groups with just members\n";
    #print Dumper( $simplegroups );
    
    #print "Static group names\n";
    my @keys = keys %$statichash;
    #print Dumper( \@keys );
    
    $self->find_pure_local_groups();
    
    #print "Locally defined groups\n";
    #print Dumper( $self->{'lgroups'} );
    #print "test:$test\n";
    $self->process_groups();
}

sub in_group {
    my ( $group_name, $user, $def ) = @_;
    my $method = $def->{'method'};
    #print "Group name: $group_name (\n";
    
    if( $group_name =~ m/^l_(.+)/ ) {
        $group_name = $1;
    }
    else {
        return [];
    }
    
    #print Dumper( $lookup );
    
    my $sgroups = $method->{'sgroups'}; # simple groups of just members
    my $lgroups = $method->{'lgroups'}; # local groups that can be worked out locally
    my $shash = arr_to_hash( $sgroups );
    my $lhash = arr_to_hash( $lgroups );
    
    #my $group = $groups{ $group_name };
    if( $user ) {
    }
    else {
        my $gp;
        if( $gp = $shash->{ $group_name } ) {
            #print "Members of $group_name:\n";
            #print Dumper( $gp->{'member'} );
            # print ")\n";
            #return forcearray( $gp->{'member'} );
            my $members = forcearray( $gp->{'member'} );
            my @memberids;
            for my $member ( @$members ) {
                my $id = $member->{'id'};
                push( @memberids, $id );
            }
            return \@memberids;
            
        }
        if( $gp = $lhash->{ $group_name } ) {
            my $gpdef = $gp->{'setdef'};
            my $members = $gpdef->members();
            #print "Members of $group_name:\n";
            #print "$members\n";
            #my @keys = keys %$members;
            #print Dumper( $members );
            #print ")\n";
            return $members;
        }
        #print ")\n";
        return [];
        #my @set = keys %$group;
        #return \@set;
    }
    #print ")\n";
}

sub arr_to_hash {
    my $arr = shift;
    my %hash;
    for my $item ( @$arr ) {
        $hash{ $item->{'name'} } = $item;
    }
    return \%hash;
}

sub find_pure_local_groups {
    my ( $core, $self ) = @_;
    my $pure_local_groups = $self->{'lgroups'} = []; # defined groups that are 'local'/static ( they don't depend on groups from another method )
    
    my $dgroups = $self->{'dgroups'};
    
    my $static = $self->{'static_groups'};
    
    # we may need to loop through repeatedly to catch local defined groups dependent on other local defined groups
    my $numgroups = $#$dgroups;
    for( my $i=0;$i<$numgroups+1;$i++ ) {
        for my $dgroup ( @$dgroups ) {
            next if( $dgroup->{'done'} );
            my $gpname = $dgroup->{'name'};
            my $def = $dgroup->{'setdef'};
            my $subhash = $def->expr_groups();
            #print "Name:$gpname\n";
            #print Dumper( $subhash );
            
            my $gotall = 1;
            for my $key ( keys %$subhash ) {
                #print "Key: $key\n";
                if( $key =~ m/^l_(.+)/ ) {
                    my $localname = $1;
                    if( ! $static->{ $localname } ) {
                        $gotall = 0;
                    }
                }
                else {
                    $gotall = 0;
                    $dgroup->{'done'} = 1; # not a static group
                }
                
            }
            if( $gotall ) {
                #print "Group $gpname is pure local\n";
                $static->{ $gpname } = 1;
                push( @$pure_local_groups, $dgroup );
            }
        }
    }
}

# go through the list of all groups with direct members, and built a hash that
# shows which groups a user is known to be in
sub process_groups {
    my ( $core, $self ) = @_;
    # find all groups that are just a list of members
    my $sgroups = $self->{'sgroups'};
    
    my $userhash = $self->{'user_group_hash'} = {};
    # for each of those, build a hash of users and which of these groups they have access to
    for my $sgroup ( @$sgroups ) {
        my $gp_name = $sgroup->{'name'};
        my $members = forcearray( $sgroup->{'member'} );
        if( @$members ) {
            for my $member ( @$members ) {
                my $user = $member->{'id'};
                $userhash->{ $user } ||= { groups => {} };
                my $userinfo = $userhash->{ $user };
                $userinfo->{'groups'}{ $sgroup->{'name'} } = 1;
            }
        }
    }
    
    # next find all groups that are defined, and that their definitions only involve local groups,
    # then repeat this same process for those
    my $lgroups = $self->{'lgroups'};
    #print Dumper( $lgroups );
    for my $lgroup ( @$lgroups ) {
        # find the members of this locally defined group
        #print "Local group: ".$lgroup->{'name'}."\n";
        my $def = $lgroup->{'setdef'};
        my $members = $def->members();
        if( @$members ) {
            for my $user ( @$members ) {
                $userhash->{ $user } ||= { groups => {} };
                my $userinfo = $userhash->{ $user };
                $userinfo->{'groups'}{ $lgroup->{'name'} } = 1;
            }
        }
    }
    #$Data::Dumper::Maxdepth = 2;
    #print Dumper( $userhash );
}

sub get_prefixes {
    my ( $core, $self ) = @_;
    return [ 'l' ];
}

# get a list of all known permissions
sub list_permissions {
    my ( $core, $self ) = @_;
    my $hash = $self->{'permhash'};
    return $hash;
}

sub group_list {
    my ( $core, $self ) = @_;
    
}

# get a list of permissions provided by a specific group
sub group_get_permissions {
    my ( $core, $self ) = @_;
    my $group = $core->get('group');
    if( $group =~ m/^l_(.+)/ ) {
        $group = $1;
        my $allgroups = $self->{'all_groups'};
        my $gp_info = $allgroups->{ $group };
        my %hash;
        my $perms = forcearray $gp_info->{'perm'};
        for my $perm ( @$perms ) {
            my $pname = $perm->{'name'};
            $hash{$pname} = 1;
        }
        return \%hash;
    }
    return {};
}

# get a list of all of the members of a group
sub group_get_members {
    # figure out which method handles this group and send it off to that
}

sub group_add_permission {
}

sub group_delete_permission {
}

sub group_add {
}

sub group_delete {
}

sub user_add {
}

sub user_delete {
}

# fetch all of the direct user permission that exist ( not ones that go through groups; that is done in the permission manager
sub user_get_permissions {
    my ( $core, $self ) = @_;
    return {};
}

sub user_get_groups {
    my ( $core, $self ) = @_;
    my $user = $core->get('user');
    my $userhash = $self->{'user_group_hash'};
    my $userinfo = $userhash->{ $user };
    return [] if( !$userinfo );
    my $gp_hash = $userinfo->{'groups'};
    return [] if( !$gp_hash || !%$gp_hash );
    my @arr;
    for my $key ( keys %$gp_hash ) {
        push( @arr, "l_$key" );
    }
    return \@arr;
}

sub user_add_permission {
    # add a new user permission of some type
    # this will be passed to each method; first one to handle it "succeeds"
}

sub user_delete_permisson {
}

sub group_add_member {
}

sub group_delete_member {
}

sub user_exists {
    my ( $core, $self ) = @_;
    my $user = $core->get('user');
    my $users = $self->{'users'};
    return $users->{ $user } ? 1 : 0;
}
sub pass_hash {
    my ( $core, $self ) = @_;
    my $user = $core->get('user');
    my $pw = $core->get('pw');
    my $salt = "fsjlfse";
    return sha1_hex("$salt--$user--$pw--$salt");
}

sub user_check_pw {
    my ( $core, $self ) = @_;
    my $user = $core->get('user');
    my $pw = $core->get('pw');
    return 0 if( !$self->user_exists( user => $user ) ); 
    my $hash = $self->pass_hash( user => $user, pw => $pw );
    my $users = $self->{'users'};
    my $userob = $users->{ $user };
    return 1 if( $userob->{'hash'} eq $hash );
    return 0;
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
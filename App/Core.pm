# App::Core Framework
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

App::Core - Application framework built around Class::Core wrapper system

=head1 VERSION

0.02

=cut

use lib '..';

package App::Core::ClassCoreExtend;
# The subroutines in this package extend the typical Class::Core::INNER ( aka $core )
use Data::Dumper;

sub getmod {
    my ( $a, $virt, $name ) = @_;
    #return $virt->{'r'}->getmod( mod => $name ) if( $virt->{'r'} );
    my $app = $virt->{'obj'}{'_app'};
    return $app->getmod( mod => $name );
}
# This function fetches the global application conf
sub getconf {
    my ( $a, $virt, $name ) = @_;
    my $conf = $virt->{'obj'}{'_glob'}{'conf'};
    return $conf;
}
sub create {
    my $a = shift;
    my $virt = shift;
    my $mod = shift;
    my $app = $virt->{'obj'}{'_app'};
    my $r = $virt->{'r'};
    my $session = $virt->{'session'};
    my %more = @_;
    return $app->load_class( mod => $mod, r => $r, session => $session, parms => \%more );
}

sub getapp  { my ( $a, $virt ) = @_;  return $virt->{'obj'}{'_app'}; }
sub getbase { my ( $a, $virt ) = @_;  return $virt->{'obj'}{'_app'}->getbase(); }
sub getmode { my ( $a, $virt ) = @_;  return $virt->{'obj'}{'_app'}{'_mode'}; }

sub dumperx {
    my ( $a, $virt, $name, $val ) = @_;
    my ($package, $filename, $line) = caller(1);
    print "XDump from $package #$line\n  $name:\n  " . Dumper( App::Core::simplify( $val ) );
}

package App::Core;
use Class::Core qw/:all/;
use XML::Bare qw/xval forcearray/;
use strict;
use vars qw/$VERSION/;
use Carp;
$VERSION = "0.02";

our $spec;
$spec = <<DONE;
<func name='run'>
    <in name='config' exists type='path'/>
    <ret type='bool'/>
</func>
DONE

my @apps;

my $runthread;

sub construct {
    my ( $core, $app ) = @_;
    push( @apps, $app );
}

sub INT_handler {
    my $thr = threads->self();
    my $tid = $thr->tid();
    exit if( $tid != $runthread );
    for my $app ( @apps ) {
        $app->end();
    }
    exit;
}

sub run {
    my ( $core, $app ) = @_;
    
    my $thr = threads->self();
    $runthread = $thr->tid();
    $SIG{'INT'} = 'App::Core::INT_handler';
    
    my $conf_file = $core->get('config');
    my $core_file = $core->get('core') || 'core.xml';
    my ( $ob , $xml  ) = new XML::Bare( file => $conf_file );
    my ( $cob, $cxml ) = new XML::Bare( file => $core_file );
    $cxml = $cxml->{'xml'};
    $xml = $xml->{'xml'};
    
    my $modes = forcearray( $xml->{'mode'} );
    my $cmodes = forcearray( $cxml->{'mode'} ); # core modes
    
    my %modehash;
    my %cmodehash;
    for my $mode  ( @$modes  ) { my $name = xval $mode ->{'name'}; $modehash { $name } = $mode;  }
    for my $cmode ( @$cmodes ) { my $name = xval $cmode->{'name'}; $cmodehash{ $name } = $cmode; }
    
    my $selected_mode = $app->{'_mode'} = $core->get('mode') || 'default';
    if( $selected_mode ne 'default' ) {
        print "Starting system in mode '$selected_mode'\n";
    }
    my $cur_mode;
    my $cur_cmode;
    if( $modehash {$selected_mode} ) { $cur_mode  = $modehash {$selected_mode}; }
    if( $cmodehash{$selected_mode} ) { $cur_cmode = $cmodehash{$selected_mode}; }
    
    my $glob = $app->{'obj'}{'_glob'};
    
    my $classhash = $glob->{'classinfo'} = {};
    my $classes = forcearray( $xml->{'class'} );
    if( @$classes ) {
        for my $class ( @$classes ) {
            my $name = xval $class->{'name'};
            my $file = xval $class->{'file'};
            $classhash->{ $name } = { file => $file, xml => $class };
        }
    }
    my $mclasses = forcearray( $cur_mode->{'class'} );
    if( @$mclasses ) {
        for my $class ( @$mclasses ) {
            my $name = xval $class->{'name'};
            my $file = xval $class->{'file'};
            $classhash->{ $name } = { file => $file, xml => $class };
        }
    }
    
    $glob->{'conf'} = $xml;
    my $r = $app->{'r'} = 'init';
    my $session = $app->{'session'} = 'init';
    
    my $imodules = forcearray( $cxml->{'module'} ); # internal core modules
    my $modules  = forcearray( $xml->{'module'} );
    
    # grab modules in core config related to the current mode and add them to the internal module array being used
    my $i_mode_modules = forcearray( $cur_cmode->{'module'} );
    push( @$imodules, @$i_mode_modules );
    
    # grab modules in config related to the current mode and add them to the module array being used
    my $mode_modules = forcearray( $cur_mode->{'module'} );
    push( @$modules, @$mode_modules );
    
    my $log = 0;
        
    $glob->{'create'} = \&create_test;
    
    my $modhash = $app->{'modhash'} = {};
    
    my %order_by_name;
    my %mod_by_order;
    
    my $maxmod = 0;
    
    for my $imod ( @$imodules ) {
        my $name = xval $imod->{'name'};
        $maxmod++;
        
        $mod_by_order{ $maxmod } = { xml => $imod, type => 'internal' };
        $order_by_name{ $name } = $maxmod;
    }
    
    for my $emod ( @$modules ) {
        my $name = xval $emod->{'name'};
        my $order = $order_by_name{ $name };
        if( $order ) { 
            if( $emod->{'file'} ) { # over-riding an internal module
                $mod_by_order{ $order } = { xml => $emod, type => 'custom' };
            }
            else {
                my $imod = $mod_by_order{ $order };
                my $a = $imod->{'xml'};
                my $b = $emod;
                if( $a && $b ) {
                    mux( $a, $b );
                }
                else {
                    $imod->{'xml'} = $a || $b;
                }
            }
        }
        else {
            $mod_by_order{ ++$maxmod } = { xml => $emod, type => 'default' };
        }
    }
    
    my @listening;
    
    for( my $k=1;$k<=$maxmod;$k++ ) {
        my $mod;
        my $base     = $mod_by_order{ $k };
        my $modxml   = $base->{'xml'};
        my $type     = $base->{'type'};
        my $mod_name = xval( $modxml->{'name'} );
        my $file     = xval( $modxml->{'file'}, $mod_name );
        my $call     = $modxml->{'call'};
        my $listen   = $modxml->{'listen'};
        
        my $mod_info = { 
            file   => $file, 
            name   => $mod_name, 
            call   => $call, 
            listen => $listen, 
            xml    => $modxml, 
            type   => $type
        };
        
        if( $modxml->{'listen'} ) {
            push( @listening, $mod_info );
        }
        
        my $res = load_module( $glob, $mod_info, $app );
        if( !$res ) {
            if( $log ) {
                $log->error( text => "Cannot load Module $mod_name - type: $type\n $@\n" ) 
            }
            else {
                print "Cannot load Module $mod_name $file - type: $type\n $@\n";
            }
            next;
        }
        $mod = $mod_info->{'ob'};
        $mod->{'r'} = $r; $mod->{'session'} = $session;
        
        if( !$mod_info->{'call'} ) {
            $mod->init( conf => $modxml, lev => 0 ); # passing modxml here is redunant; it happens above
        }
        
        if( $mod_name eq 'log' ) { 
            $log = $glob->{'log'} = $mod;
        }
        $modhash->{ $mod_name } = $mod;
        if( $log ) { 
            $log->note( text => "Loaded $type $mod_name module" );
        }
        else {
            print "Loaded $type $mod_name module\n";
        }
    }
        
    # Register everything into the API TODO
    
    if( @listening ) {
        my $rpc = $modhash->{'rpc'};
        if( !$rpc ) {
            die "There are listening modules, but no rpc module setup";
        }
        my $msg = "The following modules are listening on RPC: ";
        for my $mod_info ( @listening ) {
            my $mod_name = $mod_info->{'name'};
            $msg .= "$mod_name ";
            $rpc->register_listener( modinfo => $modhash );
        }
        $log->note( text => $msg );
        
        $rpc->start_listening();
    }
    
    if( $cur_mode ) {
        $app->runmode( mode => $cur_mode );
    }
    
    return 0;
}

sub getbase {
    my ( $core, $app ) = @_;
    return $app->{'obj'}{'_glob'}{'conf'}{'base'}{'value'};
}

sub end {
    my ( $core, $app ) = @_;
    my $modhash = $app->{'modhash'};
    for my $modname ( keys %$modhash ) {
        my $mod = $modhash->{ $modname };
        my $map = $mod->{'obj'}{'_map'};
        $mod->end() if( $map->{'end'} );
    }
}

sub getmod {
    my ( $core, $app ) = @_;
    
    my $modname = $core->get('mod');
    return $app->{'modhash'}{ $modname } || confess( "Cannot find mod $modname\n" );
}

sub runmode {
    my ( $core, $app ) = @_;
    my $mode = $core->get('mode');
    my $init = $mode->{'init'};
    my $calls = forcearray( $init->{'call'} );
    my $mods = $app->{'modhash'};
    
    my %datahash;
    for my $call ( @$calls ) {
        my $modname = xval $call->{'mod'};
        my $func = xval $call->{'func'};
        my $args = $call->{'args'};
        my $arghash = $args ? simplify( $args ) : 0; # strip value references out of xml
        fill_dollars( $arghash, \%datahash );
        
        my $mod = $mods->{ $modname } or confess( "Cannot get module $modname" );
        if( $args ) { 
            my $res = $mod->$func( %$arghash );
            $datahash{'ret'} = $res;
            if( ref( $res ) eq 'Class::Core::INNER' ) {
                my $allres = $res->getallres();
                mux( \%datahash, $allres );
            }
        }
        else { $mod->$func(); }
    }
}

sub muxdup {
    my ( $a, $b ) = @_;
    my $n = {};
    for my $key ( keys %$a ) {
        $n->{ $key } = $a->{ $key };
    }
    for my $key ( keys %$b ) {
        my $src = $n->{ $key };
        my $new = $b->{ $key };
        if( $src && $new ) {
            if( ref( $src ) eq 'ARRAY' ) {
                if( ref( $new ) eq 'ARRAY' ) {
                    push( @$src, @$new );
                }
                else {
                    push( @$src, $new );
                }
            }
        }
        else {
            $n->{ $key } = $b->{ $key };
        }
    }
    return $n;
}

sub mux {
    my ( $a, $b ) = @_;
    for my $key ( keys %$b ) {
        my $src = $a->{ $key };
        my $new = $b->{ $key };
        if( $src && $new ) {
            if( ref( $src ) eq 'ARRAY' ) {
                if( ref( $new ) eq 'ARRAY' ) {
                    push( @$src, @$new );
                }
                else {
                    push( @$src, $new );
                }
            }
        }
        else {
            $a->{ $key } = $b->{ $key };
        }
    }
}

sub fill_dollars {
    my ( $hash, $data ) = @_;
    return if( ref( $hash ) ne 'HASH' );
    for my $key ( keys %$hash ) {
        my $val = $hash->{ $key };
        my $ref = ref( $val );
        if( $ref eq '' && $val =~ m/^\$(.+)$/ ) {
            my $name = $1;
            if( $name =~ m/^arg([0-9]+)$/ ) {
                $hash->{ $key } = $ARGV[ $1 ];
            }
            else {
                if( defined( $data->{ $name } ) ) {
                    $hash->{ $key } = $data->{ $name };
                }
            }
        }
        elsif( $ref eq 'HASH' ) {
            fill_dollars( $val );
        }
    }
}

sub simplify {
    my $node = shift;
    my $ref = ref( $node );
    if( $ref eq 'ARRAY' ) {
        my @ret;
        for my $sub ( @$node ) {
            push( @ret, simplify( $sub ) );
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

my %used_mods;

sub load_module {
    my ( $glob, $info, $app ) = @_;
    my $file = $info->{'file'};
    if( !$used_mods{ $file } ) {
        eval("use $file;");
        if( $@ ) { # was $! before
            return 0;
        }
    }
    $used_mods{ $file } = 1;
    my $newref = \&{"$file\::new"};
    my $callback = ( $info->{'name'} eq 'log' || $info->{'type'} eq 'internal' ) ? 0 : \&check; # Don't do logging of log module or internal modules
    my $call = $info->{'call'};
    $info->{'ob'} = $newref->( 
        $file, 
        obj => { 
            _callback => $callback, 
            _glob     => $glob, 
            _app      => $app 
        }, 
        _call     => $call, 
        _callfunc => \&callfunc, 
        _extend   => bless( {}, 'App::Core::ClassCoreExtend' ),
        _xml      => $info->{'xml'}
        );
    return 1;
}

sub load_class {
    my ( $core, $app ) = @_;
    my $glob = $app->{'obj'}{'_glob'};
    my $mod = $core->get('mod');
    my $r = $core->get('r');
    my $session = $core->get('session');
    my $parms = $core->get('parms') || {};
    
    my $classinfo = $glob->{'classinfo'};
    my $info = $classinfo->{ $mod } or confess( "Cannot find class $mod" );
    my $file = $info->{'file'};
    
    if( !$used_mods{ $file } ) {
        eval("use $file;");
        if( $@ ) { # was $! before
            return 0;
        }
    }
    $used_mods{ $file } = 1;
    my $newref = \&{"$file\::new"};
    my $callback = \&check; # Always do logging of class calls
    return $newref->( 
        $file, 
        obj => { 
            _callback => $callback, 
            _glob     => $glob, 
            _app      => $app 
        },
        r => $r,
        session => $session,
        _extend   => bless( {}, 'App::Core::ClassCoreExtend' ),
        _xml      => $info->{'xml'},
        %$parms
        );
    
    #return $mod->new( obj => { _glob => $glob }, r => $r, session => $session, @_ );
}

# This function needs to make a remote call
sub callfunc {
    my ( $app, $call, $func, $xml ) = @_;
    my $mod = xval $call->{'mod'};
    my $port = xval $call->{'port'};
    my $rpc = $app->{'modhash'}{'rpc'};
    $rpc->call( xml => $xml, mod => $mod, func => $func );
}

sub check {
    my ( $core, $virt, $func, $parms ) = @_;
    my $obj = $virt->{'obj'};
    my $cls = $obj->{'_class'};
    my $glob = $obj->{'_glob'};
    $glob->{'log'}->note( text => "Function call - $cls\::$func" );
    my $spec = $core->{'_funcspec'};
    if( $spec->{'perms'} && $virt->{'r'} ) {
        my $user_perms = $virt->{'r'}{'perms'};
        my $func_perms = $spec->{'perms'};
        for my $item ( @$func_perms ) {
            if( !$user_perms->{ $item } ) {
                $glob->{'log'}->error( text => "User does not have permission $item" );
                return 0;
            }
        }
    }
    return 1;
}

1;

__END__

=head1 SYNOPSIS

AppCore is an application server for Perl. It is designed to be modular, with many "default" modules relevant to a base functional
system being provided. The "default" modules can be used to build a full application with minimal system code, focusing on application functionality
instead of how to handle typical things such as logging, cookies, sessions, api, etc.

AppCore allows for an application to be created as a package of configuration and modules, similar to the way web containers or servlets
are used in a Java environment with a Java application server such as JBoss or Tomcat.

AppCore differs significantly from the approach taken by other Perl applications servers such as Catalyst and Dancer, in that it attempts
to seperate the configuration of your application from the application code itself. 

=head1 DESCRIPTION

=head2 Basic Example

=head3 runcore.pl

    #!/usr/bin/perl -w
    use strict;
    use App::Core;
    
    my $core = App::Core->new();
    $core->run( config => "config.xml" );

=head3 config.xml

    <xml>
        <log>
            <console/>
        </log>
        
        <web_request>
            <mod>mongrel2</mod>
        </web_request>
        
        <mode name="default">
            <init>
                <call mod="web_request" func="run" />
                <call mod="web_request" func="wait_threads"/>
            </init>
        </mode>
    </xml>

=head2 Configuration

Configuration of an AppCore application is accomplished primarily by the creation and editing of a 'config.xml' file.
Such an xml file contains the following:

=over 4

=item * A list of the modules your application contains

=item * Configuration for each of your modules

=item * Configuration for App::Core itself and the included modules

=item * A sequence of steps to be used when starting up an AppCore instance

=back

=head2 Application Modules

Application modules are custom modules that interact with AppCore itself to define your custom application logic.
An application module is a perl module using L<Class::Core>, containing specific functions so that it can integrate with AppCore
and other modules.

=head2 Concurrency / Multithreading

AppCore does not currently support multithreading of requests. Long running requests can and will prevent handling of other requests
until the long running request is finished. This will be fixed in the next version.

=head2 Modules

Note that in version 0.03 ( this version ) the following components are included in the base install of App::Core.
Note also that none of the following links currently have any detailed documentation. The next version should address this.

=over 4

=item * L<App::Core::Admin::Default>

An admin interface to see the state of a running AppCore, and various information about it's activity.

=item * L<App::Core::Log::Default>

A simple logging system that logs to the shell.

=item * L<App::Core::Web::CookieMan::Default>

A basic cookie handling module.

=item * Incoming Web Request Modules

=over 4

=item * L<App::Core::Web::Request::HTTP_Server_Simple>

A module that uses L<HTTP::Server::Simple> in order to accept incoming requests directly.
Note that this module will need L<HTTP::Server::Simple::CGI> to be installed in order for it to work.
Also, using this module will redirect regular print statements to go through to a web request; which may be unexpected.

=item * L<App::Core::Web::Request::Mongrel2>

A module that connects to a Mongrel2 server in order to accept incoming requests.
Using this module, which is enabled by default, will require the following CPAN modules to be installed:

=over 4

=item * L<ZMQ::LibZMQ3>

=item * L<URI::Simple>

=item * L<Text::TNetstrings>

=back

=back

=item * L<App::Core::Web::Router::Default>

A basic routing module that allows modules to register routes against it so that different
modules can handle different path requests into the system.

=item * L<App::Core::Web::SessionMan::Default>

A basic session management module that stores sessions in memory. Note session data stored through
this module will be lost whenever the AppCore is restarted.

=item * Internally used modules

=over 4

=item * L<App::Core::Shared::Http_Server_Simple_Wrapper>

=back

=back

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
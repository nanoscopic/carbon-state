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
use App::Core::Router::Default;
use App::Core::Log::Default;
use App::Core::Session::Manager::Default;
use App::Core::Cookie::Manager::Default;
use App::Core::Request::Manager::Default;
use App::Core::Admin::Default;
use Carp;

package App::Core;
use Class::Core qw/:all/;
use Data::Dumper;
use XML::Bare qw/xval forcearray/;
use strict;
use vars qw/$VERSION/;
$VERSION = "0.02";

our $spec;
$spec = <<DONE;
<func name='run'>
    <in name='config' exists type='path'/>
    <ret type='bool'/>
</func>
DONE

#my %modhash;

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
    #print Dumper( $core );
    
    my $thr = threads->self();
    $runthread = $thr->tid();
    $SIG{'INT'} = 'App::Core::INT_handler';
    
    my $conf_file = $core->get('config');
    my ( $ob, $xml ) = new XML::Bare( file => $conf_file );
    
    my $glob = $app->{'obj'}{'_glob'};
    
    $glob->{'conf'} = $xml = $xml->{'xml'};
    my $r = $app->{'r'} = 'init';
    my $session = $app->{'session'} = 'init';
    my $modules = forcearray( $xml->{'module'} );
    
    my $log = 0;
    
    my %order;
    my @mod_names;
    my %mod_hash;
    for my $module ( @$modules ) {
        my $name = xval $module->{'name'};
        my $file = xval $module->{'file'}, $name;
        my $order = $module->{'order'};
        my $init = xval( $order->{'init'} ) || 0;
        my $call = $module->{'call'};
        my $listen = $module->{'listen'};
        #my $init_session = xval $order->{'init_session'};
        $order{ $name } = $init;
        $mod_hash{ $name } = { file => $file, name => $name, init => $init, call => $call, listen => $listen, xml => $module };
        push( @mod_names, $name ) if( $name !~ m/^(log)$/ );
    }
    @mod_names = sort { $order{ $a } <=> $order{ $b } } @mod_names;    
    
    #my $virt = $core->{'virt'};
    
    #print Dumper( $app );
    $glob->{'create'} = \&create_test;
    
    my $modhash = $app->{'modhash'} = {};
    
    my $wr_xml = $xml->{'web_request'};
    my $wr_mod = 'mongrel2';
    my $webmod = "";
    if( $wr_xml ) {
        $wr_mod = xval $wr_xml->{'mod'}, 'mongrel2';
    }
    
    my $rpc_xml = $xml->{'rpc'};
    my $rpc_mod = 'mongrel2';
    my $rpcmod = '';
    if( $rpc_mod eq 'mongrel2' ) {
        #eval('use App::Core::RPC::IO::Mongrel2;');
        use App::Core::RPC::IO::Mongrel2;
        $rpcmod = 'App::Core::RPC::IO::Mongrel2';
    }
    
    if( $wr_mod eq 'mongrel2' ) {
        use App::Core::Request::IO::Mongrel2;
        $webmod = 'App::Core::Request::IO::Mongrel2';
    }
    elsif( $wr_mod eq 'http_server' ) {
        eval('use App::Core::Request::IO::HTTP_Server_Simple;');
        $webmod = 'App::Core::Request::IO::HTTP_Server_Simple';
    }
    
    # Load all of the builtin modules
    my @builtins = (
            { name => 'log'         , mod => 'App::Core::Log::Default' },
            #{ name => 'api_request', mod => 'App::Core::API::ZMQ' }, # handle api requests
            #{ name => 'api_router' , mod => 'App::Core::API::Dist' }, # api core handler
            #{ name => 'perm'       , mod => 'App::Core::Perm::Default' }, # the module that figures out permissions
            { name => 'session_man' , mod => 'App::Core::Session::Manager::Default' }, # the module that creates sessions
            { name => 'cookie_man'  , mod => 'App::Core::Cookie::Manager::Default' },
            { name => 'request_man' , mod => 'App::Core::Request::Manager::Default' },
            { name => 'web_request' , mod => $webmod }, # handle "web requests" ( FCGI / Mongrel2 0MQ / ... )
            { name => 'web_router'  , mod => 'App::Core::Router::Default' },
            { name => 'core_admin'  , mod => 'App::Core::Admin::Default' },
            { name => 'rpc'         , mod => $rpcmod },
            #{ name => 'auth'       , mod => '' } # the default module that authenticates users
            #{ name => 'locking'    , mod => '' } # module to handle object locking/concurrency
        );
    BT: for my $builtin ( @builtins ) {
        my $name = $builtin->{'name'};
        my $modpath = $builtin->{'mod'};
        my $mod_info = $mod_hash{$name};
        my $mod;
        my $type = 'custom';
        if( $mod_info && $mod_info->{'file'} ne 'builtin' ) { # don't use built in
            
            my $res = load_module( $glob, $mod_info, $app );
            
            if( !$res && $log ) {
                $log->error( text => "Cannot load Module $name" );
                next;
            }
            $mod = $mod_info->{'ob'};
            $mod->{'r'} = $r; $mod->{'session'} = $session; # Note we are just copying 'init' into all of these
            if( $name eq 'log' ) { $log = $mod; }
        }
        else { # use built in
            my $modxml = {};
            if( $mod_info ) { $modxml = $mod_info->{'xml'}; }
            {
                no strict 'refs';
                my $hash = \%{"$modpath\::"};
                if( !$hash->{'new'} ) {
                    $log->error( text => "$modpath is not built in");
                    next BT;
                }
            }
            #my $newref = \&{"$modpath\::new"};
            #$mod = $newref->( $modpath );
            $mod = $modpath->new( obj => { _glob => $glob, _app => $app }, r => $r, session => $session, xml => $modxml ); # Don't use callback for builtins - #_callback => $callback, 
            if( $name eq 'log' ) { $log = $mod; }
            $type = 'default';
        }
        $mod->init( conf => $xml->{ $name }, lev => 0 );
        $modhash->{ $name } = $mod;
        $log->note( text => "Loaded $type $name module" ) if( $log );
    }    
    
    # where do I set the log so that stuff can get to it???? TODO TODO
    $log = $glob->{'log'} = $modhash->{'log'};
    
    # Register everything into the API
                    
    my @listening;
    for my $mod_name ( @mod_names ) {
        my $mod_info = $mod_hash{ $mod_name };
        next if( $mod_info->{'file'} eq 'builtin' );
        if( $mod_info->{'listen'} ) {
            push( @listening, $mod_info );
        }
        my $res = load_module( $glob, $mod_info, $app );
        $mod_info->{'ob'}->{'r'} = $r; $mod_info->{'ob'}->{'session'} = $session;
        if( !$res && $log ) {
            $log->error( text => "Cannot load Module $mod_name" );
            next;
        }
        my $init = $mod_info->{'init'};
        $log->note( text => "Loaded module: $mod_name, order=$init" );
        if( !$mod_info->{'call'} ) {
            $mod_info->{'ob'}->init( lev => 0 );
        }
        $modhash->{ $mod_name } = $mod_info->{'ob'};
    }
    
    if( @listening ) {
        my $rpc = $modhash->{'rpc'};
        if( !$rpc ) {
            die "There are listening modules, but no rpc module setup";
        }
        print "The following modules are listening on RPC:\n";
        for my $mod_info ( @listening ) {
            my $mod_name = $mod_info->{'name'};
            print "  $mod_name\n";
            $rpc->register_listener( modinfo => $modhash );
        }
        $rpc->start_listening();
    }
    
    #$app->{'mods'} = \%modhash;
    
    my $modes = forcearray( $xml->{'mode'} );
    
    my %modehash;
    for my $mode ( @$modes ) {
        my $name = xval $mode->{'name'};
        $modehash{ $name } = $mode;
    }
    
    if( $modehash{'default'} ) {
        $app->runmode( mode => $modehash{'default'} );
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

sub create_test {
    my $virt = shift;
    my $glob = shift;
    my $mod = shift;
    my $r = $virt->{'r'};
    my $session = $virt->{'session'};
    return $mod->new( obj => { _glob => $glob }, r => $r, session => $session, @_ );
    #print "$r $session $parm\n";
}

sub getmod {
    my ( $core, $app ) = @_;
    #my $glob = $app->{'_glob'};
    
    my $modname = $core->get('mod');
    return $app->{'modhash'}{ $modname } || confess( "Cannot find mod $modname\n" );
}

sub runmode {
    my ( $core, $app ) = @_;
    my $mode = $core->get('mode');
    my $init = $mode->{'init'};
    my $calls = forcearray( $init->{'call'} );
    #my $glob = $app->{'_glob'};
    my $mods = $app->{'modhash'};
    for my $call ( @$calls ) {
        my $modname = xval $call->{'mod'};
        my $func = xval $call->{'func'};
        #print "Running $func on $mod\n";
        my $args = $call->{'args'};
        my $arghash = $args ? simplify( $args ) : 0; # strip value references out of xml
        
        my $mod = $mods->{ $modname } or confess( "Cannot get module $modname" );
        #my $funcref = 
        if( $args ) { 
            print Dumper( $arghash );
            $mod->$func( %$arghash );
        }
        else { $mod->$func(); }
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
    #print Dumper( $core );
    my $file = $info->{'file'};
    if( !$used_mods{ $file } ) {
        eval("use Module::$file;");
        if( $! ) {
            return 0;
        }
    }
    $used_mods{ $file } = 1;
    my $newref = \&{"Module::$file\::new"};
    my $callback = ( $info->{'name'} eq 'log' ) ? 0 : \&check; # Don't do logging of custom log modules ( they are a special case )
    my $call = $info->{'call'};
    my $listen = $info->{'listen'};
    $info->{'ob'} = $newref->( "Module::$file", obj => { _callback => $callback, _glob => $glob, _app => $app }, _call => $call, _callfunc => \&callfunc );
    return 1;
}

# This function needs to make a remote call
sub callfunc {
    my ( $app, $call, $func, $xml )= @_;
    my $mod = xval $call->{'mod'};
    my $port = xval $call->{'port'};
    #$xml .= "<mod>$mod</mod><func>$func</func>";
    my $rpc = $app->{'modhash'}{'rpc'};
    $rpc->call( xml => $xml, mod => $mod, func => $func );
    #print "xml2:$xml\n";
}

sub check {
    my ( $core, $virt, $func, $parms ) = @_;
    my $obj = $virt->{'obj'};
    my $cls = $obj->{'_class'};
    #print Dumper( $core );
    my $glob = $obj->{'_glob'};
    $glob->{'log'}->note( text => "Function call - $cls\::$func" );
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
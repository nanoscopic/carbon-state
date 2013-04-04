package CoreMod::apitest;
use Class::Core qw/:all/;
use strict;

sub init {
    my ( $core, $self ) = @_;
    
    my $api = $core->getmod( 'core_api' );
    $api->register_via_spec( mod => $self, session => 'APP' );
}

sub home {
    my ( $core, $self ) = @_;
    my $r = $self->{'r'};
    
    my $base = $core->getbase();
    my $vars = { base => $base };
    if( $r->{'type'} eq 'post' ) {
        my $post = $r->{'postvars'};
        my $a = $post->{'a'};
        my $b = $post->{'b'};
        my $action = $post->{'action'};
        my $result;
        if( $action eq '+' ) { $result = $a + $b; }
        if( $action eq '-' ) { $result = $a - $b; }
        if( $action eq '*' ) { $result = $a * $b; }
        if( $action eq '/' ) { $result = $a / $b; }
        $vars->{'result'} = "<hr>$a $action $b = $result";
    }
    my $tpl = $core->get('tpl');
    $tpl->setvars( vars => $vars );
}

sub test {
    my ( $core, $self ) = @_;
    return { blah => 23, a => 34, sub => [ 1, 2 ] };
}

1;
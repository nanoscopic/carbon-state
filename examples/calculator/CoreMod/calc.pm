package CoreMod::calc;
use Class::Core qw/:all/;
use strict;

sub init {
}

sub home {
    my ( $core, $self ) = @_;
    my $r = $self->{'r'};
    
    my $vars = {};
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
    $tpl->set_vars( vars => $vars );
}

sub blah {
    return "blahfunc";
}

1;
package CoreMod::example;
use Class::Core qw/:all/;
use strict;

sub init {
}

sub home {
    my ( $core, $self ) = @_;
    my $r = $self->{'r'};
    
    my $main_vars = { a=>1,b=>2 };
    
    my $tpl = $core->get('tpl');
    $tpl->set_vars( vars => $main_vars );
    $tpl->tpl_vars( tpl => 'header', vars => {a=>3,b=>4}, mod => 'header' );
    $tpl->tpl_vars( tpl => 'header.nav', vars => {a=>5,b=>6} );
    
    #$core->dumper( 'tpl', $tpl->{'tpls'} );
}

sub blah {
    return "blahfunc";
}

1;
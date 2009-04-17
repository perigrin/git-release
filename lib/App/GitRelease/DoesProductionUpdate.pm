package App::GitRelease::DoesProductionUpdate;
use Moose::Role;
use Carp qw(cluck);
with qw(App::GitRelease::DoesSSH);

has 'disable_push' => (
    isa        => 'Bool',
    is         => 'ro',
    lazy_build => 1,
);
sub _build_disable_push { `git config release.disable_push` || 0 }

sub _push_to_ssh_target {
    my ( $self, $uri ) = @_;
    my $ssh = $self->_get_ssh($uri);
    print STDERR $ssh->exec("cd $uri->{path}");
    $ssh->send('git pull');
    while ( defined( my $line = $ssh->read_line() ) ) {
        print $line . "\n";
    }

    $ssh->close();
}

sub push_to_target {
    my ( $self, $target ) = @_;
    if ( $target =~ m|^ssh://([^@]+)@([^/]+)/(.*)$| ) {
        my $uri = { user => $1, host => $2, path => $3, };
        print STDERR "Attempting push to $target\n";
        $self->_push_to_ssh_target($uri);
    }
    else { cluck "Invalid target: $target"; }
}

sub push_to_production {
    $_[0]->push_to_target($_) for @{ $_[0]->release_list };
    print STDERR "Production updated\n";
}

no Moose::Role;
1;
__END__

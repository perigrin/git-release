package App::GitRelease::DoesBootstrap;
use Moose::Role;
use Carp qw(cluck);

with qw(App::GitRelease::DoesSSH);

has 'bootstrap' => (
    isa        => 'Bool',
    is         => 'ro',
    lazy_build => 1,
);
sub _build_bootstrap {0}

has remote_origin_url => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_remote_origin_url {
    chomp( my $url = `git config remote.origin.url` );
    confess 'No remote.origin.url you will need to supply one' unless $url;
    return $url;
}

sub _bootstrap_ssh_target {
    my ( $self, $uri ) = @_;
    my $ssh = $self->_get_ssh($uri);
    $ssh->send("git clone ${\$self->remote_origin_url} $uri->{path}");
    while ( my $chunk = $ssh->peek(3) ) {
        print $ssh->eat($chunk);
    }

    $ssh->close();
}

sub boostrap_target {
    my ( $self, $target ) = @_;
    if ( $target =~ m|^ssh://([^@]+)@([^/]+)/(.*)$| ) {
        my $uri = { user => $1, host => $2, path => $3, };
        print STDERR "Attempting push to $target\n";
        $self->_bootstrap_ssh_target($uri);
    }
    else { cluck "Invalid target: $target"; }

}

sub bootstrap_production {
    $_[0]->boostrap_target($_) for @{ $_[0]->release_list };
    print STDERR "Production ready\n";
}

no Moose::Role;
1;
__END__

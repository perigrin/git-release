package App::GitRelease::DoesSSH;
use Moose::Role;

use Net::SSH::Expect;

sub _get_ssh {
    my ( $self, $uri ) = @_;

    my $ssh = Net::SSH::Expect->new(
        host    => $uri->{host},
        user    => $uri->{user},
        raw_pty => 1
    );

    $ssh->run_ssh();
    print $ssh->read_all(2);
    $ssh->exec("stty raw -echo");
    return $ssh;
}

no Moose::Role;
1;
__END__

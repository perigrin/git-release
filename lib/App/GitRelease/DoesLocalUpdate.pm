package App::GitRelease::DoesLocalUpdate;
use Moose::Role;

has 'disable_update' => (
    isa        => 'Bool',
    is         => 'ro',
    lazy_build => 1,
);
sub _build_disable_update { `git config release.disable_update` || 0 }

sub run_update {
    warn 'updating local repo';
    system( 'git', 'pull' );
}

no Moose::Role;
1;
__END__

package App::GitRelease;
use Moose;

with qw(MooseX::GetOpt);

has release_list => (
    isa => 'ArrayRef',
    is  => 'ro',    
    lazy_build => 1,
);

sub _build_release_list { [ split /\n/, `git config --get-all release.url`] }

no Moose;
1;

use inc::Module::Install;

# Define metadata
name 'App-GitRelease';
all_from 'lib/App/GitRelease.pm';

# Specific dependencies
requires 'Moose'            => '0.74';
requires 'App::Prove'       => '3.16';
requires 'Net::SSH::Expect' => '1.09';

requires_external_bin 'git';

install_script 'git-release';

WriteAll;

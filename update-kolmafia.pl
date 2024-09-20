#!/usr/bin/perl
# update-kolmafia.pl
# c2t

# downloads latest KoLmafia into the current working directory if it does not already exist and creates a symbolic link "KoLmafia-latest.jar" to it
# note: if using a win32 system, the symbolic link will not be created unless running this as an administrator

use strict;
use warnings;
use LWP::Simple;
use Getopt::Long qw(GetOptions);

# options
my $makesymlink = 1;
GetOptions('symlink!' => \$makesymlink) or die "$!";

# Detect the operating system
my $os = $^O;

# need additional modules to make symlinks in Win32
if ($makesymlink) {
  if ($os eq 'MSWin32') {
    # Attempt to load Win32::Symlink
    eval {
        require Win32::Symlink;
        Win32::Symlink->import();
    };    
    # Attempt to load Win32::RunAsAdmin
    eval {
        require Win32::RunAsAdmin;
        Win32::RunAsAdmin->import();
    };
}
}

my ($page,$link,$file,$sym,$res);
$sym = 'KoLmafia-latest.jar';

# get api data
print "checking for latest KoLmafia...\n";
$page = get('https://api.github.com/repos/kolmafia/kolmafia/releases/latest') or die 'unable to get page';
$link = $page =~ m/"browser_download_url":\s*"([^"]+\.jar)"/ ? $1 : die 'unable to match download link';
$file = $link =~ m/(KoLmafia-\d+\.jar)/ ? $1 : die 'unable to match file name';

# check for file existing
if (-e "$file") {
	print "already have latest: $file\n";
}
# download
else {
	print "downloading $file...\n";
	$res = getstore($link,$file);
	if (is_error($res)) {
		die "getstore <$link> failed: $res";
	}
}

# make symlink
if ($makesymlink) {
    my $existing_link = readlink($sym);  # readlink may return undef if the link does not exist
    if (!$existing_link || $existing_link ne $file) {
        print "creating symlink: $sym...\n";
        unlink($sym);
        symlink($file, $sym) or die "$!";
    }
}

print "$0 done.\n";

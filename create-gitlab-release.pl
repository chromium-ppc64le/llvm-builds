#!/usr/bin/perl -w
#
# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

use strict;

use File::Basename;

use Data::Dumper;
use Net::GitHub::V3;

my $llvm_rev = shift;
my $asset_path = shift;

print "Uploading $asset_path\n";

open(my $asset_data, $asset_path)
    or die "Unable to open release file";

my $gh = Net::GitHub::V3->new({
    access_token => $ENV{GITHUB_API_TOKEN},
    RaiseError => 1
});

my $repos = $gh->repos;

$repos->set_default_user_repo('chromium-ppc64le', 'llvm-builds');

my $release = $repos->create_release({
    "tag_name" => "v$llvm_rev",
    "name" => "LLVM $llvm_rev"
});

print "Created GitHub release:\n";
print Dumper(\$release);

my $release_asset = do {
    local $/;
    $repos->upload_asset(
        $release->{id},
        basename($asset_path),
        'application/zstd',
        <$asset_data>
    );
};

print "Uploaded artifacts to GitHub:\n";
print Dumper(\$release_asset);


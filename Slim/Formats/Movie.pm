package Slim::Formats::Movie;

# $Id$

# SlimServer Copyright (c) 2001-2004 Sean Adams, Slim Devices Inc.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License, 
# version 2.

use strict;
use MP4::Info;
use Slim::Utils::Misc;

my %tagMapping = (
	'WRT'	=> 'COMPOSER',
	'CPIL'	=> 'COMPILATION',
	'COVR'	=> 'PIC'
);

if ($] > 5.007) {

	MP4::Info::use_mp4_utf8(1)
}

my $tagCache = [];

sub getTag {
	my $file = shift || return {};

	my $tags = MP4::Info::get_mp4tag($file) || {};

	while (my ($old,$new) = each %tagMapping) {

		if (exists $tags->{$old}) {

			$tags->{$new} = delete $tags->{$old};
		}
	}

	$tags->{'BITRATE'} = int($tags->{'SIZE'} * 8 / $tags->{'SECS'});
	$tags->{'OFFSET'}  = 0;

	# Unroll the disc info.
	if ($tags->{'DISK'} && ref($tags->{'DISK'}) eq 'ARRAY') {

		($tags->{'DISC'}, $tags->{'DISCC'}) = @{$tags->{'DISK'}};
	}

	$tagCache = [ $file, $tags ];

	return $tags;
}

sub getCoverArt {
	my $file = shift;

	# Try to save a re-read
	if ($tagCache->[0] && $tagCache->[0] eq $file && ref($tagCache->[1]) eq 'HASH') {

		my $pic = $tagCache->[1]->{'PIC'};

		# Don't leave anything around.
		$tagCache = [];

		return $pic;
	}

	my $tags = MP4::Info::get_mp4tag($file) || {};

	if (defined $tags && ref($tags) eq 'HASH') {

		return $tags->{'COVR'};
	}

	msg("Got invalid tag data back from file: [$file]\n");
}

1;

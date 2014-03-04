#!/usr/bin/perl

use strict;
use warnings;

use File::Spec ();
use File::Temp '&tempfile';
use File::Copy '&move';

{
	my ( $path, $version ) = @ARGV;

	chomp $path;
	chomp $version;

	exit 1 unless $path and $version;
	exit 2 unless $version > 0;

	my @list = &get_files( $path );

	while( defined( my $file = shift @list ) )
	{
		&change_version_for_file( $file, $version );
	}
}

exit 0;

sub change_version_for_file
{
	my ( $file, $version ) = @_;

	if( open( my $rfh, '<', $file ) )
	{
		binmode( $rfh, ':utf8' );

		my ( $wfh, $new_file ) = &tempfile();

		while( defined( my $line = readline( $rfh ) ) )
		{
			$line =~ s/^(our\s+\$VERSION\s+\=\s+).+?(\;\s+\#\#\s+VERSION)/$1$version$2/;

			print $wfh $line;
		}

		close( $rfh );
		close( $wfh );

		&move( $new_file, $file );
	}

	return;
}

sub get_files
{
	my $path = shift;
	my @out = ();

	if( opendir( my $dh, $path ) )
	{
		my @list = readdir( $dh );

		closedir( $dh );

		while( defined( my $node = shift @list ) )
		{
			chomp $node;

			next if substr( $node, 0, 1 ) eq '.';

			my $new_path = File::Spec -> catfile( $path, $node );

			if( -d $new_path )
			{
				push @out, &get_files( $new_path );

			} elsif( -f $new_path )
			{
				next if substr( $node, -3, 3 ) ne '.pm';

				push @out, $new_path;
			}
		}
	}

	return @out;
}


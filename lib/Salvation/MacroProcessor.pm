use strict;

package Salvation::MacroProcessor;

our $VERSION = 1.00;

use Moose;
use Moose::Exporter ();
use Moose::Util::MetaRole ();

use Salvation::MacroProcessor::Connector ();
use Salvation::MacroProcessor::MethodDescription ();


Moose::Exporter -> setup_import_methods( with_meta => [ 'smp_add_description', 'smp_add_share', 'smp_add_alias', 'smp_add_connector', 'smp_import_descriptions', 'smp_import_shares' ] );


sub init_meta
{
	my ( undef, %args ) = @_;

	Moose -> init_meta( %args );

	return &Moose::Util::MetaRole::apply_metaroles(
		for             => $args{ 'for_class' },
		class_metaroles => {
			class => [ 'Salvation::MacroProcessor::Meta::Role' ]
		}
	);
}

sub smp_add_description
{
	my ( $meta, $name, %args ) = @_;

	$args{ 'method' }          = $name;
	$args{ 'associated_meta' } = $meta;

	$meta -> smp_add_description( Salvation::MacroProcessor::MethodDescription -> new( %args ) );

	return 1;
}

sub smp_add_share
{
	my ( $meta, $name, $code ) = @_;

	$meta -> smp_add_share( $name => $code );

	return 1;
}

sub smp_add_alias
{
	my ( $meta, $alias, $name ) = @_;

	$meta -> smp_add_alias( $alias => $name );

	return 1;
}

sub smp_add_connector
{
	my ( $meta, $name, %args ) = @_;

	$args{ 'name' }            = $name;
	$args{ 'associated_meta' } = $meta;

	$meta -> smp_add_connector( Salvation::MacroProcessor::Connector -> new( %args ) );

	return 1;
}

sub smp_import_descriptions
{
	my ( $meta, %args ) = @_;

	$meta -> smp_import_descriptions( { %args } ); # yes, this is copying

	return 1;
}

sub smp_import_shares
{
	my ( $meta, %args ) = @_;

	$meta -> smp_import_shares( { %args } ); # yes, this is also copying

	return 1;
}


__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;


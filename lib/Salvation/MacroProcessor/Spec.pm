use strict;

package Salvation::MacroProcessor::Spec;

use Moose;

use Moose::Util::TypeConstraints;

subtype 'Salvation::MacroProcessor::Spec::_moose_class_name',
	as 'Str',
	where { $_ -> isa( 'Moose::Object' ) };

coerce 'Salvation::MacroProcessor::Spec::_moose_class_name',
	from 'Object',
	via { ref $_ };

no Moose::Util::TypeConstraints;

use Salvation::MacroProcessor::Field ();
use Salvation::MacroProcessor::Iterator ();

use Carp::Assert 'assert';

use Scalar::Util 'blessed';


has 'fields'	=> ( is => 'ro', isa => 'ArrayRef[Salvation::MacroProcessor::Field]', traits => [ 'Array' ], required => 1, handles => {
	add_field  => 'push',
	all_fields => 'elements'
} );

has 'class'	=> ( is => 'ro', isa => 'Salvation::MacroProcessor::Spec::_moose_class_name', required => 1, coerce => 1 );

has 'query'	=> ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '__build_query', init_arg => undef );

has '__shares'	=> ( is => 'rw', isa => 'HashRef', default => sub{ {} } );


sub parse_and_new
{
	my ( $self, $class, $spec ) = @_;

	assert( ref( $spec ) eq 'ARRAY' );

	$self = $self -> new( class => $class, fields => [] );

	my $meta = ( $class = $self -> class() ) -> meta();

	foreach my $field_spec ( @$spec )
	{
		assert( ref( $field_spec ) eq 'ARRAY' );

		my ( $name, $value ) = @$field_spec;

		assert( ( my $description = $meta -> smp_find_description_by_name( $name ) ), sprintf( 'Class "%s" has no MacroProcessor description for method "%s"', $class, $name ) );

		$self -> add_field( Salvation::MacroProcessor::Field -> new(
			description => $description,
			value       => $value
		) );
	}

	return $self;
}

sub check
{
	my ( $self, $object ) = @_;

	if( blessed $object )
	{
		my $meta = $self -> class() -> meta();

		assert( ( my $hook = $meta -> smp_hook() ), sprintf( 'Cannot check instance of class "%s": no hook specified', $meta -> name() ) );

		return $hook -> check( $self, $object );
	}

	assert( 0, 'Dunno what to do' );
}

sub select
{
	my ( $self, $moar_query, $additional_args ) = @_;

	$moar_query        ||= [];
	$additional_args ||= [];

	my $meta = $self -> class() -> meta();

	assert( ( my $hook = $meta -> smp_hook() ), sprintf( 'Cannot select objects of class "%s": no hook specified', $meta -> name() ) );

	return $hook -> select( $self, $moar_query, $additional_args );
}

sub __postfilter
{
	my ( $self, @objects ) = @_;

	return grep{ $self -> __postfilter_each( $_ ) } @objects;
}

sub __postfilter_each
{
	my ( $self, $object ) = @_;

	foreach my $field ( $self -> all_fields() )
	{
		unless( $field -> postfilter( $object ) )
		{
			return 0;
		}
	}

	return 1;
}

sub __build_query
{
	my $self = shift;
	my @query  = ();

	my %present    = ();
	my %required   = ();
	my %excludes   = ();
	my %connectors = ();
	my @connectors = ();

	foreach my $field ( $self -> all_fields() )
	{
		if( ( my $connector_chain = $field -> connector_chain() ) -> [ 0 ] )
		{
			my $chain_hash = join( "\0", map{ @$_ } @$connector_chain );

			push @{ $connectors{ $chain_hash } -> { 'query' } }, @{ $self -> __get_field_query( $field ) };

			unless( exists $connectors{ $chain_hash } -> { 'connector_chain' } )
			{
				$connectors{ $chain_hash } -> { 'connector_chain' } = $connector_chain;

				push @connectors, $chain_hash;
			}

		} else
		{
			push @query, @{ $self -> __get_field_query( $field ) };
		}

		$present{ $field -> name() } = 1;

		foreach my $filter ( @{ $field -> required_filters() } )
		{
			$required{ $filter } -> { $field -> name() } = 1;
		}

		foreach my $filter ( @{ $field -> excludes_filters() } )
		{
			$excludes{ $filter } -> { $field -> name() } = 1;
		}
	}

	foreach my $filter ( keys %required )
	{
		assert( exists( $present{ $filter } ), sprintf( 'Filter "%s" is not present, but required by following filter(s) of class "%s": "%s"', $filter, $self -> class(), join( ', ', keys %{ $required{ $filter } } ) ) );
	}

	foreach my $filter ( keys %excludes )
	{
		assert( not( exists( $present{ $filter } ) ), sprintf( 'Filter "%s" conflicts with following filter(s) of class "%s": "%s"', $filter, $self -> class(), join( ', ', keys %{ $excludes{ $filter } } ) ) );
	}

	my %connectors_present = ();

	while( my $chain_hash = shift @connectors )
	{
		my $data = delete $connectors{ $chain_hash };

		my ( $chain_query, $connector_chain ) = delete @$data{ 'query', 'connector_chain' };

		foreach my $connector_spec ( @$connector_chain )
		{
			my ( $class, $connector_name ) = @$connector_spec;

			if( my $connector = $class -> meta() -> smp_find_connector_by_name( $connector_name ) )
			{
				my %shares     = ();
				my $has_shares = 0;

				foreach my $share ( @{ $connector -> required_shares() } )
				{
					$shares{ $share } = $self -> __get_shared_value( $share, $class );

					$has_shares ||= 1;
				}

				$chain_query = $connector -> code() -> ( ( $has_shares ? \%shares : () ), $chain_query );

				{
					my $rref = ref( $chain_query );

					assert( ( $rref eq 'ARRAY' ), sprintf( 'Connector "%s" of class "%s" should return ArrayRef instead of "%s"', $connector_name, $class, ( $rref or 'plain scalar' ) ) );
				}
			} else
			{
				assert( 0, sprintf( 'Class "%s" has no connector with name "%s"', $class, $connector_name ) );
			}
		}

		my $last_connector_hash = join( "\0", @{ $connector_chain -> [ $#$connector_chain ] } );

		unless( exists $connectors_present{ $last_connector_hash } )
		{
			$connectors_present{ $last_connector_hash } = 1;

			push @query, @$chain_query;
		}
	}

	return \@query;
}

sub __get_shared_value
{
	my ( $self, $name, $foreign_class ) = @_;

	my $class      = ( $foreign_class or $self -> class() );
	my $share_hash = join( "\0", ( $class, $name ) );

	if( exists $self -> __shares() -> { $share_hash } )
	{
		return $self -> __shares() -> { $share_hash };
	}

	if( ref( my $code = $class -> meta() -> smp_find_share_by_name( $name ) ) eq 'CODE' )
	{
		return $self -> __shares() -> { $share_hash } = [ $code -> () ];
	}

	assert( 0, sprintf( 'Class "%s" has no share with name "%s"', $class, $name ) );
}

sub __get_field_query
{
	my ( $self, $field ) = @_;

	my %shares     = ();
	my $has_shares = 0;

	foreach my $share ( @{ $field -> required_shares() } )
	{
		my $share_name = $share;

		{
			my $class = $self -> class();

			while( $class and ( my $share_import_spec = $class -> meta() -> smp_find_share_import_spec_by_name( $share_name ) ) )
			{
				if( $share_import_spec )
				{
					$share_name = ( $share_import_spec -> { 'orig' } or $share_name );
					$class      = $share_import_spec -> { 'class' };

				} else
				{
					$class = undef;
				}
			}
		}

		$shares{ $share_name } = $self -> __get_shared_value( $share );

		if( $share ne $share_name )
		{
			$shares{ $share } = undef; # compatibility crutch
		}

		$has_shares ||= 1;
	}

	return $field -> query( ( $has_shares ? \%shares : () ) );
}

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;


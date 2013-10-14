use strict;

package Salvation::MacroProcessor::MethodDescription;

use Moose;
use MooseX::StrictConstructor;

use Carp::Assert 'assert';

use Scalar::Util 'blessed';


has 'method'	=> ( is => 'ro', isa => 'Str', required => 1 );

has 'orig_method'	=> ( is => 'ro', isa => 'Str', lazy => 1, default => sub{ shift -> method() }, clearer => '__clear_orig_method' );

has 'associated_meta'	=> ( is => 'ro', isa => 'Class::MOP::Module', required => 1, weak_ref => 1 );

has 'connector_chain'	=> ( is => 'ro', isa => 'ArrayRef[ArrayRef[Str]]', default => sub{ [] } );


has 'previously_associated_meta'	=> ( is => 'ro', isa => 'Class::MOP::Module', weak_ref => 1, predicate => 'has_previously_associated_meta' );

has '__query'	=> ( is => 'ro', isa => 'ArrayRef|CodeRef', init_arg => 'query', lazy => 1, default => sub{ [] }, predicate => 'has_query' );

has '__postfilter'	=> ( is => 'ro', isa => 'CodeRef', lazy => 1, default => sub{ sub{} }, predicate => 'has_postfilter', init_arg => 'postfilter' );

has '__required_shares'	=> ( is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub{ [] }, predicate => 'has_required_shares', init_arg => 'required_shares' );

has '__required_filters'	=> ( is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub{ [] }, predicate => 'has_required_filters', init_arg => 'required_filters' );

has '__excludes_filters'	=> ( is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub{ [] }, predicate => 'has_excludes_filters', init_arg => 'excludes_filters' );

has '__imported'	=> ( is => 'ro', isa => 'Bool', default => 0, init_arg => 'imported' );


has 'inherited_description'	=> ( is => 'ro', isa => sprintf( 'Maybe[%s]', __PACKAGE__ ), lazy => 1, builder => '__build_inherited_description', init_arg => undef, clearer => '__clear_inherited_description' );

has 'attr'	=> ( is => 'ro', isa => 'Maybe[Moose::Meta::Attribute]', lazy => 1, builder => '__build_attr', weak_ref => 1, init_arg => undef, clearer => '__clear_attr' );


sub clone
{
	my ( $self, %overrides ) = @_;

	my $clone = $self -> meta() -> clone_object( $self, %overrides );

	$clone -> __clear_orig_method() if exists $overrides{ 'method' } and not exists $overrides{ 'orig_method' };
	$clone -> __clear_inherited_description() if exists $overrides{ 'previously_associated_meta' };
	$clone -> __clear_attr() if exists $overrides{ 'associated_meta' };

	return $clone;
}

sub __build_inherited_description
{
	my $self = shift;

	if( $self -> has_previously_associated_meta() )
	{
		return $self -> previously_associated_meta() -> smp_find_description_by_name( $self -> method() );
	}

	return undef;
}

sub __build_attr
{
	my $self = shift;

	return $self -> associated_meta() -> find_attribute_by_name( $self -> orig_method() );
}

sub query
{
	my $self       = shift;
	my $shares     = undef;
	my $has_shares = 0;

	if( scalar( @_ ) == 2 )
	{
		$shares     = shift;
		$has_shares = 1;
	}

	my $value = shift;
	my @query   = ();

	assert( ref( $shares ) eq 'HASH' ) if $has_shares;

	{
		my $present_shares = join( ', ', map{ sprintf( '"%s"', $_ ) } keys %$shares );

		foreach my $share ( @{ $self -> required_shares() } )
		{
			assert( exists( $shares -> { $share } ), sprintf( 'Share "%s" is required for filter "%s" of class "%s", but not present. Present shares: %s', $share, $self -> method(), $self -> associated_meta() -> name(), $present_shares ) );
		}
	}

	my @inner_args = ( ( $has_shares ? $shares : () ), $value );

#	if( my $id = $self -> inherited_description() )
#	{
#		push @query, @{ $id -> query( @inner_args ) };
#	}

	if( $self -> has_query() )
	{
		my $query = $self -> __query();

		if( ref( $query ) eq 'CODE' )
		{
			assert( ref( $query = $query -> ( @inner_args ) ) eq 'ARRAY' );
		}

		push @query, @$query;

	} elsif( my $attr = $self -> attr() )
	{
		my $meta = $self -> associated_meta();

		assert( ( my $hook = $meta -> smp_hook() ), sprintf( 'Cannot process attribute "%s" for class "%s": no hook specified', $attr -> name(), $meta -> name() ) );

		push @query, $hook -> query_from_attribute( $self, $attr, @inner_args );

	} elsif( not $self -> has_postfilter() )
	{
		assert( 0, sprintf( 'Cannot process attribute "%s" for class "%s": do no know how', $self -> method(), $self -> associated_meta() -> name() ) );
	}

	return \@query;
}

sub postfilter
{
	my ( $self, $node, $value ) = @_;

#	if( my $id = $self -> inherited_description() )
#	{
#		unless( $id -> postfilter( $node, $value ) )
#		{
#			return 0;
#		}
#	}

	if( $self -> has_postfilter() )
	{
		return $self -> __postfilter() -> ( $node, $value );
	}

	return 1;
}

sub required_shares
{
	my $self   = shift;
	my @shares = ();

#	if( my $id = $self -> inherited_description() )
#	{
#		push @shares, @{ $id -> required_shares() };
#	}

	if( $self -> has_required_shares() )
	{
		push @shares, @{ $self -> __required_shares() };
	}

	return \@shares;
}

sub required_filters
{
	my $self    = shift;
	my @filters = ();

#	if( my $id = $self -> inherited_description() )
#	{
#		push @filters, @{ $id -> required_filters() };
#	}

	if( $self -> has_required_filters() )
	{
		push @filters, @{ $self -> __required_filters() };
	}

	return \@filters;
}

sub excludes_filters
{
	my $self    = shift;
	my @filters = ();

#	if( my $id = $self -> inherited_description() )
#	{
#		push @filters, @{ $id -> excludes_filters() };
#	}

	if( $self -> has_excludes_filters() )
	{
		push @filters, @{ $self -> __excludes_filters() };
	}

	return \@filters;
}


__PACKAGE__ -> meta() -> make_immutable();

no MooseX::StrictConstructor;
no Moose;

-1;


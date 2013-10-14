use strict;

package Salvation::MacroProcessor::Connector;

use Moose;
use MooseX::StrictConstructor;

use Carp::Assert 'assert';

use Scalar::Util 'blessed';


has 'name'	=> ( is => 'ro', isa => 'Str', required => 1 );

has 'associated_meta'	=> ( is => 'ro', isa => 'Class::MOP::Module', required => 1, weak_ref => 1 );

has 'code'	=> ( is => 'ro', isa => 'CodeRef', required => 1 );


has 'previously_associated_meta'	=> ( is => 'ro', isa => 'Class::MOP::Module', weak_ref => 1, predicate => 'has_previously_associated_meta' );

has '__required_shares'	=> ( is => 'ro', isa => 'ArrayRef[Str]', predicate => 'has_required_shares', init_arg => 'required_shares' );


has 'inherited_connector'	=> ( is => 'ro', isa => sprintf( 'Maybe[%s]', __PACKAGE__ ), lazy => 1, builder => '__build_inherited_connector', init_arg => undef, clearer => '__clear_inherited_connector' );

sub clone
{
	my ( $self, %overrides ) = @_;

	my $clone = $self -> meta() -> clone_object( $self, %overrides );

	$clone -> __clear_inherited_connector() if exists $overrides{ 'previously_associated_meta' };

	return $clone;
}

sub __build_inherited_connector
{
	my $self = shift;

	if( $self -> has_previously_associated_meta() )
	{
		return $self -> previously_associated_meta() -> smp_find_connector_by_name( $self -> name() );
	}

	return undef;
}

sub required_shares
{
	my $self   = shift;
	my @shares = ();

#	if( my $id = $self -> inherited_connector() )
#	{
#		push @shares, @{ $id -> required_shares() };
#	}

	if( $self -> has_required_shares() )
	{
		push @shares, @{ $self -> __required_shares() };
	}

	return \@shares;
}


__PACKAGE__ -> meta() -> make_immutable();

no MooseX::StrictConstructor;
no Moose;

-1;


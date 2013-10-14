use strict;

package Salvation::MacroProcessor::Role;

use Moose::Role;

sub smp_spec
{
	my $self = shift;

	require Salvation::MacroProcessor::Spec;

	return Salvation::MacroProcessor::Spec -> parse_and_new(
		$self,
		\@_
	);
}

sub smp_select
{
	return shift -> smp_spec( @_ ) -> select();
}

sub smp_check
{
	my $self = shift;

	return $self -> smp_spec( @_ ) -> check( $self );
}

no Moose::Role;

-1;


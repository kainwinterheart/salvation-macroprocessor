use strict;

package Salvation::MacroProcessor::Iterator;

use Moose;

use Moose::Util::TypeConstraints;

subtype 'Salvation::MacroProcessor::Iterator::iterator_instance',
        as 'Object',
	where { $_ -> does( 'Salvation::MacroProcessor::Iterator::Compliance' ) };

no Moose::Util::TypeConstraints;


has '__iterator'	=> ( is => 'ro', isa => 'Salvation::MacroProcessor::Iterator::iterator_instance', required => 1, handles => { ( map{ ( $_ )x2 } ( 'to_start', 'to_end' ) ) }, init_arg => 'iterator' );

has '__postfilter'	=> ( is => 'ro', isa => 'CodeRef', required => 1, init_arg => 'postfilter' );


sub seek  { die 'improssible here' }
sub count { die 'improssible here' }

sub first
{
	my $self = shift;
	my $it   = $self -> __iterator();

	my $position = $it -> __position();

	$it -> to_start();

	my $node = $self -> next();

	$it -> seek( $position );

	return $node;
}

sub last
{
	my $self = shift;
	my $it   = $self -> __iterator();

	my $position = $it -> __position();

	$it -> to_end();

	my $node = $self -> prev();

	$it -> seek( $position );

	return $node;
}

sub next
{
	my $self = shift;
	my $it   = $self -> __iterator();

	while( my $node = $it -> next() )
	{
		if( $self -> __postfilter() -> ( $node ) )
		{
			return $node;
		}
	}

	return undef;
}

sub prev
{
	my $self = shift;
	my $it   = $self -> __iterator();

	while( my $node = $it -> prev() )
	{
		if( $self -> __postfilter() -> ( $node ) )
		{
			return $node;
		}
	}

	return undef;
}


__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1


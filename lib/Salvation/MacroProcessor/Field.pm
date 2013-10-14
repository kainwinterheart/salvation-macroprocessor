use strict;

package Salvation::MacroProcessor::Field;

use Moose;

has 'description'	=> ( is => 'rw', isa => 'Salvation::MacroProcessor::MethodDescription', required => 1, handles => { ( map{ ( $_ )x2 } ( 'required_shares', 'required_filters', 'excludes_filters', 'connector_chain' ) ), ( name => 'method' ) } );

has 'value'	=> ( is => 'rw', isa => 'Any', required => 1 );


sub query        { $_[ 0 ] -> description() -> query       ( ( ( scalar( @_ ) == 2 ) ? $_[ 1 ] : () ), $_[ 0 ] -> value() ) }
sub postfilter { $_[ 0 ] -> description() -> postfilter( $_[ 1 ], $_[ 0 ] -> value() ) }


__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;


use strict;

package Salvation::MacroProcessor::Hooks;

use Moose;

sub query_from_attribute;
sub select;
sub check;

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;


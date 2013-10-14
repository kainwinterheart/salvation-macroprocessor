use strict;

package Salvation::MacroProcessor::Iterator::Compliance;

use Moose::Role;

requires 'first', 'last', 'seek', 'next', 'count', 'to_start', 'to_end', '__position', 'prev';

no Moose::Role;

-1;


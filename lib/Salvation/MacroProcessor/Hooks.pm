use strict;

package Salvation::MacroProcessor::Hooks;

use Moose;

sub query_from_attribute;
sub select;
sub check;

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;


# ABSTRACT: Base class for your hooks with implementation of actual logic for L<Salvation::MacroProcessor::Spec>

=pod

=head1 NAME

Salvation::MacroProcessor::Hooks - Base class for your hooks with implementation of actual logic for L<Salvation::MacroProcessor::Spec>

=head1 REQUIRES

L<Moose> 

=head1 METHODS

=head2 To be redefined

You can redefine following methods to achieve your own goals.

=head3 check

 $hook -> check( $spec, $object );

Checks if given C<$object> could be selected using this C<$spec>.

C<$spec> is a L<Salvation::MacroProcessor::Spec> instance.

C<$object> is an object representing a single row of data returned by the query.

Boolean value should be returned, C<false> means "skip this object" and C<true> means "yes, this object is what we want".

=head3 query_from_attribute

 $hook -> query_from_attribute( $method_description, $attr, @rest );

Generates query part which needs to be applied to the query to get an object which satisfies specified criteria.

This method will be called if all following conditions are true:

=over

=item class has an attribute (see L<Moose::Manual::Attributes> for more info) which name is exactly the same as the method being described

=item description has no C<query> argument specified

=back

C<$method_description> is a L<Salvation::MacroProcessor::MethodDescription> instance.

C<$attr> is a L<Moose::Meta::Attribute> instance.

C<@rest> is a list of arguments of the same types, conditions and meaning as it is for C<query> argument of L<Salvation::MacroProcessor>C<::smp_add_description> when C<$query> is a CodeRef.

Return value should also be as the one of C<$query> function of L<Salvation::MacroProcessor>C<::smp_add_description>.

=head3 select

 $hook -> select( $spec, $additional_query, $additional_args );

Selects objects using given C<$spec> with a mix of C<$additional_query> and C<$additional_args>.

C<$spec> is a L<Salvation::MacroProcessor::Spec> instance.

C<$additional_query> and C<$additional_args> are both passed in by you or any other developer who will try to make a query. Though both are thought of as ArrayRef's.

C<$additional_query>'s meaning is "some custom query part we need to apply to the query".

C<$additional_args>'s meaning is "some additional custom arguments we need to pass to the method which will then perform a request to complete the query".

Return value will be returned directly to caller which is your custom code issued L<Salvation::MacroProcessor::Spec>C<::select>. Though return value is thought of as L<Salvation::MacroProcessor::Iterator> instance.

=cut


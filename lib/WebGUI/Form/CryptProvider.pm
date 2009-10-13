package WebGUI::Form::CryptProvider;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2009 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use base 'WebGUI::Form::SelectList';
use WebGUI::International;

=head1 NAME

Package WebGUI::Form::CryptProvider

=head1 DESCRIPTION

Creates a Crypt Provider chooser field.

=head1 SEE ALSO

This is a subclass of WebGUI::Form::SelectList.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut

#-------------------------------------------------------------------

=head2 areOptionsSettable ( )

Returns 0.

=cut

sub areOptionsSettable {
    return 0;
}

#-------------------------------------------------------------------

=head2 definition ( [ additionalTerms ] )

See the super class for additional details.

=head3 additionalTerms

The following additional parameters have been added via this sub class.

=head4 size

How many rows should be displayed at once? Defaults to 1.

=head4 multiple

Set to "1" if multiple groups should be selectable. Defaults to 0.

=head4 defaultValue

This will be used if no value is specified. Should be passed as an array reference. Defaults to "None".

=cut

sub definition {
    my $class      = shift;
    my $session    = shift;
    my $definition = shift || [];
    push(
        @{$definition},
        {   size         => { defaultValue => 1 },
            multiple     => { defaultValue => 0 },
            defaultValue => { defaultValue => ''},
            table        => { defaultValue => ''},
            field        => { defaultValue => ''},
        }
    );
    return $class->SUPER::definition( $session, $definition );
}

#-------------------------------------------------------------------

=head2  getDatabaseFieldType ( )

Returns "CHAR(22) BINARY".

=cut 

sub getDatabaseFieldType {
    return "CHAR(22) BINARY";
}

#-------------------------------------------------------------------

=head2 getName ( session )

Returns the human readable name of this control.

=cut

sub getName {
    my ( $self, $session ) = @_;
    return WebGUI::International->new( $session, 'Crypt' )->get('Crypt');
}

#-------------------------------------------------------------------

=head2 getDefaultValue( )

Returns the default Provider. 
If table and field are defined, use them to look up the current provider. 
Otherwise, uses the providerId property.
If neither of these succeed, returns the 'None' provider.

=cut

sub getDefaultValue {
    my $self = shift;

    my $providerId;
    my $table = $self->get('table');
    my $field = $self->get('field');
    if ($table && $field) {
        $providerId = $self->session->crypt->lookupProviderId( { table => $table, field => $field } );
    } else {
        $providerId = $self->get('defaultValue');
    }
    $providerId ||= 'None';
    return wantarray ? ($providerId) : $providerId;
}

#-------------------------------------------------------------------

=head2 getValueAsHtml ( )

Return the human readible provider name.

=cut

sub getValueAsHtml {
    my $self = shift;
    my $providerId = $self->getOriginalValue;
    return $self->session->config->get('crypt')->{$providerId}{name};
}

#-------------------------------------------------------------------

=head2 isDynamicCompatible ( )

A class method that returns a boolean indicating whether this control is compatible with the DynamicField control.

=cut

sub isDynamicCompatible {
    return 1;
}

#-------------------------------------------------------------------

=head2 toHtml ( )

Returns a group pull-down field. A group pull down provides a select list that provides name value pairs for all the groups in the WebGUI system.  

=cut

sub toHtml {
    my $self = shift;
    $self->set( 'options', $self->session->crypt->getProviders );
    return $self->SUPER::toHtml();
}

#-------------------------------------------------------------------

=head2 toHtmlAsHidden ( )

Creates a series of hidden fields representing the data in the list.

=cut

sub toHtmlAsHidden {
    my $self = shift;

    $self->set( 'options', $self->session->crypt->getProviders );
    return $self->SUPER::toHtmlAsHidden();
}

1;

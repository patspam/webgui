package WebGUI::Asset::Wobject::EventManagementSystem;

use lib '/root/pb/lib'; use dav;

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
use base 'WebGUI::Asset::Wobject';
use Digest::MD5;
use JSON;
use Text::CSV_XS;
use Tie::IxHash;
use Time::HiRes;
use WebGUI::Asset::Sku::EMSBadge;
use WebGUI::Asset::Sku::EMSTicket;
use WebGUI::Asset::Sku::EMSRibbon;
use WebGUI::Asset::Sku::EMSToken;
use WebGUI::Cache;
use WebGUI::Exception;
use WebGUI::FormValidator;
use WebGUI::HTMLForm;
use WebGUI::International;
use WebGUI::Utility;
use WebGUI::Workflow::Instance;
use Tie::IxHash;
use Data::Dumper;

#-------------------------------------------------------------------
=head2 addGroupToSubmitList ( groupId )

adds the parameter to eventSubmissionGroups

=cut

sub addGroupToSubmitList {
    my $self = shift;
    my $groupId = shift;
    my @ids = split(' ', $self->get('eventSubmissionGroups'));
    my %h;
    @ids = map { $h{$_}++ == 0 ? $_ : () } ( $groupId, @ids );
    $self->update({eventSubmissionGroups => join( ' ', @ids ) });
}

#-------------------------------------------------------------------
=head2 addSubmissionForm

creates a child of class WG::Asset::EMSSubmissionForm

=head3 params

parameters that define the form

=head4 title

the title for the form

=head4 canSubmitGroupId ( optional )

group id for the users that are allowed to submit via this form
defaults to 2 -- registered users

=head4 daysBeforeCleanup ( optional )

number fo days to leave denied/created status items in the database before deleting
defaults to 7

=head4 deleteCreatedItems ( optional )

1 indicates that items with status 'created' should be deleted as well as denied
default: 0

=head4 formDescription

a JSON description of the form data fields -- a hash of the names of fields (each is 1 for active, 0 for inactive) plus
'_fieldList' added as an ARRAYREF of the fields that are active

=cut

sub addSubmissionForm {
    my $self = shift;
    my $params = shift;
    $params->{className} = 'WebGUI::Asset::EMSSubmissionForm';
    $params->{canSubmitGroupId} ||= 2;
    $self->addGroupToSubmitList($params->{canSubmitGroupId});
    return $self->addChild($params);
}

#-------------------------------------------------------------------
=head2 canSubmit

returns true is the current user can submit to any form attached to this EMS

=cut

sub canSubmit {
    my $self = shift;
    my $user = $self->session->user;
    for my $groupId (split ' ', $self->get('eventSubmissionGroups')) {
        return 1 if $user->isInGroup($groupId);
    }
    return 0;
}

#-------------------------------------------------------------------
sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my %properties;
	tie %properties, 'Tie::IxHash';
	my $i18n = WebGUI::International->new($session,'Asset_EventManagementSystem');
	%properties = (
		timezone => {
			fieldType 		=> 'TimeZone',
			defaultValue 	=> 'America/Chicago',
			tab				=> 'properties',
			label			=> $i18n->get('time zone'),
			hoverHelp		=> $i18n->get('time zone help'),
		},
		templateId => {
			fieldType 		=> 'template',
			defaultValue 	        => '2rC4ErZ3c77OJzJm7O5s3w',
			tab				=> 'display',
			label			=> $i18n->get('main template'),
			hoverHelp		=> $i18n->get('main template help'),
			namespace		=> 'EMS',
		},
		scheduleTemplateId => {
			fieldType 		=> 'template',
			defaultValue 	        => 'S2_LsvVa95OSqc66ITAoig',
			tab			=> 'display',
			label			=> $i18n->get('schedule template'),
			hoverHelp		=> $i18n->get('schedule template help'),
			namespace		=> 'EMS/Schedule',
		},
		scheduleColumnsPerPage => {
			fieldType 		=> 'Integer',
			defaultValue 		=> '5',
			tab			=> 'display',
			label			=> $i18n->get('schedule number of columns'),
			hoverHelp		=> $i18n->get('schedule number of columns help'),
		},
		badgeBuilderTemplateId => {
			fieldType 		=> 'template',
			defaultValue 	=> 'BMybD3cEnmXVk2wQ_qEsRQ',
			tab				=> 'display',
			label			=> $i18n->get('badge builder template'),
			hoverHelp		=> $i18n->get('badge builder template help'),
			namespace		=> 'EMS/BadgeBuilder',
		},
		lookupRegistrantTemplateId => {
			fieldType 		=> 'template',
			defaultValue 	=> 'OOyMH33plAy6oCj_QWrxtg',
			tab				=> 'display',
			label			=> $i18n->get('lookup registrant template'),
			hoverHelp		=> $i18n->get('lookup registrant template help'),
			namespace		=> 'EMS/LookupRegistrant',
		},
		printBadgeTemplateId => {
			fieldType 		=> 'template',
			defaultValue 	=> 'PsFn7dJt4wMwBa8hiE3hOA',
			tab				=> 'display',
			label			=> $i18n->get('print badge template'),
			hoverHelp		=> $i18n->get('print badge template help'),
			namespace		=> 'EMS/PrintBadge',
		},
		printTicketTemplateId => {
			fieldType 		=> 'template',
			defaultValue 	=> 'yBwydfooiLvhEFawJb0VTQ',
			tab				=> 'display',
			label			=> $i18n->get('print ticket template'),
			hoverHelp		=> $i18n->get('print ticket template help'),
			namespace		=> 'EMS/PrintTicket',
		},
		eventSubmissionMainTemplateId => {
			fieldType 		=> 'template',
			defaultValue 		=> 'DoVNijm6lMDE0cYrtvEbDQ',
			tab			=> 'display',
			label			=> $i18n->get('event submission main template'),
			hoverHelp		=> $i18n->get('event submission main template help'),
			namespace		=> 'EMS/SubmissionMain',
		},
		eventSubmissionTemplateId => {
			fieldType 		=> 'template',
			defaultValue 		=> '8tqyQx-LwYUHIWOlKPjJrA',
			tab			=> 'display',
			label			=> $i18n->get('event submission template'),
			hoverHelp		=> $i18n->get('event submission template help'),
			namespace		=> 'EMS/Submission',
		},
		eventSubmissionQueueTemplateId => {
			fieldType 		=> 'template',
			defaultValue 		=> 'ktSvKU8riGimhcsxXwqvPQ',
			tab			=> 'display',
			label			=> $i18n->get('event submission queue template'),
			hoverHelp		=> $i18n->get('event submission queue template help'),
			namespace		=> 'EMS/SubmissionQueue',
		},
		badgeInstructions => {
			fieldType 		=> 'HTMLArea',
			defaultValue 		=> $i18n->get('default badge instructions'),
			tab			=> 'properties',
			label			=> $i18n->get('badge instructions'),
			hoverHelp		=> $i18n->get('badge instructions help'),
		},
		ticketInstructions => {
			fieldType 		=> 'HTMLArea',
			defaultValue 	=> $i18n->get('default ticket instructions'),
			tab				=> 'properties',
			label			=> $i18n->get('ticket instructions'),
			hoverHelp		=> $i18n->get('ticket instructions help'),
		},
		ribbonInstructions => {
			fieldType 		=> 'HTMLArea',
			defaultValue 	=> $i18n->get('default ribbon instructions'),
			tab				=> 'properties',
			label			=> $i18n->get('ribbon instructions'),
			hoverHelp		=> $i18n->get('ribbon instructions help'),
		},
		tokenInstructions => {
			fieldType 		=> 'HTMLArea',
			defaultValue 	=> $i18n->get('default token instructions'),
			tab				=> 'properties',
			label			=> $i18n->get('token instructions'),
			hoverHelp		=> $i18n->get('token instructions help'),
		},
		registrationStaffGroupId => {
			fieldType 		=> 'group',
			defaultValue 	=> [3],
			tab				=> 'security',
			label			=> $i18n->get('registration staff group'),
			hoverHelp		=> $i18n->get('registration staff group help'),
		},
		submittedLocationsList => {
			fieldType 		=> 'text',
			tab			=> 'properties',
			defaultValue 	        => '',
			label			=> $i18n->get('submitted location list label'),
			hoverHelp		=> $i18n->get('submitted location list help'),
		},
		eventSubmissionGroups => {
			fieldType 		=> 'hidden',
			defaultValue 	        => '',
                        noFormPost              => 1,
		},
        nextSubmissionId => {
            tab          => "properties",
            fieldType    => "integer",
            defaultValue => 1,
            label        => $i18n->get("next submission id label"),
            hoverHelp    => $i18n->get("next submission id label help")
        },
	);
	push(@{$definition}, {
		assetName=>$i18n->get('assetName'),
		icon=>'ems.gif',
		autoGenerateForms=>1,
		tableName=>'EventManagementSystem',
		className=>'WebGUI::Asset::Wobject::EventManagementSystem',
		properties=>\%properties
		});
	return $class->SUPER::definition($session,$definition);
}

#------------------------------------------------------------------

=head2 deleteEventMetaField ( id )

Delete a meta field.

=cut

sub deleteEventMetaField {
    my $self = shift;
    my $id = shift;
	$self->deleteCollateral('EMSEventMetaField', 'fieldId', $id);
	$self->reorderCollateral('EMSEventMetaField', 'fieldId');
}


#-------------------------------------------------------------------

=head2 getBadges ()

Returns an array reference of badge objects.

=cut

sub getBadges {
	my $self = shift;
	return $self->getLineage(['children'],{returnObjects=>1, includeOnlyClasses=>['WebGUI::Asset::Sku::EMSBadge']});
}

#-------------------------------------------------------------------

=head2 getBadgeGroups ()

Returns a hash reference of id,name pairs of badge groups.

=cut

sub getBadgeGroups {
	my $self = shift;
	return $self->session->db->buildHashRef("select badgeGroupId,name from EMSBadgeGroup where emsAssetId=?",[$self->getId]);
}

#------------------------------------------------------------------

=head2 getEventMetaFields (  )

Returns an arrayref of hash references of the metadata fields. Each hash in the array has the following fields:

fieldId - the GUID for this field.

assetId - the EMS that this field is attached to.

label - the human readable name for this field.

dataType - the form field type for this field.

visible - whether or not this field should display in public views.

required - whether or not this field must be filled out as part of editing the ticket/event.

possibleValues - a list of values that may be used to create this form field if it's  a list type.

defaultValues - a list of default values that may be used to create this form field.

sequenceNumber - the order in which this field should be displayed relative to other fields.

=cut

sub getEventMetaFields {
	my $self = shift;
	return $self->session->db->buildArrayRefOfHashRefs("select * from EMSEventMetaField where assetId=? order by sequenceNumber, assetId",[$self->getId]);
}

#-------------------------------------------------------------------

=head2 getEventFieldsForImport ()

Returns an array reference of hash references containing name, label, required of the fields that are exportable or importable for events.

=cut

sub getEventFieldsForImport {
	my $self = shift;
	my @fields = ({
			name		=> 'assetId',
			label		=> WebGUI::International->new($self->session,'Asset')->get('asset id'),
			type		=> 'asset',
			required	=> 1,
		});
	my $count = 0;
	foreach my $definition (@{WebGUI::Asset::Sku::EMSTicket->definition($self->session)}) {
		$count++;
		foreach my $field (keys %{$definition->{properties}}) {
			next if ($count > 1 && !isIn($field, qw(title description)));
			next unless ($definition->{properties}{$field}{label} ne "");
			push(@fields, {
				name 	 		=> $field,
				label 	  		=> $definition->{properties}{$field}{label},
				required		=> ($field eq "eventNumber") ? 1 : 0,
				type			=>  $definition->{properties}{$field}{fieldType},
				options 		=> $definition->{properties}{$field}{options},
				defaultValue	=> $definition->{properties}{$field}{defaultValue},
				});
		}
	}
	foreach my $field (@{$self->getEventMetaFields}) {
		push(@fields, {
			name 			=> $field->{fieldId},
			label 			=> $field->{label},
			required		=> $field->{required},
			isMeta			=> 1,
			type			=> $field->{dataType},
			options 		=> $field->{possibleValues},
			defaultValue	=> $field->{defaultValues},
			helpText	=> $field->{defaultValues},
			});
	}
	return \@fields;
}

#-------------------------------------------------------------------

=head2 getLocations ()

Returns an array of all locations & dates for this EMS
may be SQL optimized for quick access

=cut

sub getLocations {
    my $self = shift;
    my $dateRef = shift;

    my %hash;
    my %hashDate;
    my %h;
    my $tickets = $self->getTickets;
# this is a really compact 'uniq' operation
    my @locations = map { $h{$_}++ == 0 ? $_ : () } ( map { $_->get('location') } ( @$tickets ) );
# the dates have the time data removed with a pattern substitution
    if( $dateRef ) {
        push @$dateRef, map { s/\s*\d+:\d+(:\d+)?//; $h{$_}++ == 0 ? $_ : () } ( map { $_->get('startDate') } ( @$tickets ) );
    }

    return @locations;
}

#-------------------------------------------------------------------

=head2 getNextSubmissionId

get a sequence number for the submission id

=cut

sub getNextSubmissionId {
    my $self = shift;
    #my $submissionId = $self->get('nextSubmissionId');
    my ($submissionId) = $self->session->db->read('select nextSubmissionId from EventManagementSystem where assetId = ?', [ $self->getId ] )->array;
    $self->update( { nextSubmissionId => ($submissionId + 1) } );
    return $submissionId;
}

#-------------------------------------------------------------------

=head2 getRegistrant ( badgeId )

Returns a hash reference containing the properties of a registrant.

=head3 badgeId

The unique id of the registrant you're looking for.

=cut

sub getRegistrant {
	my ($self, $badgeId) = @_;
	return $self->session->db->quickHashRef("select * from EMSRegistrant where badgeId=?",[$badgeId]);
}

#-------------------------------------------------------------------

=head2 getRibbons ()

Returns an array reference of ribbon objects.

=cut

sub getRibbons {
	my $self = shift;
	return $self->getLineage(['children'],{returnObjects=>1, includeOnlyClasses=>['WebGUI::Asset::Sku::EMSRibbon']});
}

#-------------------------------------------------------------------
=head2 getSubmissionLocations

retuns an arrayref of the locations found in the submission location list

=cut

sub getSubmissionLocations {
   my $self = shift;
   my $text = $self->get('submittedLocationsList');
dav::log 'getSubmissionLocations:"', $text, '"';
   return undef if $text eq '';
   return [ split( /\s+/, $text ) ];
}

#-------------------------------------------------------------------
sub getSubmissionStatus {
    my $self  = shift;
    my $key   = shift;

    unless ($self->{_status}) {
        tie my %hash, "Tie::IxHash";
        my $i18n = $self->i18n;
        for my $item (
            'pending',
            'feedback',
            'denied',
            'approved',
            'created',
            'failed',
                        ) {
            $hash{$item} = $i18n->get($item),
        }
        $self->{_status} = \%hash;
    }

    if($key) {
        return $self->{_status}{$key};
    }

    return $self->{_status};
}

#-------------------------------------------------------------------

=head2 getTickets ()

Returns an array reference of ticket objects.

=head3 options

A hash reference containing optional toggles.

=head4 returnIds

By default this method returns objects, but setting this to 1 will make it return an array reference of asset ids instead of objects.

=cut

sub getTickets {
	my $self = shift;
	my $options = shift;
	return $self->getLineage(['children'],{returnObjects=>(($options->{returnIds}) ? 0 : 1), includeOnlyClasses=>['WebGUI::Asset::Sku::EMSTicket']});
}

#-------------------------------------------------------------------

=head2 getTokens ()

Returns an array reference of badge objects.

=cut

sub getTokens {
	my $self = shift;
	return $self->getLineage(['children'],{returnObjects=>1, includeOnlyClasses=>['WebGUI::Asset::Sku::EMSToken']});
}

#-------------------------------------------------------------------
=head2 hasSubmissionForms

returns true if the EMS has subission forms attached

=cut

sub hasSubmissionForms {
   my $self = shift;
		   # are there ~any~ forms attached to this ems?
   my $res = $self->getLineage(['children'],{ limit => 1,
	 includeOnlyClasses => ['WebGUI::Asset::EMSSubmissionForm'],
     } );
   return scalar(@$res);
}

#-------------------------------------------------------------------
=head2 hasSubmissions

returns true if the current user has submission forms in this EMS

=cut

sub hasSubmissions {
   my $self = shift;
   return 0 if ! $self->canSubmit;
   my $res = $self->getLineage(['descendants'],{ limit => 1,
	 includeOnlyClasses => ['WebGUI::Asset::EMSSubmission'],
	 whereClause => q{createdBy='} . $self->session->user->userId . q/'/,
     } );
   return scalar(@$res);
}

#-------------------------------------------------------------------

=head2 i18n

returns the internationalisation object for this asset

=cut

sub i18n {
    my $self = shift;
    return $self->{_i18n} ||= WebGUI::International->new($self->session,'Asset_EventManagementSystem');
}

#-------------------------------------------------------------------

=head2 isRegistrationStaff ( [ user ] )

Returns a boolean indicating whether the user is a member of the registration staff.

=head3 user

A WebGUI::User object. Defaults to $session->user.

=cut

sub isRegistrationStaff {
	my $self = shift;
	my $user = shift || $self->session->user;
	$user->isInGroup($self->get('registrationStaffGroupId'));
}

#-------------------------------------------------------------------

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

sub prepareView {
    my $self = shift;
    $self->SUPER::prepareView();
    my $template = WebGUI::Asset::Template->new($self->session, $self->get("templateId"));
    if (!$template) {
        WebGUI::Error::ObjectNotFound::Template->throw(
            error      => qq{Template not found},
            templateId => $self->get("templateId"),
            assetId    => $self->getId,
        );
    }
    $template->prepare($self->getMetaDataAsTemplateVariables);
    $self->{_viewTemplate} = $template;
}

#------------------------------------------------------------------

=head2 purge ( )

See WebGUI::Asset::purge() for details.  Extend SUPERclass
to handle deleting tickets, tokens, ribbons, registrants, badge groups
and event meta data.

=cut

sub purge {
    my $self = shift;
    my $db = $self->session->db;

    # delete registrations
	my $deleteTicket = $db->prepare("delete from EMSRegistrantTicket where badgeId=?");
	my $deleteToken  = $db->prepare("delete from EMSRegistrantToken  where badgeId=?");
	my $deleteRibbon = $db->prepare("delete from EMSRegistrantRibbon where badgeId=?");
    my $sth = $db->read("select badgeId from EMSRegistrant where emsAssetId=?",[$self->getId]);
    while (my ($id) = $sth->array) {
        $deleteTicket->execute([$id]);
        $deleteToken->execute([$id]);
        $deleteRibbon->execute([$id]);
    }
	$deleteTicket->finish;
	$deleteToken->finish;
	$deleteRibbon->finish;
	$db->write("delete from EMSRegistrant where emsAssetId=?",[$self->getId]);

	# delete other data
	$db->write("delete from EMSBadgeGroup where emsAssetId=?",[$self->getId]);
	$db->write("delete from EMSEventMetaField where assetId=?",[$self->getId]);

    $self->SUPER::purge(@_);
}

#-------------------------------------------------------------------

=head2 view

Displays the list of configured badges. And other links.

=cut

sub view {
	my ($self) = @_;
	my $session = $self->session;
	return $session->privilege->noAccess() unless $self->canView;

	# set up objects we'll need
	my %var = (
		addBadgeUrl			=> $self->getUrl('func=add;class=WebGUI::Asset::Sku::EMSBadge'),
		buildBadgeUrl		=> $self->getUrl('func=buildBadge'),
		viewScheduleUrl		=> $self->getUrl('func=viewSchedule'),
		addSubmissionUrl	=> $self->getUrl('func=addSubmission'),
		viewSubmissionQueueUrl	=> $self->getUrl('func=viewSubmissionQueue'),
		addSubmissionFormUrl	=> $self->getUrl('func=addSubmissionForm'),
		manageBadgeGroupsUrl=> $self->getUrl('func=manageBadgeGroups'),
		getBadgesUrl		=> $self->getUrl('func=getBadgesAsJson'),
		isRegistrationStaff				=> $self->isRegistrationStaff,
		canEdit						=> $self->canEdit,
		canSubmit			=> $self->canSubmit,
		hasSubmissions			=> $self->hasSubmissions,
		hasSubmissionForms			=> $self->hasSubmissionForms,
		lookupRegistrantUrl	=> $self->getUrl('func=lookupRegistrant'),
		);

	# render
	return $self->processTemplate(\%var,undef,$self->{_viewTemplate});
}


#-------------------------------------------------------------------

=head2 www_addRibbonToBadge ()

Adds a ribbon to a badge. Expects two form parameters, assetId and badgeId, where assetId represents the ribbon, and badgeId represents the badge.

=cut

sub www_addRibbonToBadge {
	my $self = shift;
	my $session = $self->session;
    return $session->privilege->insufficient() unless $self->canView;
    my $form = $session->form;
	my $ribbon = WebGUI::Asset->new($session, $form->get('assetId'), 'WebGUI::Asset::Sku::EMSRibbon');
	if (defined $ribbon) {
		$ribbon->addToCart({badgeId=>$form->get('badgeId')});
	}
	return $self->www_getRegistrantAsJson();
}

#-------------------------------------------------------------------

=head2 www_addSubmission ()

display a form or links to forms to create a new submission

=cut

sub www_addSubmission {
dav::log __PACKAGE__ . '::www_addSubmission';
    my $self = shift;
    my $params = shift || {};
    my $session = $self->session;
    my $formId = $params->{formId} || $session->form->get('formId');
    my $i18n = WebGUI::International->new($session,'Asset_EventManagementSystem');
    my $form;

    if( ! defined $formId ) {
           my $res = $self->getLineage(['children'],{ returnObjects => 1,
                 includeOnlyClasses => ['WebGUI::Asset::EMSSubmissionForm'],
             } );
	    my @new = map { $_->canSubmit ? $_ : () } ( @$res);
            if( scalar(@new) == 0 ) {
                return $self->www_view;
            } elsif( scalar(@new) == 1 ) {
                $form = $new[0];
                $formId = $form->getId;
            } else {
                my $makeAnchorList =sub{ my $u=shift; my $n=shift; my $d=shift;
                            return qq{<li><a href='$u' title='$d'>$n</a></li>} } ;
                my $listOfLinks = join '', ( map {
                      $makeAnchorList->(
                                $_->getUrl('func=addSubmission' ),
                                $_->get('title'),
                                WebGUI::HTML::filter($_->get('description'),'all')
                             )
                           } ( @new ) );
                return $self->processStyle( '<h1>' . $i18n->get('select form to submit') .
                                            '</h1><ul>' . $listOfLinks . '</ul>' );
            }
    } else {
        $form = WebGUI::Asset->newByDynamicClass($session,$formId);
    }
    if (!defined $form) {
	$session->errorHandler->error(__PACKAGE__ . " - failed to instanciate asset with assetId $formId");
    }
    return $form->www_addSubmission;
}

#-------------------------------------------------------------------

=head2 www_addSubmissionForm ()

call www_editSubmissionForm with assetId == new

=cut

sub www_addSubmissionForm {
    my $self = shift;
    $self->www_editSubmissionForm( { assetId => 'new' } );
}

#-------------------------------------------------------------------

=head2 www_addTicketsToBadge ()

Adds selected tickets to a badge. Expects two form parameters, assetId (multiples fine) and badgeId, where assetId represents the ticket and badgeId represents the badge.

=cut

sub www_addTicketsToBadge {
	my $self = shift;
	my $session = $self->session;
    return $session->privilege->insufficient() unless $self->canView;
    my $form = $session->form;
	my @ids = $form->param('assetId');
	foreach my $id (@ids) {
		my $ticket = WebGUI::Asset->new($session, $id, 'WebGUI::Asset::Sku::EMSTicket');
		if (defined $ticket) {
			$ticket->addToCart({badgeId=>$form->get('badgeId')});
		}		
	}
	return $self->www_getRegistrantAsJson();
}

#-------------------------------------------------------------------

=head2 www_addTokenToBadge ()

Adds a token to a badge. Expects three form parameters, assetId, quantity, and badgeId, where assetId represents the token, quantity is the amount to add, and badgeId represents the badge.

=cut

sub www_addTokenToBadge {
	my $self = shift;
	my $session = $self->session;
    return $session->privilege->insufficient() unless $self->canView;
    my $form = $session->form;
	my $token = WebGUI::Asset->new($session, $form->get('assetId'), 'WebGUI::Asset::Sku::EMSToken');
	if (defined $token) {
		my $item = $token->addToCart({badgeId=>$form->get('badgeId')});
		$item->setQuantity($form->get('quantity'));
	}
	return $self->www_getRegistrantAsJson();
}

#-------------------------------------------------------------------

=head2 www_buildBadge ( [badgeId, whichTab] )

Displays available ribbons, tokens, and tickets for the current badge.

=cut

sub www_buildBadge {
	my ($self, $badgeId, $whichTab) = @_;
	my $session = $self->session;
	return $session->privilege->noAccess() unless $self->canView;
	$badgeId = $session->form->get("badgeId") if ($badgeId eq "");
	my $i18n = WebGUI::International->new($session, "Asset_EventManagementSystem");
	my %var = (
		%{$self->get},
		addTicketUrl				=> $self->getUrl('func=add;class=WebGUI::Asset::Sku::EMSTicket'),
		importTicketsUrl			=> $self->getUrl('func=importEvents'),
		exportTicketsUrl			=> $self->getUrl('func=exportEvents'),
		getTicketsUrl				=> $self->getUrl('func=getTicketsAsJson;badgeId='.$badgeId),
		canEdit						=> $self->canEdit,
		hasBadge					=> ($badgeId ne ""),
		badgeId						=> $badgeId,
		whichTab					=> $whichTab || "tickets",
		addRibbonUrl				=> $self->getUrl('func=add;class=WebGUI::Asset::Sku::EMSRibbon'),
		getRibbonsUrl				=> $self->getUrl('func=getRibbonsAsJson'),
		getTokensUrl				=> $self->getUrl('func=getTokensAsJson'),
		addTokenUrl					=> $self->getUrl('func=add;class=WebGUI::Asset::Sku::EMSToken'),
		lookupBadgeUrl				=> $self->getUrl('func=lookupRegistrant'),
		url							=> $self->getUrl,
		viewCartUrl					=> $self->getUrl('shop=cart'),
		customRequestUrl			=> $self->getUrl('badgeId='.$badgeId),
		manageEventMetaFieldsUrl 	=> $self->getUrl('func=manageEventMetaFields'),
		);
	my @otherBadges =();
	my $cart = WebGUI::Shop::Cart->newBySession($session);
	foreach my $item (@{$cart->getItems}) {
		my $id = $item->get('options')->{badgeId};
		next if ($id eq $badgeId);
		next unless ($item->getSku->isa("WebGUI::Asset::Sku::EMSBadge"));
		my $name = $session->db->quickScalar("select name from EMSRegistrant where badgeId=?",[$id]);
		push(@otherBadges, {
			badgeUrl	=> $self->getUrl('func=buildBadge;badgeId='.$id),
			badgeLabel	=> sprintf($i18n->get('switch to badge for'), $name),
			});
	}
	$var{otherBadgesInCart} = \@otherBadges;

	# render
	return $self->processStyle($self->processTemplate(\%var,$self->get('badgeBuilderTemplateId')));
}

#-------------------------------------------------------------------

=head2 www_deleteBadgeGroup ()

Deletes a badge group.

=cut

sub www_deleteBadgeGroup {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	$self->session->db->deleteRow("EMSBadgeGroup","badgeGroupId",$self->session->form->get("badgeGroupId"));
	return $self->www_manageBadgeGroups;
}

#-------------------------------------------------------------------

=head2 www_deleteEventMetaField ( )

Method to move an event metdata field up one position in display order

=cut

sub www_deleteEventMetaField {
	my $self = shift;
	return $self->session->privilege->insufficient unless ($self->canEdit);
    $self->deleteEventMetaField($self->session->form->get("fieldId"));
	return $self->www_manageEventMetaFields;
}

#-------------------------------------------------------------------

=head2 www_editBadgeGroup ()

Displays an edit screen for a badge group.

=cut

sub www_editBadgeGroup {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	my ($form, $db) = $self->session->quick(qw(form db));
	my $f = WebGUI::HTMLForm->new($self->session, action=>$self->getUrl);
	my $badgeGroup = $db->getRow("EMSBadgeGroup","badgeGroupId",$form->get('badgeGroupId'));
	$badgeGroup->{badgeList} = ($badgeGroup->{badgeList} ne "") ? JSON::from_json($badgeGroup->{badgeList}) : [];
	my $i18n = WebGUI::International->new($self->session, "Asset_EventManagementSystem");
	$f->hidden(name=>'func', value=>'editBadgeGroupSave');
	$f->hidden(name=>'badgeGroupId', value=>$form->get('badgeGroupId'));
	$f->text(
		name		=> 'name',	
		value		=> $badgeGroup->{name},
		label		=> $i18n->get('badge group name'),
		hoverHelp	=> $i18n->get('badge group name help'),
		);
	$f->submit;
	return $self->processStyle('<h1>'.$i18n->get('badge groups').'</h1>'.$f->print);
}


#-------------------------------------------------------------------

=head2 www_editBadgeGroupSave ()

Saves a badge group.

=cut

sub www_editBadgeGroupSave {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	my $form = $self->session->form;
	my $id = $form->get("badgeGroupId") || "new";
	$self->session->db->setRow("EMSBadgeGroup","badgeGroupId",{
		badgeGroupId	=> $id,
		emsAssetId		=> $self->getId,
		name			=> $form->get('name'),
		});
	return $self->www_manageBadgeGroups;
}

#-------------------------------------------------------------------

=head2  www_editSubmissionForm 

calls editSubmissionForm in WebGUI::Asset::EMSSubmissionForm

=cut

sub www_editSubmissionForm {
	my $self             = shift;
	return $self->session->privilege->insufficient() unless $self->isRegistrationStaff;
	return WebGUI::Asset::EMSSubmissionForm->www_editSubmissionForm($self,shift);
}


#-------------------------------------------------------------------

=head2  www_editSubmissionFormSave

test and save data posted from editSubmissionForm...

=cut

sub www_editSubmissionFormSave {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->isRegistrationStaff;
	my $formParams = WebGUI::Asset::EMSSubmissionForm->processForm($self);
        if( $formParams->{_isValid} ) {
            delete $formParams->{_isValid};
	    $self->addSubmissionForm($formParams);
	    return $self->www_viewSubmissionQueue;
        } else {
	    return $self->www_editSubmissionForm($formParams);
	}
}

#-------------------------------------------------------------------

=head2 www_editEventMetaField ( )

Displays the edit form for event meta fields.

=cut

sub www_editEventMetaField {
	my $self = shift;
	my $fieldId = shift || $self->session->form->process("fieldId");
	my $error = shift;
	return $self->session->privilege->insufficient unless ($self->canEdit);
	my $i18n2 = WebGUI::International->new($self->session,'Asset_EventManagementSystem');
	my $i18n = WebGUI::International->new($self->session,"WebGUIProfile");
	my $f = WebGUI::HTMLForm->new($self->session, (
		action => $self->getUrl("func=editEventMetaFieldSave;fieldId=".$fieldId)
	));
	my $data = {};
	if ($error) {
		# load submitted data.
		$data = {
			label => $self->session->form->process("label"),
			dataType => $self->session->form->process("dataType",'fieldType'),
			visible => $self->session->form->process("visible",'yesNo'),
			required => $self->session->form->process("required",'yesNo'),
			possibleValues => $self->session->form->process("possibleValues",'textarea'),
			defaultValues => $self->session->form->process("defaultValues",'textarea'),
			helpText => $self->session->form->process("helpText",'textarea'),
		};
		$f->readOnly(
			-name => 'error',
			-label => $i18n2->get('error'),
			-value => '<span style="color:red;font-weight:bold">'.$error.'</span>',
		);
	} elsif ($fieldId ne 'new') {
		$data = $self->session->db->quickHashRef("select * from EMSEventMetaField where fieldId=?",[$fieldId]);
	} else {
		# new field defaults
		$data = {
			label => $i18n2->get('type label here'),
			dataType => 'text',
			visible => 1,
			required => 0,
		};
	}
	$f->text(
		-name => "label",
		-label => $i18n2->get('label'),
		-hoverHelp => $i18n2->get('label help'),
		-value => $data->{label},
		-extras=>(($data->{label} eq $i18n2->get('type label here'))?' style="color:#bbbbbb" ':'').' onblur="if(!this.value){this.value=\''.$i18n2->get('type label here').'\';this.style.color=\'#bbbbbb\';}" onfocus="if(this.value == \''.$i18n2->get('type label here').'\'){this.value=\'\';this.style.color=\'\';}"',
	);
	$f->yesNo(
		-name=>"visible",
		-label=>$i18n->get('473a'),
		-hoverHelp=>$i18n->get('473a description'),
		-value=>$data->{visible},
		defaultValue=>1,
	);
	$f->yesNo(
		-name=>"required",
		-label=>$i18n->get(474),
		-hoverHelp=>$i18n->get('474 description'),
		-value=>$data->{required}
	);
    $f->fieldType(
        -name=>"dataType",        
        -label=>$i18n->get(486),        
        -hoverHelp=>$i18n->get('486 description'),
        -value=>ucfirst $data->{dataType},        
        -defaultValue=>"Text",
        );
	$f->textarea(
		-name => "possibleValues",
		-label => $i18n->get(487),
		-hoverHelp => $i18n->get('487 description'),
		-value => $data->{possibleValues},
	);
	$f->textarea(
		-name => "defaultValues",
		-label => $i18n->get(488),
		-hoverHelp => $i18n->get('488 description'),
		-value => $data->{defaultValues},
	);
	$f->textarea(
		-name => "helpText",
		-label => $i18n2->get('meta field help text'),
		-hoverHelp => $i18n2->get('meta field help text description'),
		-value => $data->{helpText},
	);
	$f->submit;
	return $self->processStyle($f->print);
}

#-------------------------------------------------------------------

=head2 www_editEventMetaFieldSave ( )

Processes the results from www_editEventMetaField ().

=cut

sub www_editEventMetaFieldSave {
	my $self = shift;
	return $self->session->privilege->insufficient unless ($self->canEdit);
	my $error = '';
	my $i18n = WebGUI::International->new($self->session,'Asset_EventManagementSystem');
	foreach ('label') {
		if ($self->session->form->get($_) eq "" || 
			$self->session->form->get($_) eq $i18n->get('type label here')) {
			$error .= sprintf($i18n->get('null field error'),$_)."<br />";
		}
	}
	return $self->www_editEventMetaField(undef,$error) if $error;
	my $newId = $self->setCollateral("EMSEventMetaField", "fieldId",{
		fieldId=>$self->session->form->process('fieldId'),
		label => $self->session->form->process("label"),
		dataType => $self->session->form->process("dataType",'fieldType'),
		visible => $self->session->form->process("visible",'yesNo'),
		required => $self->session->form->process("required",'yesNo'),
		possibleValues => $self->session->form->process("possibleValues",'textarea'),
		defaultValues => $self->session->form->process("defaultValues",'textarea'),
		helpText => $self->session->form->process("helpText",'textarea'),
	},1,1);
	return $self->www_manageEventMetaFields();
}

#-------------------------------------------------------------------

=head2 www_editRegistrantSave ( )

=cut

sub www_editRegistrantSave {
	my $self = shift;
	return $self->session->privilege->insufficient unless ($self->isRegistrationStaff);
	my $form = $self->session->form;
	my %badgeInfo = (badgeId=>$form->get('badgeId'));
	foreach my $field (qw(name address1 address2 address3 city state organization notes)) {
		$badgeInfo{$field} = $form->get($field, "text");
	}
	$badgeInfo{'userId'} = $form->get('userId', 'user');
	$badgeInfo{'phoneNumber'} = $form->get('phoneNumber', 'phone');
	$badgeInfo{'email'} = $form->get('email', 'email');
	$badgeInfo{'country'} = $form->get('country', 'country');
	$badgeInfo{'zipcode'} = $form->get('zipcode', 'zipcode');
	$self->session->db->setRow('EMSRegistrant','badgeId', \%badgeInfo);
	return $self->www_manageRegistrant;
}

#-------------------------------------------------------------------

=head2 www_exportEvents ( )

Method to deliver this EMS's events in CSV format.

=cut

sub www_exportEvents {
	my $self = shift;
	my $session = $self->session;
	return $session->privilege->insufficient unless $self->canEdit;

	my $csv = Text::CSV_XS->new({ eol => "\n", binary => 1 }); # TODO use their newline?
	my $fields = $self->getEventFieldsForImport;
	my $out = $session->output;

	# set http header
	$self->session->http->setFilename($self->getTitle.".csv", 'application/excel');
	
	# add file header
	my @header = ();
	foreach my $field (@{$fields}) {
		push @header, $field->{label};
	}
	$csv->combine(@header);
	$out->print($csv->string,1);

	# process events
	foreach my $id (@{$self->getTickets({returnIds=>1})}) {
		my $event = WebGUI::Asset::Sku::EMSTicket->new($session, $id);
		my @export = ();
		if (defined $event) {
			my $metadata = $event->getEventMetaData;
			foreach my $field (@{$fields}) {
				if ($field->{isMeta}) {
					push(@export, $metadata->{$field->{name}});
				}
				else {
					push(@export, $event->get($field->{name}));
				}
			}
		}
		if ($csv->combine(@export)) {
			$out->print($csv->string,1);
		}
		else {
		#	$out->print(join('|',@export)."\n",1);
			$out->print("Error: ".$csv->error_input,1);
			last;
		}
	}
	
	# finished
	return "chunked";
}

#----------------------------------------------------------------------------

=head2 www_getAllSubmissions ( )

Get a page of Asset Manager data, ajax style. Returns a JSON array to be
formatted in a WebGUI submission queue data table.

=cut

sub www_getAllSubmissions {
    my $self        = shift;
    my $session     = $self->session;
    my $datetime    = $session->datetime;
    my $form        = $session->form;
    my $rowsPerPage = 25;
    my $tableInfo  = {};    

    return $session->privilege->insufficient unless $self->canSubmit || $self->isRegistrationStaff;

    my $orderByColumn    = $form->get( 'orderByColumn' ) || $self->get("sortColumn");
    my $dir              = $form->get('orderByDirection') || $self->get('sortOrder');
    my $orderByDirection = lc ($dir) eq "asc" ? "ASC" : "DESC";

    my $whereClause ;
    if(!$self->isRegistrationStaff) {    
        my $userId     = $session->user->userId;
        $whereClause .= qq{ createdBy='$userId'};
    }

    my $rules;
    $rules->{'joinClass'         } = "WebGUI::Asset::EMSSubmission";
    $rules->{'whereClause'       } = $whereClause;
    $rules->{'includeOnlyClasses'} = ['WebGUI::Asset::EMSSubmission'];
    $rules->{'orderByClause'     } = $session->db->dbh->quote_identifier( $orderByColumn ) . ' ' . $orderByDirection if $orderByColumn;

    my $sql  = "";
    
    $sql = $self->getLineageSql(['descendants'], $rules);

    my $startIndex        = $form->get( 'startIndex' ) || 1;
    my $rowsPerPage         = $form->get( 'rowsPerPage' ) || 25;
    my $currentPage         = int ( $startIndex / $rowsPerPage ) + 1;
    
    my $p = WebGUI::Paginator->new( $session, '', $rowsPerPage, 'pn', $currentPage );
    $p->setDataByQuery($sql);

    $tableInfo->{'recordsReturned'} = $rowsPerPage;
    $tableInfo->{'totalRecords'   } = $p->getRowCount; 
    $tableInfo->{'startIndex'     } = $startIndex;
    $tableInfo->{'sort'           } = $orderByColumn;
    $tableInfo->{'dir'            } = $orderByDirection;
    $tableInfo->{'records'        } = [];
    
    for my $record ( @{ $p->getPageData } ) {
        my $asset = WebGUI::Asset->newByDynamicClass( $session, $record->{assetId} );
        
        my $lastReplyBy = $asset->get("lastReplyBy");
        if ($lastReplyBy) {
           $lastReplyBy = WebGUI::User->new($session,$lastReplyBy)->username;
        }

        # Populate the required fields to fill in
        my $lastReplyDate = $asset->get("lastReplyDate");
        if($lastReplyDate) {
            $lastReplyDate = $datetime->epochToHuman($lastReplyDate,"%y-%m-%d @ %H:%n %p");
        }

        my %fields      = (
            submissionId  => $asset->get("submissionId"),
            url           => $asset->getQueueUrl,
            title         => $asset->get( "title" ),
            createdBy     => WebGUI::User->new($session,$asset->get( "createdBy" ))->username,
            creationDate  => $datetime->epochToSet($asset->get( "creationDate" )),
            submissionStatus => $self->getSubmissionStatus($asset->get( "submissionStatus" ) || 'pending' ),
            lastReplyDate => $lastReplyDate || '',
            lastReplyBy   => $lastReplyBy || '',
        );

        push @{ $tableInfo->{ records } }, \%fields;
    }
    
    $session->http->setMimeType( 'application/json' );
    return JSON->new->encode( $tableInfo );
}

#-------------------------------------------------------------------

=head2 www_getBadgesAsJson ()

Retrieves a list of badges for the www_view() method.

=cut

sub www_getBadgesAsJson {
    my ($self) = @_;
	my $session = $self->session;
    return $session->privilege->insufficient() unless $self->canView;
    my ($db, $form) = $session->quick(qw(db form));
    my %results = ();
    $results{records} = [];
	BADGE: foreach my $badge (@{$self->getBadges}) {
        next BADGE unless $badge->canView;
		push(@{$results{records}}, {
			title 				=> $badge->getTitle,
			description			=> $badge->get('description'),
			price				=> $badge->getPrice+0,
			quantityAvailable	=> $badge->getQuantityAvailable,
			url					=> $badge->getUrl,
			editUrl				=> $badge->getUrl('func=edit'),
			deleteUrl			=> $badge->getUrl('func=delete'),
			assetId				=> $badge->getId,
			});
	}
    $results{totalRecords} = $results{recordsReturned} = scalar(@{$results{records}});
    $results{'startIndex'} = 0;
    $results{'sort'}       = undef;
    $results{'dir'}        = "asc";
    $session->http->setMimeType('application/json');
    return JSON->new->encode(\%results);
}

#-------------------------------------------------------------------

=head2  www_getSubmissionById

returns a JSON dataset with info about the requested submission

=cut


sub www_getSubmissionById {
   my $self = shift;
   my $submissionId = $self->session->form->get('submissionId');
   my $result;
   my $res = $self->getLineage(['descendants'],{ limit => 1, returnObjects=>1,
	 includeOnlyClasses => ['WebGUI::Asset::EMSSubmission'],
         joinClass          => "WebGUI::Asset::EMSSubmission",
	 whereClause => q{submissionId='} . $submissionId . q/'/,
     } );
   if( scalar(@$res) == 0 ) {
       $result->{hasError} = 1;
       $result->{errors} = [ 'failed to load submission' ];
   } else {
       $result->{text} = $res->[0]->www_editSubmission;
       $result->{title} = $submissionId;
   }
    $self->session->http->setMimeType('application/json');
    return JSON->new->encode($result);
}

#-------------------------------------------------------------------

=head2 www_getRegistrantAsJson (  )

Retrieves the properties of a specific badge and the items attached to it. Expects badgeId to be one of the form params.

=cut

sub www_getRegistrantAsJson {
	my ($self) = @_;
	my $session = $self->session;
	my $db = $session->db;
    return $session->privilege->insufficient() unless $self->canView;
    $session->http->setMimeType('application/json');
	my @tickets = ();
	my @tokens = ();
	my @ribbons = ();
	my $badgeId = $self->session->form->get('badgeId');

	# get badge info
	my $badgeInfo = $self->getRegistrant($badgeId);
	return "{}" unless (exists $badgeInfo->{badgeAssetId});
	my $badge = WebGUI::Asset::Sku::EMSBadge->new($session, $badgeInfo->{badgeAssetId});
	$badgeInfo->{title} = $badge->getTitle;
	$badgeInfo->{sku} = $badge->get('sku');
	$badgeInfo->{assetId} = $badge->getId;
	$badgeInfo->{hasPurchased} = ($badgeInfo->{purchaseComplete}) ? 1 : 0;
	
	# get existing tickets
	my $existingTickets = $db->read("select ticketAssetId from EMSRegistrantTicket where badgeId=? and purchaseComplete=1",[$badgeId]);
	while (my ($id) = $existingTickets->array) {
		my $ticket = WebGUI::Asset::Sku::EMSTicket->new($session, $id);
        my $startTime = WebGUI::DateTime->new($ticket->get('startDate'))->set_time_zone($self->get('timezone'));
		push(@tickets, {
			title			=> $ticket->getTitle,
			eventNumber		=> $ticket->get('eventNumber'),
			hasPurchased 	=> 1,
			startDate		=> $startTime->toMysqlTime,
			endDate			=> $ticket->get('endDate'),
			location		=> $ticket->get('location'),
			assetId			=> $ticket->getId,
			sku				=> $ticket->get('sku'),
			});
	}

	# get existing ribbons
	my $existingRibbons = $db->read("select ribbonAssetId from EMSRegistrantRibbon where badgeId=?",[$badgeId]);
	while (my ($id) = $existingRibbons->array) {
		my $ribbon = WebGUI::Asset::Sku::EMSRibbon->new($session, $id);
		push(@ribbons, {
			title			=> $ribbon->getTitle,
			hasPurchased 	=> 1,
			assetId			=> $ribbon->getId,
			sku				=> $ribbon->get('sku'),
			});
	}

	# get existing tokens
	my $existingTokens = $db->read("select tokenAssetId,quantity from EMSRegistrantToken where badgeId=?",[$badgeId]);
	while (my ($id, $quantity) = $existingTokens->array) {
		my $token = WebGUI::Asset::Sku::EMSToken->new($session, $id);
		push(@tokens, {
			title			=> $token->getTitle,
			hasPurchased 	=> 1,
			quantity		=> $quantity,
			assetId			=> $token->getId,
			sku				=> $token->get('sku'),
			});
	}

	# see what's in the cart
	my $cart = WebGUI::Shop::Cart->newBySession($session);
	foreach my $item (@{$cart->getItems}) {
		# not related to this badge, so skip it
		next unless $item->get('options')->{badgeId} eq $badgeId;

		my $sku = $item->getSku;
		# it's a ticket
		if ($sku->isa('WebGUI::Asset::Sku::EMSTicket')) {
            my $startTime = WebGUI::DateTime->new($sku->get('startDate'))->set_time_zone($self->get('timezone'));
			push(@tickets, {
				title			=> $sku->getTitle,
				eventNumber		=> $sku->get('eventNumber'),
				itemId 			=> $item->getId,
				startDate		=> $startTime->toMysqlTime,
				endDate			=> $sku->get('endDate'),
				location		=> $sku->get('location'),
				assetId			=> $sku->getId,
				sku				=> $sku->get('sku'),
				hasPurchased 	=> 0,
				price			=> $sku->getPrice+0,
				});
		}
		# it's a token
		elsif ($sku->isa('WebGUI::Asset::Sku::EMSToken')) {
			push(@tokens, {
				title			=> $sku->getTitle,
				itemId 			=> $item->getId,
				quantity		=> $item->get('quantity'),
				assetId			=> $sku->getId,
				hasPurchased 	=> 0,
				sku				=> $sku->get('sku'),				
				price			=> $sku->getPrice+0 * $item->get('quantity'),
				});
		}
		
		# it's a ribbon
		elsif ($sku->isa('WebGUI::Asset::Sku::EMSRibbon')) {
			push(@ribbons, {
				title			=> $sku->getTitle,
				itemId 			=> $item->getId,
				assetId			=> $sku->getId,
				hasPurchased 	=> 0,
				sku				=> $sku->get('sku'),				
				price			=> $sku->getPrice+0,
				});
		}
		# it's this badge
		elsif ($sku->isa('WebGUI::Asset::Sku::EMSBadge')) {
			$badgeInfo->{hasPurchased} = 0;
			$badgeInfo->{itemId} = $item->getId;
			$badgeInfo->{price} = $sku->getPrice+0;
		}
	}
	$badgeInfo->{tokens} = \@tokens;
	$badgeInfo->{tickets} = \@tickets;
	$badgeInfo->{ribbons} = \@ribbons;
	
	# build json datasource
    return JSON->new->encode($badgeInfo);
}

#-------------------------------------------------------------------

=head2 www_getRegistrantsAsJson (  )

Returns a list of registrants in the system. Can be a narrowed search by submitting a keywords form param with the request.

=cut

sub www_getRegistrantsAsJson {
	my ($self) = @_;
	my $session = $self->session;
    return $session->privilege->insufficient() unless $self->canView;
    my ($db, $form) = $session->quick(qw(db form));
    my $startIndex      = $form->get('startIndex') || 0;
    my $numberOfResults = $form->get('results')    || 25;
	my $keywords        = $form->get('keywords');
	
	my $sql = "select SQL_CALC_FOUND_ROWS * from EMSRegistrant where purchaseComplete=1 and emsAssetId=?";
	my @params = ($self->getId);
	
	# user or staff
	unless ($self->isRegistrationStaff) {
		$sql .= " and userId=?";
		push @params, $session->user->userId;
	}

	# keyword search
    if ($keywords ne "") {
        $db->buildSearchQuery(\$sql, \@params, $keywords, [qw{badgeNumber name address1 address2 address3 city state country email notes zipcode phoneNumber organization}])
    }

	# limit
	$sql .= ' limit ?,?';
	push(@params, $startIndex, $numberOfResults);

	# get badge info
	my @records = ();
	my %results = ();
	my $badges = $db->read($sql,\@params);
    $results{'recordsReturned'} = $badges->rows()+0;
    $results{'totalRecords'}    = $db->quickScalar('select found_rows()') + 0; ##Convert to numeric
	while (my $badgeInfo = $badges->hashRef) {
		my $badge = WebGUI::Asset::Sku::EMSBadge->new($session, $badgeInfo->{badgeAssetId});
		unless (defined $badge) {
			$session->log->error('badge '.$badgeInfo->{badgeAssetId}.' does not exist.');
			next;
		}
		$badgeInfo->{title} = $badge->getTitle;
		$badgeInfo->{sku} = $badge->get('sku');
		$badgeInfo->{assetId} = $badge->getId;
		$badgeInfo->{manageUrl} = $self->getUrl('func=manageRegistrant;badgeId='.$badgeInfo->{badgeId});
		$badgeInfo->{buildBadgeUrl} = $self->getUrl('func=buildBadge;badgeId='.$badgeInfo->{badgeId});
		push(@records, $badgeInfo);
	}
    $results{'records'}      = \@records;
    $results{'startIndex'}   = $startIndex;
    $results{'sort'}         = undef;
    $results{'dir'}          = "asc";
	
	# build json datasource
    $session->http->setMimeType('application/json');
    return JSON->new->encode(\%results);
}


#-------------------------------------------------------------------

=head2 www_getRibbonsAsJson ()

Retrieves a list of ribbons for the www_buildBadge() method.

=cut

sub www_getRibbonsAsJson {
    my ($self) = @_;
	my $session = $self->session;
    return $session->privilege->insufficient() unless $self->canView;
    my ($db, $form) = $session->quick(qw(db form));
    my %results = ();
    $results{records} = [];
	foreach my $ribbon (@{$self->getRibbons}) {
		push(@{$results{records}}, {
			title 				=> $ribbon->getTitle,
			description			=> $ribbon->get('description'),
			price				=> $ribbon->getPrice+0,
			url					=> $ribbon->getUrl,
			editUrl				=> $ribbon->getUrl('func=edit'),
			deleteUrl			=> $ribbon->getUrl('func=delete'),
			assetId				=> $ribbon->getId,
			});
	}
    $results{totalRecords} = $results{recordsReturned} = scalar(@{$results{records}});
    $results{'startIndex'} = 0;
    $results{'sort'}       = undef;
    $results{'dir'}        = "asc";
    $session->http->setMimeType('application/json');
    return JSON->new->encode(\%results);
}


#-------------------------------------------------------------------

=head2 www_getScheduleDataJSON ()

returns the JSON data for a page of the schedule table

=cut


sub www_getScheduleDataJSON {
    my $self = shift;
    my $session = $self->session;
    my $emptyRecord = JSON->new->encode( {
        records         => [ ],   totalRecords        => 0,     recordsReturned    => 0,
        startIndex      => 0,     currentLocationPage => 0,     totalLocationPages => 0,
        currentDatePage => 0,     totalDatePages      => 0,     dateRecords        => [ ],
        sort            => undef, dir                 => 'asc', pageSize           => 0,
    });
    return $emptyRecord unless $self->canView;
    # the following two are expected to be configurable...
    my $locationsPerPage   = $self->get('scheduleColumnsPerPage');

    my ($db, $form)        = $session->quick(qw(db form));
    my $locationPageNumber = $form->get('locationPage') || 1;
    my $datePageNumber     = $form->get('datePage')     || 1;
    my @dateRecords;
    my @ticketLocations = $self->getLocations( \@dateRecords );
    # the total number of pages is the number of locations divided by the number of locations per page
    my $numberOfLocationPages = int( .9 + scalar(@ticketLocations) / $locationsPerPage );
        # skip everything else if there are no locations/pages
    return $emptyRecord if $numberOfLocationPages == 0;
    # now we pick out the locations to be displayed on this page
    my $indexFirstLocation = ($locationPageNumber-1)*$locationsPerPage;
    my $indexLastLocation  = $locationPageNumber*$locationsPerPage - 1;
    my $currentDate        = $dateRecords[$datePageNumber-1];
    @ticketLocations       = @ticketLocations[$indexFirstLocation..$indexLastLocation];
	my $tickets = $db->read( q{
             select assetData.assetId, sku.description, assetData.title, EMSTicket.startDate, EMSTicket.location
               from EMSTicket
               join sku using (assetId,revisionDate)
               join assetData using (assetId,revisionDate)
               join asset using (assetId)
              where asset.parentId = ? 
                 and DATE_FORMAT( EMSTicket.startDate, '%Y-%m-%d' ) = ?
                 and EMSTicket.location in (  } . 
		         join( ',', (map { $db->quote($_) } (@ticketLocations))) .
			 q{ )
                 and assetData.revisionDate = (
                           select max(revisionDate)
                             from assetData
                            where assetData.assetId=asset.assetId
                              and ( assetData.status = 'approved'
                                  or assetData.tagId = ? )
	      )
              order by EMSTicket.startDate, eventNumber asc
                     },[  $self->getId,  $currentDate,
                           $session->scratch->get("versionTag")
                      ]);
    my %hash;
    tie %hash, 'Tie::IxHash';
    while( my $row = $tickets->hashRef ) {
	$row->{type} = 'ticket';
        $row->{location} = '&nbsp;' if $row->{location} eq '';
        push @{$hash{$row->{startDate}}{$row->{location}}}, $row;
    }
    grep { $_ = '&nbsp;' if defined $_ && $_ eq '' } @ticketLocations;
    my %results = ();
    $results{records} = [];  ##Initialize to an empty array
    my $ctr = 0;
    my %locationMap = map { 'col' . ++$ctr , $_ } @ticketLocations;
         # fill out the columns in the table
    while( $ctr < $locationsPerPage ) { $locationMap{ 'col' . ++$ctr } = '' };
    push @{$results{records}}, { colDate => '' , map { $_ , { type => 'label', title => $locationMap{$_} || '' } } ( keys %locationMap ) };
    my $redo = 0;
    for my $startDate ( keys %hash ) {
        $redo = 0;
        my $row = { colDate => $startDate };
	my $empty = 1;
	for my $col ( keys %locationMap ) {
	    my $location = $locationMap{$col};
	    if( exists $hash{$startDate}{$location} ) {
	        $row->{$col} = pop @{$hash{$startDate}{$location}};
		$empty = 0;
                $redo = 1 if scalar(@{$hash{$startDate}{$location}}) > 0;
                delete $hash{$startDate}{$location} if scalar(@{$hash{$startDate}{$location}}) == 0;
	    } else {
	        $row->{$col} = { type => 'empty' };
	    }
	}
	next if $empty;
	push @{$results{records}}, $row;
        redo if $redo;
    }

    my $rowCount = scalar(@{$results{records}});
    $results{totalRecords} = $rowCount;
    $results{recordsReturned} = $rowCount;
    $results{rowsPerPage} = $rowCount;
    $results{startIndex} = 0; 
    $results{sort}       = undef;
    $results{dir}        = "asc";
    $results{pageSize}   = 10;
             # these next two are used to configure the paginator
    $results{totalLocationPages} = $numberOfLocationPages;
    $results{currentLocationPage} = $locationPageNumber;
    $results{totalDatePages} = scalar(@dateRecords);
    $results{currentDatePage} = $datePageNumber;
    $results{dateRecords} = \@dateRecords;
    $session->http->setMimeType('application/json');
    return JSON->new->encode(\%results);
}

#-------------------------------------------------------------------

=head2 www_getTicketsAsJson ()

Retrieves a list of tickets for the www_buildBadge() method.

=cut

sub www_getTicketsAsJson {
    my ($self) = @_;
	my $session = $self->session;
    return $session->privilege->insufficient() unless $self->canView;
    my ($db, $form)     = $session->quick(qw(db form));
    my $startIndex      = $form->get('startIndex') || 0;
    my $numberOfResults = $form->get('results')    || 25;
    my $sortDir         = $form->get('sortDir')    || 'ASC';
    my $sortKey         = $form->get('sortKey')    || 'eventNumber';
    my %results = ();
	my @ids     = ();
	my $keywords = $form->get('keywords');
	
	# looking for specific events
	if ($keywords =~ m{^[\d+,*\s*]+$}) {
		@ids = $db->buildArray("select distinct(EMSTicket.assetId) from EMSTicket left join asset using (assetId) where
			asset.parentId=? and EMSTicket.eventNumber in (".$keywords.") and asset.state='published' 
            order by EMSTicket.eventNumber",[$self->getId]);
	}
	
	# looking for keywords
	elsif ($keywords ne "") {
		@ids = @{WebGUI::Search->new($session)->search({
			keywords	=> $keywords,
			lineage		=> [$self->get('lineage')],
			classes		=> ['WebGUI::Asset::Sku::EMSTicket'],
			})->getAssetIds};
	}
	
	# just get all tickets
	else {
		@ids = $db->buildArray("select assetId from asset left join EMSTicket using (assetId) where parentId=? and
className='WebGUI::Asset::Sku::EMSTicket' and state='published' and revisionDate=(select max(revisionDate) from EMSTicket where assetId=asset.assetId) order by $sortKey $sortDir", [$self->getId]);
	}
	
	# get badge's badge groups
	my $badgeId = $form->get('badgeId');
	my @badgeGroups = ();
	if (defined $badgeId) {
		my $assetId = $db->quickScalar("select badgeAssetId from EMSRegistrant where badgeId=?",[$badgeId]);
		my $badge = WebGUI::Asset->new($session, $assetId, 'WebGUI::Asset::Sku::EMSBadge');
		@badgeGroups = split("\n",$badge->get('relatedBadgeGroups')) if (defined $badge);
	}
	
	# get a list of tickets already associated with the badge
	my @existingTickets = $db->buildArray("select ticketAssetId from EMSRegistrantTicket where badgeId=?",[$badgeId]);

	# get assets
	my $counter = 0;
	my $totalTickets = scalar(@ids);
	my @records = ();
	foreach my $id (@ids) {

		# skip tickets we already have
		if (isIn($id, @existingTickets)) {
			$totalTickets--;
			next;
		}

		my $ticket = WebGUI::Asset->new($session, $id, 'WebGUI::Asset::Sku::EMSTicket');
		
		# skip borked tickets
		unless (defined $ticket) {
			$session->errorHandler->warn("EMSTicket $id couldn't be instanciated by EMS ".$self->getId.".");
			$totalTickets--;
			next;
		}
		
		# skip tickets we can't view
		unless ($ticket->canView) {
			$totalTickets--;
			next;
		}
		
		# skip tickets not in our badge's badge groups
		if ($badgeId ne "" && scalar(@badgeGroups) > 0 && $ticket->get('relatedBadgeGroups') ne '') { # skip check if it has no badge groups
			my @groups = split("\n",$ticket->get('relatedBadgeGroups'));
			my $found = 0;
			BADGE: {
				foreach my $a (@badgeGroups) {
					foreach my $b (@groups) {
						if ($a eq $b) {
							$found = 1;
							last BADGE;
						}
					}
				}
			}
			unless ($found) {
				$totalTickets--;
				next;
			}
		}

        # gotta get to the page we're working with
        $counter++;
        next unless ($counter >= ($startIndex * $numberOfResults));
		
		# publish the data for this ticket
        my $description = $ticket->get('description');
        my $data = $ticket->get('eventMetaData');
        $data = '{}' if ($data eq "");
        my $meta = JSON->new->decode($data);
        foreach my $field (@{$self->getEventMetaFields}) {
            my $label = $field->{label};
            if ($field->{visible} && $meta->{$label} ne "") {
                $description .= '<p><b>'.$label.'</b>: '.$meta->{$label}.'</p>';
            }
        }
		my $date = WebGUI::DateTime->new($session, mysql => $ticket->get('startDate'))
                ->set_time_zone($self->get("timezone"))
                ->webguiDate("%W %z %Z");
		push(@records, {
			title 				=> $ticket->getTitle,
			description			=> $description,
			price				=> $ticket->getPrice+0,
			quantityAvailable	=> $ticket->getQuantityAvailable,
			url					=> $ticket->getUrl,
			editUrl				=> $ticket->getUrl('func=edit'),
			deleteUrl			=> $ticket->getUrl('func=delete'),
			assetId				=> $ticket->getId,
			eventNumber			=> $ticket->get('eventNumber'),
			location			=> $ticket->get('location'),
			startDate			=> $date,
			duration			=> $ticket->get('duration'),
			});
		last unless (scalar(@records) < $numberOfResults);
	}
	
	# humor
	my $find = pack('u',$keywords);
	chomp $find;
	if ($find eq q|'2$%,,C`P,0``|) {
		push(@records, {title=>unpack('u',q|022=M('-O<G)Y+"!$879E+@``|)});
		$totalTickets++;
	}
	
	# build json
	$results{records} 			= \@records;
    $results{totalRecords} 		= $totalTickets;
	$results{recordsReturned} 	= scalar(@records);
    $results{'startIndex'}   	= $startIndex;
    $results{'sort'}       		= undef;
    $results{'dir'}        		= "asc";
    $session->http->setMimeType('application/json');
    return JSON->new->encode(\%results);
}



#-------------------------------------------------------------------

=head2 www_getTokensAsJson ()

Retrieves a list of tokens for the www_buildBadge() method.

=cut

sub www_getTokensAsJson {
    my ($self) = @_;
	my $session = $self->session;
    return $session->privilege->insufficient() unless $self->canView;
    my ($db, $form) = $session->quick(qw(db form));
    my %results = ();
    $results{records} = [];  ##Initialize to an empty array
	foreach my $token (@{$self->getTokens}) {
		push(@{$results{records}}, {
			title 				=> $token->getTitle,
			description			=> $token->get('description'),
			price				=> $token->getPrice+0,
			url					=> $token->getUrl,
			editUrl				=> $token->getUrl('func=edit'),
			deleteUrl			=> $token->getUrl('func=delete'),
			assetId				=> $token->getId,
			});
	}
    $results{totalRecords} = $results{recordsReturned} = scalar(@{$results{records}});
    $results{'startIndex'} = 0;
    $results{'sort'}       = undef;
    $results{'dir'}        = "asc";
    $session->http->setMimeType('application/json');
    return JSON->new->encode(\%results);
}

#-------------------------------------------------------------------

=head2 www_importEvents ( [ $errors_aref ] )

Show the CSV-file upload form, along with optional errors.

=cut

sub www_importEvents {
	my ($self) = shift;
	my $errors_aref = shift || [];

	return $self->session->privilege->insufficient unless $self->canEdit;
	my $i18n = WebGUI::International->new($self->session,'Asset_EventManagementSystem');
	my $form = $self->session->form;
	
	# header, with optional errors as unordered list
	my $page_header = $i18n->get('import form header');
	if (@$errors_aref) {
		$page_header .= "<ul>";
		for my $error_msg (@$errors_aref) {
			$page_header .= "<li>$error_msg</li>";
		}
		$page_header .= "</ul>";
	}

	# create the form
	my $f = WebGUI::HTMLForm->new( $self->session, action => $self->getUrl("func=importEventsSave"), enctype => 'multipart/form-data' );

	$f->file(
		-label     => $i18n->get('choose a file to import'),
		-hoverHelp => $i18n->get('import hoverhelp file'),
		-name      => 'file',
	);
	$f->yesNo(
		-label   => $i18n->get('ignore first line'),
		-name    => 'ignore_first_line',
		-hoverHelp => $i18n->get('import hoverhelp first line'),
		-defaultValue   => $form->param('ignore_first_line'),
	);

	# create the std & meta fields part of the form
	my %importableFields = ();
	tie %importableFields, 'Tie::IxHash';
	foreach my $field (@{$self->getEventFieldsForImport}) {
		$importableFields{$field->{name}} = $field->{label};
	}
	my @defaultImportableFields = keys %importableFields;
	$f->checkList(
		vertical			=> 1,
		showSelectAllButton	=> 1,
		label				=> 'Fields',
		name				=> 'fieldsToImport',
		defaultValue		=> \@defaultImportableFields,
		options				=> \%importableFields,
		value				=> $form->get('fieldsToImport'),
	);

	$f->submit(-value=>$i18n->get('import events'));

	return $self->processStyle($page_header.'<p/>'.$f->print);
}



#-------------------------------------------------------------------

=head2 www_importEventsSave ( )

Handle the uploading of a CSV event data file, along with other options.

=cut

sub www_importEventsSave {
	my $self = shift;
	my $session = $self->session;
	return $session->privilege->insufficient unless $self->canEdit;
$|=1;

	# set up
	$session->http->setMimeType("text/plain");
	my $start = [Time::HiRes::gettimeofday];
	my $i18n = WebGUI::International->new($session,'Asset_EventManagementSystem');
	my $csv = Text::CSV_XS->new({ binary => 1 });
	my $out = $session->output;
	my $fields = $self->getEventFieldsForImport;
	my $form = $session->form;
	my $ignoreFirst = $form->get("ignore_first_line");
	my $validate = WebGUI::FormValidator->new($session);
	
	# find fields to import
    $out->print("Finding fields to import...\n",1);
	my @import = $form->get("fieldsToImport");
	my $i = 0;
	my $assetIdIndex = undef;
	foreach my $field (@import) {
		if ($field eq "assetId") {
            $out->print("\t$i\n",1);
			$assetIdIndex = $i;
			last;
		}
		$i++;
	}
	
	# get csv data
	$out->print("Reading file...\n",1);
	my $storage		= WebGUI::Storage->createTemp($session);
    my $filename	= $storage->addFileFromFormPost("file_file");
	
	# do import
	my $first = 1;
	if (open my $file, "<", $storage->getPath($filename)) {
		$out->print("Processing file...\n",1);
		ROW: while (my $line = <$file>) {
			if ($first) {
				$first = 0;
				if ($ignoreFirst) {
					next;
				}
			}
			if ($csv->parse($line)) {
				my @row = $csv->fields;
                my $start = [Time::HiRes::gettimeofday];
        		$out->print("Processing ".join(",", @row)."\n",1);
				my $event = undef;
				if (defined $assetIdIndex) {
					$event = WebGUI::Asset::Sku::EMSTicket->new($session, $row[$assetIdIndex]);
				}
				if (defined $event) {
					$out->print('Updating '.$event->getId."\n",1);
				}
				else {
					$event = $self->addChild({className=>'WebGUI::Asset::Sku::EMSTicket'});
					$out->print("Adding new asset ".$event->getId."\n",1)
				}
				my %properties = ();
				my $metadata = $event->getEventMetaData;
				my $i = 0;
				foreach my $field (@{$fields}) {
					next unless isIn($field->{name}, @import);
            		$out->print("\tAdding field ".$field->{label}."\n",1);
					my $type = $field->{type};
                    ##Force the use of Form::DateTime and MySQL Format
                    if ($field->{name} eq 'startDate') {
                        $type = 'dateTime';
                        $field->{defaultValue} = '1999-05-24 17:30:00';
                    }
					my $value = $validate->$type({
							name			=> $field->{name},
							defaultValue	=> $field->{defaultValue},
							options			=> $field->{options},
							},$row[$i]);
                    if ($field->{name} eq 'startDate' && !$value) {
                        $out->print('Skipping event on line '.$line.' due to bad date format');
                        next ROW;
                    }
					if ($field->{isMeta}) {
						$metadata->{$field->{label}} = $value;
					}
					else {
						$properties{$field->{name}} = $value;
					}
					$i++;
				}
                $out->print("\tUpdating properties\n",1);
                $properties{menuTitle} = $properties{title};
                $properties{url} = $self->get("url")."/".$properties{title};
				$event->update(\%properties);
                $out->print("\tUpdating meta data\n",1);
				$event->setEventMetaData($metadata);
                $out->print("\tCommitting asset\n",1);
                WebGUI::VersionTag->getWorking($session)->commit;
                $out->print("\tAdding event took ".Time::HiRes::tv_interval($start)." seconds to run.\n",1);
			}
			else {
				$out->print($csv->error_input() . ": ". $line."\n",1);
			}
		}
	}
	else {
		$out->print($i18n->get("no import took place")."\n",1);
	}
	
	# clean up
	$out->print("The import took ".Time::HiRes::tv_interval($start)." seconds to run.\n",1);
	$storage->delete;
	return "chunked";
}

#-------------------------------------------------------------------

=head2 www_lookupRegistrant ()

Displays the badges purchased by the current user, or all users if the user is part of the registration staff.

=cut

sub www_lookupRegistrant {
	my ($self) = @_;
	my $session = $self->session;
	return $session->privilege->noAccess() unless ($self->canView && $self->session->user->isRegistered);

	# set up template variables
	my %var = (
		buyBadgeUrl			=> $self->getUrl,
		viewEventsUrl		=> $self->getUrl('func=buildBadge'),
		viewCartUrl			=> $self->getUrl('shop=cart'),
		getRegistrantsUrl	=> $self->getUrl('func=getRegistrantsAsJson'),
		isRegistrationStaff	=> $self->isRegistrationStaff,		
		);

	# render the page
	return $self->processStyle($self->processTemplate(\%var, $self->get('lookupRegistrantTemplateId')));
}

#-------------------------------------------------------------------

=head2 www_manageBadgeGroups ()

Displays a list of badge groups.

=cut

sub www_manageBadgeGroups {
	my $self = shift;
	my $session = $self->session;
    return $session->privilege->insufficient() unless $self->canView;
	my $i18n = WebGUI::International->new($session, 'Asset_EventManagementSystem');
	my $output = '<h1>'.$i18n->get('badge groups')
		.q|</h1><p><a href="|.$self->getUrl("func=editBadgeGroup").q|">|.$i18n->get('add a badge group').q|</a>
		&bull; <a href="|.$self->getUrl.q|">|.$i18n->get('view badges').q|</a>
		</p>|;
	my $groups = $session->db->read("select badgeGroupId,name from EMSBadgeGroup where emsAssetId=?",[$self->getId]);
	my $badgeGroups = $self->getBadgeGroups;
	foreach my $id (keys %{$badgeGroups}) {
		$output .= q|<div>[<a href="|.$self->getUrl("func=deleteBadgeGroup;badgeGroupId=".$id).q|">|.$i18n->get('delete').q|</a>
			/ <a href="|.$self->getUrl("func=editBadgeGroup;badgeGroupId=".$id).q|">|.$i18n->get('edit').q|</a>]
			|.$badgeGroups->{$id}.q|</div>|;
	}
	return $self->processStyle($output);
}

#-------------------------------------------------------------------

=head2 www_manageEventMetaFields ( )

Method to display the event metadata management console.

=cut

sub www_manageEventMetaFields {
	my $self = shift;

	return $self->session->privilege->insufficient unless ($self->canEdit);

	my $i18n = WebGUI::International->new($self->session,'Asset_EventManagementSystem');
	my $output = '<h1>'.$i18n->get('meta fields')
		.q|</h1><p><a href="|.$self->getUrl("func=editEventMetaField").q|">|.$i18n->get('add an event meta field').q|</a>
		&bull; <a href="|.$self->getUrl('func=buildBadge').q|">|.$i18n->get('view tickets').q|</a>
		</p>|;
	my $metadataFields = $self->getEventMetaFields;
	my $count = 0;
	my $number = scalar(@{$metadataFields});
	if ($number) {
		foreach my $row1 (@{$metadataFields}) {
			my %row = %{$row1};
			$count++;
			$output .= "<div>".
			$self->session->icon->delete('func=deleteEventMetaField;fieldId='.$row{fieldId},$self->get('url'),$i18n->get('confirm delete event metadata')).
			$self->session->icon->edit('func=editEventMetaField;fieldId='.$row{fieldId}, $self->get('url')).
			$self->session->icon->moveUp('func=moveEventMetaFieldUp;fieldId='.$row{fieldId}, $self->get('url'),($count == 1)?1:0);
			$output .= $self->session->icon->moveDown('func=moveEventMetaFieldDown;fieldId='.$row{fieldId}, $self->get('url'),($count == $number)?1:0).
			" ".$row{label}."</div>";
		}
	}
	else {
		$output .= $i18n->get('you do not have any metadata fields to display');
	}
	return $self->processStyle($output);
}

#-------------------------------------------------------------------

=head2 www_manageRegistrant ()

Displays an admin interface for managing a registrant.

=cut

sub www_manageRegistrant {
	my $self = shift;
	my $session = $self->session;
	
	# check privs
	return $session->privilege->insufficient unless ($self->isRegistrationStaff);
	
	# setup 
	my $badgeId = $self->session->form->get('badgeId');
	my $db = $session->db;
	my $i18n = WebGUI::International->new($session, "Asset_EventManagementSystem");
	my $registrant = $self->getRegistrant($badgeId);

	# show lookup registrant if registrant requested doesn't exist
	unless ($registrant->{badgeId} ne "") {
		return $self->www_lookupRegistrant;
	}
	
	# build form
	my $f = WebGUI::HTMLForm->new($session, action=>$self->getUrl, tableExtras=>'class="manageRegistrant"');
	$f->submit;
	$f->hidden(name=>"func", value=>"editRegistrantSave");
	$f->hidden(name=>'badgeId', value=>$badgeId);
	$f->readOnly(
		label			=> $i18n->get('badge number'),
		value			=> $registrant->{badgeNumber},
	);
	$f->user(
		name			=> 'userId',
		label			=> $i18n->get('user'),
		defaultValue	=> $registrant->{userId},
	);
	$f->text(
		name			=> 'name',
		label			=> $i18n->get('name','Shop'),
		defaultValue	=> $registrant->{name},
		);
	$f->text(
		name			=> 'organization',
		label			=> $i18n->get('organization'),
		defaultValue	=> $registrant->{organization},
		);
	$f->text(
		name			=> 'address1',
		label			=> $i18n->get('address','Shop'),		
		defaultValue	=> $registrant->{address1},
		);
	$f->text(
		name			=> 'address2',
		defaultValue	=> $registrant->{address2},
		);
	$f->text(
		name			=> 'address3',
		defaultValue	=> $registrant->{address3},
		);
	$f->text(
		name			=> 'city',
		label			=> $i18n->get('city','Shop'),		
		defaultValue	=> $registrant->{city},
		);
	$f->text(
		name			=> 'state',
		label			=> $i18n->get('state','Shop'),		
		defaultValue	=> $registrant->{state},
		);
	$f->zipcode(
		name			=> 'zipcode',
		label			=> $i18n->get('code','Shop'),		
		defaultValue	=> $registrant->{zipcode},
		);
	$f->country(
		name			=> 'country',
		label			=> $i18n->get('country','Shop'),		
		defaultValue	=> $registrant->{country},
		);
	$f->phone(
		name			=> 'phoneNumber',
		label			=> $i18n->get('phone number','Shop'),		
		defaultValue	=> $registrant->{phoneNumber},
		);
	$f->email(
		name			=> 'email',
		label			=> $i18n->get('email address'),
		defaultValue	=> $registrant->{email}
		);
	$f->textarea(
		name			=> 'notes',
		label			=> $i18n->get('notes'),
		defaultValue	=> $registrant->{notes}
		);
	$f->submit;
	
	# build html
	my $output = q|
	<div id="doc3">
		<div id="hd">
			^ViewCart;
			&bull; <a href="|.$self->getUrl('func=lookupRegistrant').q|">|.$i18n->get('lookup badge').q|</a>
			&bull; <a href="|.$self->getUrl.q|">|.$i18n->get('buy badge').q|</a>
		</div>
		<div id="bd">
			<div class="yui-gc">
				<div class="yui-u first">
				|.$f->print.q|
				</div>
				<div class="yui-u">
		|;
			
	if ($registrant->{hasCheckedIn}) {
		$output .= q|<a style="font-size: 200%; margin: 10px; line-height: 200%; padding: 10px; background-color: #ffdddd; color: #800000; text-decoration: none;" href="|.$self->getUrl('func=toggleRegistrantCheckedIn;badgeId='.$badgeId).q|">|.$i18n->get('checked in').q|</a>|;
	}
	else {
		$output .= q|<a style="font-size: 200%; margin: 10px; line-height: 200%; padding: 10px; background-color: #ddffdd; color: #008000; text-decoration: none;" href="|.$self->getUrl('func=toggleRegistrantCheckedIn;badgeId='.$badgeId).q|">|.$i18n->get('not checked in').q|</a>|;
	}

	# badge management
	my $badge = WebGUI::Asset::Sku::EMSBadge->new($session, $registrant->{badgeAssetId});
	$output .= q|<p><b style="font-size: 150%; line-height: 150%;">|.$badge->getTitle.q|</b><br />
		<a href="|.$self->getUrl('func=printBadge;badgeId='.$badgeId).q|" target="_blank">|.$i18n->get('print').q|</a>
		&bull; <a href="|.$self->getUrl('func=refundItem;badgeId='.$badgeId.';transactionItemId='.$registrant->{transactionItemId}).q|">|.$i18n->get('refund').q|</a>
		&bull; |;
	if ($registrant->{hasCheckedIn}) {
		$output .= q|<a href="|.$self->getUrl('func=toggleRegistrantCheckedIn;badgeId='.$badgeId).q|">|.$i18n->get('mark as not checked in').q|</a>|;
	}
	else {
		$output .= q|<a href="|.$self->getUrl('func=toggleRegistrantCheckedIn;badgeId='.$badgeId).q|">|.$i18n->get('mark as checked in').q|</a>|;
	}
	$output .= q|
		&bull; <a href="|.$self->getUrl('func=buildBadge;badgeId='.$badgeId).q|">|.$i18n->get('add more items').q|</a>
		</p><br />|;
	
	# ticket management
	my $existingTickets = $db->read("select ticketAssetId, transactionItemId from EMSRegistrantTicket where badgeId=? and purchaseComplete=1",[$badgeId]);
	while (my ($id, $itemId) = $existingTickets->array) {
		my $ticket = WebGUI::Asset::Sku::EMSTicket->new($session, $id);
		$output .= q|<p><b>|.$ticket->getTitle.q|</b><br />
			<a href="|.$self->getUrl('func=printTicket;badgeId='.$badgeId.';ticketAssetId='.$id).q|" target="_blank">|.$i18n->get('print').q|</a>
			&bull; <a href="|.$self->getUrl('func=refundItem;badgeId='.$badgeId.';transactionItemId='.$itemId).q|">|.$i18n->get('refund').q|</a>
			</p><br />|;
	}

	# ribbon management
	my $existingRibbons = $db->read("select ribbonAssetId, transactionItemId from EMSRegistrantRibbon where badgeId=?",[$badgeId]);
	while (my ($id, $itemId) = $existingRibbons->array) {
		my $ribbon = WebGUI::Asset::Sku::EMSRibbon->new($session, $id);
		$output .= q|<p><b>|.$ribbon->getTitle.q|</b><br />
			<a href="|.$self->getUrl('func=refundItem;badgeId='.$badgeId.';transactionItemId='.$itemId).q|">|.$i18n->get('refund').q|</a>
			</p><br />|;
	}

	# token management
	my $existingTokens = $db->read("select tokenAssetId,quantity,transactionItemIds from EMSRegistrantToken where badgeId=?",[$badgeId]);
	while (my ($id, $quantity, $itemIds) = $existingTokens->array) {
		my $token = WebGUI::Asset::Sku::EMSToken->new($session, $id);
		my @itemIds = split(',', $itemIds);
		$output .= q|<p><b>|.$token->getTitle.q|</b> (|.$quantity.q|)<br />
			<a href="|.$self->getUrl('func=refundItem;badgeId='.$badgeId.';transactionItemId='.join(';transactionItemId=', @itemIds)).q|">|.$i18n->get('refund').q|</a>
			</p><br />|;
	}

	$output .= q|
				</div>
			</div>
		</div>
		<div id="ft"></div>
	</div>
	|;

	# render
	$session->style->setLink($session->url->extras('/yui/build/reset-fonts-grids/reset-fonts-grids.css'), {rel=>"stylesheet", type=>"text/css"});
	$session->style->setRawHeadTags(q|
		<style type="text/css">
		.manageRegistrant tbody tr td { padding: 2px;}
		</style>
		|);
	return $self->processStyle($output);
}

#-------------------------------------------------------------------

=head2 www_moveEventMetaFieldDown ( )

Method to move an event down one position in display order

=cut

sub www_moveEventMetaFieldDown {
	my $self = shift;
	return $self->session->privilege->insufficient unless ($self->canEdit);
	$self->moveCollateralDown('EMSEventMetaField', 'fieldId', $self->session->form->get("fieldId"));
	return $self->www_manageEventMetaFields;
}

#-------------------------------------------------------------------

=head2 www_moveEventMetaFieldUp ( )

Method to move an event metdata field up one position in display order

=cut

sub www_moveEventMetaFieldUp {
	my $self = shift;
	return $self->session->privilege->insufficient unless ($self->canEdit);
	$self->moveCollateralUp('EMSEventMetaField', 'fieldId', $self->session->form->get("fieldId"));
	return $self->www_manageEventMetaFields;
}

#-------------------------------------------------------------------

=head2 www_printBadge ( )

Prints a badge using a template.

=cut

sub www_printBadge {
	my $self = shift;
	my $session = $self->session;
	return $session->privilege->insufficient unless ($self->isRegistrationStaff);
	my $form = $session->form;
	my $registrant = $self->getRegistrant($form->get('badgeId'));
	my $badge = WebGUI::Asset::Sku::EMSBadge->new($session, $registrant->{badgeAssetId});
	$registrant->{badgeTitle} = $badge->getTitle;
	return $self->processTemplate($registrant,$self->get('printBadgeTemplateId'));
}

#-------------------------------------------------------------------

=head2 www_printTicket ( )

Prints a ticket using a template.

=cut

sub www_printTicket {
	my $self = shift;
	my $session = $self->session;
	return $session->privilege->insufficient unless ($self->isRegistrationStaff);
	my $form = $session->form;
	my $registrant = $self->getRegistrant($form->get('badgeId'));
	my $ticket = WebGUI::Asset::Sku::EMSTicket->new($session, $form->get('ticketAssetId'));
	$registrant->{ticketTitle} = $ticket->getTitle;
        my $startTime = WebGUI::DateTime->new($ticket->get('startDate'))->set_time_zone($self->get('timezone'));
	$registrant->{ticketStart} = $startTime->strftime('%F %R');
	$registrant->{ticketDuration} = $ticket->get('duration');
	$registrant->{ticketLocation} = $ticket->get('location');
	$registrant->{ticketEventNumber} = $ticket->get('eventNumber');
	return $self->processTemplate($registrant,$self->get('printTicketTemplateId'));
}


#-------------------------------------------------------------------

=head2 www_refundItem ()

Removes a ribbon, token, or ticket or badge that is attached to a registrant.

=cut

sub www_refundItem {
	my $self = shift;
	my $session = $self->session;
    return $session->privilege->insufficient() unless $self->canView;
	my @itemIds = $session->form->param("transactionItemId");
	foreach my $id (@itemIds) {
		my $item = eval{WebGUI::Shop::TransactionItem->newByDynamicTransaction($session, $id)};
		if (WebGUI::Error->caught('WebGUI::Error::InvalidParam')) {
			$session->log->warn('Got "'.$@.'" which probably means we are working on a registrant that was migrated, and cannot be refunded.');
			$self->www_manageRegistrant();
		}
		if (defined $item) {
			$item->issueCredit;
		}
	}
	return $self->www_manageRegistrant();	
}


#-------------------------------------------------------------------

=head2 www_removeItemFromBadge ()

Removes a ribbon, token, or ticket from a badge that is in the cart.

=cut

sub www_removeItemFromBadge {
	my $self = shift;
	my $session = $self->session;
    return $session->privilege->insufficient() unless $self->canView;
    my $form = $session->form;
	my $cart = WebGUI::Shop::Cart->newBySession($session);
	my $item = $cart->getItem($form->get('itemId'));
    $item->remove;
	return $self->www_getRegistrantAsJson();	
}


#-------------------------------------------------------------------

=head2 www_toggleRegistrantCheckedIn ()

Toggles the registrant checked in flag.

=cut

sub www_toggleRegistrantCheckedIn {
	my $self = shift;
	return $self->session->privilege->insfufficient() unless ($self->isRegistrationStaff);
	my $db = $self->session->db;
	my $badgeId = $self->session->form->param('badgeId');
	my $flag = $db->quickScalar("select hasCheckedIn from EMSRegistrant where badgeId=?",[$badgeId]);
	$flag = ($flag == 1) ? 0 : 1;
	$db->write("update EMSRegistrant set hasCheckedIn=? where badgeId=?",[$flag, $badgeId]);
	return $self->www_manageRegistrant;
}


#-------------------------------------------------------------------

=head2 www_viewSchedule ()

View the schedule table.

=cut

sub www_viewSchedule {
	my $self             = shift;
    return $self->session->privilege->insufficient() unless $self->canView;
    my $rowsPerPage      = 25;
    my $locationsPerPage = $self->get('scheduleColumnsPerPage');

    my @columnNames = map { "'col" . $_ . "'" } ( 1..$locationsPerPage );
    my $fieldList   = join ',', @columnNames;
    my $dataColumns = join ",\n",  map {
	    '{key:' . $_ . ',sortable:false,label:"",formatter:formatViewScheduleItem}'
                     }  @columnNames;

	return $self->processStyle(
               $self->processTemplate({
                      backUrl => $self->getUrl,
                      rowsPerPage => $rowsPerPage,
                      dataColumns => $dataColumns,
                      fieldList => $fieldList,
                      dataSourceUrl => $self->getUrl('func=getScheduleDataJSON'),
                  },$self->get('scheduleTemplateId')));

}

#---------------------------------------------
=head2 www_viewSubmissionQueue

=cut

sub www_viewSubmissionQueue {
	my $self             = shift;
        my $isRegistrationStaff = $self->isRegistrationStaff;
        my $canSubmit = $self->canSubmit;
        my $canEdit = $self->canEdit;
	my $i18n = $self->i18n;
    return $self->session->privilege->insufficient() unless $canSubmit || $isRegistrationStaff;

	my $QueueTabData = 
               $self->processTemplate({
                      backUrl => $self->getUrl,
		      isRegistrationStaff => $isRegistrationStaff,
		      canEdit		=> $canEdit,
		      mainUrl    => $self->getUrl,
		      canSubmit => $canSubmit,
		      hasSubmissionForms => $self->hasSubmissionForms,
		      getSubmissionQueueDataUrl => $self->getUrl('func=getAllSubmissions'),
		      addSubmissionFormUrl => $self->getUrl('func=addSubmissionForm'),
		      editSubmissionFormUrl =>  $self->getUrl('func=editSubmissionForm'), 
		      addSubmissionUrl => $self->getUrl('func=addSubmission'),
                  },$self->get('eventSubmissionQueueTemplateId'));

	return $self->processStyle( 
               $self->processTemplate({ 
                      queueTabTitle   => $isRegistrationStaff ? $i18n->get('submission queue') : $i18n->get('my submissions'),
                      queueTabData   => $QueueTabData,
                      backUrl => $self->getUrl,
		      isRegistrationStaff => $isRegistrationStaff,
		      canEdit			=> $canEdit,
		      canSubmit => $canSubmit,
		      hasSubmissionForms => $self->hasSubmissionForms,
		      getSubmissionQueueDataUrl => $self->getUrl('func=getAllSubmissions'),
		      addSubmissionFormUrl => $self->getUrl('func=addSubmissionForm'),
		      editSubmissionFormUrl =>  $self->getUrl('func=editSubmissionForm'), 
		      addSubmissionUrl => $self->getUrl('func=addSubmission'),
                  },$self->get('eventSubmissionMainTemplateId')));
}

1;


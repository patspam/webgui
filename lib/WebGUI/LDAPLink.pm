package WebGUI::LDAPLink;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2005 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut


use strict;
use Tie::CPHash;
use WebGUI::International;
use WebGUI::Session;
use WebGUI::SQL;
use Net::LDAP;

=head1 NAME

Package WebGUI::LDAPLink

=head1 DESCRIPTION

This package contains utility methods for WebGUI's ldap link system.

=head1 SYNOPSIS

 use WebGUI::LDAPLink;
 $hashRef = WebGUI::LDAPLink::getList();
 %ldapLink = WebGUI::LDAPLink::get($ldapLinkId);
 
 $ldapLink = WebGUI::LDAPLink->new($ldapLinkId);
 $connection = $ldapLink->authenticate();
 $ldapLink->disconnect;

=head1 METHODS

These subroutines are available from this package:

=cut

=head2 bind ( )

Authenticates against the ldap server with the parameters stored in the class, returning a valid ldap connection, or 0 if a connection
cannot be established

=cut
#-------------------------------------------------------------------
sub bind {
	my $class = shift;
	my ($uri, $ldap, $auth, $result, $error);
	
	if (defined $class->{_connection}) {
		return $class->{_connetcion};
	}
	
	my $ldapUrl = $class->{_ldapLink}->{ldapUrl};
	my $connectDn = $class->{_ldapLink}->{connectDn};
	my $identifier = $class->{_ldapLink}->{identifier};
		
	if($ldapUrl eq "") {
	   $class->{_error} = 100;
	   return 0;
	} elsif ($connectDn eq "") {
	   $class->{_error} = 101;
	   return 0;
	} elsif ($identifier eq "") {
	   $class->{_error} = 102;
	   return 0;
	}
	
	if($uri = URI->new($ldapUrl)) {
	   unless($ldap = Net::LDAP->new($uri->host, (port=>($uri->port || 389)))){
	      $class->{_error} = 103;
		  return 0;
	   }
	   
	   $auth = $ldap->bind(dn=>$connectDn, password=>$identifier);
       if ($auth->code == 48 || $auth->code == 49){
		  $class->{_error} = 104;
	   }elsif($auth->code > 0){
	      $class->{_error} = $auth->code;
	   }
	   $class->{_connection} = $ldap;
	}else{
	   $class->{_error} = 105;
	   return 0;
	}
	return $class->{_connection};
}

#-------------------------------------------------------------------
sub DESTROY {
   my $class = shift;
   $class->unbind;
}

#-------------------------------------------------------------------
=head2 getErrorMessage ( [ldapErrorCode] )

Returns the error string representing the error code generated by Net::LDAP.  If no code is passed in,
the most recent error stored by the class is returned

=head3 ldapErrorCode

A valid ldap error code.

=cut

sub getErrorMessage {
   my $class = shift;
   my $errorCode = $_[0] || $class->{_error};
   return "" unless $errorCode;
   my $i18nCode = "LDAPLink_".$errorCode;
   return WebGUI::International::get($i18nCode);
}

#-------------------------------------------------------------------
=head2 getList ( )

Returns a hash reference  containing all ldap links.  The format is:
	ldapLinkId => ldapLinkName

=cut

sub getList {
    my %list;
	tie %list, "Tie::IxHash";
	%list = ('0'=>WebGUI::International::get("ldap link"),WebGUI::SQL->buildHash("select ldapLinkId, ldapLinkName from ldapLink order by ldapLinkName"));
	return \%list;
}

#-------------------------------------------------------------------
=head2 get ( ldapLinkId )

Returns a hashRef containing a single ldap link.

=head3 ldapLinkId

A valid ldapLinkId

=cut

sub get {
   my %hash;
   tie %hash, 'Tie::CPHash';
   %hash = WebGUI::SQL->quickHash("select * from ldapLink where ldapLinkId=".quote($_[0]));
   return \%hash;
}

#-------------------------------------------------------------------
=head2 unbind ( )

Disconnect cleanly from the current databaseLink.

=cut

sub unbind {
	my ($class, $value);
	$class = shift;
	$value = shift;
	if (defined $class->{_connection}) {
		$class->{_connection}->unbind;
	}
}

#-------------------------------------------------------------------

=head2 new ( ldapLinkId )

Constructor.

=head3 ldapLinkId

The ldapLinkId of the ldapLink you're creating an object reference for. 

=cut

sub new {
    my ($class, $ldapLinkId, $ldapLink);
    $class = shift;
	$ldapLinkId = shift;
	return undef unless $ldapLinkId;
	$ldapLink = get($ldapLinkId);
	bless {_ldapLinkId => $ldapLinkId, _ldapLink => $ldapLink }, $class;
}

1;
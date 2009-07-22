package WebGUI::Crypt::Provider::Simple;
use strict;
use warnings;
use Class::InsideOut qw{ :std };
use Crypt::CBC;
use Params::Validate qw(:all);
Params::Validate::validation_options( on_fail => sub { WebGUI::Error::InvalidParam->throw( error => shift ) } );

=head1 NAME

WebGUI::Crypt::Provider::Simple

=head1 DESCRIPTION

Simple Crypt provider for WebGUI

Simple in the sense that the encryption key is stored in your site config file. Encryption is carried out via L<Crypt::CBC>.

You can choose a cipher class class to use from the following:

=over 3

=item L<Crypt::DES>

=item L<Crypt::DES_EDE3>

=item L<Crypt::IDEA>

=item L<Crypt::Blowfish>

=item L<Crypt::CAST5>

=item L<Crypt::Rijndael>

=back

The default is L<Crypt::Rijndael>, which is recommended for simple compatibility with openssl. 
See t/Crypt/OpenSSL.t for an example of how to manually decrypt data using the openssl command-line binary.

You can specify a fixed salt (hello rainbow table attack), or leave it undefined to have a random salt used (the default).

See L<Crypt::CBC> for more information.

=head1 SYNOPSIS

=head1 METHODS

These methods are available from this package:

=cut

# InsideOut object properties
readonly session => my %session;    # WebGUI::Session object
public providerId  => my %providerId;
private cipher   => my %cipher;

#-------------------------------------------------------------------

=head2 new ( session, config )

Constructor.

=head3 session

A reference to the current session.

=head3 config

Crypt config object

=cut

sub new {
    my $class = shift;
    my $session = shift;
    my %opts = validate(@_, { providerId => 1, provider => 1, name => 1, key => 1, cipher => { default => 'Crypt::Rijndael' }, salt => { default => 1 } });
    
    # Check arguments..
    if ( !defined $session || !$session->isa('WebGUI::Session') ) {
        WebGUI::Error::InvalidParam->throw(
            param => $session,
            error => 'Need a session.'
        );
    }

    my $cipher_class = $opts{cipher};
    
    # Make sure cipher_class module available
    eval { WebGUI::Pluggable::load($cipher_class) };
    if ($@) {
        WebGUI::Error->throw(error => "Unable to load crypt simple provider cipher class $cipher_class: $@");
    }
    
    if ($opts{salt} ne '1' && length $opts{salt} != 8) {
        WebGUI::Error->throw(error => "Salt must be exactly 8 bytes long");
    }

    # Register Class::InsideOut object..
    my $self = register 'WebGUI::Crypt::Provider::Simple';

    # Initialise object properties..
    my $id = id $self;
    $session{$id} = $session;
    $providerId{$id} = $opts{providerId};

    $cipher{$id}  = Crypt::CBC->new(
        -key    => $opts{key},
        -cipher => $cipher_class,
        -header => 'salt',
        -salt   => $opts{salt},
    );
    return $self;
}

#-------------------------------------------------------------------

=head2 encrypt ( $plaintext )

Encrypt some plaintext

=cut

sub encrypt {
    my ( $self, $plaintext ) = @_;
    return $cipher{ id $self}->encrypt($plaintext);
}

#-------------------------------------------------------------------

=head2 decrypt ( $ciphertext )

Decrypt some ciphertext

=cut

sub decrypt {
    my ( $self, $ciphertext ) = @_;
    return if not defined $ciphertext;
    return $cipher{ id $self}->decrypt($ciphertext);
}

1;

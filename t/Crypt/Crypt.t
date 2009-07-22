# Tests WebGUI::Crypt
#
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Test::Deep;
use Exception::Class;

use WebGUI::Test;    # Must use this before any other WebGUI modules
use WebGUI::CryptTest;

#----------------------------------------------------------------------------
# Init
my $session = WebGUI::Test->session;

#----------------------------------------------------------------------------
# Create test data
my $ct = WebGUI::CryptTest->new( $session, 'Crypt.t' );

#----------------------------------------------------------------------------
# Tests
WebGUI::Error->Trace(1);    # Turn on tracing of uncaught Exception::Class exceptions
plan tests => 32;

#----------------------------------------------------------------------------
# put your tests here
use_ok('WebGUI::Crypt');

#----------------------------------------------------------------------------
# constructor
{
    eval { my $crypt = WebGUI::Crypt->new() };
    my $e = Exception::Class->caught();
    isa_ok( $e, 'WebGUI::Error::InvalidParam', 'new takes exception to missing session object' );
}
{
    isa_ok( WebGUI::Crypt->new($session), 'WebGUI::Crypt', 'Returns a happy WebGUI::Crypt' );
}

#----------------------------------------------------------------------------
# Config File has crypt settings
{
    is( ref $session->config->get('crypt'), 'HASH', 'Config file has the crypt hash' );
}

#----------------------------------------------------------------------------
# session->crypt
{

    # This test requires that your webgui site config file contains crypt settings
    my $crypt = $session->crypt;
    isa_ok( $crypt, 'WebGUI::Crypt', 'session contructor works too' );
}

#----------------------------------------------------------------------------
# session->crypt->getProviders
{
    cmp_deeply($session->crypt->getProviders, {
        None => 'None',
        SimpleTest => "Test Simple Provider - delete me",
        SimpleTest2 => "Test Simple Provider2 - Blowfish",
        SimpleTest3 => "Test Simple Provider3 - unsalted",
    }, 'getProviders gives us all of the providers created by WebGUI::CryptTest');
}
#----------------------------------------------------------------------------
# session->crypt->setProvider
{
    eval { $session->crypt->setProvider() };
    my $e = Exception::Class->caught();
    isa_ok( $e, 'WebGUI::Error::InvalidParam', 'Must provide arguments to setProvider' );
}
{
    eval { $session->crypt->setProvider( {} ) };
    my $e = Exception::Class->caught();
    isa_ok( $e, 'WebGUI::Error::InvalidParam', 'Must provide valid arguments to setProvider' );
}
{
    is( $session->crypt->setProvider(
            { table => 'encryptTest', field => 'testField', key => 'id', providerId => 'None' }
        ),
        1,
        'Valid arguments should set the provider'
    );
    is( $session->crypt->setProvider(
            { table => 'encryptTest', field => 'testField', key => 'id', providerId => 'SimpleTest' }
        ),
        1,
        'Valid arguments should update the provider'
    );
}

#----------------------------------------------------------------------------
# session->crypt->parseHeader
{
    my ( $a, $b ) = $session->crypt->parseHeader("hello");
    is( $a, 'None',  'No header returns the None provider' );
    is( $b, 'hello', 'No header returns the None provider and text' );
}
{
    my ( $a, $b ) = $session->crypt->parseHeader("CRYPT:None:hello");
    is( $a, 'None',  'Header returns the None provider' );
    is( $b, 'hello', 'Header returns the None provider and text' );
}
{
    my ( $a, $b ) = $session->crypt->parseHeader("CRYPT:BobJaneCryptMart:hello\n with\n newlines!");
    is( $a, 'BobJaneCryptMart',  'Header returns the correct provider' );
    is( $b, "hello\n with\n newlines!", '..and ciphertext, even when newlines present' );
}

#----------------------------------------------------------------------------
# session->crypt->isEnabled
{
    my $enabled = $session->setting->get('cryptEnabled');
    is( $session->crypt->isEnabled, $enabled, 'Does enabled show the correct setting' );
}

#----------------------------------------------------------------------------
# session->crypt->lookupProviderId
{
    eval { $session->crypt->lookupProviderId };
    my $e = Exception::Class->caught();
    isa_ok( $e, 'WebGUI::Error::InvalidParam', 'Must provide a hashref as argument' );
}
{
    eval { $session->crypt->lookupProviderId( {} ) };
    my $e = Exception::Class->caught();
    isa_ok( $e, 'WebGUI::Error::InvalidParam', 'Must provide a valid hashref as argument' );
}
{
    is( $session->crypt->lookupProviderId( { table => 'encryptTest', field => 'testField' } ),
        'SimpleTest', 'ProviderId should be SimpleTest bc we set it via setProvider' );
    ok( $session->crypt->setProvider(
            { table => 'encryptTest', field => 'testField', key => 'id', providerId => 'None' }
        ),
        '..and we can change it'
    );
    is( $session->crypt->lookupProviderId( { table => 'encryptTest', field => 'testField' } ),
        'None', '..to get a different Provider' );
}

#----------------------------------------------------------------------------
# session->_getProvider
{
    eval { $session->crypt->_getProvider() };
    my $e = Exception::Class->caught();
    isa_ok( $e, 'WebGUI::Error::InvalidParam', 'Must provide a hashref as argument' );
}
{
    eval { $session->crypt->_getProvider( {} ) };
    my $e = Exception::Class->caught();
    isa_ok( $e, 'WebGUI::Error::InvalidParam',
        'Must provide a hashref with either providerId or table and field.' );
}
{
    isa_ok( $session->crypt->_getProvider( { providerId => 'None' } ),
        'WebGUI::Crypt::Provider::None', 'There should always be a None provider to test against' );
}

#----------------------------------------------------------------------------
# session->crypt/decrypt?_hex
{
    eval { $session->crypt->encrypt() };
    my $e = Exception::Class->caught();
    isa_ok( $e, 'WebGUI::Error::InvalidParam', 'encrypt must have $plaintext defined.' );
}
{
    is( $session->crypt->decrypt(), undef, 'empty call to decrypt' );
}
{
    eval { $session->crypt->encrypt_hex() };
    my $e = Exception::Class->caught();
    isa_ok( $e, 'WebGUI::Error::InvalidParam', 'encrypt_hex must have $cyphertext defined.' );
}
{
    is( $session->crypt->decrypt_hex(), undef, 'empty call to decrypt_hex' );
}

#----------------------------------------------------------------------------
# mergeActiveProviderIds
{
    is(WebGUI::Crypt::mergeActiveProviderIds('', 'a'), 'a', q{'' + 'a' = 'a'});
    is(WebGUI::Crypt::mergeActiveProviderIds('a', 'b'), 'a,b', q{'a' + 'b' = 'a,b'});
    is(WebGUI::Crypt::mergeActiveProviderIds('a,a,b', 'c'), 'a,b,c', q{'a,a,b' + 'c' = 'a,b,c'});
}

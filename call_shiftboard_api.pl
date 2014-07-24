#!/usr/bin/perl

use warnings ('FATAL' => 'all');
use 5.014;

my $ACCESS_KEY_ID = 'Your Shiftboard API key';
my $SIGNATURE_KEY = 'Your Shiftboard API signature key -- keep this very protected';

use MIME::Base64 ();
use Digest::HMAC_SHA1 ();
use URI::Escape ();
use JSON::XS ();
use LWP::UserAgent ();

# Call the Shiftboard API's system.echo method
my %params = (
    'dinner' => 'nachos',
);
my $data = _call_api( 'system.echo', \%params );

# Print out what we got back.
use Data::Dumper ();
say Data::Dumper::Dumper( $data );

exit;

sub _call_api {
    my ( $method, $params ) = @_;

    # Convert the params to JSON
    my $json_params = JSON::XS::encode_json(\%params);

    # Take the JSON, BASE-64 encode it, then URI escape that.
    my $uri64_params = URI::Escape::uri_escape(MIME::Base64::encode_base64($json_params,''));

    # Sign this request using our secret signature key
    my $sign = "method" . $method . "params" . $json_params;
    my $signature = MIME::Base64::encode_base64( Digest::HMAC_SHA1::hmac_sha1( $sign, $SIGNATURE_KEY ), '' );

    # Assemble the URL
    my $url = join( '&',
        'https://api.shiftdata.com/api/api.cgi?jsonrpc=2.0',
        "access_key_id=$ACCESS_KEY_ID",
        "method=$method",
        "params=$uri64_params",
        "signature=$signature",
        'id=1',
    );

    # Create an http request
    my $request = HTTP::Request->new(GET => $url);

    # Pass request to the user agent and get a response back
    my $ua = LWP::UserAgent->new();
    my $response = $ua->request($request);

    # Get the returned content
    my $return_string = $response->content();

    # The API returns JSON, decode that and return the data structure.
    return JSON::XS::decode_json($return_string);
}

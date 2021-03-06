#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Monzo::Client;

$Business::Monzo::Resource::client = Business::Monzo::Client->new(
    token      => 'foo',
);

use_ok( 'Business::Monzo::Account' );
isa_ok(
    my $Account = Business::Monzo::Account->new(
        "id"          => "acc_00009237aqC8c5umZmrRdh",
        "description" => "Peter Pan's Account",
        "created"     => "2015-08-22T12:20:18Z",
        'client'      => Business::Monzo::Client->new(
            token      => 'foo',
        ),
    ),
    'Business::Monzo::Account'
);

can_ok(
    $Account,
    qw/
        url
        get
        to_hash
        as_json
        TO_JSON

        id
        description
        created
    /,
);

throws_ok(
    sub { $Account->get },
    'Business::Monzo::Exception'
);

is(
    $@->message,
    'Monzo API does not currently support getting account data',
    ' ... with expected message'
);

throws_ok(
    sub { $Account->url },
    'Business::Monzo::Exception'
);

is(
    $@->message,
    'Monzo API does not currently support getting account data',
    ' ... with expected message'
);

throws_ok(
    sub { $Account->add_feed_item },
    'Business::Monzo::Exception'
);

is(
    $@->message,
    'add_feed_item requires params: title, image_url',
    ' ... with expected message'
);

no warnings 'redefine';
*Business::Monzo::Client::api_post = sub { {} };

ok( $Account->add_feed_item(
    params => {
        title => "My custom item",
        image_url => "www.example.com/image.png",
        background_color => "#FCF1EE",
        body_color => "#FCF1EE",
        title_color => "#333",
        body => "Some body text to display",
    },
),'->add_feed_item' );

throws_ok(
    sub { $Account->register_webhook },
    'Business::Monzo::Exception'
);

is(
    $@->message,
    'register_webhook requires params: callback_url',
    ' ... with expected message'
);

*Business::Monzo::Client::api_post = sub { {
    webhook => {
        account_id => $Account->id,
        id         => "webhook_id",
        url        => 'https://foo',
    },
} };

isa_ok(
    my $Webhook = $Account->register_webhook( callback_url => 'https://foo' ),
    'Business::Monzo::Webhook',
    '->register_webhook'
);

is( $Webhook->account,$Account,'->account' );
is( $Webhook->id,'webhook_id','->id' );
is( $Webhook->callback_url,'https://foo','->callback_url' );

*Business::Monzo::Client::api_get = sub { {
    webhooks => [
        {
            account_id => $Account->id,
            id         => "webhook_id",
            url        => 'https://foo',
        },
        {
            account_id => $Account->id,
            id         => "webhook_id",
            url        => 'https://bar',
        },
    ]
} };

ok( my @webhooks = $Account->webhooks,'->webhooks' );
is( $webhooks[1]->callback_url,'https://bar',' ... has list' );

ok( $Account->to_hash,'to_hash' );
ok( $Account->as_json,'as_json' );
ok( $Account->TO_JSON,'TO_JSON' );

*Business::Monzo::Client::api_get = sub {
    {
        "balance"     => 5000,
        "currency"    => 'GBP',
        "soend_today" => 0,
    };
};

isa_ok( $Account->balance,'Business::Monzo::Balance' );

done_testing();

# vim: ts=4:sw=4:et

use t::common;
use parent qw(Test::Class);

use Play::Users;

sub setup :Tests(setup) {
    reset_db();
    Dancer::session->destroy;
}

sub get_settings_no_login :Tests {
    my $response = dancer_response GET => '/api/current_user/settings';
    is $response->status, 500;
}

sub get_settings_empty :Tests {

    for my $user (qw/ foo bar /) {
        http_json GET => "/api/fakeuser/$user";
    }

    Dancer::session login => 'foo';
    my $settings = http_json GET => '/api/current_user/settings';
    cmp_deeply $settings, {};
}

sub set_settings :Tests {

    for my $user (qw/ foo bar /) {
        http_json GET => "/api/fakeuser/$user";
    }

    Dancer::session login => 'foo';
    http_json PUT => '/api/current_user/settings', { params => {
        email => 'me@berekuk.ru', notify_likes => 1,
    } };
    my $settings;
    $settings = http_json GET => '/api/current_user/settings';
    cmp_deeply $settings, {
        email => 'me@berekuk.ru',
        notify_likes => 1,
    }, 'new settings';

    http_json PUT => '/api/current_user/settings', { params => {
        overwrite => 1,
    } };
    $settings = http_json GET => '/api/current_user/settings';
    cmp_deeply $settings, {
        overwrite => 1,
    }, 'updating settings overwrites them completely';

    http_json POST => '/api/current_user/settings', { params => {
        overwrite => 2,
    } };
    $settings = http_json GET => '/api/current_user/settings';
    cmp_deeply $settings, {
        overwrite => 2,
    }, 'POST is the same as PUT';

    Dancer::session login => 'bar';
    http_json PUT => '/api/current_user/settings', { params => {
        a => 'b', user => 'foo' # attempt to hack foo's settings
    } };
    $settings = http_json GET => '/api/current_user/settings';
    cmp_deeply $settings, {
        a => 'b',
    }, 'bar edited his own settings despite his attempt to break the app';

    Dancer::session login => 'foo';
    $settings = http_json GET => '/api/current_user/settings';
    cmp_deeply $settings, {
        overwrite => 2,
    }, 'foo settings are intact';
}

sub server_settings :Tests {
    http_json GET => "/api/fakeuser/foo";
    Dancer::session login => 'foo';

    http_json PUT => '/api/current_user/settings', { params => {
        email => 'someone@somewhere.com',
        email_confirmed => 1,
        email_confirmation_secret => 'iddqd',
    } };

    my $settings = http_json GET => '/api/current_user/settings';
    cmp_deeply $settings, {
        email => 'someone@somewhere.com',
    }, "user can't change secret or protected settings";
}

__PACKAGE__->new->runtests;

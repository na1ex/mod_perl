package TestAPI::request_rec;

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

use Apache::RequestRec ();
use Apache::RequestUtil ();

use Apache::Const -compile => 'OK';

#this test module is only for testing fields in the request_rec
#listed in apache_structures.map
#XXX: GloabalRequest test should be moved elsewhere
#     as should $| test

sub handler {
    my $r = shift;

    plan $r, tests => 42;

    #Apache->request($r); #PerlOptions +GlobalRequest takes care
    my $gr = Apache->request;

    ok $$gr == $$r;

    my $newr = Apache::RequestRec->new($r->connection, $r->pool);
    Apache->request($newr);
    $gr = Apache->request;

    ok $$gr == $$newr;

    Apache->request($r);

    ok $r->pool->isa('APR::Pool');

    ok $r->connection->isa('Apache::Connection');

    ok $r->server->isa('Apache::Server');

    for (qw(next prev main)) {
        ok (! $r->$_()) || $r->$_()->isa('Apache::RequestRec');
    }

    ok $r->the_request || 1;

    ok $r->assbackwards || 1;

    ok $r->proxyreq || 1;

    ok $r->header_only || 1;

    ok $r->protocol =~ /http/i;

    ok $r->proto_num;

    ok $r->hostname || 1;

    ok $r->request_time;

    ok $r->status_line || 1;

    ok $r->status || 1;

    ok $r->method;

    ok $r->method_number || 1;

    ok $r->allowed || 1;

    #allowed_xmethods
    #allow_methods

    ok $r->bytes_sent || 1;

    ok $r->mtime || 1;

    ok $r->headers_in;

    ok $r->headers_out;

    ok $r->err_headers_out;

    ok $r->subprocess_env;

    ok $r->notes;

    ok $r->content_type;

    ok $r->handler;

    #content_encoding
    #content_language
    #content_languages

    #user

    ok $r->ap_auth_type || 1;

    ok $r->no_cache || 1;

    {
        local $| = 0;
        ok 11  == $r->print("# buffered\n");
        ok 0  == $r->print();
        local $| = 1;
        ok 15 == $r->print('#',' ','n','o','t',' ','b','u','f','f','e','r','e','d',"\n");
    }

    #no_local_copy

    ok $r->unparsed_uri;

    ok $r->uri;

    ok $r->filename;

    my $location = '/' . Apache::TestRequest::module2path(__PACKAGE__);
    ok t_cmp($location, $r->location, "location");

    my $mtime = (stat __FILE__)[9];
    $r->mtime($mtime);

    ok $r->mtime == $mtime;

    ok $r->path_info || 1;

    ok $r->args || 1;

    #finfo
    #parsed_uri

    #per_dir_config
    #request_config

    #output_filters
    #input_filers

    #eos_sent

    Apache::OK;
}

1;
__END__
PerlOptions +GlobalRequest
package TestAPI::uri;

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

use APR::Pool ();
use APR::URI ();
use Apache::URI ();
use Apache::RequestRec ();
use Apache::RequestUtil ();

use Apache::Const -compile => 'OK';

my $location = '/' . Apache::TestRequest::module2path(__PACKAGE__);

sub handler {
    my $r = shift;

    plan $r, tests => 22;

    $r->args('query');

    # basic
    {
        my $uri = $r->parsed_uri;

        ok $uri->isa('APR::URI');

        ok t_cmp(qr/^$location/, $uri->path, "path");

        my $up = $uri->unparse;
        ok t_cmp(qr/^$location/, $up, "unparse");
    }

    # construct_server
    {
        my $server = $r->construct_server;
        ok t_cmp($server,
                 join(':', $r->get_server_name, $r->get_server_port),
                 "construct_server/get_server_name/get_server_port");
    }
    {
        my $hostname = "example.com";
        my $server = $r->construct_server($hostname);
        ok t_cmp($server,
                 join(':', $hostname, $r->get_server_port),
                 "construct_server($hostname)");
    }
    {
        my $hostname = "example.com";
        my $port     = "9097";
        my $server = $r->construct_server($hostname, $port);
        ok t_cmp($server,
                 join(':', $hostname, $port),
                 "construct_server($hostname, $port)");

    }
    {
        my $hostname = "example.com";
        my $port     = "9097";
        my $server = $r->construct_server($hostname, $port, $r->pool->new);
        ok t_cmp($server,
                 join(':', $hostname, $port),
                 "construct_server($hostname, $port, new_pool)");

    }

    # construct_url
    {
        # if no args are passed then only $r->uri will be included (no
        # query and no fragment fields)
        my $curl = $r->construct_url;
        t_debug("construct_url: $curl");
        t_debug("r->uri: " . $r->uri);
        my $parsed = APR::URI->parse($r->pool, $curl);

        ok $parsed->isa('APR::URI');

        my $up = $parsed->unparse;
        ok t_cmp(qr/$location/, $up, "unparse");

        my $path = '/foo/bar';

        $parsed->path($path);

        ok t_cmp($path, $parsed->path, "parsed path");
    }
    {
        # this time include args in the constructed url
        my $fragment = "fragment";
        $r->parsed_uri->fragment($fragment);
        my $curl = $r->construct_url(sprintf "%s?%s", $r->uri, $r->args);
        t_debug("construct_url: $curl");
        t_debug("r->uri: ", $r->uri);
        my $parsed = APR::URI->parse($r->pool, $curl);

        my $up = $parsed->unparse;
        ok t_cmp(qr/$location/, $up, 'construct_url($uri)');
        ok t_cmp($r->args,  $parsed->query, "args vs query");
    }
    {
        # this time include args and a pool object
        my $curl = $r->construct_url(sprintf "%s?%s", $r->uri, $r->args, 
                                     $r->pool->new);
        t_debug("construct_url: $curl");
        t_debug("r->uri: ", $r->uri);
        my $up = APR::URI->parse($r->pool, $curl)->unparse;
        ok t_cmp(qr/$location/, $up, 'construct_url($uri, $pool)');
    }

    # segfault test
    {
        # test the segfault in apr < 0.9.2 (fixed on mod_perl side)
        # passing only the /path
        my $parsed = APR::URI->parse($r->pool, $r->uri);
        # set hostname, but not the scheme
        $parsed->hostname($r->get_server_name);
        $parsed->port($r->get_server_port);
        #$parsed->scheme('http');
        my $expected = $r->construct_url;
        my $received = $parsed->unparse;
        t_debug("the real received is: $received");
        # apr < 0.9.2-dev + fix in mpxs_apr_uri_unparse will return
        #    '://localhost.localdomain:8529/TestAPI::uri'
        # apr >= 0.9.2 with internal fix will return
        #    '//localhost.localdomain:8529/TestAPI::uri'
        # so in order to test pre-0.9.2 and post-0.9.2-dev we massage it
        $expected =~ s|^http:||;
        $received =~ s|^:||;
        ok t_cmp($expected, $received,
                 "the bogus url is expected when 'hostname' is set " .
                 "but not 'scheme'");
    }

    # parse_uri
    {
        my $path     = "/foo/bar";
        my $query    = "query";
        my $fragment = "fragment";
        my $newr = Apache::RequestRec->new($r->connection, $r->pool);
        my $url_string = "$path?$query#$fragment";

        # new request
        $newr->parse_uri($url_string);
        ok t_cmp($path, $newr->uri, "uri");
        ok t_cmp($query, $newr->args, "args");

        my $puri = $newr->parsed_uri;
        ok t_cmp($path,     $puri->path,     "path");
        ok t_cmp($query,    $puri->query,    "query");
        ok t_cmp($fragment, $puri->fragment, "fragment");

        my $port = 6767;
        $puri->port($port);
        $puri->scheme('ftp');
        $puri->hostname('perl.apache.org');

        ok t_cmp($port, $puri->port, "port");

        ok t_cmp("ftp://perl.apache.org:$port$path?$query#$fragment",
                 $puri->unparse, "unparse");
    }

    # unescape_url
    {
        my @c = qw(one two three);
        my $url_string = join '%20', @c;

        Apache::URI::unescape_url($url_string);

        ok $url_string eq "@c";
    }

    Apache::OK;
}

1;

package TestFilter::in_str_bin_data;

# test that $r->print and $f->print handle binary data correctly
# (e.g. doesn't truncate on "\0" if there is more data after it)

use strict;
use warnings FATAL => 'all';

use Apache::RequestIO ();
use Apache::RequestRec ();
use Apache::Filter ();

use Apache::TestTrace;

use TestCommon::Utils ();

use Apache::Const -compile => qw(OK M_POST);

sub pass_through {
    my $f = shift;

    while ($f->read(my $buffer, 1024)) {
        debug "read: " . length ($buffer) . "b [$buffer]";
        $f->print($buffer);
    }

    return Apache::OK;
}

sub handler {
    my $r = shift;

    if ($r->method_number == Apache::M_POST) {
        my $data = TestCommon::Utils::read_post($r);
        my $length = length $data;
        debug "pass through $length bytes of $data\n";
        $r->print($data);
    }

    Apache::OK;
}

1;
__END__
<NoAutoConfig>
PerlModule TestFilter::in_str_bin_data
<Location /TestFilter__in_str_bin_data_filter>
    PerlInputFilterHandler TestFilter::in_str_bin_data::pass_through
    SetHandler modperl
    PerlResponseHandler TestFilter::in_str_bin_data
</Location>
<Location /TestFilter__in_str_bin_data>
    SetHandler modperl
    PerlResponseHandler TestFilter::in_str_bin_data
</Location>
</NoAutoConfig>

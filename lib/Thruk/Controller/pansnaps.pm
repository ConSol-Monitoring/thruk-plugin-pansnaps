package Thruk::Controller::pansnaps;
require Thruk::Utils::Panorama;
require Thruk::Utils;
require Template;

use warnings;
use strict;

use Thruk::Utils::IO ();

my $tabs = "$ENV{OMD_ROOT}/etc/thruk/panorama";
my $html = "$ENV{OMD_ROOT}/var/pansnaps/htdocs";
my $idlink = "/$ENV{OMD_SITE}/thruk/cgi-bin/panorama.cgi?map=";
my $t = Template->new;

sub add {
    my ($c) = @_;
    my $id = $c->req->parameters->{'id'};
    my $title = $c->req->parameters->{'title'};
    my $pname = Thruk::Utils::get_plugin_name(__FILE__, __PACKAGE__);
    my $ppath = $c->config->{plugin_path};
    my $not_ready = "$ppath/plugins-enabled/$pname/not_ready.jpg";
    my $out = "";
    $t->process("_pansnaps_id.tt", {
        id => $id,
        title => $title,
    }, \$out) || die $t->error();
    Thruk::Utils::IO::write("$html/$id.html", $out);
    system({ "/bin/cp" } "/bin/cp", "$not_ready", "$html/$id.jpg");
    $c->{rendered} = 1;
    $c->res->body("<ok/>");
    return;
}

sub remove {
    my ($c) = @_;
    my $id = $c->req->parameters->{'id'};
    unlink("$html/$id.html");
    unlink("$html/$id.png");
    unlink("$html/$id.jpg");
    $c->{rendered} = 1;
    $c->res->body("<ok/>");
    return;
}

sub index {
    my ( $c ) = @_;

    my $dashboards = [
        @{ Thruk::Utils::Panorama::get_dashboard_list($c, 'my') // [] },
        @{ Thruk::Utils::Panorama::get_dashboard_list($c, 'public') // [] },
    ];
    for my $d (@{$dashboards}) {
       $d->{published} = -e "$html/$d->{nr}.html"
    }

    $dashboards = [ sort { $a->{name} cmp $b->{name} } @{$dashboards} ];

    $c->stash->{OMD_ROOT}      = $ENV{OMD_ROOT};
    $c->stash->{OMD_SITE}      = $ENV{OMD_SITE};
    $c->stash->{dashboards}    = $dashboards;
    $c->stash->{template}      = 'pansnaps.tt';
    $c->stash->{'plugin_name'} = Thruk::Utils::get_plugin_name(__FILE__, __PACKAGE__);
    return;
}

1;

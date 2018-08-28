package Thruk::Controller::pansnaps;
require Thruk::Utils::Panorama;
require Thruk::Utils;
require Template;

use strict;
use warnings;

my $tabs = "$ENV{OMD_ROOT}/etc/thruk/panorama";
my $html = "$ENV{OMD_ROOT}/var/pansnaps/htdocs";
my $idlink = "/$ENV{OMD_SITE}/thruk/cgi-bin/panorama.cgi?map=";
my $t = Template->new;
my $id_template;

sub add {
    my ($c) = @_;
    my $id = $c->req->parameters->{'id'};
    my $title = $c->req->parameters->{'title'};
    my $pname = Thruk::Utils::get_plugin_name(__FILE__, __PACKAGE__);
    my $ppath = $c->config->{plugin_path};
    my $not_ready = "$ppath/plugins-enabled/$pname/not_ready.jpg";
    my $out = "";
    $t->process(\$id_template, {
        id => $id,
        title => $title,
    }, \$out) || die $t->error();
    open(my $f, ">", "$html/$id.html") or die($!);
    print $f $out;
    close($f) or die($!);
    system({ "ln" } "ln", "$not_ready", "$html/$id.jpg");
    $c->{rendered} = 1;
    $c->res->body("<ok/>");
}

sub remove {
    my ($c) = @_;
    my $id = $c->req->parameters->{'id'};
    unlink("$html/$id.html");
    unlink("$html/$id.png");
    unlink("$html/$id.jpg");
    $c->{rendered} = 1;
    $c->res->body("<ok/>");
}

sub index {
    my ( $c ) = @_;

    my $dashboards = Thruk::Utils::Panorama::get_dashboard_list($c, 'my');
    for my $d (@$dashboards) {
       $d->{published} = -e "$html/$d->{nr}.html"
    }

    $dashboards = [ sort { $a->{name} cmp $b->{name} } @$dashboards ];

    $c->stash->{OMD_ROOT} = $ENV{OMD_ROOT};
    $c->stash->{OMD_SITE} = $ENV{OMD_SITE};
    $c->stash->{dashboards} = $dashboards;
    $c->stash->{template} = 'pansnaps.tt';
}

$id_template = << 'EOT';
<!doctype html>
<html>
    <head>
        <meta charset="utf-8">      
        <title>[% title %]</title>
    </head>

    <body>

    <!-- Get the initial image. -->
    <img id="frame" src="[% id %].jpg" style="display: block; margin-left: auto; margin-right: auto; width: 100%;">

    <script>        
        document.addEventListener("DOMContentLoaded", () => {
            let reload_interval = 10* 1000;
            let timeout_interval = 60 * 1000;

            let img = document.getElementById("frame");
            let timeout_function = () => {
                alert("Reloading image failed");
            }
            let timeout = setTimeout(timeout_function, timeout_interval);

            img.addEventListener("load", () => {
                clearTimeout(timeout)
                timeout = setTimeout(timeout_function, timeout_interval);
                //let d = new Date;
                //document.getElementById("loadtime").innerHTML=d.toLocaleDateString() + " " + d.toLocaleTimeString()
            });

            let updateImage = () => {
                let img = document.getElementById("frame");
                img.src = "[% id %].jpg?" + (new Date).getTime();
                setTimeout(updateImage, reload_interval);
            }

            setTimeout(updateImage, reload_interval);
        });
    </script>
    </body>
</html>
EOT


1;

package Thruk::Controller::pansnaps;
require Thruk::Utils::Panorama;
require Thruk::Utils;
require Template;

use warnings;
use strict;

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

    $c->stash->{OMD_ROOT} = $ENV{OMD_ROOT};
    $c->stash->{OMD_SITE} = $ENV{OMD_SITE};
    $c->stash->{dashboards} = $dashboards;
    $c->stash->{template} = 'pansnaps.tt';
    return;
}

$id_template = << 'EOT';
<!doctype html>
<html>
    <head>
        <meta charset="utf-8">
        <title>[% title %]</title>
    <style>
        .container {
            position: relative;
            text-align: center;
        }
        .top-right {
            position: absolute;
            top: 3px;
            right: 16px;
        }
    </style>
    </head>

    <body>

    <!-- Get the initial image. -->
    <div class="container">
    <img id="frame" src="[% id %].jpg" style="display: block; margin-left: auto; margin-right: auto; width: 100%;">
    <span class="top-right" id="showtime"></span>
    </div>

    <script>
        document.addEventListener("DOMContentLoaded", () => {
            const reload_interval = 10* 1000;
            const timeout_interval = 60 * 1000;

            const img = document.getElementById("frame");
            const timeout_function = () => {
                alert("Reloading image failed");
            }
            let timeout = setTimeout(timeout_function, timeout_interval);

            const showtime = document.getElementById("showtime")
            const updateTime = () => {
                const date = new Date
                const year = date.getUTCFullYear().toString();
                const month = (date.getUTCMonth() + 1).toString().padStart(2,'0')
                const day  = date.getUTCDate().toString().padStart(2,'0');
                const hour = date.getUTCHours().toString().padStart(2,'0');
                const min  = date.getUTCMinutes().toString().padStart(2,'0');
                showtime.innerHTML = `${year}-${month}-${day} ${hour}:${min} UTC`
                setTimeout(updateTime, 1000);
            }
            setTimeout(updateTime, 1000);

            img.addEventListener("load", () => {
                clearTimeout(timeout)
                timeout = setTimeout(timeout_function, timeout_interval);
            });

            const updateImage = () => {
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

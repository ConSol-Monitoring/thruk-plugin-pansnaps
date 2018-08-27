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
    my $pname = Thruk::Utils::get_plugin_name(__FILE__, __PACKAGE__);
    my $ppath = $c->config->{plugin_path};
    my $not_ready = "$ppath/plugins-enabled/$pname/not_ready.jpg";
    my $out = "";
    $t->process(\$id_template, {
        id => $id,
    }, \$out) || die $t->error();
    open(my $f, ">", "$html/$id.html") or die($!);
    print $f $out;
    close($f) or die($!);
    system({ "ln" } "ln", "$not_ready", "$html/$id.jpg");
    $c->{rendered} = 1;
    $c->res->body("");
}

sub remove {
    my ($c) = @_;
    my $id = $c->req->parameters->{'id'};
    unlink("$html/$id.html");
    unlink("$html/$id.png");
    unlink("$html/$id.jpg");
    $c->{rendered} = 1;
    $c->res->body("");
}

sub index {
    my ( $c ) = @_;

    my $dashboards = Thruk::Utils::Panorama::get_dashboard_list($c, 'my');
    for my $d (@$dashboards) {
       $d->{published} = -e "$html/$d->{nr}.html"
    }
    $c->stash->{OMD_ROOT} = $ENV{OMD_ROOT};
    $c->stash->{OMD_SITE} = $ENV{OMD_SITE};
    $c->stash->{dashboards} = $dashboards;
    $c->stash->{title}           = 'Pansnaps!';
    $c->stash->{'subtitle'}              = 'Pansnaps!';
    $c->stash->{'infoBoxTitle'}          = 'Pansnaps!';
    $c->stash->{'no_auto_reload'}      = 1;
    $c->stash->{template} = 'pansnaps.tt';
}

$id_template = << 'EOT';
<!doctype html>
<html>
    <head>
        <meta charset="utf-8">      
        <title>Image Refresh</title>
    </head>

    <body>

    <!-- Get the initial image. -->
    <img id="frame" src="[% id %].jpg" style="display: block; margin-left: auto; margin-right: auto; width: 100%;">

    <script>        
        // Use an off-screen image to load the next frame.
        var img = new Image();

        // When it is loaded...
        img.addEventListener("load", function() {

            // Set the on-screen image to the same source. This should be instant because
            // it is already loaded.
            document.getElementById("frame").src = img.src;

            // Schedule loading the next frame.
            setTimeout(function() {
                img.src = "[% id %].jpg?" + (new Date).getTime();
            }, 1000/15); // 15 FPS (more or less)
        })

        // Start the loading process.
        img.src = "[% id %].jpg?" + (new Date).getTime();
    </script>
    </body>
</html>
EOT


1;

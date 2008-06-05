#!/usr/bin/perl

package JSH::Test::HTTP::Server::Simple;

our $VERSION = '0.07';

use warnings;
use strict;
use Carp;

use NEXT;

my @CHILD_PIDS;
$SIG{INT} = sub { warn "INT:$$"; exit 0};

END {
        my $done = not @CHILD_PIDS;
        while (not $done) {
            kill 'USR1', @CHILD_PIDS;
            local $SIG{ALRM} = sub {die "XX"};
            alarm(5);
            eval { 1 while $_ = wait and $_ > 0; };
            alarm(0);
            $done = not $@;
        }
    exit(0);
} 

sub started_ok {
    my $self = shift;

    my $pid;

    $self->{'test_http_server_simple_parent_pid'} = $$;

    my $child_loaded_yet = 0;
    local %SIG;
    $SIG{'USR1'} = sub { $child_loaded_yet = 1; exit(0) unless $self->{'test_http_server_simple_parent_pid'} == $$ };


    $pid = $self->background;
    push @CHILD_PIDS, $pid;
    1 while not $child_loaded_yet;


    return "http://localhost:".$self->port
}

sub setup_listener {
    my $self = shift;
    $self->NEXT::setup_listener;
        kill 'USR1', $self->{'test_http_server_simple_parent_pid'};
}

sub pids {
    return @CHILD_PIDS;
}


package JSH::Server;
use base qw/JSH::Test::HTTP::Server::Simple HTTP::Server::Simple::CGI/;
use Path::Class;

sub load_server {
        my $self = shift;
        $self->{'payload'} = shift;

}

sub handle_request {
        my $self = shift;
        my $cgi = shift;
        if ($ENV{'REQUEST_URI'} eq '/done') {
               print "HTTP/1.0 200 OK\n";
               print "Content-Type: text/html\n\n";
               print "<h1>Done!</h1>\n";        
                $self->{'test_result'} = $cgi->param('POSTDATA');
        }
        elsif ($ENV{'REQUEST_URI'} eq '/results') {
               print "HTTP/1.0 200 OK\n";
               print "Content-Type: text/tap\n\n";
                print $self->{'test_result'} || 'not yet';

                


        }
        elsif ($self->{'payload'}) {
                 print "HTTP/1.0 200 OK\n";
                print "Content-Type: text/html\n\n";
                 print $self->{'payload'};
                 print "\n";
        
                 delete $self->{'payload'}; 
        } elsif ($ENV{'REQUEST_URI'} =~ /\/(.*\.js)$/) { 
            my $file = $1;
                warn "outputting content of $file";
            if (-f $file) {
                 print "HTTP/1.0 200 OK\n";
                print "Content-Type: text/javascript\n\n";
                print file($file)->slurp; 
            } else {
                 print "HTTP/1.0 404 not found\n";

            }
                
        } elsif($ENV{'REQUEST_URI'} ne '/favicon.ico') {
               use YAML;
               warn YAML::Dump(\%ENV, $cgi);

        } 
}

sub print_banner {}
package main;

use Path::Class;
my $source=file($ENV{'JS_TEST'}||'test.js.t')->slurp();
my @libs  = split(/\n/,file($ENV{'JS_LIBS'}||'js-libs')->slurp());

my $server = JSH::Server->new( 8000+ int(rand(1000)));
$server->load_server(<<"EOF");
<html>
<head>
</head>
<body>
<pre id="results"># Javascript. TAP. Lurking Horror
</pre>
<script>

var counter = 0;

function say(msg) {
    var output = document.getElementById("results").firstChild;
    output.appendData(msg);
    output.appendData("\\n");
}

function diag(msg) {
        say("# "+msg);
}


var test_plan;

function plan(count) {
    test_plan = count;
    say('1..'+test_plan);

}



function use_ok(path, reason) {
    if (!reason) reason = 'Loading ' + path;
    var used_ok = '';
    var used_ok_msg = '';
    var tmp = window.onerror;
    window.onerror = function (msg,url,line) { used_ok = -1; used_ok_msg = msg + " line "+line }


   function loaded_ok() {diag('loaded!');  _pass(reason);}

   var head= document.getElementsByTagName('head')[0];
   var script= document.createElement('script');
   script.type= 'text/javascript';
   script.onreadystatechange= function () {
      if (this.readyState == 'complete') loaded_ok();
   }
   script.onload= loaded_ok;
   script.src= path;
   head.appendChild(script);


    if (used_ok === -1) {
        diag(used_ok_msg);
        _fail(reason);
    }

    window.onerror= tmp;

}

function _pass (msg) { 
    say("ok " + ++counter  + " " +msg);
}

function _fail (msg) { 
    say("not ok " + ++counter  + " " +msg);
}



function ok (exp, msg) {
    if(eval(exp)) {
       _pass(msg);
    } else {
       _fail(msg);
    }
}






@{[$source]}


</script>
<script>
function done() {
    if (! test_plan) {
        plan(counter);
    }
  if (window.XMLHttpRequest) {
    req = new XMLHttpRequest();
  } else if (window.ActiveXObject) {
    req = new ActiveXObject("Microsoft.XMLHTTP");
  }
  if (req != undefined) {
    req.onreadystatechange = function() {}
    req.open("POST", 'http://localhost:@{[$server->port]}/done', true);
    req.send(document.getElementById('results').innerHTML);
  }
}  
done();
</script>
</body>
</html>
EOF
my $root = $server->started_ok();
my $pid = open(my $ff, "|firefox -no-remote -P testing $root") || die "firefox fail $!";
use LWP::Simple;
my $out = "not yet";
my $counter = 0;
while ( $counter++ < 30) {
 $out = get($root."/results");
    last unless ($out eq 'not yet');
    sleep 1;
 
 }
#kill 9, $pid;
close($ff);
print $out;
exit(0);

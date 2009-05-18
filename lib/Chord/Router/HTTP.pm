package Chord::Router::HTTP;
use Any::Moose;
use HTTP::Engine;

use Exporter::Lite;
our @EXPORT = qw(route GET POST PUT HEAD);

use Chord::GlobalConfig;

sub GET  { "GET"  }
sub POST { "POST" }
sub PUT  { "PUT"  }
sub HEAD { "HEAD" }

our $routing = [];

sub route ($;%) {
	my ($path, %opts) = @_;
	my $regexp  = "^$path\$";
	my $capture = [];

	$regexp =~ s{([:*])(\w+)}{
		my $type = $1;
		my $name = $2;
		push @$capture, $name;
		sprintf("(%s)",
			$opts{$name} ||
			(($type eq "*") ? ".*": "[^\/]+")
		);
	}ge;

	push @$routing, {
		%opts,
		define  => $path,
		regexp  => $regexp,
		capture => $capture,
	};
}

sub dispatch {
	my ($self, $req, $res, @opts) = @_;
	my $path   = $req->path;
	my $method = uc $req->method;
	my $params = {};
	my $action;

	for my $route (@$routing) {
		next if $route->{method} && ($route->{method} ne $method);
		if (my @capture = ($path =~ $route->{regexp})) {
			for my $name (@{ $route->{capture} }) {
				$params->{$name} = shift @capture;
			}
			$action = $route->{action};
			Chord::GlobalConfig->log(debug => ["Request: %s %s", $method, $path]);
			Chord::GlobalConfig->log(debug => ["Routing to: %s", $route->{define}]);
			last;
		}
	}

	$req->param(%$params);
	if ($action) {
		$action->($req, $res, @opts);
		$res;
	} else {
		undef;
	}
}

sub process {
	my ($self, $req, @opts) = @_;

	my $res = HTTP::Engine::Response->new(status => 200);
	$res->header("Content-Type" => "text/html");
	eval {
		unless ($self->dispatch($req, $res, @opts)) {
			$res->code(404);
			$res->content("Not Found");
		}
	}; if ($@) {
		$res->code(500);
		$res->header("Content-Type" => "text/plain");
		$res->content($@);
	}

	$res;
}

sub run {
	my ($class, %opts) = @_;

	HTTP::Engine->new(
		interface => {
			module => 'ServerSimple',
			args   => {
				host => 'localhost',
				port =>  3000,
			},
			request_handler => sub {
				my $req = shift;
				$class->new->process($req);
			},
			%opts
		},
	)->run;
}


1;
__END__




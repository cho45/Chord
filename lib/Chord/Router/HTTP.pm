package Chord::Router::HTTP;
use Any::Moose;
use HTTP::Engine;

use Exporter::Lite;
our @EXPORT = qw(route);

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
	my ($self, $request, @opts) = @_;
	my $path   = $request->path;
	my $params = {};
	my $action;

	for my $route (@$routing) {
		if (my @capture = ($path =~ $route->{regexp})) {
			for my $name (@{ $route->{capture} }) {
				$params->{$name} = shift @capture;
			}
			$action = $route->{action};
			last;
		}
	}

	my $req = $request;
	$req->param(%$params);
	my $res = HTTP::Engine::Response->new(status => 200);
	$res->header("Content-Type" => "text/html");
	if ($action) {
		eval {
			$action->($req, $res, @opts);
		}; if ($@) {
			$res->code(500);
			$res->header("Content-Type" => "text/plain");
			$res->content($@);
		}
	} else {
		$res->code(404);
		$res->content("Not Found");
	}
	$res;
}

sub process {
	my ($self, $request, @opts) = @_;

	$self->dispatch($request, @opts);
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




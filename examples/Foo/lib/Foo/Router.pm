package Foo::Router;
use Any::Moose;

use Chord::Router::HTTP;
extends "Chord::Router::HTTP";

use Foo::App;
use Foo::View;

use Data::Dumper;
sub p ($) { warn Dumper shift };

# filter

around "process" => sub {
	my ($next, $class, @args) = @_;

	my ($request) = @args;
	$request->param(
		user => app->user(session_id => $request->cookie('session_id'))
	);

	$next->($class, @args);
};

around "dispatch" => sub {
	my ($next, $class, @args) = @_;

	my ($req, $res) = @args;
	eval {
		$res = $next->($class, @args);
	};
	if (my $e = Exception::Class->caught('Foo::App::AuthorNotFound') ) {
		$res->code(404);
		$res->content(sprintf("%s is not found.", $e->error->{author}));
	}
	$res;
};

# routing

route "/",
	action => sub {
		my ($req, $res) = @_;
		html $res, {
			title   => "Hello",
			content => "Hello",
		};
	};

route "/my/*path",
	action => sub {
		my ($req, $res) = @_;
		$res->code(302);
		$res->header("Location" => sprintf("/foo/%s", $req->param("path")));
	};

route "/:author/", author => qr/[a-z][a-z0-9]{1,30}/,
	action => sub {
		my ($req, $res) = @_;
		my $app = app("User")->new(
			author_name => $req->param("author")
		);

		html $res, {
			title   => "Hello",
			content => $app->message
		};
	};

route "/api/foo",
	action => sub {
		my ($req, $res) = @_;
		json $res, {
			foo => "bar"
		};
	};

route "/die",
	action => sub {
		die "Died";
	};

1;

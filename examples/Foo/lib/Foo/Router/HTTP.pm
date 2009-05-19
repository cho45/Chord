package Foo::Router::HTTP;
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

	my $e;
	if      ($e = Exception::Class->caught('Foo::App::AuthorNotFound') ) {
		$res->code(404);
		$res->content(sprintf("%s is not found.", $e->error->{author}));
	} elsif ($e = Exception::Class->caught) {
		ref $e ? $e->rethrow : die $e;
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

route "/login",
	action => sub {
		my ($req, $res) = @_;
		my $cert = $req->param("cert");
		if (!$cert) {
			$res->code(302);
			$res->header("Location" => app->auth_api->uri_to_login);
		} else {
			my $user = app->auth_api->login($cert) or die "Couldn't login";
			$res->cookie(session_id => $user->session_id);
			meta_redirect $res => "/";
		}
	};

route "/my/*path",
	action => sub {
		my ($req, $res) = @_;
		$res->code(302);
		if ($req->param('user')) {
			$res->header("Location" => sprintf(
				"/%s/%s",
				$req->param('user')->name,
				$req->param("path")
			));
		} else {
			$res->header("Location" => sprintf(
				"/login?return_to=/%s/%s",
				$req->param('user')->name,
				$req->param("path")
			));
		}
	};

route "/:author/", author => qr/[a-z][a-z0-9]{1,30}/,
	action => sub {
		my ($req, $res) = @_;
		my $app = app("User")->new(
			author_name => $req->param("author")
		);

		html $res, { app => $app };
	};

route "/api/foo",
	method => POST,
	action => sub {
		my ($req, $res) = @_;
		json $res, {
			foo => "bar"
		};
	};

1;

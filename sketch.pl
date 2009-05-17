#!/usr/bin/env perl
package FooRouter;
use Any::Moose;

use Chord::Router::HTTP;
extends "Chord::Router::HTTP";

use Data::Dumper;
sub p ($) { warn Dumper shift };

# define views
use JSON::XS;
sub json ($$) {
	my ($res, $stash) = @_;
	$res->header("Content-Type" => "application/json");
	$res->content(encode_json($stash));
}

use Text::MicroMason;
sub html ($%) {
	my ($res, $stash) = @_;
	my $m  = Text::MicroMason->new(qw/ -SafeServerPages -AllowGlobals /);
	$m->set_globals(map { ("\$$_", $stash->{$_}) } keys %$stash);

	my $content = $m->execute(text =>  q{
		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
		<title><%= $title %></title>
		<p><%= $content %>
	});

	$res->header("Content-Type" => "text/html");
	$res->content($content);
}

# filter

around "process" => sub {
	my ($next, $class, @args) = @_;

	my ($request) = @args;
	$request->param(
		user => $request->cookie('session_id')
	);

	$next->($class, @args);
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
		html $res, {
			title   => "Hello",
			content => sprintf("This is %s's page.", $req->param("author"))
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


__PACKAGE__->run;

__END__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<title><%= title %></title>
<p><%= content %>


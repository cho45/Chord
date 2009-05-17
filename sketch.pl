#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
sub p ($) { warn Dumper shift }

use Perl6::Say;

package Chord::Engine;
# Model を組み合せていろいろやるアプリケーションロジック部分
# App 相当もの

package Chord::View;

package Chord::Router::HTTP;
use Any::Moose;

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
		define  => $path,
		regexp  => $regexp,
		capture => $capture,
	};
}

sub routing {
	my ($class, $block) = @_;

	$block->();

	use Data::Dumper;
	warn Dumper $routing;
}

sub dispatch {
	my ($self, $path) = @_;
	my $params = {};
	my $found  = 0;

	for my $route (@$routing) {
		if (my @capture = ($path =~ $route->{regexp})) {
			for my $name (@{ $route->{capture} }) {
				$params->{$name} = shift @capture;
			}
			$found = 1;
			last;
		}
	}

	if (!$found) {
		die "404 Not Found";
	}

	use Data::Dumper;
	warn Dumper $params;
}

sub process {
	my ($self, $req) = @_;

	my $res = $self->dispatch($req->path);
}



__PACKAGE__->routing(sub {
	route "/index",
		module => "Index";

	route "/my/*path",
		action => sub {
			res->redirect("/user/");
		};

	route "/help/:foobar/*rest";

	route "/:user/", user => qr/[a-z][a-z0-9]{1,30}/,
		module => "User";

	route "/:user/edit", user => qr/[a-z][a-z0-9]{1,30}/,
		before => [qw/ Filter::RequireUser /],
		after  => sub {
			if (req->method eq 'POST') {
				dispatch("");
			}
		},
		module => "User::Edit";
});


package main;
use HTTP::Engine;

HTTP::Engine->new(
	interface => {
		module => 'ServerSimple',
		args   => {
			host => 'localhost',
			port =>  3001,
		},
		request_handler => sub {
			my $req = shift;

			p $req->uri->path;

			Chord::Router::HTTP->new->process($req);

#			my $app = chord->engine("Index")->new();
#			my $res = chord->view("MicroMason")->new->process( app => $app );


			return HTTP::Engine::Response->new(
				status => 200,
				body   => 'Hello, World',
			);
		},
	},
)->run;



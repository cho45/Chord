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
		%opts,
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
	my ($self, $request) = @_;
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

	$action or die "404 Not Found";

#	use Data::Dumper;
#	warn Dumper $params;
#	warn Dumper $action;

	my $req = $request;
	$req->param(%$params);
	my $res = HTTP::Engine::Response->new(status => 200);
	$action->($req, $res);
	$res;
}

sub process {
	my ($self, $request) = @_;

	$self->dispatch($request);
}

__PACKAGE__->routing(sub {
	route "/",
		action => sub {
			my ($req, $res) = @_;
			$res->content("Hello");
		};

	route "/my/*path",
		action => sub {
			my ($req, $res) = @_;
			$res->redirect("/user/" . $req->param("path"));
		};

	route "/:author/", author => qr/[a-z][a-z0-9]{1,30}/,
		action => sub {
			my ($req, $res) = @_;
			$res->content(sprintf("This is %s's page.", $req->param("author")));
		}
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

		},
	},
)->run;



package Foo::View;

use strict;
use warnings;

use Exporter::Lite;
our @EXPORT = qw/json html/;

# define views
use JSON::XS;
sub json ($$) {
	my ($res, $stash) = @_;
	$res->header("Content-Type" => "application/json");
	$res->content(encode_json($stash));
}

use Text::MicroMason;
use Text::MicroMason::AllowGlobals;
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


1;
__END__




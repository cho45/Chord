package Foo::App;
use Any::Moose;

use Exporter::Lite;
our @EXPORT = qw/app throw/;

use Exception::Class (
	"Foo::App::Exception",
	"Foo::App::UserRequired"   => { isa => "Foo::App::Exception" },
	"Foo::App::AuthorNotFound" => { isa => "Foo::App::Exception" }
);

has author_name => (
	is => 'rw',
	isa => 'Str'
);

has author => (
	is => 'rw',
	isa => 'Any' ## Model::User
);

sub app {
	my ($name) = @_;
	return __PACKAGE__ unless $name;
	my $ret = sprintf("%s::%s", __PACKAGE__, $name);
	$ret->use or die $@;
	$ret;
}

sub throw {
	my ($name, $error) = @_;
	my $exception = sprintf("%s::%s", __PACKAGE__, $name);
	$exception->throw(error => $error);
}

sub user {
	my ($class, %opts) = @_;
	# XXX retrieve user with opts ...
	{
		name => "cho45"
	};
}

1;

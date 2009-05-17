package Foo::App::User;
use Any::Moose;

use Foo::App;

extends app;


sub message {
	my ($self) = @_;

	throw("AuthorNotFound", { author => $self->author_name }) unless $self->author_name eq 'foo';

	sprintf("This is %s's page.", $self->author_name);
}

1;

package Foo::GlobalConfig;
use Any::Moose;
extends "Chord::Config";

__PACKAGE__->setup({
	app_config => {
		default => {
		},

		devel => {
		},

		staging => {
		},

		production => {
		}
	}
});


1;
__END__




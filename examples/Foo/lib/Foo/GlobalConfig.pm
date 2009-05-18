package Foo::GlobalConfig;
use Any::Moose;
extends "Chord::GlobalConfig";

use YAML;

__PACKAGE__->setup({
	default => {
		hatena_auth => YAML::LoadFile("hatena_auth.yaml"),

		logger => {
			Screen => {
				name      => "screen",
				min_level => "debug",
				stderr    => 1,
			}
		}
	},

	devel => {
	},

	staging => {
	},

	production => {
	}
});


1;
__END__




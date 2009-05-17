#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use lib glob 'examples/*/lib';

require UNIVERSAL::require;

my $router = 'Foo::Router';
$router->use or die $@;
$router->run;


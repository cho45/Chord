package Chord::GlobalConfig;
use Any::Moose;

use Log::Dispatch;

our $config = {};
our $logger = Log::Dispatch->new;

sub setup {
	my ($class, $new) = @_;
	$config = $new;

	my $dispatchers = $class->get("logger");

	for my $name (keys %$dispatchers) {
		my $dispatch_class = sprintf("Log::Dispatch::%s", $name);
		$dispatch_class->use;
		$logger->add($dispatch_class->new(%{ $dispatchers->{$name} }));
		$class->log(debug => "Add $dispatch_class");
	}
}

sub get {
	my ($class, $name) = @_;
	$name ? $config->{$class->env}->{$name} : $config->{$class->env};
}

sub env {
	$ENV{CHORD_ENV} || 'default';
}

sub log {
	my ($class, $level, $message) = @_;

	if (ref($message) eq "ARRAY") {
		$message = sprintf(shift(@$message), @$message);
	}

	$message =~ s/^\s+|\s+$//g;

	$logger->log(level => $level, message => "$message\n");
}


1;
__END__




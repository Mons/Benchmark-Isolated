package Benchmark::Isolated;

use 5.008008;
use common::sense 2;m{
use strict;
use warnings;
};
use Carp;

=head1 NAME

Benchmark::Isolated - ...

=cut

our $VERSION = '0.01'; $VERSION = eval($VERSION);

=head1 SYNOPSIS

    package Sample;
    use Benchmark::Isolated;

    ...

=head1 DESCRIPTION

    ...

=cut


=head1 FUNCTIONS

=over 4

=item ...()

...

=back

=cut


use Benchmark ':all';
BEGIN {
	use Exporter;
	our(@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	push @ISA, 'Exporter';
	@EXPORT = ('timethose', 'cmpthese', @Benchmark::EXPORT);
	@EXPORT_OK = @Benchmark::EXPORT_OK;
	%EXPORT_TAGS=( all => [ @EXPORT, @EXPORT_OK  ] ) ;
}
use Storable;

$Benchmark::_Usage{'Isolated::timethose'} = <<'USAGE';
usage: timethose($count, { Name1 => sub { init; return 'code1' }, ... } );        or
       timethose($count, { Name1 => sub { init; return sub { code1 } }, ... });;
USAGE
;

sub timethose {
	my ($n,$alt,$style) = @_;
	die Benchmark::usage() unless ref $alt eq 'HASH';
	
	my @names = sort keys %$alt;
	$style = "" unless defined $style;
	print "Benchmark: " unless $style eq 'none';
	if ( $n > 0 ) {
		croak "non-integer loopcount $n, stopped" if int($n)<$n;
		print "timing $n iterations of" unless $style eq 'none';
	} else {
		print "running" unless $style eq 'none';
	}
	print " ", join(', ',@names) unless $style eq 'none';
	unless ( $n > 0 ) {
		my $for = Benchmark::n_to_for( $n );
		print ", each" if $n > 1 && $style ne 'none';
		print " for at least $for CPU seconds" unless $style eq 'none';
	}
	print "...\n" unless $style eq 'none';
	my %results;
	for my $name (@names) {
		pipe(my $rd,my $wr);
		if (my $pid = fork) {
			close $wr;
			waitpid $pid,0;
			my $rbuf;
			while () {
				sysread $rd, $rbuf, 16384, length $rbuf or last;
				while () {
					my $len = unpack "L", $rbuf;
					last unless $len && $len + 4 <= length $rbuf;
					my $req = Storable::thaw substr $rbuf, 4;
					substr $rbuf, 0, $len + 4, ""; # remove length + request
					die $req->[1] if ref $req eq 'ARRAY' and !defined $req->[0];
					$results{$name} = $req;
					last;
				}
			}
		}
		else {
			close $rd;
			my $r = eval {
				my $test = $alt->{$name}->($name);
				timethis $n, $test, $name, $style;
			} || [ undef, "$@" ];
			syswrite($wr, pack "L/a*", Storable::freeze( $r ));
			exit;
		}
	}
	return \%results;
}

=for rem
my %tests = (
	'A' => sub {
		my $key = shift;
		warn "preinit $key";
		return sub {
			2**10 for 1..0000;
		};
	},
	'B' => sub {
		my $key = shift;
		warn "preinit $key";
		return sub {
			2**10+100*100 for 1..00000;
		};
	}
);
my $timex = -1;
my %results;

for my $key (sort keys %tests) {
	pipe(my $rd,my $wr);
	if (my $pid = fork) {
		close $wr;
		waitpid $pid,0;
		my $rbuf;
		while () {
			sysread $rd, $rbuf, 16384, length $rbuf or last;
			while () {
				my $len = unpack "L", $rbuf;
				last unless $len && $len + 4 <= length $rbuf;
				my $req = Storable::thaw substr $rbuf, 4;
				substr $rbuf, 0, $len + 4, ""; # remove length + request
				$results{$key} = $req;
				last;
			}
		}
	}
	else {
		close $rd;
		warn "child $$";
		my $r = eval {
			my $test = $tests{$key}->($key);
			timethis $timex, $test, $key;
		} || [ undef, "$@" ];
		syswrite($wr, pack "L/a*", Storable::freeze( $r ));
		exit;
	}
}

cmpthese \%results;

=cut

=head1 AUTHOR

Mons Anderson, C<< <mons@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

=cut

1;

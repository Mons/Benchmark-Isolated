#!/usr/bin/env perl -w

use common::sense;
use lib::abs '../lib';
use Test::More tests => 2;
use Test::NoWarnings;

BEGIN {
	use_ok( 'Benchmark::Isolated' );
}

diag( "Testing Benchmark::Isolated $Benchmark::Isolated::VERSION, Perl $], $^X" );

use lib::abs '..';
use Benchmark::Isolated;

cmpthese( timethose( -0.1, {
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
} ) );

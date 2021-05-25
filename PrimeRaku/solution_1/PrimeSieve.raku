#! /usr/bin/env raku
use v6.d;

proto sub assert (|) {*}
multi sub assert ( Str:D $message ) {
    warn $message;
}
multi sub assert ( Bool:D $ where ?* ) { #= True
}
multi sub assert ( Bool:D ) { #= False
    warn 'something bad happened'
}

class Prime-Sieve {
    #| Upper limit, highest prime candidate we'll consider
    has int $.limit = 1_000_000;
    #| Storage for sieve.
    #| Since we filter out evens, just half as many bits
    has int8 @!rawbits = 1 xx ($!limit+1) div 2;
    # (there are plans for adding int1 and uint1 including in native arrays)

    #| Historical data for validating our results
    my constant %prime-counts = Hash[Int, Int](
                 10 =>       4,
                100 =>      25,
              1_000 =>     168,
             10_000 =>    1229,
            100_000 =>    9592,
          1_000_000 =>   78498,
         10_000_000 =>  664579,
        100_000_000 => 5761455,
    );

    #| Look up our count of primes in the historical data (if we have it) to see if it matches
    method validate-results ( --> Bool:D ) {
        $.count-primes == (%prime-counts{$!limit} // (2..$!limit).grep(*.is-prime).elems)
        # If we don't have it, calculate using built-in .is-prime
        # (Which is fine as it is only a sanity check)
    }

    #| Gets a bit from the array of bits, but automatically just filters out even numbers
    #| and then only half as many bits for actual storage
    method !get-bit (int $index --> int ) {
#       $index %% 2
#       ?? 0
#       !!
        @!rawbits[$index div 2]
    }

    #| Reciprocal of GetBit, ignores even numbers and just stores the odds.
    #| Since the prime sieve work should never wast time clearing even numbers
    #| this code will warn if you try to
    method !clear-bit (int $index --> Nil ) {
#       $index %% 2
#       ?? assert "clearing even bit $index"
#       !!
        @!rawbits[$index div 2] = 0
    }

    #| Calculate the primes up to the specified limit
    method run-sieve() {
        # convert to native integer so that the rest of the code
        # doesn't have to do coercions and boxing/unboxing
        my int $sqrt = Int( $!limit.sqrt );

        # No need to check evens, so skip to next odd ($factor = 3, 5, 7, 9 … ∞)
        loop ( my int $factor = 3 ; $factor < $sqrt ; $factor += 2 ) {
            # find the next factor
            next unless self!get-bit($factor);
#           for $factor..$!limit -> int $num {
#               if self!get-bit($num) {
#                   $factor = $num;
#                   last;
#               }
#           }

            # If marking factor 3, you wouldn't mark 6 (it's a multiple of 2) so start with the 3rd multiple
            # We can then step by a factor * 2 because every second one is going to be even by definition
            loop ( my int $num = $factor * 3 ; $num < $!limit ; $num += $factor * 2 ) {
                self!clear-bit($num)
            }
        }
        # return the is_prime array
        @!rawbits
    }

    #| Return the count of bits that are still set in the sieve.
    #| Assumes you've already called .runSieve()
    # (works because @!rawbits[1 div 2] is set even though we don't use it.)
    method count-primes () {
        sum @!rawbits
    }

    #| Displays the primes found (or just the total count, depending on what you ask for)
    method print-results (
        $duration,
        $passes,
        Bool:D :$show-results = False,
    ) {
        # Since we auto-filter evens, we have to special case the number 2
        print '2, ' if $show-results;

        my int $count = 1;
        for 3..$!limit -> int $num {
            if self!get-bit($num) {
                print "$num, " if $show-results;
                ++$count;
            }
            LAST put() if $show-results;
        }

        assert $count == $.count-primes;
        put "Passes: $passes, Time: $duration, Avg: {$duration/$passes}";
    }
}

sub MAIN (
    Bool:D :$show-results = False, #= Show the prime numbers
    Int:D  :$limit = 1_000_000,    #= The maximum prime candidate to check
    Real:D :$time = 5.0,           #= The minimum amount of time in seconds
    Bool:D :$validate = False,
    Bool:D :$drag-race = True,
) {
    my $start = now;
    my int $passes = 0;
    my Prime-Sieve $sieve;

    # Run until at least $time seconds have elapsed
    my $timer = Promise.in($time);
    until $timer {
        $sieve .= new(:$limit);
        $sieve.run-sieve; # gives result
        ++$passes;
    }

    my $duration = now - $start;

    if $validate && not $sieve.validate-results {
        assert False;
    }
    if $drag-race {
        put "b2gills;$passes;$duration;1"
    } else {
        $sieve.print-results( $duration, $passes, :$show-results );
    }
}

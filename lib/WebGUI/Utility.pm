package WebGUI::Utility;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2002 Plain Black LLC.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use Exporter;
use strict;
use Tie::IxHash;

our @ISA = qw(Exporter);
our @EXPORT = qw(&commify &randomizeArray &sortHashDescending &sortHash &isIn &randint &round);

#-------------------------------------------------------------------
sub commify {
 	my $text = reverse $_[0];
 	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
 	return scalar reverse $text;
}

#-------------------------------------------------------------------
sub isIn {
        my ($i, @a, @b, @isect, %union, %isect, $e);
        foreach $e (@_) {
                if ($a[0] eq "") {
                        $a[0] = $e;
                } else {
                        $b[$i] = $e;
                        $i++;
                }
        }
        foreach $e (@a, @b) { $union{$e}++ && $isect{$e}++ }
        @isect = keys %isect;
        if (@isect) {
		undef @isect;
                return 1;
        } else {
                return 0;
        }
}

#-------------------------------------------------------------------
sub randint {
	my ($low, $high) = @_;
	$low = 0 unless defined $low;
	$high = 1 unless defined $high;
	($low, $high) = ($high,$low) if $low > $high;
	return $low + int( rand( $high - $low + 1 ) );
}

#-------------------------------------------------------------------
sub randomizeArray {
	my ($array, $i, $j);
	$array = shift;
	if ($#$array > 0) {
		for ($i = @$array; --$i; ) {
			$j = int rand ($i+1);
			next if $i == $j;
			@$array[$i,$j] = @$array[$j,$i];
		}
	}
}

#-------------------------------------------------------------------
sub round {
        return sprintf("%.0f", $_[0]);
}

#-------------------------------------------------------------------
sub sortHash {
	my (%hash, %reversedHash, %newHash, $key);
	tie %hash, "Tie::IxHash";
	tie %reversedHash, "Tie::IxHash";
	tie %newHash, "Tie::IxHash";
        %hash = @_;
	%reversedHash = reverse %hash;
	foreach $key (sort {$b cmp $a} keys %reversedHash) {
        	$newHash{$key}=$reversedHash{$key};
	}
	%reversedHash = reverse %newHash;
        return %reversedHash;
}

#-------------------------------------------------------------------
sub sortHashDescending {
        my (%hash, %reversedHash, %newHash, $key);
        tie %hash, "Tie::IxHash";
        tie %reversedHash, "Tie::IxHash";
        tie %newHash, "Tie::IxHash";
        %hash = @_;
        %reversedHash = reverse %hash;
        foreach $key (sort {$a cmp $b} keys %reversedHash) {
                $newHash{$key}=$reversedHash{$key};
        }
        %reversedHash = reverse %newHash;
        return %reversedHash;
}



1;


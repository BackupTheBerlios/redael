#!/usr/bin/env perl -w
#
# Copyright (C) 2001 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

use strict;
use Carp;

use constant DESTROYS => 0;
use constant STEALS   => 1;
use constant UNEASY   => 2;
use constant EXPOSES  => 3;
use constant IMPASSE  => 4;
use constant ADMIRES  => 5;
use constant OBSERVES => 6;
use constant ACCEPTS  => 7;
use constant READY    => 8;
use constant ATTITUDES => 9;

use constant MAX_DISTANCE => (ATTITUDES*2 - 2)*2;

sub new_perfection {
    my $v = shift;
    my @p;
    for (my $x=0; $x < ATTITUDES; $x++) {
	$p[$x*2] = $v;
	$p[1+$x*2] = $v;
    }
    \@p;
}

sub new_template {
    confess "new_template wants 9 args" if @_ != 9;
    my @p;
    for (my $x=0; $x < ATTITUDES; $x++) {
	my $v = $_[$x];
	if ($v =~ m,/,) {
	    my @pair = split m|/|, $v;
	    $p[$x*2] = $pair[0];
	    $p[$x*2+1] = $pair[1];
	    next;
	} elsif ($v =~ /^([+-])A$/) {
	    my $sign = $1;
	    $p[$x*2] = $sign eq '+'? 1:-1;
	    $p[$x*2+1] = $sign eq '+'? -1:1;
	    next;
	}
	$v = (rand 2)-1
	    if $v eq '?';
	$p[$x*2] = $v;
	$p[$x*2+1] = $v;
    }
    \@p;
}

sub new_symmetric {
    my @p;
    for (my $x=0; $x < ATTITUDES; $x++) {
	my $v = (rand 2)-1;
	$p[$x*2] = $v;
	$p[$x*2+1] = $v;
    }
    \@p;
}

sub new_asymmetric {
    my @p;
    for (my $x=0; $x < ATTITUDES; $x++) {
	$p[$x*2] = (rand 2)-1;
	$p[1+$x*2] = (rand 2)-1;
    }
    # these situations can never be asymmetric
    for my $x (IMPASSE, READY) { $p[$x*2] = $p[$x*2+1] }
    \@p;
}

sub pair_average {
    my ($l, $r) = @_;
    my @n;
    for (my $x=0; $x < ATTITUDES; $x++) {
	$n[$x*2] = ($l->[$x*2] + $r->[$x*2])/2;
	$n[$x*2+1] = ($l->[$x*2+1] + $r->[$x*2+1])/2;
    }
    # these situations can never be asymmetric
    for my $x (IMPASSE, READY) { $n[$x*2] = $n[$x*2+1] }
    \@n
}

sub max {
    my $m;
    for my $z (@_) {
	if (!defined $m) { $m = $z } else { $m = $z if $z > $m }
    }
    $m
}

sub min {
    my $m;
    for my $z (@_) {
	if (!defined $m) { $m = $z } else { $m = $z if $z < $m }
    }
    $m
}

sub disharmony {
    my ($p0, $p1) = @_;
    my $ouch = _disharmony($p0, $p1) + _disharmony($p1, $p0);

    # ready -> vivid
    $ouch *= (1-abs $p0->[READY*2]) + (1-abs $p1->[READY*2]);

    $ouch / 4;
}

sub _disharmony {
    my ($l, $r) = @_;
    my $ouch=0;       # all contributions are scaled [0..1]
    
    # penalize if target doesn't like it
    for my $x (DESTROYS, STEALS, EXPOSES) {
	my $left = $l->[$x*2] - $r->[$x*2+1];
	$ouch += $left/2 if $left > 0;
    }
    # worst case is l=+1, r=-1
    # best case is l <= r
    
    # do you want to make me uneasy?
    if ($l->[UNEASY*2+1] > 0) {
	# good, if i like being uneasy
	if ($r->[UNEASY*2] <= $l->[UNEASY*2+1]) {
	    $ouch -= min $r->[UNEASY*2], $l->[UNEASY*2+1];
	} else {
	    # penalty if observation becomes too much
	    $ouch += $r->[UNEASY*2] - $l->[UNEASY*2+1];
	}
    }
    # worst case is l=+1, r=-1
    # best case is l=+1, r=+1

    # accuracy annoys inaccuracy
    my $sharp = abs $l->[IMPASSE*2] - abs $r->[IMPASSE*2];
    $ouch += $sharp if $sharp > 0;
    # worst case is l=+/-1, r=0
    # best case is abs(l) <= abs(r), symmetric=0

    # how much you admire me (and i think i deserve it)
    if ($r->[ADMIRES*2] > 0 and $r->[ADMIRES*2] <= $l->[ADMIRES*2+1]) {
	$ouch -= $r->[ADMIRES*2];
    }
    # worst case is l < r
    # best case is l=+1, r=+1

    # how much we both admire/hate someone else
    $ouch -= abs(($r->[ADMIRES*2] + $l->[ADMIRES*2]) / 2);
    # worst case is avg(l,r) == 0
    # best case is l=r = +/-1

    if ($r->[OBSERVES*2] > 0 and $l->[OBSERVES*2+1] >= 0) {
	# i want to be observed, how closely do you watch me?
	if ($r->[OBSERVES*2] <= $l->[OBSERVES*2+1]) {
	    $ouch -= min $r->[OBSERVES*2], $l->[OBSERVES*2+1];
	} else {
	    # penalty if observation becomes too much
	    $ouch += $r->[OBSERVES*2] - $l->[OBSERVES*2+1];
	}
    }
    # worst case is l=+0, r=+1
    # best case is l=+1, r=+1

    # she want more than i can give
    if ($l->[ACCEPTS*2] < $r->[ACCEPTS*2+1]) {
	$ouch += ($r->[ACCEPTS*2+1] - $l->[ACCEPTS*2])/2;
    }
    # worst case is l=-1 r=1
    # best case is l >= r

    # i enjoy giving as much as i can
    if ($r->[ACCEPTS*2+1] > 0 and $l->[ACCEPTS*2] > 0) {
	$ouch -= min $r->[ACCEPTS*2+1], $l->[ACCEPTS*2];
    }
    # worst case is l<0 or r<0
    # best case is l=+1 r=+1

    # pessimism and optimism can counterbalance
    $ouch -= ($l->[READY*2] + $r->[READY*2]) / 2;
    # worst case is l=-1 r=-1
    # best case is l=1 r=1

    $ouch;
}

sub show_cross {
    my ($m) = @_;
    my @k = sort keys %$m;
    my $w = max 7, map { length } @k;
    print(' 'x$w . ' ');
    for my $k (@k) {
	printf "%$ {w}s ", $k;
    }
    print "\n";
    for (my $x=0; $x < @k; $x++) {
	printf "%$ {w}s ", $k[$x];
	for (my $y=0; $y < @k; $y++) {
	    if ($y < $x) { print(' 'x$w.' '); next }
	    my @pair = ($m->{ $k[$x] }, $m->{ $k[$y] });
	    printf(' 'x($w-7)."%4.1f/%2d ",
		   -disharmony(@pair), 100*pair_distance(@pair));
	}
	print "\n";
    }
}

my %Character = (
		 'follower' => \&follower,
		 'comedian' => \&comedian,
		 'novice' => \&novice,
		 'seeker' => \&seeker,
		 'teacher' => \&teacher,
		 );

sub show {
    my ($p) = @_;
    my @C;
    for my $ch (keys %Character) {
	push @C, [$Character{ $ch }->($p), $ch];
    }
    @C = sort { $a->[0] <=> $b->[0] } @C;
    if ($C[0][0] < .2) {
	printf "# %s/%4.3f", $C[0][1], $C[0][0];
	printf " (%s/%4.3f)", $C[1][1], $C[1][0]
	    if $C[1][0] < .2;
    }
    print "\n";
    for (my $x=0; $x < 3; $x++) {
	for (my $y=0; $y < 3; $y++) {
	    my $attitude = 3*$y + $x;
	    my $c = 2 * $attitude;
	    my $l = $p->[$c];
	    my $r = $p->[$c+1];
	    if (abs($l - $r) < .1) {  # symmetric
		printf "   %4.1f   ", $l;
	    } else {
		if ($attitude == IMPASSE or $attitude == READY) {
		    # should not happen
		    printf "  ~%4.1f~  ", ($l+$r)/2;
		} else {
		    printf "%4.1f/%4.1f ", $l, $r;
		}
	    }
	}
	print "\n";
    }
}

# cartesian distance
sub pair_distance {
    my ($l, $r) = @_;
    my $d = 0;
    for (my $x=0; $x < ATTITUDES; $x++) {
	$d += abs($l->[$x*2] - $r->[$x*2]);
	next if $x == IMPASSE || $x == READY;
	$d += abs($l->[$x*2+1] - $r->[$x*2+1]);
    }
    $d / MAX_DISTANCE
}

sub follower {
    my ($p) = @_;
    my $d = 0;
    $d += abs( $p->[DESTROYS*2] + 1 );
    $d += abs( $p->[DESTROYS*2+1] + 1 );
    $d += abs( $p->[UNEASY*2] + 1 );
    $d += abs( $p->[UNEASY*2+1] + 1 );
    $d += (1 - abs( $p->[IMPASSE*2] )) * 2;
    $d += abs( $p->[ADMIRES*2] + 1 );
    $d += abs( $p->[ADMIRES*2+1] - 1 );
    $d += abs( $p->[OBSERVES*2] );
    $d += abs( $p->[OBSERVES*2+1] );
    $d += abs( $p->[ACCEPTS*2] );
    $d += abs( $p->[ACCEPTS*2+1] );
    $d += abs( $p->[READY*2] - 1 )*2;
    $d / MAX_DISTANCE
}

sub comedian {
    my ($p) = @_;
    my $d = 0;
    $d += abs( $p->[DESTROYS*2] + 1 );
    $d += abs( $p->[DESTROYS*2+1] + 1 );
    $d += abs( $p->[STEALS*2] );
    $d += abs( $p->[STEALS*2+1] );
    $d += abs( $p->[UNEASY*2] );
    $d += abs( $p->[UNEASY*2+1] + 1 );
    $d += abs( $p->[EXPOSES*2] - 1 );
    $d += abs( $p->[EXPOSES*2+1] - 1 );
    $d += abs( $p->[IMPASSE*2] + 1 )*2;
    $d += abs( $p->[ADMIRES*2] - 1 );
    $d += abs( $p->[ADMIRES*2+1] - 1 );
    $d += abs( $p->[OBSERVES*2] - 1 );
    $d += abs( $p->[OBSERVES*2+1] - 1 );
    $d += abs( $p->[ACCEPTS*2] );
    $d += abs( $p->[ACCEPTS*2+1] );
    $d += abs( $p->[READY*2] ) * 2;
    $d / MAX_DISTANCE
}

sub novice {
    my ($p) = @_;
    my $d = 0;
    $d += abs( $p->[DESTROYS*2] );
    $d += abs( $p->[DESTROYS*2+1] );
    $d += abs( $p->[STEALS*2] + 1 );
    $d += abs( $p->[STEALS*2+1] + 1 );
    $d += abs( $p->[UNEASY*2] );
    $d += abs( $p->[UNEASY*2+1] );
    $d += abs( $p->[IMPASSE*2] + 1 )*2;
    $d += abs( $p->[ADMIRES*2] - 1 );
    $d += abs( $p->[ADMIRES*2+1] + 1 );
    $d += abs( $p->[OBSERVES*2] + 1 );
    $d += abs( $p->[OBSERVES*2+1] - 1 );
    $d += abs( $p->[ACCEPTS*2] - 1 );
    $d += abs( $p->[ACCEPTS*2+1] - 1 );
    $d += abs( $p->[READY*2] - 1 )*2;
    $d / MAX_DISTANCE
}

sub seeker {
    my ($p) = @_;
    my $d = 0;
    $d += abs( $p->[DESTROYS*2] );
    $d += abs( $p->[DESTROYS*2+1] );
    $d += abs( $p->[STEALS*2] + 1 );
    $d += abs( $p->[STEALS*2+1] - 1 );
    $d += abs( $p->[UNEASY*2] - 1 );
    $d += abs( $p->[UNEASY*2+1] - 1 );
    $d += abs( $p->[EXPOSES*2] - 1 );
    $d += abs( $p->[EXPOSES*2+1] - 1 );
    $d += abs( $p->[IMPASSE*2] )*2;
    $d += abs( $p->[ADMIRES*2] );
    $d += abs( $p->[ADMIRES*2+1] );
    $d += abs( $p->[OBSERVES*2] - 1 );
    $d += abs( $p->[OBSERVES*2+1] - 1 );
    $d += abs( $p->[ACCEPTS*2] );
    $d += abs( $p->[ACCEPTS*2+1] );
    $d += abs( $p->[READY*2] - 1 )*2;
    $d / MAX_DISTANCE
}

sub teacher {
    my ($p) = @_;
    my $d = 0;
    $d += abs( $p->[DESTROYS*2] );
    $d += abs( $p->[DESTROYS*2+1] );
    $d += abs( $p->[STEALS*2] );
    $d += abs( $p->[STEALS*2+1] );
    $d += abs( $p->[UNEASY*2] - 1 );
    $d += abs( $p->[UNEASY*2+1] + 1 );
    $d += abs( $p->[EXPOSES*2] - 1 );
    $d += abs( $p->[EXPOSES*2+1] - 1 );
    $d += abs( $p->[IMPASSE*2] )*2;
    $d += abs( $p->[ADMIRES*2] + 1 );
    $d += abs( $p->[ADMIRES*2+1] - 1 );
    $d += abs( $p->[OBSERVES*2] - 1 );
    $d += abs( $p->[OBSERVES*2+1] - 1 );
    $d += abs( $p->[ACCEPTS*2] );
    $d += abs( $p->[ACCEPTS*2+1] );
    $d += abs( $p->[READY*2] ) * 2;
    $d / MAX_DISTANCE
}

sub coarse {
    my ($z, $d) = @_;
    int(($z+1)*$d / 2.0001)
}

sub describe {
    my ($p) = @_;
    my @d;
    my $x = coarse($p->[DESTROYS*2], 3);
    my $m = do {
	if ($x == 0) {
	    "i refuse to kill"
	} elsif ($x == 1) {
	    "i can kill someone if there is no other choice"
	} else {
	    "i savor a mortal challenge"
	}
    };
    my $y = coarse($p->[DESTROYS*2+1], 3);
    if ($x != $y) {
	$m .= ", but ";
	$m .= do {
	    if ($y == 0) {
		"i am terrified of my own death"
	    } elsif ($y == 1) {
		"i don't want to die"
	    } else {
		"i'm willing to sacrifice my life"
	    }
	};
    }
    $m .= ".";
    push @d, $m;

    $x = coarse($p->[STEALS*2], 3);
    $m = do {
	if ($x == 0) {
	    "i never think of stealing"
	} elsif ($x == 1) {
	    "i steal infrequently"
	} else {
	    "Theft is my way of life"
	}
    };
    $y = coarse($p->[STEALS*2+1], 3);
    if ($x != $y) {
	$m .= ", but ";
	$m .= do {
	    if ($y == 0) {
		"i assume my possessions are perfectly safe"
	    } elsif ($y == 1) {
		"i take reasonable care to secure my possessions"
	    } else {
		"i am paranoid about thieves"
	    }
	};
    }
    $m .= ".";
    push @d, $m;
    
    $x = coarse($p->[UNEASY*2], 3);
    $m = do {
	if ($x == 0) {
	    "i am confident that i know what i'm doing"
	} elsif ($x == 1) {
	    "i don't mind feeling like a beginner sometimes"
	} else {
	    "Learning something new is great fun"
	}
    };
    $y = coarse($p->[UNEASY*2+1], 3);
    if ($x != $y) {
	$m .= ", but ";
	$m .= do {
	    if ($y == 0) {
		"i am careful not to pressure slow learners"
	    } elsif ($y == 1) {
		"sometime i will observe how your study is progressing"
	    } else {
		"i keep a close eye on your progress"
	    }
	};
    }
    $m .= ".";
    push @d, $m;
    
    $x = coarse($p->[EXPOSES*2], 3);
    $m = do {
	if ($x == 0) {
	    "Even if someone is doing something dumb, i mind my own business"
	} elsif ($x == 1) {
	    "i correct people when it is necessary"
	} else {
	    "Criticism is devilishly fun"
	}
    };
    $y = coarse($p->[EXPOSES*2+1], 3);
    if ($x != $y) {
	$m .= ", but ";
	$m .= do {
	    if ($y == 0) {
		"i am offended if someone points out a defect in my behavior"
	    } elsif ($y == 1) {
		"i can usual take criticism constructively"
	    } else {
		"i love to be scolded"
	    }
	};
    }
    $m .= ".";
    push @d, $m;
    
    $x = coarse($p->[IMPASSE*2], 3);
    $m = do {
	if ($x == 0) {
	    "i avoid serious confrontation at any cost"
	} elsif ($x == 1) {
	    "i approach impasse with balanced concern"
	} else {
	    "Debating is too much fun"
	}
    };
    $m .=".";
    push @d, $m;
    
    $x = coarse($p->[ADMIRES*2], 3);
    $m = do {
	if ($x == 0) {
	    "i haven't met anyone worth my admiration"
	} elsif ($x == 1) {
	    "i admire those who follows the saints"
	} else {
	    "i admire everyone"
	}
    };
    $y = coarse($p->[ADMIRES*2+1], 3);
    if ($x != $y) {
	$m .= ", but ";
	$m .= do {
	    if ($y == 0) {
		"you shouldn't admire me"
	    } elsif ($y == 1) {
		"i like to be admired on occation"
	    } else {
		"you should worship me"
	    }
	};
    }
    $m .= ".";
    push @d, $m;
    
    $x = coarse($p->[OBSERVES*2], 3);
    $m = do {
	if ($x == 0) {
	    "i am bored watching people in the spotlight"
	} elsif ($x == 1) {
	    "Sometimes i like to watch people in the spotlight"
	} else {
	    "i love to watch someone who is in the spotlight"
	}
    };
    $y = coarse($p->[OBSERVES*2+1], 3);
    if ($x != $y) {
	$m .= ", but ";
	$m .= do {
	    if ($y == 0) {
		"i am terrified of taking the spotlight"
	    } elsif ($y == 1) {
		"sometimes i enjoy being in the spotlight"
	    } else {
		"i must be in spotlight"
	    }
	};
    }
    $m .= ".";
    push @d, $m;
    
    $x = coarse($p->[ACCEPTS*2], 3);
    $m = do {
	if ($x == 0) {
	    "i refuse to accept you on your own terms"
	} elsif ($x == 1) {
	    "i accept reasonable requests"
	} else {
	    "i am surrendered to your will"
	}
    };
    $y = coarse($p->[ACCEPTS*2+1], 3);
    if ($x != $y) {
	$m .= ", but ";
	$m .= do {
	    if ($y == 0) {
		"i never ask for anything"
	    } elsif ($y == 1) {
		"i ask only for what i need"
	    } else {
		"i am very demanding"
	    }
	};
    }
    $m .= ".";
    push @d, $m;
    
    $x = coarse($p->[READY*2], 5);
    $m = do {
	if ($x == 0) {
	    "i am depressed."
	} elsif ($x == 1) {
	    "i am pessimistic."
	} elsif ($x == 2) {
	    "i am ready!"
	} elsif ($x == 3) {
	    "i am optimistic."
	} else {
	    "i daydream about my love."
	}
    };
    push @d, $m;
    
    join "\n", @d;
}

sub best_pairs {
    my ($tries, $pool) = @_;
    die "pool has odd number of people" if @$pool & 1;
    my @pair;
    while (@$pool) {
	my $p = shift @$pool;
	my $score;
	my $pick;
	for (my $x=0; $x < @$pool and $x < $tries; $x++) {
	    my $dh = disharmony($p, $pool->[$x]);
	    if (!defined $score or $score > $dh) {
		$score = $dh;
		$pick = $x;
	    }
	}
	push @pair, [$p, splice(@$pool, $pick, 1), $score];
    }
    @pair;
}

sub pair_harmony {
    my @menu = @_;
    my @P = best_pairs(0+@menu, \@menu);
    @P = sort { $a->[2] <=> $b->[2] } @P;

    if (0) {
    my @bad;
    push @bad, pop @P;
    push @bad, pop @P;
    my @good;
    push @good, shift @P;
    push @good, shift @P;
    my @mid = splice @P, @P/2-1, 2;
    }

#    for my $z (@bad, @mid, reverse @good) {
    for my $z (@P) {
	print "\n";
	print('-'x20 . " ");
	printf("harmony=%4.2f distance=%4.2f\n", -$z->[2],
	       pair_distance($z->[0], $z->[1]));
	show($z->[0]);
	#print describe($z->[0])."\n\n";
	show($z->[1]);
	#print describe($z->[1])."\n\n";
    }
}

my $friends = {
	       Follower => new_template(-1, '?', -1, '?', (rand>.5?-1:1), .5, 0, 0, .75),
	       Comedian => new_template(-1, 0, '0/-1', 1, -1, 1, 1, 0, 0),
	       Novice => new_template(0, -1, 0, '?', -1, '+A', '-A', 1, 1),
	       Seeker => new_template(0, '-A', 1, 1, 0, 0, 1, 0, 1),
	       Teacher => new_template(0, 0, '+A', 1, 0, '-A', 1, 0, 0),
	       Min => new_template('+A','+A','-A','+A',1,0,'1/0','-A',0),
	       Max => new_template('-A','-A',1,'-A',0,1,1,1,0)
	   };
show_cross($friends)
    if 0;

if (0) {
for my $name (sort keys %$friends) {
    print "\n$name\n";
    show($friends->{$name});
    print describe($friends->{$name})."\n";
}
}

if (1) {
my @P;
for (0..19) {
    push @P, (new_symmetric(),
	      new_asymmetric());
}
if (0) {
for (0..1) {
    my @pure = (new_template(-1, '?', -1, '?', (rand>.5?-1:1), '-A', 0, 0, 1),
		new_template(-1, 0, -1, 1, -1, 1, 1, 0, 0),
		new_template(0, -1, 0, '?', -1, '+A', '-A', 1, 1),
		new_template(0, '-A', 1, 1, 0, 0, 1, 0, 1),
		new_template(0, 0, '+A', 1, 0, '-A', 1, 0, 0),
	       );
    for (my $x=0; $x < @pure; $x++) {
	for (my $y=$x+1; $y < @pure; $y++) {
	    push @P, pair_average($pure[$x], $pure[$y]);
	}
    }
    push @P, @pure;
}
}

pair_harmony(@P);
}

__END__

apply transformers
  team juggling
  Go

search for most harmonious personalities relative to a group
  try brute force implementation

harmony(p, reverse_spin(p)) ?

Java applet to let web surfers play with a pair of personalities

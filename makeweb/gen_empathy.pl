#!/usr/bin/perl -w

#
# upload with:
#
# tar zcf empathy.tgz empathy
# scp empathy.tgz vishnu@shell.berlios.de:/home/groups/redael/htdocs/
#

use 5.6.1;
use strict;
use Carp;

our @Em;
our @Attr = (qw(intent initiator victim phase tension intensity jtype));
our %Attr =
  (
   intent => [qw(ready accepts observes admires impasse
		 exposes uneasy steals kills)],
   initiator => [qw(left right)],
   victim => [qw(absent)],
   phase => [qw(before during after)],
   tension => [qw(focused relaxed stifled)],
   intensity => [qw(gentle forceful extreme)],
   jtype => [qw(react amend)]
  );

sub last_constraint {
  my ($pat) = @_;
  my $ch = $pat->{chain};
  if (! @$ch) { push @$ch, {} };
  @$ch[ $#$ch ];
}

{
  my $map = '/usr/share/redael/empathy';
  open my $fh, $map or die "open $map: $!";

  my $cur;
  my $l;
  while (defined ($l = <$fh>)) {
    if ($l =~ /^if/) {
      $cur = { chain => [], label => '', match => [] };
      next;
    } elsif ($l =~ /^\s*$/) {
      next;
    }

    my $ch = $cur->{chain};
    my $last = last_constraint($cur);

    if ($l =~ /(\w+) \s* \= \s* (\w+)/x) {
      my ($attr, $val) = ($1,$2);
      $attr = 'intent'
	if $attr eq 'situation';
      $last->{ $attr } = $val;
    } elsif ($l =~ /then \s* \" (.*) \"/x) {
      if (keys %$last == 0) {  die 'no keys'; }
      $cur->{label} = $1;
      push @Em, $cur;
      undef $cur;
    } elsif ($l =~ /(react|amend)/) {
      $last->{jtype} = $1;
      push @$ch, {};
    } else {
      warn "? $l";
    }
  }
}

sub is_pattern {
  my ($haystack, $needle) = @_;
  
  return
    if @{$needle->{chain}} != @{$haystack->{chain}};

  my $nlen = @{$needle->{chain}};
  return 1
    if $nlen == 0;

  for (my $cx=0; $cx < $nlen; $cx++) {
    my $hc = $haystack->{chain}[$cx];
    my $nc = $needle->{chain}[$cx];

    return
      if keys %$nc != keys %$hc;

    for my $k (keys %$nc) {
      return
	if !$hc->{$k} or $nc->{$k} ne $hc->{$k};
    }
  }
  1;
}

sub is_subpattern {
  my ($haystack, $needle) = @_;

  return
    if @{$needle->{chain}} > @{$haystack->{chain}};

  my $nlen = @{$needle->{chain}};
  return 1
    if $nlen == 0;

  for (my $cx=0; $cx < $nlen; $cx++) {
    my $hc = $haystack->{chain}[$cx];
    my $nc = $needle->{chain}[$cx];

    no warnings 'uninitialized';
    if ((exists $nc->{initiator} and
	 $nc->{initiator} ne $hc->{initiator}) or
	(exists $nc->{victim} and
	 $nc->{victim} ne $hc->{victim}) or
	(exists $nc->{intent} and
	 $nc->{intent} ne $hc->{intent}) or
	(exists $nc->{phase} and
	 $nc->{phase} ne $hc->{phase}) or
	(exists $nc->{tension} and
	 $nc->{tension} ne $hc->{tension}) or
	(exists $nc->{intensity} and
	 $nc->{intensity} ne $hc->{intensity}) or
	(exists $nc->{jtype} and
	 $nc->{jtype} ne $hc->{jtype}))
      { return }
  }
  1;
}

sub copy_pattern {
  my ($pat) = @_;
  my $n = { chain => [] };
  for my $c1 (@{ $pat->{chain} }) {
    push @{ $n->{chain} }, { %$c1 };
  }
  $n;
}

sub pattern_rank {
  my ($pat) = @_;
  my $rank = 0;
  my $ch = $pat->{chain};
  for my $c1 (@$ch) {
    $rank += 10;
    ++$rank if exists $c1->{initiator};
    ++$rank if exists $c1->{victim};
    ++$rank if exists $c1->{intent};
    ++$rank if exists $c1->{phase};
    ++$rank if exists $c1->{tension};
    ++$rank if exists $c1->{intensity};
  }
  $rank;
}

our $N = 0;
our @Page;

sub traverse {
  my ($oldpat) = @_;
  
  my $id = $N++;

  my @final;
  my @branch;
  my @orig = grep { is_subpattern($_, $oldpat) } @Em;
  my $oldlast = last_constraint($oldpat);

  for my $attr (@Attr) {
    next if exists $oldlast->{$attr};
    next if ($attr eq 'jtype' and !exists $oldlast->{intent});

    for my $choice (@{ $Attr{$attr} }) {
      # refine pattern
      my $pat = copy_pattern($oldpat);
      my $last = last_constraint($pat);
      $last->{$attr} = $choice;
      if ($attr eq 'jtype') {
	push @{ $pat->{chain} }, {};
      }

      my @match = grep { is_subpattern($_, $pat) } @Em;
      next if (@match == 0 or @orig == @match);

      if (@match == 1) {
	if (!grep { $_->[2] == $match[0] } @final) {
	  push @final, [$attr, $choice, $match[0]];
	  push @{ $match[0]->{match} }, $id;
	}
      } else {
	push @branch, [$attr, $choice, traverse($pat)];
      }
    }
  }

  $Page[$id] = { id => $id, pat => $oldpat,
		 final => \@final, branch => \@branch };
  $id;
}

traverse({ chain => [] });

BEGIN {
  require "./minixml.pl";
}

sub page {
  my ($file, $x) = @_;
  
  open my $fh, ">tmp$$";
  select $fh;

  doctype 'HTML', '-//W3C//DTD HTML 4.01//EN',
    'http://www.w3.org/TR/html4/strict.dtd';
  startTag 'html';
  startTag 'head';

  $x->();

  endTag 'body';
  endTag 'html';
  print "\n";
  close $fh;
  
  #run "tidy -config tidy.conf -utf8 -xml tmp$$";
  rename "tmp$$", $file or die "rename: $!";
}

sub body {
  my ($pad) = @_;

  $pad ||= 0;

  startTag ('body',
	    'bgcolor', "#FFFFFF",
	    'topmargin', 0,
	    'bottommargin', 0,
	    'leftmargin', 0,
	    'rightmargin', 0,
	    'marginheight', $pad,
	    'marginwidth', $pad);
}

mkdir 'empathy';
chdir 'empathy' or die "chdir empathy: $!";

sub filename {
  my ($px) = @_;
  confess "index missing" if !defined $px;
  sprintf "e%04d.html", $px;
}

sub pat2html {
  my ($pat, %opt) = @_;
  my $light = $opt{light} || '';
  my $rev = $opt{rev};
  
  startTag 'table', border => 1, cellspacing => 0, cellpadding => 6;
  startTag 'tr';
  
  my $clen = @{ $pat->{chain} };

  my $ch = $pat->{chain};
  for (my $cx=0; $cx < $clen; $cx++) {
    my $c1 = $ch->[$cx];
    last if !keys %$c1;

    startTag 'td';
    for my $attr (@Attr) {
      if (exists $c1->{$attr}) {
	my $gotrev;
	if ($rev) {
	  my $rpat = copy_pattern($pat);
	  if ($attr ne 'jtype' and $cx == $clen - 1) {
	    # ok
	  } elsif ($attr eq 'jtype' and $cx == $clen - 2) {
	    pop @{ $rpat->{chain} };
	  } else {
	    goto skip_rev;
	  }
	  my $rlast = last_constraint($rpat);
	  delete $rlast->{$attr};
	  my @rev = grep { is_pattern($_->{pat}, $rpat) } @Page;
	  $gotrev = $rev[0];
	}
      skip_rev:

	if ($attr ne 'jtype') {
	  startTag 'a', href => filename($gotrev->{id})
	    if $gotrev;

	  startTag 'font', color => 'DarkBlue'
	    if ($cx == $clen-1 and $attr eq $light);
	  text "$attr = $c1->{$attr}\n";
	  endTag 'font'
	    if ($cx == $clen-1 and $attr eq $light);
	  endTag 'a'
	    if $gotrev;
	  emptyTag 'br';
	} else {
	  endTag 'td';
	  startTag 'td';
	  startTag 'a', href => filename($gotrev->{id})
	    if $gotrev;
	  text $c1->{$attr};
	  endTag 'a'
	    if $gotrev;
	}
      }
    }
    endTag 'td';
  }
  endTag 'tr';
  endTag 'table';
}

warn "Generating HTML...\n";

sub header_map {
  my ($full) = @_;
  
  startTag 'table', border => 0, width => '100%';
  startTag 'tr';
  
  startTag 'td', align => 'center';
  element 'a', 'Back To X-Ref ', href => '../doc-xref.html';
  endTag 'td';
  
  startTag 'td', align => 'center';
  element 'a', 'Emotion Index', href => 'index.html';
  endTag 'td';
  
  startTag 'td', align => 'center';
  element 'a', 'No Pattern', href => filename(0);
  endTag 'td';
  
  endTag 'tr';
  endTag 'table';
  
  emptyTag 'hr';

  return if !$full;

  startTag 'p';
  text 'The empathy map matches abstract situations
to abstract emotions.  An abstract situation consists of
one or more spans connected by joints (jtype).
There are six parameters which describe a span:';
  for (0..5)  { text " $Attr[$_]" }
  text '.';
  endTag 'p';

  for my $attr (@Attr) {
    startTag 'p';
    text "$attr :";
    for my $val (@{ $Attr{ $attr} }) {
      text " $val";
    }
    endTag 'p';
  }

  element 'p', 'It is possible that more than one abstract emotion
matches a given abstract situation.  All matches can be considered,
but usually the most specific match is of greater interest.';

  my @tm = localtime;
  element 'p', 'Last modified ' .
    sprintf "%02d/%02d/%04d", $tm[3], $tm[4]+1, $tm[5]+1900;

  emptyTag 'hr';
}

sub footer {
#  emptyTag 'br';
#  emptyTag 'br';
#  emptyTag 'hr';
#  element 'p', 'Copyright (C) 2002 Joshua Nathaniel Pritikin.
# Verbatim copying and distribution of this entire article is
# permitted in any medium, provided this notice is preserved.';
}

for (my $px=0; $px < @Page; $px++) {
  my $page = $Page[$px];
  page filename($px), sub {
    element 'title', "Empathy Map - Page $px";
    endTag 'head';

    body 4;

    header_map($px == 0);

    startTag 'table', border => 0;

    startTag 'tr';
    element 'td', 'Current Pattern', bgcolor => 'LightGreen';
    startTag 'td';
    my @exact = grep { is_pattern($_, $page->{pat}) } @Em;
    if (@exact) {
      push @{ $exact[0]->{match} }, $page->{id};

      startTag 'table'; startTag 'tr';
      startTag 'td';
      pat2html $page->{pat}, rev=>1;
      endTag 'td';
      element 'td', '==>';
      element 'td', $exact[0]->{label};
      endTag 'tr';
      endTag 'table';
    } else {
      pat2html $page->{pat}, rev=>1;
    }
    endTag 'td';
    endTag 'tr';

    if (@{ $page->{branch} }) {
      startTag 'tr';
      element 'td', 'Branches', bgcolor => 'yellow', align=>'center';
      startTag 'td';
      
      for my $br (@{ $page->{branch} }) {
	my ($attr, $val, $id) = @$br;
	startTag 'p';
	if ($attr ne 'jtype') {
	  element 'a', "$attr = $val", href => filename($id);
	} else {
	  element 'a', "$val", href => filename($id);
	}
	endTag 'p';
      }
      endTag 'td';
      endTag 'tr';
    }

    if (@{ $page->{final} }) {
      startTag 'tr';
      element 'td', 'Matches', bgcolor => 'orange', align=>'center';
      startTag 'td';
      
      for my $fin (@{ $page->{final} }) {
	my ($attr, $val, $match) = @$fin;
	startTag 'table'; startTag 'tr';
	startTag 'td';
	pat2html $match, light => $attr;
	endTag 'td';
	element 'td', '==>';
	element 'td', $match->{label};
	endTag 'tr';
	endTag 'table';
      }
      endTag 'td';
      endTag 'tr';
    }
    endTag 'table';

    footer();
  }
}

warn "Generating Index...\n";

page 'index.html', sub {
  element 'title', 'Emotion Index';
  endTag 'head';

  body 4;

  header_map(1);

  startTag 'table';
  my $col=0;
  for my $em (sort { $a->{label} cmp $b->{label} } @Em) {
    startTag 'tr'
      if $col == 0;

    my @id = @{ $em->{match} };

    if (@id == 0) {
      warn "'$em->{label}' not reached";
      next;
    }
    # warn $em->{label} . ' : ' . join(' ', sort { $a <=> $b } @id);

    @id = sort { pattern_rank($Page[$a]->{pat}) -
		 pattern_rank($Page[$b]->{pat})
	       } @id;

    startTag 'td';
    element 'a', $em->{label}, href => filename($id[0]);
    endTag 'td';

    if (++$col == 3) {
      endTag 'tr';
      $col = 0;
    }
  }
  endTag 'tr'
    if $col != 0;

  endTag 'table';

  footer();
};


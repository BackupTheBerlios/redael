#!/usr/bin/perl -w

use strict;
use Fatal qw(open);
BEGIN { require "./minixml.pl" }

if (-d 'root' and !-e 'cache') {
  rename 'root', 'cache' or warn "rename root cache: $!";
}
if (!-e 'root') {
  mkdir 'root' or die "mkdir root: $!";
}

our $Scores;
require './scores';

sub run {
  my ($cmd) = @_;
  system($cmd) == 0 or die "system $cmd failed: $?";
}

sub modtime {
  my ($f) = @_;
  my @s = stat $f;
  $s[9] || 0;
}

our $NoteNumber;
our @Notes;
sub note {
  my ($text) = @_;
  element 'a', "[$NoteNumber]", href => "#$NoteNumber";
  push @Notes, [$NoteNumber, $text];
  ++ $NoteNumber;
}

sub show_notes {
  startTag 'small';
  for my $ni (@Notes) {
    my ($n, $text) = @$ni;
    startTag 'p';
    element 'a', "[$n]", name => "$n";
    text ' ';
    text $text;
    endTag 'p';
  }
  @Notes = ();
  endTag 'small';
}

sub page {
  my ($file, $x) = @_;
  
  $NoteNumber = 1;
  @Notes = ();

  open my $fh, "> root/$file";
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
}

sub hskip {
  my $reps = $_[0] || 1;
  print '&nbsp;' while --$reps >= 0;
}

sub vskip {
  my $reps = $_[0] || 1;
  print '<p>&nbsp;</p>' while --$reps >= 0
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

sub br { emptyTag 'br' }

sub img {
  my ($src, $alt, @rest) = @_;
  
  my $cache = "cache/$src";
  my $path = "root/$src";
  my $oldart = "art/$src";

  if (!-e $path) {
    if (-e $cache) {
      rename $cache, $path or die "rename $cache $path: $!";
    } elsif (-e $oldart) {
      rename $oldart, $path or die "rename $oldart $path: $!";
    } else {
      warn "$path doesn't exist";
      return;
    }
  }

  emptyTag 'img', src=>$src, alt=>$alt, @rest;
}

sub thumb {
  my ($src, $caption) = @_;

  my $cache = "cache/$src";
  my $path = "root/$src";
  my $oldart = "art/$src";

  if (!-e $path) {
    if (-e $cache) {
      rename $cache, $path or die "rename $cache $path: $!";
    } elsif (-e $oldart) {
      rename $oldart, $path or die "rename $oldart $path: $!";
    } else {
      warn "$path doesn't exist";
      return;
    }
  }
  
  my $sm = $src;
  if ($sm =~ s/\.jpg$/-sm.jpg/) {
    my $smcache = "cache/$sm";
    my $smroot = "root/$sm";
    if (modtime($smcache) >= modtime($path)) {
      rename $smcache, $smroot or die "rename $smcache $smroot: $!";
    } elsif (modtime($smroot) >= modtime($path)) {
      # ok
    } else {
      run "cp $path $smroot";
      run "mogrify -geometry 160x160 $smroot";
    }
  }
  else { warn "what is $src ?" }

  startTag 'center';
  startTag 'a', href => $src;
  emptyTag 'img', src=>$sm, alt=>$caption;
  endTag 'a';
  br;
  text "$caption";
  endTag 'center';
}

sub startLi {
  startTag 'li';
  startTag 'p';
}

sub endLi {
  endTag 'p';
  endTag 'li';
}

sub columns {
  startTag 'table', border => 0, cellspacing => 0, cellpadding => 0;
  startTag 'tr';

  for my $c (@_) {
    startTag 'td';
    $c->();
    endTag 'td';
  }

  endTag 'tr';
  endTag 'table';
}

sub row {
  my ($x) = @_;
  
  startTag 'tr';
  startTag 'td';
  $x->();
  endTag 'td';
  endTag 'tr';
}

sub nth {
  my ($n) = @_;

  if ($n == 0)    { text '0'; element 'sup', 'th' }
  elsif ($n == 1) { text '1'; element 'sup', 'st' }
  elsif ($n == 2) { text '2'; element 'sup', 'nd' }
  elsif ($n == 3) { text '3'; element 'sup', 'rd' }
  else { die $n; }
}

sub nth_ex {
  my ($n) = @_;

  if ($n == 0)    { text 'pure spirit' }
  elsif ($n == 1) { text 'emotion' }
  elsif ($n == 2) { text 'personality' }
  elsif ($n == 3) { text 'situation' }
  else { die $n; }
}

sub attention {
  my ($s, $o, $hl) = @_;

  my @s_opt;
  my @o_opt;
  if ($hl) {
    @s_opt = (bgcolor => "yellow") if $hl eq 's';
    @o_opt = (bgcolor => "yellow") if $hl eq 'o';
  }

  startTag 'table', border=>1, cellpadding=>3, cellspacing=>0;
  startTag 'tr';
  startTag 'th', @s_opt;
  text 'subject:';
  hskip;
  nth $s;
  endTag 'th';
  startTag 'th', @o_opt;
  text 'object:';
  hskip;
  nth $o;
  endTag 'th';
  endTag 'tr';
  startTag 'tr';
  startTag 'td', @s_opt;
  nth_ex $s;
  endTag 'td';
  startTag 'td', @o_opt;
  nth_ex $o;
  endTag 'td';
  endTag 'tr';
  endTag 'table';
}

sub EICOLOR { '#006600' }

##########################################################
package MenuTree;

sub new { bless $_[1], $_[0]; }

sub file {
  my ($o, $item) = @_;

  for (my $x=0; $x < @$o; ++$x) {
    my $cur = $o->[$x];

    if (@$cur == 3) {
      my $ans = file($cur->[2], $item);
      return $ans
	if $ans;
    }

    next if $cur->[0] ne $item;
    return $cur->[1];
  }
  undef
}

package main;

##########################################################

page 'index.html', sub {
  my $title = 'Complete Integrated Self Awareness';
  element 'title', $title;
  endTag 'head';

  body();

  startTag 'center';
  vskip 1;
  element 'h1', $title;

  startTag 'table', 'border', 0, 'cellpadding', 25;
  startTag 'tr';
  
  startTag 'td', 'align', 'center', valign=>'bottom';
  img 'about_sy_chart.png', 'Chakra System', border=>0;
  br;
  element 'a', 'En Masse Self-Realization', 'href', 'http://sahajayoga.org';
  endTag 'td';
  
  startTag 'td', 'align', 'center', valign=>'bottom';
  img 'trident.png', 'Attention Trident', border => 0;
  br;
  element 'a', 'Situation Assessment', 'href', 'news.html';
  endTag 'td';
  
  endTag 'tr';
  endTag 'table';
  
  endTag 'center';
  vskip;
};

our $topmenu = MenuTree
  ->new([
	 ['News'              => 'news.html',
	  [
	   ['History'          => 'history.html'],
	  ]],
	 ['Download'           => 'download.html'],
	 ['Mailing Lists'     => 'lists.html'],
	 ['High Scores'       => 'scores.html'],
	 ['Research & Professional' => 'jobs.html',
	  [
	   ['IMRT'            => 'imrt.html'],
	  ]
	 ],
	 ['Philosophy'        => 'philo.html'],
	]);

page 'fairuse.html', sub {
  element 'title', 'Fair Use Statement';
  endTag 'head';

  body(20);

  element 'h2', 'Fair Use Statement';

  element 'p', 'Despite the fact that Aleader is an international project,
this discussion will
entertain American copyright law because America is presently taking a
leadership role in legislating and enforcing restictions on fair use.';

  emptyTag 'hr';

  startTag 'p';
  text 'The references which i used to research this discussion include ';
  element 'a', 'http://fairuse.stanford.edu',
    href=>'http://fairuse.stanford.edu';
  text ' and ';
  element 'a', 'http://www.benedict.com',
    href=>'http://www.benedict.com';
  text '.';
  endTag 'p';

  emptyTag 'hr';

  startTag 'font', color=>'red';
  element 'p', 'Fair Use Provision of the U.S. Copyright Act: Ch 1 Sec 107';
  element 'p', '[...]  In determining whether the use made of a work in any particular
case is a fair use the factors to be considered shall include -';
  element 'p', '(1) the purpose and character of the use, including whether such use
is of a commercial nature or is for nonprofit educational purposes;';
  endTag 'font';
  
  element 'p', 'Aleader uses films for non-profit educational purposes, specifically
for the purposes of teaching, scholarship, and research.  The films
are used verbatim (not transformed) and retain proper attribution.';

  
  startTag 'font', color=>'red';
  element 'p', '(2) the nature of the copyrighted work;';
  endTag 'font';

  element 'p', 'Our fair use statement does not contest the worthiness of film for
protection under copyright law.';

  startTag 'font', color=>'red';
  element 'p', '(3) the amount and substantiality of the portion used in relation to
the copyrighted work as a whole; and';
  endTag 'font';

  element 'p', 'The decision to make a portion of a copyrighted film available under
the fair use provision was not undertaken lightly.  We decided to
distribute the minimum workable sub-sample: only the first 10% of the
film at sub-standard quality.';

  startTag 'ul';
  startTag 'li';
  element 'p',
'Quality justification: Video and audio must be of sufficient quality to
activate the empathy mechanism, to generate emotions.  The customary quality
used in for-profit film presentation is not required for our purposes.';
  endTag 'li';

  startTag 'li';
  element 'p',
'First 10% justification: To properly annotation duration, a whole film is
required.  Our compromise is to use only the first 10%.  Within 10%, joints &
duration can be demonstrated in a limited way which we hope and expect
will be sufficient.';
  endTag 'li';

  endTag 'ul';
  
  startTag 'font', color=>'red';
  element 'p',
'(4) the effect of the use upon the potential market for or value of
the copyrighted work. The fact that a work is unpublished shall not
itself bar a finding of fair use if such finding is made upon
consideration of all the above factors.';
  endTag 'font';
  
  startTag 'ul';
  startTag 'li';
  element 'p',
 'Part of the motivation for this fair use statement is to encourage
people to take copyright seriously.  Please buy an
authorized duplicate if you wish to view a film for any purpose not
protected under the fair use provision.';
  endTag 'li';

  startTag 'li';
  element 'p',
'Offering 10% of a quality degraded film is similar to the practice
routinely used in film promotion (previews).
Hopefully it is plausible to studios that making available our proposed
film sub-set will not diminish the asset value of a given film.
Of course the actual effect on asset value is hard to measure objectively
with any precision.';
  endTag 'li';

  endTag 'ul';

  vskip 2;
};

my %Chapter;

sub menupage {
  my ($menu, $curitem, $x) = @_;

  my $file = $menu->file($curitem);
  if (!$file) {
    warn "menupage($curitem): not found (ignoring)";
    return;
  }
  my $print = $file;
  $print =~ s/\.html$/-pr.html/;

  my $is_chapter;

  page $file, sub {
    element 'title', $curitem;
    endTag 'head';
    body;

    startTag 'table', 'border', 0, cellspacing => 0, cellpadding => 3;
    startTag 'tr';

    startTag 'td', 'valign', 'top', 'bgcolor', '#ccffcc';

    br;

    # this is a gross hack
    for my $item (@$menu) {
      startTag 'p';

      my $sub = $item->[2];
      my $in_sub = MenuTree::file($sub, $curitem)
	if $sub;

      if ($item->[0] eq $curitem) {
	text $item->[0];
      } else {
	element 'a', $item->[0], 'href', $item->[1];
      }

      $is_chapter = 1
	if (@$item == 3 and $item->[0] eq $curitem);

      if (@$item == 3 and ($item->[0] eq $curitem or $in_sub)) {
	push @{ $Chapter{ $menu->file($item->[0]) } }, $x;
	
	startTag 'table';
	for my $s (@{$item->[2]}) {
	  startTag 'tr';
	  startTag 'td';
	  hskip 2;
	  endTag 'td';
	  startTag 'td';
	  if ($s->[0] eq $curitem) {
	    text $s->[0];
	  } else {
	    element 'a', $s->[0], 'href', $s->[1];
	  }
	  endTag 'td';
	  endTag 'tr';
	}
	endTag 'table';
      }
      endTag 'p';
    }

    vskip 2;
    
    element 'a', '[Print]', href => $print;
    if (0 and $is_chapter) {
      my $ch = $file;
      $ch =~ s/\.html$/-ch.html/;
      text ' ';
      element 'a', '[Chapter]', href => $ch;
    }

    vskip 1;
    startTag 'p';
    text 'Hosted by:';
    br;
    startTag 'a', 'href', 'http://developer.berlios.de/projects/redael';
    emptyTag 'img', 'src', 'http://developer.berlios.de/images/logo_fokus.gif',
      'alt', 'GMD FOKUS', 'border', 0, 'height', 73, 'width', 66;
    endTag 'a';
    endTag 'p';
    
    endTag 'td';
    
    startTag 'td', 'valign', 'top', 'bgcolor', '#ffcccc';
    hskip;
    endTag 'td';

    startTag 'td', 'valign', 'top';
    
    $x->();
    
    endTag 'td';
    
    endTag 'tr';
    endTag 'table';
    vskip 4;

    columns sub { hskip 2 },
    sub {
      emptyTag 'hr';
      element 'p', 'Copyright (C) 2001, 2002, 2003 Joshua Nathaniel Pritikin.  Verbatim copying and distribution of this entire article is permitted in any medium, provided this notice is preserved.';
      emptyTag 'hr';
    },
    sub { hskip 2 };
  };

  page $print, sub {
    element 'title', $curitem;
    endTag 'head';
    body 10;
    $x->();
    vskip 1;
    
    columns sub { hskip 2 },
    sub {
      emptyTag 'hr';
      element 'p', 'Copyright (C) 2001, 2002, 2003 Joshua Nathaniel Pritikin.  Verbatim copying and distribution of this entire article is permitted in any medium, provided this notice is preserved.';
      emptyTag 'hr';
    },
    sub { hskip 2 };
  };
};

menupage $topmenu, 'News', sub {
  startTag 'center';
  emptyTag 'hr';
  startTag 'big';
  startTag 'i';
  element 'p', 'How well do you understand the meaning of your emotions?';
  element 'p', 'How accurately can you assess difficult situations?';
  element 'p', 'How gracefully do you manage people?';
  endTag 'i';
  endTag 'big';
  emptyTag 'hr';
  endTag 'center';

  element 'h1', 'Introduction';

  element 'p', 'i am not against competition,
but i believe that this software project is unique.
As far as i know, there is nothing else like it.
For this reason, a little extra effort
may be needed to understand what this software does and why
it is important.';

  element 'p', 'Our concern is with measuring and increasing
assessment quotient (AQ).
Our test presents film segments and tests how consistantly you
can be a witness.
Aleader is the software used to administer the test.
It combines a video player, annotation tools,
and a scoring system into an easy to use GUI.';

  element 'p', "So what is assessment quotient (AQ)?  Let us
consider AQ's relationship with spiritual traditions, personality
development, and general harmony with society:";

  startTag 'table', cellspacing => 10, cellpadding => 0, border => 0;

  startTag 'tr';

  my $bgcolor = 'LightYellow1';
  startTag 'td', valign => 'top', bgcolor => $bgcolor;
  text 'There is a concept called "witness state" noted in many ';
  element 'b', 'spiritual traditions';
  text '.  Here we are interested in the definition of witness
state which is practical in daily life.
For example, if a boy verbally insults me then what do i do?
Do i start a fight on the spot?  If i am trying for a witness
state then i will not react immediately to a verbal insult.  i
will take an appropriate amount of time to consider the whole
situation.  Once i have a cool head, then i can decide on
a action (if any).';
  endTag 'td';
  endTag 'tr';

  startTag 'tr';
  startTag 'td', valign => 'top';
  text 'To what extent am i in the witness state?  How
much do i know about the witness state?  In the past, these
questions were mostly a matter of personal introspection.  Now you can
objectively measure your witnessing power as assessment quotient.';
  endTag 'td';
  endTag 'tr';

  startTag 'tr';
  element 'td', '*', align => 'center';
  endTag 'tr';

  startTag 'tr';
  startTag 'td', valign => 'top', bgcolor => $bgcolor;
  text 'The witness state is closely related to personality development. ';
  element 'b', 'Personality development';
  text " generally focuses on the student's reaction to a given situation.
Certainly choosing the correct reaction *is* important.
However, deciding on a reaction depends on assessing
the situation accurately.
If your perfect reaction is based on a misreading of the situation
then how can you expect to act effectively?";
  endTag 'td';
  endTag 'tr';

  startTag 'tr';
  startTag 'td', valign => 'top';
  text "If my AQ is below average then attending a personality
development course will do more harm that good.  Many of my new
reactions will be wrong or seem artificial.  Fortunately, now we
can measure AQ numerically.  If my assessment quotient is below
average then i can invest time in raising my AQ, clearing the
way for constructive personality development.";
  endTag 'td';
  endTag 'tr';

  startTag 'tr';
  element 'td', '*', align => 'center';
  endTag 'tr';

  startTag 'tr';
  startTag 'td', valign => 'top', bgcolor => $bgcolor;
  text 'One who has experienced the wider variety of situations
is better attuned to understand the thoughts and reactions of others.
Such a person can live in greater ';
  element 'b', 'harmony with society';
  text ' and derive
greater meaning and pleasure out of life.  However, gaining awareness
of such a vast variety of situations typically requires an
entire lifetime.';
  endTag 'td';
  endTag 'tr';

  startTag 'tr';
  startTag 'td', valign => 'top';
  text 'What if there were a way to understand all possible
situations in a short amount of time?  What if students could attain
the clarity of a wise old man';
  note 'AQ helps reach the clarity of a wise old man,
but not the personality of a wise old man.';
  text ' in less than a year?
This is a promise and benefit of increasing the assessment quotient.';
  endTag 'td';

  endTag 'tr';
  endTag 'table';

  startTag 'p';
  text 'Aleader uses a non-mystical, statistical approach to measure
situation assessment ability (or witnessing power).
This project is strictly non-profit.
The software is licensed under the ';
  element 'a', 'GPL', 'href', 'http://www.gnu.org/philosophy/philosophy.html';
  text ' and is freely available from the ';
  element 'a', 'download page', href => 'download.html';
  text '.';
  endTag 'p';
  
  show_notes();

  element 'h1', "News";

  startTag 'p';
  text '[26 Apr 2002] Courtesy of the Institute of Management,
Research & Technology here in Nashik, the results of our first
small research study are ';
  element 'a', 'available', href => 'imrt.html';
  text '!';
  endTag 'p';

};

menupage $topmenu, 'History', sub {
  element 'h1', "Old News";
  
  element 'p', '[11 Jun 2002] After trying to discuss emotional
intelligence for about a year, i am confident that
this terminology is not suitable.
Henceforce, "emotional intelligence" is changed to "situation assessment".';

  startTag 'p';
  columns sub {
    text '[12 Feb 2002] We plan to start giving regular tests at a local
college here in Maharashtra.  Since the mother tongue is Marathi,
we are slowly translating the most important screens.  Here is an
snapshot of our progress.';
  },
  sub { hskip 4 },
  sub {
    img 'marathi_demo1.png', 'Situations in Marathi';
  };
  endTag 'p';

  element 'p', '[23 Jan 2002] A pre-compiled binary is available
for Debian i386.';

  startTag 'p';
  text '[5 Dec 2001] Assuming the cooperation of upstream
libraries, a binary release of Redael will be made
within a few months (1Q02).  As part of the release,
i would very much like to make available
some exemplar annotations. However, this will depend upon
the vagaries of international copywrite law.  Can anyone comment
on a preliminary ';
  element 'a', 'fair use statement',
    href => 'fairuse.html';
  text '?';
  endTag 'p';

  element 'p', '[3 Oct 2001] The basic features of the software have
been working since two days ago.  A few patches are pending with
upstream libraries, but everything should be resolved for
out-of-the-box, no-fuss compilation on the order of weeks.  (In
other words, my personal software development nightmare is
almost over. :-)';

  element 'p', '[18 Sep 2001] A re-designed web site goes online
with a more pragmatic approach.';

  startTag 'p';
  text '[22 Feb 1999] After attending my first puja of ';
  element 'a', 'Mataji Shri Nirmala Devi',
    href => 'http://theworldsavior.org';
  text ' in New Jersey (USA), the importance of the
word "competition" was revealed to me. i started writing down
everything i could discover about competition without any idea
where it would lead.';
  endTag 'p';
};

menupage $topmenu, 'Download', sub {
  columns sub {
    element 'h1', 'Get the Software';
  },
  sub { hskip 2 },
  sub {
    startTag 'a', href => 'http://www.gnu.org/philosophy/philosophy.html';
    img 'floating.jpg', 'GNU Software', border=>0, hspace=>4;
    endTag 'a';
  };

  element 'h2', 'Requirements';

  startTag 'font', color => 'red';
  startTag 'p';
  text 'Old versions of the software are available but they
are difficult to compile and do not work very well.
We are currently preparing a new release.  The latest
snapshot is ';
  element 'a', 'here', href => 'ftp://ftp.berlios.de/pub/redael/aleader-0.9.0.tar.bz2';
  text '.';
  endTag 'p';
  endTag 'font';

  startTag 'p';
  text 'If your computer is fast enough to playback VCD format films
then you computer is fast enough to use Aleader.  Aleader is as
portable as ';
  element 'a', 'Gtk+', href => 'http://gtk.org';
  text ' and ';
  element 'a', 'Gstreamer', href => 'http://gstreamer.net';
  text '.  If these two libraries are ported to your chipset
and operating system then, chances are, Aleader will also work.';
  endTag 'p';

  element 'p', 'In addition to the Aleader software, you will need
some films with an exemplar to get started.';

  element 'h2', 'Films';

  element 'p', 'i selected some of my favorite films for initial
analysis.  As more films are analyzed, the exemplars will appear here.';

  startTag 'table', border=>1;
  startTag 'tr';
  element 'th', 'Title';
  element 'th', 'Blurb';
  element 'th', 'Rating';
  element 'th', 'Status';
  element 'th', 'Annotation';
  endTag 'tr';

  startTag 'tr';
  startTag 'td';
  element 'a', 'Kaze no Tani no Naushika (1984)',
    href => 'http://www.nausicaa.net/miyazaki/nausicaa/';
  endTag 'td';
  element 'td', 'Epic Animated Adventure';
  element 'td', 'All Ages';
  element 'td', '5%';
  startTag 'td';
  #element 'a', '22k', href => 'annotation/naushika35';
  text 'soon';
  endTag 'td';
  endTag 'tr';

  startTag 'tr';
  startTag 'td';
  element 'a', 'Good Will Hunting (1997)',
    href => 'http://www.un-official.com/GWH/GWMain.html';
  endTag 'td';
  element 'td', 'Drama';
  element 'td', '17+ (language, adult themes)';
  element 'td', '0%';
  element 'td', 'soon';
  endTag 'tr';

  startTag 'tr';
  startTag 'td';
  element 'a', 'Star Wars: A New Hope (1977)',
    href => 'http://www.starwars.com/episode-iv/';
  endTag 'td';
  element 'td', 'Space Opera';
  element 'td', 'All Ages';
  element 'td', '0%';
  element 'td', 'soon';
  endTag 'tr';

  endTag 'table';

  element 'p', 'Films which will not be analyzed here: most comedy, horror,
and action movies (unless especially insightful).  Why not?  Because these
films generally offer a monotonous emotional structure.  Consider the
following chart:';

  startTag 'center';

  startTag 'table', border => 1;
  startTag 'tr';
  element 'th', 'Film Genre';
  element 'th', 'Situation';
  element 'th', 'Example';
  endTag 'tr';

  startTag 'tr';
  element 'td', 'Comedy';
  element 'td', '[0] observes [-]';
  element 'td', 'The Great Dictator (1940)';
  endTag 'tr';

  startTag 'tr';
  element 'td', 'Horror (serious)';
  element 'td', '[-] is made uneasy by [0]';
  element 'td', 'Alien (1979)';
  endTag 'tr';

  startTag 'tr';
  element 'td', 'Action';
  element 'td', '[+] exposes [-]';
  element 'td', "Jackie Chan's Police Story (1985)";
  endTag 'tr';

  endTag 'table';

  startTag 'blockquote';
  startTag 'i';
  text 'Even if a film is excellent and entertaining,
these genres probably do not offer enough emotional complexity
to serve as a basis for Aleader annotations.';
  endTag 'i';
  endTag 'blockquote';

  endTag 'center';

# Ghost (1990)
# Devil's Advocate (1997)

  startTag 'p';
  text 'i heartily recommend ';
  run "cp thematrix.html root/thematrix.html";
  element 'a', 'The Matrix (1999)', href => 'thematrix.html';
  text ', however, this film is not really a good film to analyze
with Aleader.  The beauty of this film is less due to its
abstract emotional content.';
  endTag 'p';
};

if (0) {
menupage $topmenu, 'Debian', sub {
  element 'h1', 'Debian Installation';

  element 'p', 'GStreamer debs beyond 0.3.1 are not supported
yet.  You can install debs for glib/gtk+ but then
follow the Unix installation, instead of the instructions below:';

  startTag 'font', color=>'gray';

  element 'p', 'Add the following lines to /etc/apt/sources.list:';

  startTag 'p';
  startTag 'blockquote';
  startTag 'pre';
  text 'deb http://gstreamer.net/releases/debian ./
deb http://redael.berlios.de/releases/debian ./
';
  endTag 'pre';
  endTag 'blockquote';
  endTag 'p';

  element 'p', 'Then simply use apt-get:';

  startTag 'p';
  startTag 'blockquote';
  startTag 'pre';
  text '# apt-get update
# apt-get install aleader
';
  endTag 'pre';
  endTag 'blockquote';
  endTag 'p';

  endTag 'font';
};

menupage $topmenu, 'Unix', sub {
  element 'h1', 'Generic Unix Installation';

  element 'p', 'If your operating system is not listed then you
can compile Aleader from source code.';

  startTag 'p';
  columns sub {
    startTag 'a', 'href', 'http://gtk.org/download/';
    img 'gnomelogo.png', 'Gnome', 'border', 0;
    endTag 'a';
  },
  sub { hskip 6 },
  sub {
    text 'Install 1.3.13 or later versions of glib, atk, pango, and gtk+.';
  };
  endTag 'p';

  startTag 'p';
  columns sub {
    startTag 'a', 'href', 'http://www.gstreamer.net/';
    img 'gstlogo.png', 'Gstreamer', 'border', 0;
    endTag 'a';
  },
  sub { hskip 6 },
  sub {
    element 'p', 'Install gstreamer 0.3.1.  To build the plugins,
you will also need some libraries:
libbz2, libmpeg2 0.2.0, liba52 0.7.2, hermes, and mad.';

    startTag 'font', color =>'red';
    element 'p', 'ALERT: Aleader has not been ported to gstreamer 
version 0.3.2 or later yet.  You must use exactly version 0.3.1.';
    endTag 'font';
  };
  endTag 'p';

  startTag 'p';
  startTag 'a', href=>'http://developer.berlios.de/project/filelist.php?group_id=167';
  text 'Download the latest snapshot of Aleader source code.';
  endTag 'a';
  endTag 'p';
};
}

menupage $topmenu, 'Mailing Lists', sub {
  element 'h1', 'Mailing Lists';

  my $list = sub {
    my ($name, $desc, $vol) = @_;

    startTag 'li';
    startTag 'p';
    element 'b', $name;
    text ' - ';
    element 'a', 'Subscribe', 'href', "https://lists.berlios.de/mailman/listinfo/$name";
    text ' / ';
    element 'a', 'Archives', 'href', "https://lists.berlios.de/pipermail/$name";
    endTag 'p';

    startTag 'p';
    text $desc;

    br;

    startTag 'i';
    text $vol;
    endTag 'i';
    endTag 'p';

    endTag 'li';
  };

  startTag 'ul';

  $list->('redael-announce',
	  'Announcements about releases or other important events.',
'At most one message per day.');

  $list->('redael-devel',
	  'Technical discussions about software development and philosophy.',
'Can be high volume on occation.');

  endTag 'ul';
};

menupage $topmenu, 'High Scores', sub {
  element 'h1', 'Scores';

  element 'p', 'This page contains a compilation of AQ test results.
Send email with
your results to get listed here.  Obviously you can forge any results,
however, honesty can keep this page somewhat useful.  Certified results
obtained through professional testing methods will be placed on a different
web page.';

  startTag 'font', color => 'red';
  element 'p', 'The scores are reset due to minor changes in the
weighting and score reporting.';
  endTag 'font';

if (0) {
  startTag 'center';

  startTag 'table', border=>1, cellpadding=>4;

  startTag 'tr';
  element 'th', 'Date';
  element 'th', 'Name';
  element 'th', 'Location';
  element 'th', 'Film';
  element 'th', 'Match';
  element 'th', 'AQ';
  element 'th', 'Note';
  endTag 'tr';
  
  for my $s (@$Scores) {
    startTag 'tr';
    element 'td', $s->[0];
    element 'td', $s->[1];
    # gender, SY : hidden
    element 'td', $s->[4];
    element 'td', $s->[5];
    element 'td', $s->[6];
    element 'td', $s->[7];
    element 'td', $s->[8] || '';
    endTag 'tr';
  }
  endTag 'table';

  startTag 'blockquote';
  element 'p', 'Notes: 1 and 2 indicates that the test was of depth
1 or 2 (instead of 3).  P indicates a practice test.';

  endTag 'blockquote';

  endTag 'center';
}
};

menupage $topmenu, 'Philosophy', sub {
  element 'h1', 'What is Philosophy?';

  startTag 'p';
  element 'i', 'Perhaps there are many definitions, but here we mean: ';
  endTag 'p';

  startTag 'blockquote';
  text 'Pursuit of the truth.';
  br;
  text 'An analysis of the grounds of and
concepts expressing fundamental beliefs.';
  endTag 'blockquote';

  element 'h1', 'Yoga';

  element 'p', 'Yoga is an ancient sanskrit word which
means approximately "union with the divine."  
Here we present a secular model of reality on
which yoga is seen to take place.
Any such model is a miniature representation, and a *good* model
confers tangible insight into reality and joy.';

  element 'h2', 'Categories of Feeling';

  columns sub {
  element 'p', 'The words emotion, spirit, and feeling are used to mean a
variety of different things in different contexts.  The defintions used
here are as follows:';

  },
  sub {
    img 'feelings.png', 'Feelings';
  };

  startTag 'ul';
  startTag 'li';
  text "`Emotion' is a feeling which arises in the context of two separate people.";
  note "We can give a definition for `thought',
however, distinguishing between thought and emotion is not necessary
for this discussion. Here `emotion' is meant inclusive of thought --
some non-physical sensation arising in the context of two separate people.";
  endTag 'li';
  startTag 'li';
  text "`Spirit' is a feeling which does not admit the idea of separation.";
  endTag 'li';
  startTag 'li';
  text "`Compassion' is a special feeling which bridges spirit to emotion.";
  note "Emotion doesn't require two living breathing people.
Only the *context* of two people is important.
For example,
if you have compassion for a stone then emotion can
arise between you and the stone (maybe you are a sculptor).
Anthropomorphic emotions are still emotions.";
  endTag 'li';
  startTag 'li';
  text "`Feeling' is the most general word, including emotion,
spirit, and compassion.";
  endTag 'li';
  endTag 'ul';

  show_notes();

  element 'h2', 'Compassion';

  columns sub {

  startTag 'p';
  text 'Compassion awakens gradually in each individual.
A good mother ususally sooths the development into a balanced path.
If for some reason compassion goes out of balance then
horrible atrocities can result.  The business of slavery
and the Nazi killings in Germany can be attributed to a
terrible imbalance in compassion.';
  endTag 'p';
  startTag 'p';
  text 'Before compassion awakens, an individual can be described
as follows:  His main focus is on the ';
  nth(1);
  text ' person perspective.  There is no partition between personality
and emotion.  There are no situations, only *my* situation (singular).
Charming, huh?
As compassion dawns, the four perspectives come into focus:';
  endTag 'p';

  },
  sub { hskip 4 },
  sub {
    emptyTag 'img', src=>'nocompassion.jpg', alt => 'No Compassion';
  };

  startTag 'center';
  columns sub {
    startTag 'i';
    text 'Balanced compassion';
    br;
    text 'crystalizes the';
    br;
    text 'four perspectives:';
    endTag 'i';
  },
  sub { hskip 10 },
  sub {
    emptyTag 'img', src => 'fourpp.jpg', alt => 'Four Perspectives';
  },
  sub { hskip 4 },
  sub {
    startTag 'table', border=>0, cellspacing=>0, cellpadding=>0;
    row sub { nth(3); text ' person perspective (situation)' };
    row sub { nth(2); text ' person perspective (personality)' };
    row sub { nth(1); text ' person perspective (emotion)' };
    row sub { nth(0); text ' person perspective (pure spirit)' };
    endTag 'table';
  };
  endTag 'center';

  element 'p', 'That fostering compassion is "the answer" is nothing new.
However, we can do better than talking about it in the typical
vague terms. Since balanced compassion is defined as awareness
of the four perspectives, we can study the relationships
between perspectives. These relationships may reveal a way to
foster compassion with scientific certainty.';

  element 'h2', 'Subject / Object';

  startTag 'p';
  columns sub {
    text "`Subject' and `object' describe end-points of an attention vector.
(These words are not meant in a strict grammatical sense.)
The subject is the origin of attention.  Attention is focused on an object,
the object is enveloped with awareness, and the subject is informed
about the object.";
  },
  sub {
    emptyTag 'img', src => 'informs.png', alt => 'Informs',
      width => 206, height => 64;
  };
  endTag 'p';

  element 'h2', 'Attention Configurations';

  element 'p', 'Within the realm of compassionate individuality,
there are various ways attention can be configured.  What
are all the permutations?  The connection with grammer makes
it is easy to generate examples to invoke a given configuration.
Once posed as an example, we can consider the utility of a configuration
and draw any further conclusions.';

  startTag 'p';
  columns sub { attention 0,1 },
    sub { hskip 2 },
      sub {
	element 'tt', 'detachment'; br;
        text 'For example: "i am angry, but i am detached from
my anger.  The anger is an object of my attention.  i forgive,
i forgive.  Now i do not feel angry."';
      };
  endTag 'p';

  startTag 'p';
  columns sub { attention 1,3 },
    sub { hskip 2 },
      sub {
        element 'tt', 'empathy';  br;
	text 'Perhaps the most obvious example of empathy is
what happens while watching a film.  A film is nothing but ';
	nth 3;
	text ' person perspective: images and sound.  However,
people can easily empathize with the actors and *feel* a
precise replica of the emotions depicted onscreen.  The film
is the object and emotion is the subject, hence "empathy."';
        note 'A few people fail to developed a sense of empathy
as children.  Such people are called "autistic".';
      };
  endTag 'p';

  startTag 'p';
  columns sub { attention 3,1 },
    sub { hskip 2 },
      sub {
	startTag 'font', color=> EICOLOR;
        element 'tt', 'situation assessment'; br;
	text '"Based on how i feel, what is the structural situation?"
This style of question is repeatedly posed in Aleader annotations.';
	endTag 'font';
      };
  endTag 'p';


  startTag 'p';
  columns sub { attention 1,2 },
  sub { hskip 2 },
  sub {
    element 'tt', 'follow everyone else'; br;
    text '"What are other people doing?"  Extra-ordinary personal
preference and fashions are expressions of this configuration of
attention.  For example, "Everyone is going to the pub therefore
i will also go to the pub."';
  };
  endTag 'p';

  startTag 'p';
  columns sub { attention 2,1 },
  sub { hskip 2 },
  sub {
     element 'tt', 'ideal role-model'; br;
     text 'How would an ideal personality behave?
For example, "How would my mother behave in my place?"  Parents
or great teachers of morality can serve as a role-model.';
  };
  endTag 'p';

  element 'p', "The word 'character' generally indicates the
relationship between emotion and personality: 
A person with poor character will often follow whims or trends.
A person with sound character behaves in accord with ideal principles.";

  startTag 'p';
  columns sub { attention 0,0 },
    sub { hskip 2 },
      sub {
        element 'tt', 'self-realization'; br;
	text "If you have *not* experienced self-realization then
please visit a local ";
	element 'a', 'Sahaja Yoga', href=>'http://sahajayoga.org';
	text " center and feel the divine cool breeze.
Self-realization will turn this theoretical discussion
into your living reality.";
      };
  endTag 'p';

  startTag 'p';
  columns sub { attention 1,0 },
    sub { hskip 2 },
      sub {
        element 'tt', 'divine expression'; br;
	text 'After meditation, part of my attention remains
connected with the spirit, thereby enlightening the experience
of individuality.
Divine expression makes individuality most beautiful and enjoyable,
much more so than any physical or mental amusement.';
      };
  endTag 'p';

  startTag 'p';
    text "Attention flows between the ";
    nth(0);
    text ' and ';
    nth(1);
    text '; ';
    nth(1);
    text ' and ';
    nth(2);
    text '; and ';
    nth(1);
    text ' and ';
    nth(3);
    text ' perspectives. ';

    text 'Jumping directly between the ';
    nth(2);
    text ' and ';
    nth(3);
    text " perspectives doesn't make sense.  ";

  text 'The following table and diagram summarize all sensical
configurations:';
  endTag 'p';

  startTag 'center';
  columns sub {
    emptyTag 'img', src=>'trident.png', alt=>'Attention Trident';
  },
  sub { hskip 10 },
  sub {
    startTag 'p';
    columns sub { text '(a) ' },
    sub { text 'detachment'; attention 0,1 };
    endTag 'p';

    startTag 'p';
    columns sub { text '(b) ' },
    sub { text 'empathy'; attention 1,3 },
    sub { hskip 6 },
    sub { text '(c) ' },
    sub {
      startTag 'font', color=> EICOLOR;
      text 'situation assessment';
      endTag 'font';
      attention 3,1 };
    endTag 'p';

    startTag 'p';
    columns sub { text '(d) ' },
    sub { text 'follow everyone else'; attention 1,2 },
    sub { hskip 6 },
    sub { text '(e) ' },
    sub { text 'ideal role-model'; attention 2,1 };
    endTag 'p';

    startTag 'p';
    columns sub { text '(f) ' },
    sub { text 'self-realization'; attention 0,0 },
    sub { hskip 6 },
    sub { text '(g) ' },
    sub { text 'divine expression'; attention 1,0 };
    endTag 'p';
  };
  endTag 'center';

  show_notes();

  element 'h2', 'Toward Self-Identity';

  columns sub {
  element 'p', 'Our goal is divine expression (g).
The challenge is to get the attention focused on pure spirit.
Self-realization (f) is the only configuration to accomplish this
(pure spirit as an object).
Even so, the attention quickly flows outward into other configurations
and the divine quality (g) of attention is soon dilute.';

    startTag 'p';
    text 'To restart the divine flow, we need a way to consistently
place our attention in the configuration of self-realization (f).
However, neither self-realization (f) or divine expression (g) are
easily accessible because their object is pure spirit.
How to focus the attention on pure spirit?
The attention is lost in seemingly infinite variations of experience.
Detachment (a) is essential to elminate the confusion.
This configuration (a) is unique: the pure spirit is present
(as the subject) and the object tangible.
None of the other accessible configurations';
    note 'Configurations (a), (b), (c), (d), and (e) are easily accessible
because their object is something tangible.';
    text ' even involve the pure spirit.';
    endTag 'p';

    element 'p', 'Detachment (a) is a most subtle topic.
H. H. Shri Mataji describes it well:
"The spirit is like the steady axis of a wheel. If
our attention reaches the immovable firm axis at the very centre of the
wheel of our existence (which is constantly moving), we become
enlightened by the spirit, the source of inner peace, and reach a state
of complete calm and self-knowledge."
In geometric terms, the attention ceases to be a vector (looking
from here to there) and resolves to the point of complete calm.';

    columns sub {
      element 'p', '
If detachment (a) supports self-realization (f) then
what kind of experiences support detachment (a)?
The pressures of daily life keep attention bouncing
around the various configurations.
At least the emotions can be kept as the object of
attention.  If emotion is the object then the attention is
already halfway configured as detachment (a).';

      startTag 'p';
    text 'While having some importance,
empathy (b) and following everyone else (d) need not
be full-time pursuits.  The two remaining attention configurations
take emotion as the object: (c) and (e).
Studying an ideal role-model (e)
is one of the special configurations, however, here we are
concerned exclusively with ';
    element 'font', 'situation assessment (c)', color=>EICOLOR;
    text '.';
      endTag 'p';
    },
    sub { hskip 2 },
    sub {
      text '(a) detachment';
      attention 0,1,'o'; br;
      element 'font', '(c) situation assessment', color=>EICOLOR;
      attention 3,1,'o'; br;
      text '(e) ideal role-model';
      attention 2,1,'o';
    };
    show_notes();
  },
  sub {
    startTag 'center';
    element 'h3', 'Summary';
    endTag 'center';

    startTag 'ul';
    startLi;
    text 'Self-realization (f) converts to divine expression (g), but
divine expression is soon diluted by subsequent experiences.';
    endLi;

    startLi;
    text 'Only detachment (a) can lead to self-realization (f).';
    endLi;

    startLi;
    text 'Detachment (a) demands a subtle understanding
of thought and emotion.';
    endLi;

    startLi;
    text 'Detachment (a) is supported when emotion is the
object of attention.';
    endLi;

    startTag 'center';
    img 'trident-sr.png', "Emotion as Object";
    endTag 'center';

    startLi;

    text 'The configurations ';
    element 'font', 'situation assessment (c)', color=>EICOLOR;
    text ' and ideal role-model (e) both take emotion as
the object of attention.';

    endLi;

    endTag 'ul';
  };
};

menupage $topmenu, 'Research & Professional', sub {
  element 'h1', 'The Next Step';

  element 'h2', 'Research';

  startTag 'p';
  text 'This project should be of interest to lots of research grants,
and there is plenty of work to do.
The methodology used in Aleader has only been tested on
a hand-full of people.  Larger scale scientific studies are needed
to better reveal its effectiveness. ';
  text 'There are basically two things which need to be
established statistically:';

  endTag 'p';

  startTag 'ul';
  startLi;
  text 'How many hours of practice does it take to produce
an accurate AQ score?';
  endLi;
  startLi;
  text 'Does well does our AQ score correlate with career
performance?';
  br;
  text '(Personality development has shown significant
correlation with career performance.  Therefore, AQ should
also show significant correlation because AQ is a prerequisite
for developing the personality.)';
  endLi;
  endTag 'ul';

  startTag 'p';
  text "If you have run a psychology experiment in college then
you are qualified to apply for a grant.  Programming skills are
not necessary.  For example, consider NIH grant ";
  startTag 'a', href => 'http://grants.nih.gov/grants/guide/pa-files/PA-00-105.html';
  text 'PA-00-105';
  endTag 'a';
  text '.  On the other hand, a grant is not even necessary
for a small study.  You just need one computer, a small
group of students, and time commitment.';
  text '  For example, see the study we did at '; element 'a', 'IMRT', href=>'imrt.html'; text '.';
  endTag 'p';

  element 'h2', 'Certified AQ Testing';

  startTag 'p';
  text 'Once some studies are completed then we can approach
business and government human resources departments.
There are already successful companies in this sector such
as those affiliated with ';
  startTag 'a', href => 'http://www.eiconsortium.org';
  text 'EI Consortium';
  endTag 'a';
  text '.  Anyone is welcome to do this -- the code
is licensed under the ';
  element 'a', 'GPL', href=> 'http://www.gnu.org/copyleft/gpl.html';
  text ' -- so you can start your own AQ testing franchise, royalty free.';
  endTag 'p';
};

our $ScoresIMRT;
require './scores.imrt';

menupage $topmenu, 'IMRT', sub {
  element 'h1', 'Research Study #1';

  startTag 'p';
  startTag 'center';
  columns sub {
    startTag 'big';
    startTag 'center';
    text "Nashik District Maratha Vidya Prasarak Samaj's"; br;
    text 'Institute of Management, Research & Technology'; br;
    text 'M.V.P. Campus, Shivajinagar, Gangapur Road, Nashik-422002';
    endTag 'center';
    endTag 'big';
  },
  sub { hskip 8 },
  sub {
    startTag 'center';
    thumb 'imrt0.jpg', 'IMRT Entrance';
    endTag 'center';
  };
  endTag 'center';
  endTag 'p';

  element 'p', 'IMRT is recognized as a research institute by the
university of Pune for Ph.D. in Management, Commerce, and Social
Sciences.';

  element 'p', 'We would like to express gratitude
to Dr. B. B. Rayate Sir, director of IMRT for granting us permission to
conduct our testing.
We would also like to thank Mr. Faruk K. Shaikh Sir, Master of Social Work,
for his support.';

  element 'p', 'When: 10 April -> 19 April 2002';

  element 'p', 'Who: 2nd year Master of Social Work students';

  element 'p', 'Film: Nausicaa (Japanese with an English transcript)';

  element 'p', "Method: The students were given at least 30 minutes
to prepare for the test:  We played the relevant section of the film.
We demonstrated how to take the test.  We gave them time to become
comfortable with operating the computer.  We gave them a short practice
test.  During the test, we asked each student to give answers for
10 situations.";

  startTag 'table';
  startTag 'tr';
  element 'th', 'Date';
  startTag 'th'; hskip 1; endTag 'th';
  element 'th', 'Name';
  element 'th', 'Prefers';
  element 'th', "Language Problem?";
  element 'th', 'Enough Time?';
  element 'th', 'Time';
  startTag 'th'; hskip 1; endTag 'th';
  element 'th', 'AQ';
  element 'th', 'Rank';
  endTag 'tr';

  my %Lang = (
    'e' => 'English',
    'm' => 'Marathi',
    'h' => 'Hindi',
    'o' => 'Other',
  );
  my %YesNo = (
    0 => 'No',
    1 => 'Yes',
  );

  @$ScoresIMRT = sort { $b->[7] <=> $a->[7] } @$ScoresIMRT;

  for (my $x=0; $x < @$ScoresIMRT; $x++) {
    my $r = $ScoresIMRT->[$x];
    startTag 'tr';
    element 'td', "$r->[0]/04";
    element 'td', '';
    element 'td', $r->[1];
    my @l = split / */, $r->[2];
    my $lang = join ', ', map { $Lang{ $_ } } @l;
    element 'td', $lang;
    element 'td', $YesNo{ $r->[3] };
    element 'td', $YesNo{ $r->[4] };
    element 'td', $r->[5];
    element 'td', '';
    element 'td', $r->[7], align => 'right';
    element 'td', 1+$x, align => 'right';
    endTag 'tr';
  }
  endTag 'table';

  element 'p', 'The maximum AQ one can achieve is 60.';

  startTag 'p';
  text 'We gave a "Post-Test Evaluation".  Here are
some examples of the response we received.  ';
  startTag 'font', color=>'red';
  text '[Note: The
statistic was called "emotional intelligence" instead of
"situation assessment" when these evaluations were written.]';
  endTag 'font';
  endTag 'p';

  columns sub {
    thumb 'posttest1.jpg', 'Bhagade Arun Ramdas';
  },
  sub {
    thumb 'posttest4.jpg', '(backside)';
  },
  sub { hskip 4 },
  sub {
    text 'Through this test we get a knowledge:
how to concentrate more and how to get more intelligence.
Simultaneously through this test, we acquire more knowledge.
We come to know the importance of time.  Concentration is
very important.  What i most like about the test is that
i myself was operating everything.  Through this i understood
the importance of time, intelligence, mind, attention, brain,
emotions and how to bring all these things together -- how
to concentrate and get more good results out of it.  i want
to know about this test in detail.';
  };
  br;
  columns sub {
    thumb 'posttest2.jpg', 'Prakash Genoo Bhagade';
  },
  sub {
    thumb 'posttest3.jpg', '(backside)';
  },
  sub { hskip 4 },
  sub {
    text 'Emotional intelligence is not an academic course
but it has more concentration towards intelligence.  That is
why this is a very useful test.  This test is really meant
to increase the emotional intelligence.  Through this test
we come to know how much emotional intelligence we have and
through this test we become more concentrated.  Nothing
boring in this test.  i want to know more about this test.
i am sure that if i give this test again then it will help
to increase my emotional intelligence.  i like this test
very much.  There is nothing to dislike about this test but
i want more information regarding situations.';
  };

  element 'p', 'We did find one problem in the answer key.
Most of the students disagreed with my assessment of
situation #15.  Since the answer key should express the
majority opinion, the answer key was updated, clarified,
and the scores were recalculated.';

  element 'h2', 'Conclusions';

  startTag 'ul';
  startLi;
  element 'p', 'Almost all the students reported that they had enough
time to understand the test.  This shows that the test is easy to
administer.';
  endLi;

  startLi;
  element 'p', 'Half the students reported no problem understanding the language.';
  endLi;

  startLi;
  element 'p', 'We found that students really enjoyed answering the test.
This was the most gratifying aspect of the research.
The students expressed faith that the test would help them become sharp
in taking decisions and improve at situation assessment.';
  endLi;
  endTag 'ul';

  startTag 'center';
  columns sub {
    img 'imrt1.jpg', 'Day 1';
  },
  sub { hskip 4 },
  sub {
    img 'imrt2.jpg', 'Day 2';
  };
  endTag 'center';

};

exit; # skip chapter generation

for my $file (keys %Chapter) {
  my $ch = $file;
  $ch =~ s/\.html$/-ch.html/;

  page $ch, sub {
    element 'title', $file;
    endTag 'head';
    body 10;

    for my $x (@{$Chapter{$file}}) {
     $x->();
    }

    vskip 1;

    columns sub { hskip 2 },
    sub {
      emptyTag 'hr';
      element 'p', 'Copyright (C) 2001, 2002, 2003 Joshua Nathaniel Pritikin.  Verbatim copying and distribution of this entire article is permitted in any medium, provided this notice is preserved.';
      emptyTag 'hr';
    },
    sub { hskip 2 };
  };
};

__END__

This test is only concerned with situation assessment.  It leaves the
question of choosing the perfect reaction up to your spontaneous
creativity.

Algorithmic definition of Happiness

#!/usr/bin/perl -w

use 5.6.1;
use strict;
use Fatal qw(open);

BEGIN {
  require "./minixml.pl";
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
  emptyTag 'img', src=>$src, alt=>$alt, @rest;
}

sub thumb {
  my ($src, $caption) = @_;

  if (!-e "$src") {
    warn "$src doesn't exist";
    return;
  }
  
  my $sm = $src;
  if ($sm =~ s/\.jpg$/-sm.jpg/) {
    if (modtime("$src") > modtime("$sm")) {
      run "cp $src $sm";
      run "mogrify -geometry 160x160 $sm";
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
  my ($s, $o) = @_;
  
  startTag 'table', border=>1, cellpadding=>3, cellspacing=>0;
  startTag 'tr';
  startTag 'th';
  text 'subject:';
  hskip;
  nth $s;
  endTag 'th';
  startTag 'th';
  text 'object:';
  hskip;
  nth $o;
  endTag 'th';
  endTag 'tr';
  startTag 'tr';
  startTag 'td';
  nth_ex $s;
  endTag 'td';
  startTag 'td';
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
  img 'art/about_sy_chart.png', 'Chakra System', border=>0;
  br;
  element 'a', 'En Masse Self-Realization', 'href', 'http://sahajayoga.org';
  endTag 'td';
  
  startTag 'td', 'align', 'center', valign=>'bottom';
  img 'art/trident.png', 'Attention Trident', border => 0;
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
	 ['Download'           => 'download.html',
	  [
	   [Debian             => 'dl-debian.html'],
	   [Unix               => 'dl-unix.html'],
	   [Windows            => 'dl-windows.html'],
	  ]
	 ],
	 ['Documentation'     => 'doc.html',
	  [
	   ['Acknowledgment'  => 'doc-intro.html'],
	   ['Getting Started' => 'doc-starting.html'],
	   ['Film'            => 'doc-film.html'],
	   ['Situation'       => 'doc-situation.html'],
	   ['Joints'          => 'doc-joints.html'],
	   ['X-Reference'     => 'doc-xref.html'],
	   ['Exam'            => 'doc-exam.html'],
	   ['Disagreement Resolution' => 'doc-disagree.html'],
	  ]],
	 ['Mailing Lists'     => 'lists.html'],
	 ['High Scores'       => 'scores.html'],
	 ['Research & Professional' => 'jobs.html',
	  [
	   ['IMRT'            => 'imrt.html'],
	  ]
	 ],
	 ['Philosophy'        => 'philo.html',
	 [
	  ['Aleader'           => 'philo-redael.html'],
	 ]],
	]);

require 'marriage.pl';
require 'realization.pl';

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
    if ($is_chapter) {
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
      element 'p', 'Copyright (C) 2001, 2002 Joshua Nathaniel Pritikin.  Verbatim copying and distribution of this entire article is permitted in any medium, provided this notice is preserved.';
      element 'p', 'Last modified @DATE@.';
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
      element 'p', 'Copyright (C) 2001, 2002 Joshua Nathaniel Pritikin.  Verbatim copying and distribution of this entire article is permitted in any medium, provided this notice is preserved.';
      element 'p', 'Last modified @DATE@.';
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

  element 'p', "Personality development generally focuses on the student's
reaction to a given situation.
Certainly choosing the correct reaction *is* important.
However, deciding on a reaction depends on assessing
the situation accurately.
If your perfect reaction is based on a misreading of the situation
then how can you expect to act effectively?";

  element 'p', 'Our concern is with measuring and increasing
AQ (assessment quotient).
Our test presents film segments and tests how consistantly you
can be a witness.
Aleader is the software used to administer the test.
It combines a video player, annotation tools,
and a scoring system into an easy to use GUI.';

  startTag 'p';
  text 'This project is strictly non-profit.
The software is licensed under the ';
  element 'a', 'GPL', 'href', 'http://www.gnu.org/philosophy/philosophy.html';
  text ' and is freely available from the ';
  element 'a', 'download page', href => 'download.html';
  text '.';
  endTag 'p';
  
  element 'h1', "News";

  startTag 'p';
  text '[08 Jul 2002] What are all the different emotions and
how can we organize them?  Now you can browse a hyper-linked ';
  element 'a', 'empathy map', href => 'empathy/index.html';
  text '.';
  endTag 'p';

  startTag 'p';
  text '[26 Apr 2002] Courtesy of the Institute of Management,
Research & Technology here in Nashik, the results of our first
small research study are ';
  element 'a', 'available', href => 'imrt.html';
  text '!';
  endTag 'p';

  startTag 'p';
  text '[20 Jan 2002] i got ';
  element 'a', 'married', href => 'm.html';
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
    img 'art/marathi_demo1.png', 'Situations in Marathi';
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
    img 'art/floating.jpg', 'GNU Software', border=>0, hspace=>4;
    endTag 'a';
  };

  element 'h2', 'Requirements';

  startTag 'ul';

  startTag 'li';
  element 'p', 'A video card supporting the XVideo extension is highly recommended.';
  endTag 'li';

  startTag 'li';
  element 'p', 'Playing movies requires at least mid-range hardware.
Here are some anecdotal data points:';
  
  startTag 'table', border=>1, cellpadding=>3;
  startTag 'tr';
  element 'th', 'Configuration';
  element 'th', 'CPU% for VCD';
  element 'th', 'CPU% for DVD';
  endTag 'tr';

  startTag 'tr';
  element 'td', 'AMD K6-III @ 400Mhz';
  element 'td', '100% and choppy';
  element 'td', 'too slow';
  endTag 'tr';

  startTag 'tr';
  element 'td', 'AMD K6-III @ 400Mhz via XVideo';
  element 'td', '95%';
  element 'td', 'too slow';
  endTag 'tr';

  startTag 'tr';
  element 'td', 'Intel P-3 @ 764Mhz via XVideo';
  element 'td', '15%';
  element 'td', '?';
  endTag 'tr';

  startTag 'tr';
  element 'td', 'Dual Intel P-3 @ 500Mhz via XVideo';
  element 'td', '20%';
  element 'td', '60%';
  endTag 'tr';

  endTag 'table';

  endTag 'li';

  endTag 'ul';

  element 'p', 'To install the software, please choose specific
instructions for your operating system.';

  element 'h2', 'Films';

  startTag 'table', border=>1;
  startTag 'tr';
  element 'th', 'Title';
  element 'th', 'Blurb';
  element 'th', 'Rating';
  element 'th', 'Status';
  element 'th', 'Format';
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
  element 'td', 'VCD';
  startTag 'td';
  element 'a', '22k', href => 'annotation/naushika35';
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
  element 'td', 'DVD';
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
  element 'td', 'VCD';
  element 'td', 'soon';
  endTag 'tr';

  if (0) {
  startTag 'tr';
  startTag 'td';
  text 'Hum Dil De Chuke Sanam (1999)';
  endTag 'td';
  element 'td', 'Hindi Drama';
  element 'td', '13+ (adult themes)';
  element 'td', '0%';
  element 'td', 'VCD';
  element 'td', 'soon';
  endTag 'tr';
  }

  endTag 'table';

  startTag 'blockquote';
  startTag 'font', color => 'red';
  element 'i', 'You must use the same format as is given in the
table above because synchronization is accomplished with byte-offsets
instead of time-offsets.  This will be fixed as soon as possible.';
  endTag 'font';
  endTag 'blockquote';

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

  element 'p', "Films under consideration for future analysis:
Devil's Advocate (1997), Ghost (1990),
or serious Hindi drama.  Do not submit your favorite film
titles until the first annotations are completed.";

  element 'p', 'Does anyone know where Hindi film scripts are
available?';

  element 'p', 'i heartily recommend The Matrix (1999), however, this
film would be difficult to analyze.';
};

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
    img 'art/gnomelogo.png', 'Gnome', 'border', 0;
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
    img 'art/gstlogo.png', 'Gstreamer', 'border', 0;
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

menupage $topmenu, 'Windows', sub {
  element 'h1', 'Microsoft Windows';

  element 'p', "i don't know much about programming on Windows
and i don't have time to learn.
If you have the expertise, 
you are welcome to port Aleader to Windows and submit patches.";
};

menupage $topmenu, 'Documentation', sub {
  element 'h1', 'Documentation';

  element 'p', 'The user interface combines the elements from a word
processor and movie player.  There are also some interface
elements for making annotations and advanced features for scoring.';

  element 'p', 'Aleader operates in basically two modes:';

  startTag 'ol';

  startTag 'li';
  element 'p', 'A student can be tested against an exemplar film annotation.
Once the user interface is mastered, as little as one hour is required
for a rough AQ estimate.';
  endTag 'li';

  startTag 'li';
  element 'p', 'A researcher can develop an exemplar film annotation.
This demands a considerable amount of time.  Annotations should be
consistent across three or more films.  Expect a whole film to consume
at least a man-month of effort.';
  endTag 'li';

  endTag 'ol';
};

menupage $topmenu, 'Acknowledgment', sub {
  element 'h1', 'Acknowledgment';

  startTag 'p';
  text 'In scientific literature, it customary to provide
a bibliography of related research.  However, i am forced to break
with this convention because i can hardly make a short
list of people whose contribution i should acknowledge.
i have drawn inspiration from too many sources.  The best i can
do is refer you to the ';
  element 'a', 'philosophy page', href => 'philo.html';
  text '.';
  endTag 'p';

  element 'p', 'i have given my life for this research,
put everything into it, every moment,
person, and experience.  Perhaps i am the author, but only as
a transcriber for the Author of All.';
};

menupage $topmenu, 'Getting Started', sub {
  element 'h1', 'Getting Started';

  element 'p', 'The most important feature of Aleader is that you
do not have to understand *why* it works to benefit.  All you have to do is
gain practical experience using it.  Moreover, you are welcome to
use standard test-taking techniques to improve your score.';

  element 'p', "The test medium is multiple-choice except for spans,
duration and joints.  Don't try to figure out spans or joints on your
first attempt.  Follow a gradual introduction:";

  startTag 'ol';
  startTag 'li';
  element 'p', 'Take an exam with original spans and also ignore any joints.
Always set duration to Closed.  Use the diff tool to
examine your mistakes. (Depth 1)';
  endTag 'li';
  
  startTag 'li';
  element 'p', 'Take an exam with the original spans
and always set the duration to Open.
Add closing joints until all the situations are closed.
You can use the duration query screen to check whether anything remains open.
Use the diff tool to examine your mistakes. (Depth 2)';
  endTag 'li';
  
  startTag 'li';
  element 'p', 'Take an exam without any original annotation.
Now it is your responsibility to deterime the span of each situation.
Set the duration and add joints as you see fit.
Use the diff tool to examine your mistakes. (Depth 3)';
  endTag 'li';
  
  endTag 'ol';

  element 'p', 'The diff tool can measure the difference between
your answers and the exemplar.  Generally, any differences will
be your mistake.  However, this is not always true.  You may find
errors in the exemplar.  Please report possible errors to the mailing
list.';
};

menupage $topmenu, 'Film', sub {
  element 'h1', 'Film Transcript';

  startTag 'center';
  startTag 'p';
  img 'art/transcript.png', 'Transcript View';
  endTag 'p';
  endTag 'center';
  
  element 'p', 'The left side contains the film transcript.  Each highlighted
segment indicates the span of a single situation.  The right side
contain a list of situations.  When you move the cursor, the left
and right sides stay in-sync.  By selecting text or by pressing the
"Play" button, you can effortless play back any piece of the film.';

  startTag 'p';
  emptyTag 'hr';
  endTag 'p';

  element 'h2', 'Film View';

  startTag 'center';
  startTag 'p';
  img 'art/filmview.jpg', 'Film View', border=>0;
  endTag 'p';
  endTag 'center';

  element 'p', 'Actually it takes a lot of effort to make this effortless.
Fortunately, only folks who are preparing a new film annotation need
to understand these steps in detail.';

  startTag 'ol';
  startTag 'li';
  startTag 'p';
  text 'Copy a film onto your hard drive.  MPEG1 (vcd) or MPEG2 (dvd)
is OK.  Actually, this step is optional.  You do not *need* to copy the
film, but the following steps will involve lots of seeking which might
stress your CD/DVD.';
  endTag 'p';
  endTag 'li';

  startLi;
  text 'Find or create a transcript of your film.  Creating a transcript
from scratch is *really* tedious.  Be sure to search ';
  element 'a', "Drew's Script-O-Rama", href=>'http://www.script-o-rama.com';
  text " or any other similar sites for your title.  If you can't find
a script then consider whether you should go back to step (1) and
pick a different film.";
  endLi;

  startTag 'li';
  startTag 'p';
  text 'Load your transcript and film together in Aleader.';
  endTag 'p';
  endTag 'li';

  startTag 'li';
  startTag 'p';
  text 'Actors or actresses generally take turns talking.  Place your
cursor at the beginning of a segment of talking.  Sync the film up to
the same place so the film matches your cursor position in the
transcript.  Select Insert::Sync from the menu.';
  endTag 'p';
  endTag 'li';

  startTag 'li';
  startTag 'p';
  text 'Re-position your cursor at the end of the dialog.  Select Insert::Sync.  Repeat until you have done the whole film. Aleader will do
linear interpolation between the explicit time sync marks so
you only have to add a time sync at the important places.';
  endTag 'p';
  endTag 'li';

  startTag 'li';
  startTag 'p';
  text 'Make backups.  This is something you should never be forced to
do more than once!';
  endTag 'p';
  endTag 'li';
  endTag 'ol';
};

menupage $topmenu, 'Situation', sub {
  element 'h1', 'Abstract Situation';

  element 'p',
'This screen shows the structural parameters of the situation.  Here
questions are presented, mostly in a multiple-choice format.';

  startTag 'center';
  startTag 'p';
  img 'art/ip.png', 'Abstract Situation', border=>1;
  endTag 'p';
  endTag 'center';

  startTag 'ol';

  startLi;
  text 'Select the two most important people in the scene.
A situation always consists of two participants (real or anthropomorphic).';
  endLi;
  
  startLi;
  text "Choose the initiator.  Generally, whoever is talking is
the initiator.  Always consider the situation from the initiator's
point of view.";
  endLi;

  startLi;
  text "Choose the situation.";
  endLi;

  startLi;
  text 'Choose the phase, tension, and intensity.';
  endLi;

  startLi;
  text 'The span of a situation is the longest period of time
during which the parameters of the situation remain constant.';
  endLi;

  startLi;
  text 'Choose the duration.  Although duration is not considered
for scoring, duration indicates whether the situation will be the
target of a joint (see the Joint section).  An ambiguous
duration is only useful for exemplars to indicate an *optional*
situation.';
  endLi;

  endTag 'ol';

  element 'p', 'At first glance, the questions may seem simple,
but they attempt to summarize all possible experiences between individuals.
The idea is to construct a
sentence by the options given which best describes what is
happening in the film.  Three detailed screens provide
guidance for describing situations uniquely and consistently.
These screens are available from the Help menu.';

  startTag 'center';
  startTag 'p';
  columns sub {
    thumb 'art/situation_help1.jpg', 'Situation';
  },
  sub { hskip 4 },
  sub {
    thumb 'art/situation_help2.jpg', 'Phase & Initiative';
  },
  sub { hskip 4 },
  sub {
    thumb 'art/situation_help3.jpg', 'Intensity & Tension';
  };
  endTag 'p';
  endTag 'center';

};


menupage $topmenu, 'Joints', sub {
  element 'h1', 'Add Joint';

  element 'p', 'These two screens are used to create connections
between two situations.  Connections (a.k.a. joints) describe
a temporal relationship between two situations.';

  element 'p', 'Canidate situations are generally indicated by
having an open duration.  The Duration Query screen (not shown)
offers a convenient summary of duration status.';

  startTag 'p';
  columns sub {
    img 'art/addjoint1.png', 'Add Joint (1)', border=>0;
  },
  sub { hskip 2 },
  sub {
    img 'art/addjoint2.png', 'Add Joint (2)', border=>0;
  };
  endTag 'p';

  element 'p', "Each joint has particular characteristics.  (This is
really hard to understand until you actually use Aleader so don't worry
if it doesn't make much sense.)";

  startTag 'p';
  startTag 'table', border=>1, cellpadding=>4;

  startTag 'tr';
  element 'td', '';
  element 'td', 'react';
  element 'td', 'amend';
  element 'td', 'revoke';
  element 'td', 'echo';
  element 'td', 'witness';
  endTag 'tr';

  startTag 'tr';
  element 'td', 'in-force';
  element 'td', '--';
  element 'td', 'yes';
  element 'td', 'no';
  element 'td', 'yes';
  element 'td', '--';
  endTag 'tr';

  startTag 'tr';
  element 'td', 'change';
  element 'td', '--';
  element 'td', 'yes';
  element 'td', 'yes';
  element 'td', 'no';
  element 'td', '--';
  endTag 'tr';

  startTag 'tr';
  element 'td', 'linkage';
  startTag 'td'; nth 2; endTag 'td';
  startTag 'td'; nth 1; endTag 'td';
  startTag 'td'; nth 1; endTag 'td';
  startTag 'td'; nth 1; endTag 'td';
  startTag 'td'; nth 3; endTag 'td';
  endTag 'tr';

  endTag 'table';
  endTag 'p';

  startTag 'ul';
  startTag 'li';
  element 'b', 'in-force';
  text ': Whether the past situation will continue
to be in-force.  Here is an example where the past situation
is revoked: "Send five pizzas.  No, cancel, send six pizzas."';
  endTag 'li';

  startTag 'li';
  element 'b', 'change';
  text ': Whether there is a desire to change the past situation.';
  endTag 'li';

  startTag 'li';
  element 'b', 'linkage';
  text ': This gives a hint about the identity of the initiator
and contraparty.  If '; nth(1);
  text ' person then the initiator or contraparty will remain the
same.  If '; nth(2);
  text ' person then the participants will take turns being the initiator.
If '; nth(3);
  text ' then the participants in the past and present situations
might be entirely different.';
  endTag 'li';

  endTag 'ul';

  element 'p', "Joint characteristics are enforced by a set of rules
written in a simple if-then language.  These rules are loaded at
Aleader startup.  If you don't like the default rules then you can
customize them.";

  element 'p', 'In any case, the scoring algorithm only distinguishes
witness or non-witness type joints as the joint type can usually be
inferred from surrounding context.';
};

menupage $topmenu, 'X-Reference', sub {
  element 'h1', 'Cross Reference';

  element 'p', 'Once you have annotated the film in the 3rd person then you can
create empathy patterns to translate back into the 1st person
perspective.  This completes the empathy <---> situation assessment cycle.';

  startTag 'p';
  img 'art/crossref.png', 'Cross Reference', border=>0;
  endTag 'p';

  element 'p', "About 110 patterns have been gathered based on
a comparison of annotations from three films, however, this work was
done before i wrote Aleader.  With Aleader's help, we should be able
to develop a larger and more consistent collection of patterns.
(Your help is needed. :-)";

  startTag 'p';
  text 'You might enjoy browsing the hyper-linked ';
  element 'a', 'empathy map', href => 'empathy/index.html';
  text '.';
  endTag 'p';

};

menupage $topmenu, 'Exam', sub {
  element 'h1', 'Exam Setup';

  element 'p', 'Once an exemplar film annotation is prepared
and verified then students can be tested against it.';

  startTag 'center';
  startTag 'p';
  img 'art/exam_setup.png', 'Exam Setup', border=>0;
  endTag 'p';
  endTag 'center';

  element 'p', 'Exam Status: The heart of Aleader is the score
calculation.  The definition of AQ is:
"# of correctly categorized situations per hour."
Here is an example of an exam in progress.';

  columns sub {
    element 'p', '"Changed" is the number of situations
which the student has *potentially*
categorized correctly.  "Ideal AQ" is the AQ which the student
could have gotten if he had actually categorized the situations perfectly.
"AQ" is the actual AQ.  "Speed" is a recommendation based on
whether the student is making a good trade-off between speed and accuracy.
If the accuracy is too low (lots of errors) then Aleader will suggest
"Go Slower".  If the accuracy is too high (no errors) then Aleader will
suggest "Go Faster".';
  },
  sub { hskip 4 },
  sub {
    img 'art/exam_status.png', 'Exam Status', border=>0;
  };

  columns sub {
    element 'p', 'In this case, the student needs to spend
more time working on accuracy since the actual AQ is about 10%
of the Ideal AQ (84.9 * 10% = 8.4 > 8.26).';
  }, 
  sub { hskip 4 },
  sub {
    img 'art/exam_status2.png', 'Exam Status';
  };

  startTag 'p';
  columns sub {
    element 'p', 'Ideal AQ is a function of "Elapse Time" and "Changed".
The table (right side) offers some examples of this function.
Notice that both 5 situations in 5 minutes and
25 situations in 25 minutes give an Ideal AQ of 60.  This
makes sense because one situation per minute is 60 situations per hour.';
    element 'p', 'It is hard to score above 60 without practicing the test in advance.';
  },
  sub {
  startTag 'table';
  startTag 'tr';
  element 'th', '';
  for (my $ch = 5; $ch <= 55; $ch += 10) {
    element 'th', $ch;
  }
  element 'th', 'Changed';
  endTag 'tr';
  for (my $tm = 5; $tm <= 45; $tm += 5) {
    startTag 'tr';
    element 'th', "$tm:00";
    for (my $ch = 5; $ch <= 55; $ch += 10) {
      my $ieq = $ch * 60 / $tm;
      if ($ieq > 60) {
        startTag 'td';
        element 'font', sprintf("%d", $ieq), color => 'gray';
        endTag 'td';
      } else {
        element 'td', sprintf("%d", $ieq);
      }
    }
    endTag 'tr';
  }
  startTag 'tr';
  element 'th', 'Elapsed';
  endTag 'tr';
  endTag 'table';
  };
  endTag 'p';

  columns sub {
    element 'p', 'Here is another example.  The AQ is almost the
same as the Ideal AQ, so Aleader recommends "Go Faster".  By
going faster, the student will do two things: raise the Ideal AQ
and make slightly more mistakes.  Overall, the AQ score should
improve by balancing speed and accuracy.';
  },
  sub { hskip 4 },
  sub {
    img 'art/exam_status3.png', 'Exam Status';
  };

  element 'p', 'Spending more time taking a test increases
the accuracy.  On the other hand, spending longer than one hour
becomes exhausting and the score is likely to decay somewhat.
Empirically, we found that 15, 30, and 45 minutes are probably
the most enjoyable test durations.';

};

menupage $topmenu, 'Disagreement Resolution', sub {
  element 'h1', 'Disagreement Resolution';

  element 'p', '*Expect* disagreements to happen.  The questions
posed by Aleader may seem easy but sometimes it is hard to figure
out the best way to answer.  The first thing to check is:
what is happening in the film?';

  startTag 'blockquote';
  element 'p', "Just discuss the situation in more detail and see
if you can reach an agreement on the general meaning of the
film.  Repeatedly view the scene 5, 10 or 100 times.
If you can't agree on the meaning then the film is just too ambiguous.";

  element 'p', 'Add some notes to the transcript to hint at an agreed
upon meaning.  Until the film is clear, it is not possible to
classify a given situation.';
  endTag 'blockquote';

  element 'p', 'Here are a few more guidelines to disambiguate
complex scenes.  Understand that abstract situations are a
*simplification* of the actual film.  It is sufficient to
model only the most important aspects of a situation.';

  startTag 'ul';
  startLi;
  text 'The film may include an actor who is doing narration
from a 3rd person perspective.  This narration is less important
that any immediate action.';
  endLi;

  startLi;
  text 'If there seem to be multiple active situations (for
example both [+] admires [0] and [0] accepts [+]) then the
situation with a shorter span is more important.';
  endLi;

  startLi;
  text "You are welcome to study the whole film, however,
you must respect the status of hidden information before it
is subsequently revealed.  For example, if someone's
identity is not yet revealed then treat that person as
Someone until the film progresses to the point where
the person's identity is actually revealed in the film.
A 5-10 second look-ahead is admissible in some cases.
Use your good judgment.";
  endLi;
  endTag 'ul';

  element 'h2', 'Hard Disagreements';

  element 'p', 'If there is still a disagreement then it is
necessary to resort to a democratic protocol.  The general
principle for resolving disputes is "the majority wins".  However, your
vote will not be counted until you demonstrate thoroughly level-headed
consistency.';

  element 'blockquote', 'The utility of a model of 3rd person situations
is whether it provides a one-to-one mapping between abstract situations
and abstract emotions.

A one-to-one mapping provides an inverse-of-empathy mapping
(situation assessment) which can then be seen, understood,
and tested against.';

  element 'p',  'Use the Cross Reference screen to check
the consistency of the annotations.  For a given annotation,
all the matching situations should evoke a similar emotion.
Check this theory by re-playing matching situations from the film.
Each group of matching situations should evoke a distinct
cluster of similar emotions.  Try it.
This is how to gain confidence in the categorization system.';

  element 'p','If you are advocating a different categorization
system then you need to show that your system offers at least
as much consistancy.  May the most consistent system prevail.
Good luck!';

};

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
    img 'art/feelings.png', 'Feelings';
  };

  startTag 'ul';
  startTag 'li';
  text "`Emotion' is a feeling which arises in the context of two separate people.";
  endTag 'li';
  startTag 'li';
  text "`Spirit' is a feeling which does not admit the idea of separation.";
  endTag 'li';
  startTag 'li';
  text "`Compassion' is a special feeling which bridges spirit to emotion.";
  endTag 'li';
  startTag 'li';
  text "`Feeling' is the most general word, including emotion,
spirit, and compassion.";
  endTag 'li';
  endTag 'ul';

  element 'p', 'Here are some additional notes:';

  startTag 'ul';

  startLi;
  text "We can give a definition for `thought',
however, distinguishing between thought and emotion is not necessary
for this discussion. Here `emotion' is meant inclusive of thought.";
  endLi;

  startLi;
  text "Emotion doesn't require two living breathing people.
Only the *context* of two people is important.
For example,
if you have compassion for a stone then emotion can
arise between you and the stone (maybe you are a sculptor).
Anthropomorphic emotions are still emotions.";
  endLi;

  endTag 'ul';

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
  text 'Before compassion, the main focus is on the ';
  nth(1);
  text ' person perspective.  There is no partition between personality
and emotion.  There are no situations, only *my* situation (singular).
Charming, huh?
As compassion dawns, the four perspectives come into focus:';
  endTag 'p';

  },
  sub { hskip 4 },
  sub {
    emptyTag 'img', src=>'art/nocompassion.jpg', alt => 'No Compassion';
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
    emptyTag 'img', src => 'art/fourpp.jpg', alt => 'Four Perspectives';
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
    emptyTag 'img', src => 'art/informs.png', alt => 'Informs',
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
	text 'For example: "i am angry, but i am detached from
my anger.  The anger is an object of my attention.  i forgive,
i forgive.  Now i do not feel angry."';
      };
  endTag 'p';

  startTag 'p';
  columns sub { attention 1,3 },
    sub { hskip 2 },
      sub {
	text 'Perhaps the most obvious example of empathy is
what happens while watching a film.  A film is nothing but ';
	nth 3;
	text ' person perspective: images and sound.  However,
people can easily empathize with the actors and *feel* a
precise replica of the emotions depicted onscreen.  The film
is the object and emotion is the subject, hence "empathy."';
      };
  endTag 'p';

  startTag 'p';
  columns sub { attention 3,1 },
    sub { hskip 2 },
      sub {
	startTag 'font', color=> EICOLOR;
	text '"Based on how i feel, what is the structural situation?"
This style of question is repeatedly posed in Aleader annotations.';
	endTag 'font';
      };
  endTag 'p';


  startTag 'p';
  columns sub { attention 1,2 },
  sub { hskip 2 },
  sub {
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
	text 'While practicing true meditation, i focus my attention on
the pure spirit.  After meditation, part of my attention remains
connected with the spirit, thereby enlightening the experience
of individuality.
Divine expression makes individuality most beautiful and enjoyable,
much more so than any physical or mental amusement.';
      };
  endTag 'p';

  startTag 'p';
  text 'Jumping directly between the ';
    nth(2);
    text ' and ';
    nth(3);
    text " perspectives doesn't make sense.  Attention flows between the ";
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

  text 'The following table and diagram summarize all sensical
configurations:';
  endTag 'p';

  startTag 'center';
  columns sub {
    emptyTag 'img', src=>'art/trident.png', alt=>'Attention Trident';
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

  element 'h2', 'Toward Self-Identity';

  columns sub {
  element 'p', 'Our goal is divine expression (g).
The challenge is to get the attention focused on pure spirit.
Self-realization (f) is the only configuration to accomplish this
(pure spirit as an object).
Even so, the attention quickly flows outward into other configurations
and the divine quality (g) of attention is soon dilute.';

    element 'p', '
To restart the divine flow, we need a way to consistently
place our attention in the configuration of self-realization (f).
The problem with seeking self-realization (f) is that the attention
is lost in seemingly infinite variations of experience.
Detachment (a) is essential to elminate the confusion.
This configuration (a) is unique because the pure spirit is present
as the subject.  None of the other accessible configurations
directly involve the pure spirit.';

    element 'p', '
By aligning the attention as soothing detachment (a) with respect to
the complete octave of emotions, no significant object remains.
The attention ceases to be a vector and resolves to
the point of self-realization (f).
"The spirit is like the steady axis of a wheel. If
our attention reaches the immovable firm axis at the very centre of the
wheel of our existence (which is constantly moving), we become
enlightened by the spirit, the source of inner peace, and reach a state
of complete calm and self-knowledge." (H. H. Shri Mataji)';

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
  sub { hskip 4 },
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
    text 'Detachment (a) demands a precise understanding
of emotions.';
    endLi;

    startLi;
    text 'Detachment (a) is supported when emotion is the
object of attention.';
    endLi;

    startTag 'center';
    img 'art/trident-sr.png', "Emotion as Object";
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

menupage $topmenu, 'Aleader', sub {
  element 'h1', 'Aleader';

  element 'h2', 'Workflow';

  element 'p', 'See below for an explanation of each numbered point.';

  startTag 'center';
  startTag 'p';
  img 'art/workflow.png', 'Workflow', border=>0;
  endTag 'p';
  endTag 'center';

  startTag 'ol';

  startTag 'li';
  startTag 'p';
  text 'People can easily empathize with the actors and actresses,
and *feel* a precise replica of the emotions depicted onscreen.
(A few people fail to developed a sense of empathy as children.  Such
people are called "autistic".)';
  endTag 'p';
  endTag 'li';

  startTag 'li';
  startTag 'p';
  text 'AQ (assessment quoient) is the factor which allows one to
envision the 3rd person situation by sensitivity to emotion.
The Situation screen
records the structural parameters of the situation.  The
Joint screens record any relationships between situations.';
  endTag 'p';
  endTag 'li';

  startTag 'li';
  startTag 'p';
  text 'The Cross Reference screen automates pattern
matching from abstract situations to abstract emotions.  This
mechanical process aims to mimic the empathy sense.';
  endTag 'p';
  endTag 'li';

  startTag 'li';
  startTag 'p';
  text 'The principal
reason to want abstract emotions is for verifying correctness.  For
example, it is much easier to imagine the abstract emotion "try
to cover up mistake" (or "shame") than to imagine the corresponding abstract
situation "before ';
  element 'b', '[0]';
  text ' accepts [+] followed by :react: during stifled
[+] exposes ';
element 'b', '[-]';
  text '".  Since emotions are often repeated, pattern classifications
can be established with certainty.';
  endTag 'p';
  endTag 'li';

  startTag 'li';
  startTag 'p';
  text 'The pattern matching also makes it easier to verify that
each abstract situation corresponds to its associated actual situation
in the film.  If the abstract emotions seem correct except for one
case then the structure of the exceptional situation probably
needs re-evaluation.';
  endTag 'p';
  endTag 'li';

  endTag 'ol';

  startTag 'p';
  text 'Steps (4) and (5) work against each other in opposite directions.
After checking and re-checking, we can gain confidence that the
abstract representation is a fairly accurate distillation of the film.';
  endTag 'p';

  startTag 'p';
  text "During an examination session, the automated facilities relating to
abstract emotions are disabled (step 3).  
A student's AQ (assessment quotient) is tested intensively.";
  endTag 'p';

if (0){
  element 'h2', 'The Model';

  element 'p', 'By showing a film, it is easy to present actual situations
which are complex enough to activate the empathy mechanism.
However, it is not at all obvious how to record the structural
parameters of an abstract situation.';

  element 'p', 'The utility of a given model of 3rd person situations
is whether it provides a one-to-one mapping between abstract situations
and abstract emotions.  If the mapping is one-to-one then the model
can be taken as equal to the actual empathy sense.  Moreover, a
one-to-one mapping exposes the inverse-of-empathy mechanism
(situation assessment) which can then be seen, understood, and
tested against.';

  element 'p', 'So what is the *best* model to use for recording
the structural parameters of a situation?  There are probably an infinite
number of ways to organize all the situations involving individuals.
Even so, by thinking about this question like a mathematical
equation, a solution is revealed.';

  startTag 'center';
  img 'art/model.png', 'Model Mathematics';
  endTag 'center';

  startTag 'ol';
  startLi;
  text 'Write our question like a mathematical equation.';
  endLi;
  startLi;  
  text 'Be specific about our terms.  Situation can be the object
of attention (as with empathy) or the subject of attention (as with
situation assessment).';
  endLi;
  startLi;
  text 'For the case of the situation as a subject, we can
substitute the word "competition".';
  endLi;
  startLi;
  text 'Divide both sides of the equation by "competition".';
  endLi;
  startLi;
  text 'Our sentence is re-written as: "The best model of competition
is the actual objective situation."';
  endLi;
  endTag 'ol';

  element 'p', 'This explanation may seem far-fetched,
but it is easy to check the practical utility of the resulting model
using the metric proposed above (whether the model is one-to-one with
respect to emotions).';
  };

  element 'h2', 'Ghost Wheel?';

  element 'p', '"Ghost" refers to the all-pervading power of divine
love, the divine cool breeze.  "Wheel" hints at the idea of a machine.
So "ghost-wheel" refers to the timeless machine which is animated
by the power of divine love.  This machine is *timeless* because only
one prerequisite is needed to trigger its operation:
 compassionate individuals.';

  startTag 'table', border => 0, cellspacing => 0, cellpadding => 0;
  startTag 'tr';
  startTag 'td', width=>'50%', valign => 'top';
    element 'p', 'The other name i used for this project is "why-compete".
This name is based on the inspiration i received when i was trying to
figure out how to design the situation model.';

    element 'p', 'Redael is the word "leader" with the letters reversed.
Pronounce it as you wish.';

    element 'p', 'Aleader has at least two meanings:';
    startTag 'ul';
    startLi;
    text 'It is a short form of "assessment leader".';
    endLi;
    startLi;
    text 'It suggests a contrast between "a leader" and "the leader".
Only one of us is the leader, but we can all be a leader.
In other words, i believe that leadership qualities are not dependent on
the number of followers.';
    endLi;
    endTag 'ul';
  endTag 'td';
  startTag 'td';
  hskip 4;
  endTag 'td';
  startTag 'td', width => '50%', valign => 'top';
    startTag 'p';
    text 'The river carves out the valley by flowing beneath it.';
    br;
    text 'Thereby the river is the master of the valley.';
    br;br;
    text 'In order to master people';
    br;
    text 'One must speak as their servant;';
    br; 
    text 'In order to lead people';
    br;
    text 'One must follow them.';
    br;br;
    text 'So when the gentle rise above the people,';
    br;
    text 'They do not feel oppressed;';
    br;
    text 'And when the gentle stand before the people,';
    br;
    text 'They do not feel hindered.';
    br;br;
    text 'So support for the gentle does not fail,';
    br;
    text 'They do not contend, and none contend against them.';
    endTag 'p';
    element 'a', 'Tao Te Ching #66',
      href => 'http://home.san.rr.com/merel/gnl.html';
  endTag 'td';
  endTag 'tr';
  endTag 'table';
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
  br;
  text '(i speculate that accuracy will emerge
after the 2nd or 3rd attempt.)';
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
    thumb 'art/imrt0.jpg', 'IMRT Entrance';
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
    thumb 'art/posttest1.jpg', 'Bhagade Arun Ramdas';
  },
  sub {
    thumb 'art/posttest4.jpg', '(backside)';
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
    thumb 'art/posttest2.jpg', 'Prakash Genoo Bhagade';
  },
  sub {
    thumb 'art/posttest3.jpg', '(backside)';
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
    img 'art/imrt1.jpg', 'Day 1';
  },
  sub { hskip 4 },
  sub {
    img 'art/imrt2.jpg', 'Day 2';
  };
  endTag 'center';

};

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
      element 'p', 'Copyright (C) 2001, 2002 Joshua Nathaniel Pritikin.  Verbatim copying and distribution of this entire article is permitted in any medium, provided this notice is preserved.';
      element 'p', 'Last modified @DATE@.';
      emptyTag 'hr';
    },
    sub { hskip 2 };
  };
};

__END__

This test is only concerned with situation assessment.  It leaves the
question of choosing the perfect reaction up to your spontaneous
creativity.


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
  
  run "tidy -config tidy.conf -utf8 -xml tmp$$";
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

  if ($n == 0)    { text 'I am' }
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
  img 'art/mensa.png', 'Mensa Logo', border => 0;
  br;
  text 'IQ: ';
  element 'a', 'Mental Intelligence', 'href', 'http://www.mensa.org';
  endTag 'td';
  
  startTag 'td', 'align', 'center', valign=>'bottom';
  img 'art/about_sy_chart.png', 'Chakra System', border=>0;
  br;
  text 'SQ: ';
  element 'a', 'Spiritual Intelligence', 'href', 'http://sahajayoga.org';
  endTag 'td';
  
  startTag 'td', 'align', 'center', valign=>'bottom';
  img 'art/trident.png', 'Attention Trident', border => 0;
  br;
  text 'EQ: ';
  element 'a', 'Emotional Intelligence', 'href', 'news.html';
  endTag 'td';
  
  endTag 'tr';
  endTag 'table';
  
  endTag 'center';
  vskip;
};

our $topmenu = MenuTree
  ->new([
	 ['News'              => 'news.html'],
	 ['Download'          => 'download.html',
	  [
	   [Debian             => 'dl-debian.html'],
	   [Unix               => 'dl-unix.html'],
	   [Windows            => 'dl-windows.html'],
	  ]
	 ],
	 ['Documentation'     => 'doc.html',
	  [
	   ['Film'            => 'doc-film.html'],
	   ['Situation'       => 'doc-situation.html'],
	   ['Joints'          => 'doc-joints.html'],
	   ['X-Reference'     => 'doc-xref.html'],
	   ['Exam'            => 'doc-exam.html'],
	  ]],
	 ['Mailing Lists'     => 'lists.html'],
	 ['High Scores'       => 'scores.html'],
	 ['Business Opportunities' => 'jobs.html'],
	 ['Philosophy'        => 'philo.html',
	 [
	  ['Redael'           => 'philo-redael.html'],
	 ]],
	]);

require 'marriage.pl';

page 'fairuse.html', sub {
  element 'title', 'Fair Use Statement';
  endTag 'head';

  body(20);

  element 'h2', 'Fair Use Statement';

  element 'p', 'Despite the fact that Redael is an international project,
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
  
  element 'p', 'Redael uses films for non-profit educational purposes, specifically
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

sub menupage {
  my ($menu, $curitem, $x) = @_;

  page $menu->file($curitem), sub {
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

      if (@$item == 3 and ($item->[0] eq $curitem or $in_sub)) {
	for my $s (@{$item->[2]}) {
	  br;
	  hskip 2;
	  if ($s->[0] eq $curitem) {
	    text $s->[0];
	  } else {
	    element 'a', $s->[0], 'href', $s->[1];
	  }
	}
      }
      endTag 'p';
    }

    vskip 4;
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
};

menupage $topmenu, 'News', sub {
  element 'h1', 'Introduction';
  element 'p', 'Our concern is with measuring and increasing
EQ score (emotional quotient or emotional intelligence).  This project is
strictly non-profit and for education.  Our approach is to study
films to test how consistantly you can be a witness.';
  
  startTag 'p';
  text 'Redael is a software package that combines a video
player (MPEG1/MPEG2), annotation tools, and a scoring system into an
easy to use GUI.  This software is licensed under the ';
  element 'a', 'GPL', 'href', 'http://www.gnu.org/philosophy/philosophy.html';
  text ' and is available from the download page.';
  endTag 'p';
  
  element 'h1', "News";

  element 'p', '[23 Jan 2002] A pre-compiled binary is available
for Debian i386.';

  startTag 'p';
  text '[20 Jan 2002] i got ';
  element 'a', 'married', href => 'm.html';
  text '!';
  endTag 'p';

  startTag 'p';
  text '[5 Dec 2001] Assuming the cooperation of upstream
libraries, a binary release of redael will be made
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
  element 'a', '22k', href => 'annotation/naushika12';
  endTag 'td';
  endTag 'tr';

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

  endTag 'table';

  startTag 'blockquote';
  element 'i', 'You must use the same format as is given in the
table above because synchronization is accomplished with byte-offsets
instead of time-offsets.  This will be fixed as soon as possible.';
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
to serve as a basis for redael annotations.';
  endTag 'i';
  endTag 'blockquote';

  endTag 'center';

  element 'p', "Films under consideration for future analysis:
Any Given Sunday (1999), Devil's Advocate (1997), Ghost (1990),
American Werewolf in Paris (1997), or serious Hindi
drama.  Do not submit your favorite film titles until the first
annotations are completed.";
};

menupage $topmenu, 'Debian', sub {
  element 'h1', 'Debian Installation';

  element 'p', 'A i386 binary package is available (but not yet
as part of the main debian distribution).';

  element 'p', 'Add the following lines to /etc/apt/sources.list:';

  startTag 'p';
  startTag 'blockquote';
  startTag 'pre';
  text 'deb http://gstreamer.net/releases/debian ./
deb-src http://gstreamer.net/releases/debian ./

deb http://redael.berlios.de/releases/debian ./
';
  endTag 'pre';
  endTag 'blockquote';
  endTag 'p';

  element 'p', 'And then simply use apt-get:';

  startTag 'p';
  startTag 'blockquote';
  startTag 'pre';
  text '# apt-get update
# apt-get install redael
';
  endTag 'pre';
  endTag 'blockquote';
  endTag 'p';
};

menupage $topmenu, 'Unix', sub {
  element 'h1', 'Generic Unix Installation';

  element 'p', 'If your operating system is not listed then you will
need to compile redael from source code.';

  startTag 'p';
  columns sub {
    startTag 'a', 'href', 'http://gtk.org/download/';
    img 'art/gnomelogo.png', 'Gnome', 'border', 0;
    endTag 'a';
  },
  sub { hskip 6 },
  sub {
    text 'Install 1.3.11 or later versions of glib, atk, pango, and gtk+.';
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
    text 'Install 0.3.0 or later version of gstreamer.  You will also
need some libraries: libmpeg2, liba52, and libHermes.  Make sure gstreamer
is built with --enable-glib2.';
  };
  endTag 'p';

  startTag 'p';
  startTag 'a', href=>'http://developer.berlios.de/project/filelist.php?group_id=167';
  text 'Download the latest snapshot of redael.';
  endTag 'a';
  endTag 'p';

  element 'p', 'Compile and run.';
};

menupage $topmenu, 'Windows', sub {
  element 'h1', 'Please do not port software to Windows';

  element 'p', 'At least, do not port my software to Windows.';

  element 'p', 'While the GNU General Public License expressly
  prohibits me from denying you the freedom to port software protected
  by it to Windows, I feel that you do great damage to the world if
  you do. Let me explain.';

  element 'p', "Windows is a proprietary environment. They don't give
  you the source code, and they do anything in their power to limit
  your freedom. They even try to limit what you can do with the
  software you rightfully bought from them. So, supporting them in any
  way is bad for the world, because it encourages others to try to
  limit others' freedoms (it worked great for Microsoft, so it must be
  a good idea, right?).";

  element 'p', "I don't want any of my work to give anyone a reason to
  support companies like Microsoft who try to limit people's freedoms.";

  startTag 'p';
  text "That's why I develop my software on a completely free
  platform. So I know it works on a completely free platform. Many
  people using Windows don't care about their freedom. They do care
  about quality software and for that reason try to replace all the
  user space software from Microsoft with better free
  alternatives. This is the sole reason for the existance of ";
  element 'a', 'cygwin', href => 'http://sources.redhat.com/cygwin/';
  text '.';
  endTag 'p';

  element 'p', "However, giving people a way to work around bugs in
  Windows makes them stay longer with Windows. That's why I consider
  porting software to Windows sabotage. It does not help people under
  Windows, in the contrary. It makes them stay longer with
  Windows. And while they stay, they will put pressure on others to
  also use Windows. It only helps Microsoft.";

  element 'p', "While this text singles out Microsoft, other companies
  are equally evil. For example, porting redael to Solaris
  would help Sun, noone else. Don't do it.";

  element 'p', 'In the same line of argumentation, I will not modify
  any of my software so it works better with proprietary development
  platforms like Visual C++, even if I sacrifice great amounts of
  performance by not exploiting their features. And I ask you to do
  the same.';

  startTag 'p';
  element 'a', '(This discussion was copied from www.fefe.de.)',
    href => 'http://www.fefe.de';
  endTag 'p';
};

menupage $topmenu, 'Documentation', sub {
  element 'h1', 'Documentation';

  element 'p', 'The user interface combines the elements from a word
processor and movie player.  There are also some interface
elements for making annotations and advanced features for scoring.';

  element 'p', 'Redael operates in basically two modes:';

  startTag 'ol';

  startTag 'li';
  element 'p', 'A student can be tested against an exemplar film annotation.
Once the user interface is mastered, as little as one hour is required
for a rough EQ estimate.';
  endTag 'li';

  startTag 'li';
  element 'p', 'A researcher can develop an exemplar film annotation.
This demands a considerable amount of time.  Annotations should be
consistent across three or more films.  Expect a whole film to consume
at least a man-month of effort.';
  endTag 'li';

  endTag 'ol';

  startTag 'p';
  emptyTag 'hr';
  endTag 'p';

  element 'h2', 'Getting Started';

  element 'p', 'The most important feature of redael is that you
do not have to understand *why* it works to benefit.  All you have to do is
gain practical experience using it.  Moreover, you are welcome to
use standard test-taking techniques to improve your score.';

  element 'p', "The test medium is multiple-choice except for spans,
duration and joints.  Don't try to figure out spans or joints on your
first attempt.  Follow a gradual introduction:";

  startTag 'ol';
  startTag 'li';
  element 'p', 'Take an exam with original spans and also ignore any joints.
Always set duration to Closed.  After you finish, use the diff tool to
examine your mistakes.';
  endTag 'li';
  
  startTag 'li';
  element 'p', 'Take an exam with the original spans
and always set the duration to Open.
Add closing joints until all the situations are closed.
You can use the duration query screen to check whether anything remains open.
After you finish, use the diff tool to examine your mistakes.';
  endTag 'li';
  
  startTag 'li';
  element 'p', 'Take an exam without any original annotation.
Now it is your responsibility to deterine the span of each situation.
Set the duration and add joints as you see fit.
After you finish, use the diff tool to examine your mistakes.';
  endTag 'li';
  
  endTag 'ol';

  element 'p', 'The diff tool can measure the difference between
your answers and the exemplar.  Generally, any differences will
be your mistake.  However, this is not always true.  You may find
errors in the exemplar.  Please report possible errors to the mailing
list.';

  startTag 'p';
  emptyTag 'hr';
  endTag 'p';

  element 'h2', 'Screenshots';

  startTag 'p';
  img 'art/transcript.png', 'Transcript View';
  endTag 'p';
  
  element 'p', 'The left side contains the film transcript.  Each highlighted
segment indicates the span of a single situation.  The right side
contain a list of situations.  When you move the cursor, the left
and right sides stay in-sync.  You can double-click in the situation
list to open a detail screen (below).';

  vskip;
};

menupage $topmenu, 'Situation', sub {
  element 'h1', 'Abstract Situation';

  element 'p',
'This screen shows the structural parameters of the situation.  Here
questions are presented, mostly in a multiple-choice format.';

  startTag 'p';
  img 'art/ip.png', 'Abstract Situation', border=>1;
  endTag 'p';

  element 'p', 'The questions are simple:';

  startTag 'ol';

  startLi;
  text 'Select the two most important people in the scene.
A situation always consists of two participants (real or anthropomorphic).';
  endLi;
  
  startLi;
  text 'Choose the initiator.  Generally, whoever is talking is
the initiator.';
  endLi;

  startTag 'p';
  img 'art/wheel.png', 'The Ghost Wheel';
  endTag 'p';

  startLi;
  text "Choose the situation.  To pick the correct situation, the
intention of the two participants must be taken into account.
If there is an initiator then estimate intentions relative to
the initiator's point of view.
For each person, estimate his or her attention.  By this pair
of intentions you can pick the appropriate situation.";
  endLi;

  startLi;
  text 'For phase, tension, and intensity, see the example
dialogues in the Help menu.';
  endLi;

  endTag 'ol';
};


menupage $topmenu, 'Film', sub {
  element 'h1', 'Film';

  element 'p', 'The filmview offers effortless seeking to any
point in a film. (Films not included. :-)';

  startTag 'p';
  img 'art/filmview.jpg', 'Film View', border=>0;
  endTag 'p';

  element 'p', 'Actually it takes a lot of effort to make this effortless:';

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
  text 'Load your transcript and film together in redael.';
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
  text 'Re-position your cursor at the end of the dialog.  Select Insert::Sync.  Repeat until you have done the whole film. Redael will do
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

menupage $topmenu, 'Joints', sub {
  element 'h1', 'Add Joint';

  element 'p', 'These two screens are used to create connections
between two situations.  Connections (a.k.a. joints) describe
a temporal relationship between two situations.';

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
really hard to understand until you actually use redael so don't worry
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
redael startup.  If you don't like the default rules then you can
customize them.";
};

menupage $topmenu, 'X-Reference', sub {
  element 'h1', 'Cross Reference';

  element 'p', 'Once you have annotated the film in the 3rd person then you can
create empathy patterns to translate back into the 1st person
perspective.  This completes the empathy <---> emotional intelligence cycle.';

  startTag 'p';
  img 'art/crossref.png', 'Cross Reference', border=>0;
  endTag 'p';

  element 'p', "About 110 patterns have been gathered based on
a comparison of annotations from three films, however, this work was
done before i wrote redael.  With redael's help, we should be able
to develop a larger and more consistent collection of patterns.
(Your help is needed. :-)";

  element 'p', 'Here are some example patterns:';

  startTag 'pre';
  text q(if
 initiator = right
 situation = steals
 phase = during
 tension = stifled
then "angry with himself / herself"

if
 initiator = left
 situation = admires
 phase = during
 tension = focused
then "awe / offer service"
);
  endTag 'pre';
};

menupage $topmenu, 'Exam', sub {
  element 'h1', 'Exam Setup';

  element 'p', 'Once an exemplar film annotation is prepared
and verified then students can be tested against it.';

  startTag 'p';
  img 'art/exam_setup.png', 'Exam Setup', border=>0;
  endTag 'p';

  columns sub {
  element 'p', 'Exam Status: The progress of an exam is shown.  The
EQ score can be calculated in real-time.  This particular screen
shows an elapse time of 49 seconds.  The accuracy of the EQ score will
increase as the exam progresses.';
  },
  sub { hskip 4 },
  sub {
  img 'art/exam_status.png', 'Exam Status', border=>0;
  };
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

  element 'p', 'This page contains a compilation of EQ test results.
Send email with
your results to get listed here.  Obviously you can forge any results,
however, honesty can keep this page somewhat useful.  Certified results
obtained through professional testing methods will be placed on a different
web page.';

  startTag 'center';

  startTag 'table', border=>1, cellpadding=>4;

  startTag 'tr';
  element 'th', 'Date';
  element 'th', 'Name';
  element 'th', 'Location';
  element 'th', 'Film';
  element 'th', 'Match';
  element 'th', 'EQ';
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
    endTag 'tr';
  }
  endTag 'table';

  startTag 'blockquote';
  startTag 'i';
  text 'For a reliable EQ score, the match should be
greater than the EQ.  In other words, the elapse time of a
test should be at least one hour.';
  endTag 'i';
  endTag 'blockquote';

  endTag 'center';
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

  element 'h1', 'The Need For a Model';

  element 'p', "We can't see ourselves apart from ourselves.
To understand life, it is necessary to develop a *model* --
a description or analogy -- to help visualize something that
cannot be directly observed.  A model is a miniature representation,
and a *good* model confers tangible insight into reality and joy.";

  element 'p', 'The rest of this page offers a philosophical
justification of the model used by redael.';

  element 'h2', 'Categories of Feeling';

  element 'p', 'The words emotion, spirit, and feeling are used to mean a
variety of different things in different contexts.  The defintions used
here are as follows:';

  startTag 'ul';
  startTag 'li';
  text "`Emotion' is a feeling which arrises in the context of two separate people.";
  endTag 'li';
  startTag 'li';
  text "`Spirit' is a feeling which does not admit the idea of separation.";
  endTag 'li';
  startTag 'li';
  text "`Feeling' includes both emotion and spirit.";
  endTag 'li';
  startTag 'li';
  text "`Compassion' is a special feeling which bridges spirit to emotion.";
  endTag 'li';
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

  }, sub {
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
    row sub { nth(0); text ' person perspective ("I am")' };
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
  }, sub {
    emptyTag 'img', src => 'art/informs.png', alt => 'Informs',
      width => 206, height => 64;
  };
  endTag 'p';

  element 'h2', 'Attention Configurations';

  element 'p', 'Within the realm of compassionate individuality,
there are various ways attention can be configured.  What
are all the permutations?  Fortunately, it is easy to generate
a question to invoke a given configuration.  Once posed
as a question, we can consider whether
the configuration makes sense and draw any further conclusions.';

  startTag 'p';
  columns sub { attention 0,1 },
    sub { hskip 2 },
      sub {
	text 'For example: "i am angry, but i am detached from
my anger.  i am not allowing the anger to affect my behavior.
The anger is an object of my attention."';
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
people can easily empathize with the characters and *feel* a
precise replica of the emotions depicted onscreen.  The film
is the object and emotion is the subject, hence "empathy."';
      };
  endTag 'p';

  startTag 'p';
  columns sub { attention 3,1 },
    sub { hskip 2 },
      sub {
	startTag 'font', color=>'#006600';
	text '"Based on how i feel, what is the structural situation?"
This style of question is repeatedly posed in redael annotations.';
	endTag 'font';
      };
  endTag 'p';


  startTag 'p';
  columns sub { attention 1,2 },
  sub { hskip 2 },
  sub {
    text '"How do i feel about [something]?" ([something] is some
imaginary situation.)  Extra-ordinary personal preference and fashions
are expressions of this configuration of attention.';
  };
  endTag 'p';

  startTag 'p';
  columns sub { attention 2,1 },
  sub { hskip 2 },
  sub {
     text '"How would [XXX] feel about [something]?"
Replace [XXX] with any of: Krishna, Rama, Jesus the Christ, Buddha,
Mahavira, Lao Zi, etc.  In other words, how would an ideal
role-model react in a given situation?';
  };
  endTag 'p';

  startTag 'p';
  columns sub { attention 0,0 },
    sub { hskip 2 },
      sub {
	text "If you have *not* experienced self-realization then
please visit a local ";
	element 'a', 'Sahaja Yoga', href=>'http://sahajayoga.org';
	text " center and feel the divine cool breeze.  You can't
really understand philosophy unless and until you take your second birth.";
      };
  endTag 'p';

  startTag 'p';
  columns sub { attention 1,0 },
    sub { hskip 2 },
      sub {
	text 'While practicing true meditation, i focus my attention on
the Whole (a.k.a. "I am").  After meditation, part of my attention remains
connected with the Whole, thereby enlightening the experience of individuality.
This divine expression makes individuality most beautiful and enjoyable,
much more so than any physical or mental amusement.';
      };
  endTag 'p';

  startTag 'p';
  columns sub {
    text 'The permutations between ';
    nth(2);
    text ' and ';
    nth(3);
    text " perspectives don't make sense.  Our information (or
flexibility) is necessarily partial because the four perspectives
are known only by compassion.  For example, ";
    text '"How is your personality affected by observing the situation?"
-- this question could only be answered by an omniscient individual.
We are merely compassionate individuals.
Attention vectors are only possible between the ';
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
    text ' perspectives.';
  },
  sub { hskip 2 },
  sub { text 'impossible'; attention 3,2 };
  endTag 'p';

  element 'p', 'The following table and diagram summarize all sensical
configurations:';

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
      startTag 'font', color=>'#006600';
      text 'emotional intelligence';
      endTag 'font';
      attention 3,1 };
    endTag 'p';

    startTag 'p';
    columns sub { text '(d) ' },
    sub { text 'how do i feel about ..?'; attention 1,2 },
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

  element 'p', 'How is emotional intelligence (c) related to
self-realization (f)?';

  columns sub {
    element 'p', '
The problem with seeking self-realization (f)
is that the actual
self (the original subject or "I am") cannot appear as an object,
by definition.  "I am" is the *subject*.  So to realize the self, we have
to use divine intelligence.';

    element 'p', 'The most direct approach is to concentrate all the
attention as emotional detachment (a) while soothing the emotions
down.  As the strength of emotions fade, the actual self is experienced
when the attention vector resolves to a point (f).
However, this approach is not generally practical.
The pressures of daily life keep the attention bouncing
around the various other configurations.';
  },
  sub { hskip 4 },
  sub {
    img 'art/trident-sr.png', "Emotion as Object";
  };

  element 'p', 'At least the emotions can be kept as the object of
attention.  If emotion is the object then the attention has a
chance to settle into emotional detachment (a) and spontaneously
resolve into self-identity (f).  Consideration of emotion as
a object is important for this reason, as a means of
taking self-realization and preserving self-identity.
Besides emotional detechment (a), there are two other
attention configurations which consider emotion as an object.
Our interest here is with one of those configurations: emotional
intelligence (c).';
};

menupage $topmenu, 'Redael', sub {
  element 'h1', 'Redael';

  element 'h2', 'Workflow';

  startTag 'p';
  img 'art/workflow.png', 'Workflow', border=>0;
  endTag 'p';

  startTag 'ol';

  startTag 'li';
  startTag 'p';
  text 'People can easily empathize with the actors and actresses, and *feel* a
precise replica of the emotions depicted onscreen.';
  endTag 'p';
  endTag 'li';

  startTag 'li';
  startTag 'p';
  text 'Emotional Intelligence is the factor which allows one to
envision a
situation from a 3rd person perspective.  The Situation Editor
assists in recording the structural parameters of the situation.  The
Add Joint screens assist in recording any relationships between situations.';
  endTag 'p';
  endTag 'li';

  startTag 'li';
  startTag 'p';
  text 'The Cross Reference screen automates pattern
matching from abstract situations to abstract emotions.';
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
  text '".  Since emotions are occasionally repeated, the pattern classifications
can be established with some certainty.  As few as two or three repetitions
are generally sufficient.';
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
After checking and re-checking, we can gain confidence that
abstract representation is a fairly accurate distillation of the film.';
  endTag 'p';

  startTag 'p';
  text "For an examination session, the automated facilities relating to
abstract emotions are disabled.  Part of the reconciliation, step (4),
is changed into a manual process.  A student's capacity for (2) emotional
intelligence is tested intensively.";
  endTag 'p';

  element 'h2', 'The Model';

  startTag 'p';
  element 'i', 'What is the best model to encode abstract situations?';
  endTag 'p';

  element 'p', 'One way to identify a good model is that
it will have a one-to-one mapping between
abstract situations and abstract emotions.  However, this
condition does not provide much guidance about how to
represent an abstract situation.';

  startTag 'p';
  text 'The trick is to analyze the question.  "What is the ';
  element 'b', 'best';
  text ' model to encode abstract situations?"  This word "best"
implies some sort of competition between canidate models.  [write more...]';

  endTag 'p';
};

menupage $topmenu, 'Business Opportunities', sub {
  element 'h1', 'The Next Step';

  element 'h2', 'Research';

  startTag 'p';
  text 'This project should be of interest to lots of research grants,
and there is plenty of work to do.
The methodology used in redael has only been tested on
a hand-full of people.  Larger scale scientific studies are needed
to better estimate its effectiveness.';
  endTag 'p';

  startTag 'p';
  text "If you have run a psychology experiment in college then
you are qualified to apply for a grant.  Programming skills are
not necessary.  For example, consider NIH grant ";
  startTag 'a', href => 'http://grants.nih.gov/grants/guide/pa-files/PA-00-105.html';
  text 'PA-00-105';
  endTag 'a';
  text '.  A more tantalizing opportunity is the ';
  startTag 'a', href => 'http://www.templeton.org/';
  text 'John Templeton Foundation';
  endTag 'a';
  text ", but that's a long-shot.";
  endTag 'p';

  element 'h2', 'Certified EQ Testing';

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

  text ' -- so you can start your own EQ testing franchise, royalty free.';
  endTag 'p';
};

__END__

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
#	 ['High Scores'       => 'scores.html'],
	 ['Research & Professional' => 'jobs.html',
	  [
	   ['IMRT'            => 'imrt.html'],
	  ]
	 ],
	]);

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

  startTag 'p';
  text 'Aleader uses a non-mystical, statistical approach to measure
situation assessment ability.
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
  text '[28 Feb 2003] Aleader 0.9.1 is out.
The main change in this release is exam mode, which is greatly
simplified.  Also, a few SEGV are fixed, a bunch of memory leaks are
plugged, and there are an assortment of minor cosmetic improvements.
Work continues on building a correct analysis (exemplar) for each
of our first films.';
  endTag 'p';

  startTag 'p';
  text '[10 Feb 2003] After a long wait, Aleader 0.9.0 is released.
This is the first release that builds without any pre-released code
from CVS.  On i386, all library dependencies can be resolved by
binary packages from debian unstable.  Beta testing is needed.
Please try it out.';
  endTag 'p';

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

my %Film;

sub film_name {
  my ($f) = @_;
  die "$f not found" if !exists $Film{$f};
  $f.'_r'.$Film{$f}.'.leadr';
}

sub grab_films {
  my $edir = "/home/joshua/aleader/exemplar";
  opendir my $dh, $edir or die "opendir $edir: $!";
  for my $f (readdir $dh) {
    if ($f =~ s/_r(\d+)\.leadr$//) {
      my $ver = $1;
      if (!exists $Film{$f} or $Film{$f} < $ver) {
	$Film{$f} = $ver;
      }
    }
  }
  for my $f (keys %Film) {
    my $fn = film_name($f);
    run "cp $edir/$fn root/";
  }
}

sub film_link {
  my ($f) = @_;
  element 'a', "v$Film{$f}", href => film_name($f);
}

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

  element 'h2', 'Debian (i386)';

  run 'mkdir -p root/releases/debian';
  run 'cp ~/aleader/release/* root/releases/debian';
  run 'cd root/releases/debian; dpkg-scansources . | gzip > Sources.gz; dpkg-scanpackages . /dev/null | gzip > Packages.gz';

  element 'p', 'Add the following line to /etc/apt/sources.list:';

  startTag 'p';
  startTag 'blockquote';
  startTag 'pre';
  text 'deb http://redael.berlios.de/releases/debian ./';
  endTag 'pre';
  endTag 'blockquote';
  endTag 'p';

  element 'p', 'Then:';

  startTag 'p';
  startTag 'blockquote';
  startTag 'pre';
  text 'apt-get update
apt-get install aleader aleader-doc
';
  endTag 'pre';
  endTag 'blockquote';
  endTag 'p';

  element 'h2', 'Generic Unix';

  startTag 'p';
  text 'Build and install ';
  element 'a', 'Gtk+', href => 'http://gtk.org/download/';
  text ' 2.2 (or better) and ';
  element 'a', 'Gstreamer', href => 'http://www.gstreamer.net/download';
  text ' 0.6.0 (or better). ';
  startTag 'a', href=>'http://developer.berlios.de/project/filelist.php?group_id=167';
  text 'Download the latest release of Aleader source code.';
  endTag 'a';
  text ' Compile and install.';
  endTag 'p';

  if (!-e 'root/manual') {
    mkdir 'root/manual' or die "mkdir root/manual: $!";
  }

  if (modtime("root/manual/aleader.pdf") <
      modtime("/home/joshua/aleader/doc/aleader.pdf")) {
    run "cp /home/joshua/aleader/doc/aleader.pdf root/manual";
  }

  run "cp /home/joshua/aleader/doc/index.html root/manual";
  run "cp /home/joshua/aleader/doc/*.png root/manual";
  run "cp /home/joshua/aleader/doc/*.jpg root/manual";

  element 'h2', 'Documentation';

  startTag 'p';
  element 'a', 'HTML', href => 'manual/index.html';
  text ' | ';
  element 'a', 'PDF', href => 'manual/aleader.pdf';
  br;
  element 'small', '(PDF looks a _lot_ better than HTML)';
  endTag 'p';

  element 'h2', 'Films';

  element 'p', 'In addition to the Aleader software, you will need
some films to get started.  i selected some of my favorite films for
analysis.  It is important to work with films which you enjoy
watching because you will have to watch them so many times to
analyze them properly.';

  grab_films();

  startTag 'center';
  startTag 'table', border=>1;
  startTag 'tr';
  element 'th', 'Title';
  element 'th', 'Rating';
  element 'th', 'Exemplar';
  endTag 'tr';

  startTag 'tr';
  startTag 'td';
  element 'a', 'Kaze no Tani no Naushika (1984)',
    href => 'http://www.nausicaa.net/miyazaki/nausicaa/';
  endTag 'td';
  element 'td', 'All Ages';
  startTag 'td';
  film_link('Nausicaa');
  endTag 'td';
  endTag 'tr';

  startTag 'tr';
  startTag 'td';
  element 'a', 'Star Wars: A New Hope (1977)',
    href => 'http://www.starwars.com/episode-iv/';
  endTag 'td';
  element 'td', 'All Ages';
  startTag 'td';
  film_link('StarWars');
  endTag 'td';
  endTag 'tr';

  startTag 'tr';
  startTag 'td';
  element 'a', 'Good Will Hunting (1997)',
    href => 'http://www.un-official.com/GWH/GWMain.html';
  endTag 'td';
  element 'td', '17+ (language, adult themes)';
  startTag 'td';
  film_link('GoodWillHunting');
  endTag 'td';
  endTag 'tr';

  # add Pixar films here

  endTag 'table';
  endTag 'center';

  startTag 'p';
  text 'To accompany the exemplar, you need the actual
film in VCD format.  If you already have the film then it is not
difficult to ';
  run "cp /home/joshua/aleader/doc/conversion.txt root/";
  element 'a', 'convert to VCD format', href => 'conversion.txt';
text ".  If you don't have the film then you can make a ";
  run "cp /home/joshua/aleader/doc/fair-use.txt root/";
  element 'a', 'fair-use claim', href => 'fair-use.txt';
  text ' against the copywrite and send email to ';
  element 'a', 'joshua@why-compete.org',
    href => 'mailto:joshua@why-compete.org';
  text '.';
  endTag 'p';

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
to serve as a basis for Aleader analysis.';
  endTag 'i';
  endTag 'blockquote';

  endTag 'center';

# Ghost (1990)
# Devil's Advocate (1997)
# Tukaram

  startTag 'p';
  text 'i heartily recommend ';
  run "cp thematrix.html root/thematrix.html";
  element 'a', 'The Matrix (1999)', href => 'thematrix.html';
  text ', however, this film is not really a good film to analyze
with Aleader.  The beauty of this film is less due to its
abstract emotional content and more due to its artistic use of
fantasy to illuminate the structure of reality.';
  endTag 'p';

  element 'h3', 'Combined Exemplar Statistics';

  element 'p', 'Here are the coverage statistics for
the film exemplars finished so far.';

  startTag 'center';
  startTag 'table', border => 1;
  startTag 'tr';
  element 'th', 'Date';
  element 'th', 'Situations';
  element 'th', 'Patterns';
  element 'th', 'Unknown';
  element 'th', 'Coverage';
  element 'th', 'Complexity';
  endTag 'tr';
  startTag 'tr';
  element 'td', '26 Feb 2002';
  element 'td', '437';
  element 'td', '98';
  element 'td', '39';
  element 'td', '58.2%';
  element 'td', '4.266';
  endTag 'tr';
  endTag 'table';
  endTag 'center';

  element 'p', '58.2% coverage and 39 unknown is not very good.  i know.  We are working on it.';
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
	  'Everything else.  Bug reports, user support, and developer
discussion.',
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

menupage $topmenu, 'Research & Professional', sub {
  element 'h1', 'The Next Step';

  element 'h2', 'Research';

  startTag 'p';
  text 'This project should be of interest to lots of research grants,
and there is plenty of work to do.
The methodology used in Aleader has only been tested on
a hand-full of people.  Larger scale scientific studies are needed
to better reveal its effectiveness. ';
  text 'Here are few questions which could be the target of
a research study:';

  endTag 'p';

  startTag 'ul';
  startLi;
  text 'Which emotions are common across most spoken languages?  Which
emotions are unique to just a few languages?';
  endLi;
  
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
group of students, and a lot of time.';
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

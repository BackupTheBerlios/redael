#!/usr/bin/perl -w

use 5.6.1;
use strict;
use Fatal qw(open);

BEGIN { require "./minixml.pl"; }

sub run {
  my ($cmd) = @_;
  system($cmd) == 0 or die "system $cmd failed: $?";
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
  close $fh;
  
  run "tidy -config tidy.conf -utf8 -xml tmp$$";
  rename "tmp$$", $file or die "rename: $!";
}

sub hspace {
  my $reps = $_[0] || 1;
  print '&nbsp;' while --$reps >= 0;
}

sub vspace {
  my $reps = $_[0] || 1;
  print '<p>&nbsp;</p>' while --$reps >= 0
}

sub body {
  startTag ('body',
	    'bgcolor', "#FFFFFF",
	    'topmargin', 0,
	    'bottommargin', 0,
	    'leftmargin', 0,
	    'rightmargin', 0,
	    'marginheight', 0,
	    'marginwidth', 0);
}

sub br { emptyTag 'br' }

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

##########################################################
package MenuTree;

sub new { bless $_[1], $_[0]; }

sub file {
  my ($o, $item) = @_;

  for (my $x=0; $x < @$o; $x += 2) {
    next if $o->[$x] ne $item;
    return $o->[$x + 1];
  }
  die "can't find $item";
}

sub titles {
  my ($o) = @_;
  my @ret;

  for (my $x=0; $x < @$o; $x += 2) {
    push @ret, $o->[$x];
  }
  @ret;
}

package main;

##########################################################

page 'index.html', sub {
  element 'title', 'Complete, Integrated Personality Development';
  endTag 'head';

  body();

  startTag 'center';
  vspace 2;
  element 'h1', 'Complete, Integrated Personality Development';
  vspace 2;
  
  startTag 'table', 'border', 0, 'cellpadding', 25;
  startTag 'tr';
  
  startTag 'td', 'align', 'center';
  emptyTag 'img', 'src', 'art/shri.jpg', 'alt', 'Shri Chaktra', 'border', 0;
  br;
  text 'SQ:';
  element 'a', 'Spiritual Intelligence', 'href', 'http://sahajayoga.org';
  endTag 'td';
  
  startTag 'td', 'align', 'center';
  emptyTag 'img', 'src', 'art/trident.png',
    'alt', 'Attention Trident', 'border', 0;
  br;
  text 'EQ:';
  element 'a', 'Emotional Intelligence', 'href', 'news.html';
  endTag 'td';
  
  startTag 'td', 'align', 'center';
  emptyTag 'img', 'src', 'art/mensa.png', 'alt', 'Mensa Logo', 'border', 0;
  br;
  text 'IQ:';
  element 'a', 'Mental Intelligence', 'href', 'http://www.mensa.org';
  endTag 'td';
  
  endTag 'tr';
  endTag 'table';
  
  endTag 'center';
  vspace;
};

our $topmenu = MenuTree
  ->new([
	 'News'          => 'news.html',
	 'Download'      => 'download.html',
	 'Documentation' => 'doc.html',
	 'Mailing Lists' => 'lists.html',
	 'Philosophy'    => 'philo.html'
	]);

sub menupage {
  my ($menu, $curitem, $x) = @_;

  page $menu->file($curitem), sub {
    element 'title', $curitem;
    endTag 'head';
    body;

    startTag 'table', 'border', 0, cellspacing => 0, cellpadding => 4;
    startTag 'tr';

    startTag 'td', 'valign', 'top', 'bgcolor', '#ccffcc';

    br;

    for my $item ($menu->titles) {
      startTag 'p';
      if ($item eq $curitem) {
	text $item;
      } else {
	element 'a', $item, 'href', $menu->file($item);
      }
      endTag 'p';
    }

    vspace 4;
    startTag 'p';
    text 'Hosted by:';
    br;
    startTag 'a', 'href', 'http://developer.berlios.de/projects/redael';
    emptyTag 'img', 'src', 'http://developer.berlios.de/images/logo_fokus.gif',
      'alt', 'GMD FOKUS', 'border', 0, 'height', 73, 'width', 66;
    endTag 'a';
    endTag 'p';
    
    endTag 'td';
    
    startTag 'td', 'valign', 'top';
    
    $x->();
    
    endTag 'td';
    
    endTag 'tr';
    endTag 'table';
    vspace 4;
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
player (MPEG1/2), annotation tools, and a scoring system into an
easy to use GUI.  This software is licensed under the ';
  element 'a', 'GPL', 'href', 'http://www.gnu.org/philosophy/philosophy.html';
  text ' and is available from the download page.';
  endTag 'p';
  
  element 'h1', "News";
  element 'p', '18 Sep 2001: The re-designed web site goes online
with a more pragmatic approach.';
};

menupage $topmenu, 'Download', sub {
  element 'h1', 'Downloading';

  element 'p', 'Presently, redael is only distributed as source code,
and worse, it is difficult to compile.  Binaries will be available
as soon as it is a practical possibility.  If you are still undaunted
then you may attempt the following steps:';

  element 'p', 'Subscribe to the redael-devel mailing list.  You are
going to need help.';

  startTag 'p';
  startTag 'a', 'href', 'http://gtk.org/download/';
  emptyTag 'img', 'src', 'art/gnomelogo.png', 'alt', 'Gnome', 'border', 0;
  endTag 'a';
  br;
  text 'Get the current CVS for glib, atk, pango, and gtk+.  Apply
this patch for 64-bit parameters.  Follow the directions in HACKING
to build from CVS sources.';   # XXX
  endTag 'p';

  startTag 'p';
  startTag 'a', 'href', 'http://www.gstreamer.net/';
  emptyTag 'img', 'src', 'art/gstlogo.png', 'alt', 'Gstreamer', 'border', 0;
  endTag 'a';
  br;
  text 'Get the current CVS for gstreamer.  Apply this patch for
large file support.  You need to install the libraries: mpeg2dec, a52dec,
and Hermes.  Build gstreamer with --enable-glib2.';
  endTag 'p';

  element 'p', 'Download the latest snapshot of redael.  Add salt to taste.';
};

menupage $topmenu, 'Documentation', sub {
  element 'h1', 'Documentation';

  text 'Add lots of screen captures with explanation.';
};

menupage $topmenu, 'Mailing Lists', sub {
  element 'h1', 'Mailing Lists';

  my $list = sub {
    my ($name, $desc) = @_;

    startTag 'p';
    element 'b', $name;
    text ' - ';
    element 'a', 'Subscribe', 'href', "https://lists.berlios.de/mailman/listinfo/$name";
    text ' / ';
    element 'a', 'Archives', 'href', "https://lists.berlios.de/pipermail/$name";
    br;
    text $desc;
    endTag 'p';
  };

  $list->('redael-announce',
	  'Announcements of new versions.  Low-volume; at most one message
 per day.');

  $list->('redael-devel',
	  'Technical discussions about software development and philosophy.');
};

menupage $topmenu, 'Philosophy', sub {
  element 'h1', 'What is Philosophy?';

  startTag 'p';
  element 'i', 'Perhaps there are many definitions, but here we mean: ';
  br;
  text 'Pursuit of the truth.  An analysis of the grounds of and
concepts expressing fundamental beliefs.';
  endTag 'p';

  element 'h1', 'The Need For a Model';

  element 'p', "We can't see ourselves apart from ourselves.
To understand life, it is necessary to develop a model --
a description or analogy to help visualize something that
cannot be directly observed.  A model is a miniature representation,
and a *good* model confers real insight into reality and joy.";

  element 'p', 'The rest of this page offers a philosophical
justification of the model used by redael.';

  element 'h2', 'Subject / Object';

  startTag 'p';
  columns sub {
    text 'These words are not meant in a strict grammatical sense.
"Subject" and "object" describe end-points of an attention vector.
The subject is the origin of attention.  Attention is focused on an object,
the object is enveloped with awareness, and the subject is informed
about the object.';
  }, sub {
    emptyTag 'img', src => 'art/informs.png', alt => 'Informs',
      width => 206, height => 64;
  };
  endTag 'p';

  element 'h2', 'Compassion';

  startTag 'p';
  columns sub {
    text 'Far back in history, one animal looked at another
with compassion.  He or she realized that there
were a multiplicity of individuals, for the *first* time.
Before compassion, each animal was ruthless, perfectly self-centered,
and alone.  Even ';
  }, sub {
    emptyTag 'img', src=>'art/nocompassion.png', alt => 'No Compassion';
  };
  endTag 'p';

  startTag 'p';
  text 'Compassion crystalizes the four perspectives:';
  endTag 'p';

  startTag 'center';
  columns sub {
    emptyTag 'img', src => 'art/fourpp.png', alt => 'Four Perspectives',
      width=>159, height=>93;
  },
  sub {
    startTag 'table', border=>0, cellspacing=>0, cellpadding=>0;
    row sub { nth(3); text ' person perspective (situation)' };
    row sub { nth(2); text ' person perspective (personality)' };
    row sub { nth(1); text ' person perspective (emotion)' };
    row sub { nth(0); text ' person perspective ("I am")' };
    endTag 'table';
  };
  endTag 'center';

  startTag 'p';
  text 'Before compassion, the main focus is on the ';
  nth(1);
  text ' person perspective.  There is no personality or
emotion, only a vibratory feeling.  There are no situations,
only *the* situation (singular).';
  endTag 'p';

  element 'h2', 'Attention Configurations';

  startTag 'p';
  text 'Note that each of the n';
  element 'sup', 'th';
  text ' person perspectives are a possible origin of the subject
of attention.  Furthermore, the object of attention can ';
  endTag 'p';

  columns sub {
    startTag 'table', border=>1, cellpadding=>3, cellspacing=>0;
    startTag 'tr';
    startTag 'th';
    text 'subject: ';
    nth(0);
    endTag 'th';
    startTag 'th';
    text 'object: ';
    nth(1);
    endTag 'th';
    endTag 'tr';
    startTag 'tr';
    element 'td', 'I am';
    element 'td', 'emotion';
    endTag 'tr';
    endTag 'table';
  },
  sub { hspace 2 },
  sub {
    text 'For example i am angry, but i am detached.';
  };
};

__END__





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

sub img {
  my ($src, $alt, @rest) = @_;
  emptyTag 'img', src=>$src, alt=>$alt, @rest;
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
  vskip 2;
  element 'h1', 'Complete, Integrated Personality Development';
  vskip 2;
  
  startTag 'table', 'border', 0, 'cellpadding', 25;
  startTag 'tr';
  
  startTag 'td', 'align', 'center';
  img 'art/shri.jpg', 'Shri Chakra', border=>0;
  br;
  text 'SQ: ';
  element 'a', 'Spiritual Intelligence', 'href', 'http://sahajayoga.org';
  endTag 'td';
  
  startTag 'td', 'align', 'center';
  img 'art/trident.png', 'Attention Trident', border => 0;
  br;
  text 'EQ: ';
  element 'a', 'Emotional Intelligence', 'href', 'news.html';
  endTag 'td';
  
  startTag 'td', 'align', 'center';
  img 'art/mensa.png', 'Mensa Logo', border => 0;
  br;
  text 'IQ: ';
  element 'a', 'Mental Intelligence', 'href', 'http://www.mensa.org';
  endTag 'td';
  
  endTag 'tr';
  endTag 'table';
  
  endTag 'center';
  vskip;
};

our $topmenu = MenuTree
  ->new([
	 'News'              => 'news.html',
	 'Download'          => 'download.html',
	 'Documentation'     => 'doc.html',
	 'Mailing Lists'     => 'lists.html',
	 'Job Opportunities' => 'jobs.html',
	 'Philosophy'        => 'philo.html',
	]);

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

    for my $item ($menu->titles) {
      startTag 'p';
      if ($item eq $curitem) {
	text $item;
      } else {
	element 'a', $item, 'href', $menu->file($item);
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
    startTag 'a', href => 'http://www.gnu.org/philosophy/philosophy.html';
    img 'art/richard.jpg', 'Richard Stallman', border=>0, hspace=>4;
    endTag 'a';
  },
  sub { hskip 2 },
  sub {
    element 'h1', 'Downloading';
  };

  element 'p', 'Presently, redael is only distributed as source code,
and worse, it is difficult to compile.  Binaries will be available
as soon as it is a practical possibility.  If you are still undaunted
then you may attempt the following steps:';

  element 'p', 'Subscribe to the redael-devel mailing list.  You are
going to need help.';

  startTag 'p';
  columns sub {
    text 'Install 1.3.10 or later versions of glib, atk, pango, and gtk+.';
  },
  sub { hskip 2 },
  sub {
    startTag 'a', 'href', 'http://gtk.org/download/';
    img 'art/gnomelogo.png', 'Gnome', 'border', 0;
    endTag 'a';
  };
  endTag 'p';

  startTag 'p';
  columns sub {
    text 'Get the current CVS for gstreamer.  Apply this patch for
large file support.  You need to install the libraries: mpeg2dec, a52dec,
and Hermes.  Build gstreamer with --enable-glib2.';
  },
  sub { hskip 2 },
  sub {
    startTag 'a', 'href', 'http://www.gstreamer.net/';
    img 'art/gstlogo.png', 'Gstreamer', 'border', 0;
    endTag 'a';
  };
  endTag 'p';

  startTag 'p';
  startTag 'a', href=>'http://developer.berlios.de/project/filelist.php?group_id=167';
  text 'Download the latest snapshot of redael.';
  endTag 'a';
  text ' Add salt to taste.';
  endTag 'p';
};

menupage $topmenu, 'Documentation', sub {
  element 'h1', 'Documentation';

  element 'p', 'The interface combines the elements from a word
processor and movie player.  There are also some user interface
elements for making annotations and advanced features for scoring.';

  element 'h2', 'Workflow Summary';

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
  text 'After checking and re-checking, we can gain confidence that
abstract representation is a fairly accurate distillation of the film.';
  endTag 'p';

  startTag 'p';
  text "For an examination session, the automated facilities relating to
abstract emotions are disabled.  Part of the reconciliation, step (4),
is changed into a manual process.  A student's capacity for (2) emotional
intelligence is tested intensively.";
  endTag 'p';

  startTag 'p';
  emptyTag 'hr';
  endTag 'p';

  startTag 'p';
  img 'art/transcript.png', 'Transcript View', border=>1;
  endTag 'p';
  
  element 'p', 'The left side contains the film transcript.  Each highlighted
segment indicates the span of a single situation.  The right side
contain a list of situations.  When you move the cursor, the left
and right side stay in-sync.  You can double-click in the situation
list to open a detail screen (below).';

  startTag 'p';
  img 'art/ip.png', 'Abstract Situation', border=>1;
  endTag 'p';

  element 'p',
'Situation Editor: This screen shows the structural parameters of the
situation.  A situation always consists of two participants (real or
anthropomorphic).
Perhaps the best way to learn what these descriptions mean is to examine
one of the exemplar film annotations.  Most of the terms are not
defined beyond the customary dictionary.';

  startTag 'p';
  img 'art/filmview.jpg', 'Film View', border=>0;
  endTag 'p';

  element 'p', 'The filmview screen offers effortless seeking to any
point in a film. (Films not included. :-)';

  startTag 'p';
  columns sub {
    img 'art/addjoint1.png', 'Add Joint (1)', border=>0;
  },
  sub { hskip 2 },
  sub {
    img 'art/addjoint2.png', 'Add Joint (2)', border=>0;
  };
  endTag 'p';

  element 'p', 'Add Joint: These two screens are used to create connections
between two situations.  Connections (a.k.a. joints) are a
bookkeeping aide to help keep everything in proper perspective.';

  startTag 'p';
  img 'art/crossref.png', 'Cross Reference', border=>0;
  endTag 'p';

  element 'p', 'Cross Reference:
Once you have annotated the film in the 3rd person then you can
create empathy patterns to translate back into the 1st person
perspective.  This completes the empathy - emotional intelligence cycle.';

  vskip;

  element 'p', '[Add lots of screen captures with explanation.]';
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
	  'Announcements about releases or other important events.
Low-volume; at most one message per day.');

  $list->('redael-devel',
	  'Technical discussions about software development and philosophy.
Can be high volumn on occation.');
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

  element 'h2', 'Compassion';

  startTag 'p';
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
  endTag 'p';

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
  sub { hskip 1 },
  sub { attention 2,1 },
  sub { hskip 2 },
  sub {
    element 'i', 'These configurations, which involve personality,
are difficult to understand and not particularly important.  They will be
explored elsewhere.'
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
    sub { hskip 3 },
    sub {
      startTag 'font', color=>'#006600';
      text 'emotional intelligence';
      endTag 'font';
      attention 3,1 };
    endTag 'p';

    startTag 'p';
    columns sub { text '(c) ' },
    sub { text 'prerequisite'; attention 1,2 },
    sub { hskip 3 },
    sub { text 'transformative pressure'; attention 2,1 };
    endTag 'p';

    startTag 'p';
    columns sub { text '(d) ' },
    sub { text 'self-realization'; attention 0,0 },
    sub { hskip 6 },
    sub { text '(e) ' },
    sub { text 'divine expression'; attention 1,0 };
    endTag 'p';
  };
  endTag 'center';
};

menupage $topmenu, 'Job Opportunities', sub {
  element 'h1', 'Possible Research Grants';

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

  startTag 'p';
  text 'In any case, if you are interested in writing a grant proposal
then please contact the mailing list.';
  endTag 'p';
};

__END__

#!/usr/bin/perl -w

package Empathy;

use strict;
use warnings;
use List::Util qw(shuffle);
use blib '/home/joshua/Aleader';
use App::Aleader ':all';

BEGIN {
  do "./minixml.pl";
  die if $@;
}

use constant EXEMPLAR_DIR => '/home/joshua/aleader/exemplar';
use constant HTML_ROOT => '/home/joshua/gw/makeweb/root';
use constant HTML_CACHE => '/home/joshua/gw/makeweb/cache';

our @Film = (qw(Nausicaa StarWars GoodWillHunting));
our $Empathy =
  App::Aleader::GPtrSet::Empathy->open('/home/joshua/aleader/editor/empathy');
our %FilmName;
our %Index;
our %Render;
our %Used;

mkdir HTML_ROOT . '/empathy' or do {
  die $! if ($! ne 'File exists');
};

sub run {
  my ($cmd) = @_;
  system($cmd) == 0 or die "system $cmd failed: $?";
}

sub br { emptyTag 'br' }

sub hskip {
  my $reps = $_[0] || 1;
  print '&nbsp;' while --$reps >= 0;
}

sub vskip {
  my $reps = $_[0] || 1;
  print '<p>&nbsp;</p>' while --$reps >= 0
}

sub page {
  my ($file, $x) = @_;
  
  open my $fh, ">$file";
  my $oldfh = select $fh;

  doctype 'HTML', '-//W3C//DTD HTML 4.01//EN',
    'http://www.w3.org/TR/html4/strict.dtd';
  startTag 'html';
  startTag 'head';

  $x->();

  endTag 'body';
  endTag 'html';
  print "\n";
  close $fh;
  select $oldfh;
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

sub startLi {
  startTag 'li';
  startTag 'p';
}

sub endLi {
  endTag 'p';
  endTag 'li';
}

sub situation_name {
  my ($s) = @_;
  my $film = $FilmName{ $s->get_transcript->get_pathname };
  my $spec = sprintf "%s_%.2f__%.2f", $film, $s->get_time_bounds;
  $spec =~ tr/./_/;
  $spec;
}

sub add_to_index {
  my ($tx) = @_;

  my $name = $tx->get_pathname;
  $name =~ s,^/.*/,,;
  $name =~ s/\.leadr$//;
  $FilmName{ $tx->get_pathname } = $name;

  my $situations = $tx->get_situations;

  for (my $x=0; $x < $situations->len; $x++) {
    my $sit = $situations->at($x);

    my @m = $sit->empathize($Empathy);
    for my $label (map { $_->get_label } @m) {
      push @{ $Index{$label} }, $sit;
    }

    my $spec = situation_name($sit);
    my $preview = $spec . ".jpg";
    if (-e HTML_CACHE . "/empathy/$preview" or
	-e HTML_ROOT . "/empathy/$preview") {
      $Render{$spec} = $sit;
    }
  }
}

for my $exemplar (@Film) {
  my $tx =
    App::Aleader::Transcript->open(EXEMPLAR_DIR . "/$exemplar.leadr");
  print "Loading $exemplar #".$tx->get_version."...\n";

  add_to_index ($tx);
}
warn((0+keys %Render)." situations already rendered\n");

# remove entries with less than 2 examples
for my $key (sort keys %Index) {
  my $situations = $Index{$key};
  my $count = @$situations;
  delete $Index{$key} if $count < 2;
}

sub emotion_label_to_filename {
  my ($label) = @_;
  $label = lc $label;
  $label =~ tr/a-z//cd;
  substr $label, 0, 32;
}

sub empathy_page {
  my ($fn, $k) = @_;

  page HTML_ROOT . "/empathy/$fn.html", sub {
    element 'title', "Empathy \"$k\"";
    endTag 'head';
    body(4);
    
    element 'h2', 'Illustrated Empathy Index';
    element 'h3', "\"$k\"";
    
    my @ready;
    my @example = @{ $Index{$k} };
    
    while (@ready < @Film+1) {
      my $s = select_example(\@example, \@ready, 1);
      last if !$s;
      push @ready, $s;
    }
    
    startTag 'p';
    element 'b', 'Instructions: ';
    text "Watch each example. Contemplate whether all
examples reference / trigger the same emotion.  Some emotions are
too general, such as 'give' or 'take'.  Other emotions are more
specific, such as 'prediction' or 'meticulous doubt'.";
    endTag 'p';
    
    situations_to_html(\@ready, 1);
    
    startTag 'p';
    text "If you feel like one of the example isn't matching
then please report this problem to ";
    mailing_list();
    text ".  In your report,
include all the information in the ";
    element 'i', 'Location';
    text " column and a short description what you think is wrong.";
    endTag 'p';
    
    fair_use();
    
    vskip 6;
  };
}

sub empathy_body {
  if (1) {
    startTag 'table';
    startTag 'tr';
    startTag 'td', valign => 'top';
  }

  element 'h1', 'Illustrated Empathy Index';

  emptyTag 'hr';

  element 'p', 'There are two ways to examine the index on the web:';

  startTag 'ol';
  startLi;
  text 'Pick an emotion. Compare the illustrative film clips.';
  endLi;
  startLi;
  text 'Play the guessing game.
Four situations will be presented.
Three of the situations reference the same emotion.
You are challenged to pick the forth situation, which triggers
a different emotion.';
  endLi;
  endTag 'ol';

  startTag 'p';
  text "Film clips are encoded in DIVX format.  You need a DIVX
player to view them.
Windows and MacOS users can download a player from ";
  element 'a', '<http://www.divx.com>',
    href => 'http://www.divx.com';
  text ".  If you're not using Windows or MacOS then
your video player most likely already supports DIVX.";
  endTag 'p';

  emptyTag 'hr';

  my $len = 1;
  while (1) {
    my @match;
    for my $k (sort keys %Index) {
      my $ent = $Empathy->lookup_key($k);
      next if $ent->len != $len;
      push @match, $k;
    }

    last if !@match;

    my $cols = 2;
    my $percol = int(($cols - 1 + @match) / $cols);

    element 'p', "These are the simplest emotions, having two
or more examples from our films.";

    startTag 'table', cellspacing => 6;
    for (my $row = 0; $row < $percol; $row++) {
      startTag 'tr';
      for (my $x=0; $x < $cols; $x++) {
	if ($x > 0) {
	  startTag 'td';
	  hskip 5;
	  endTag 'td';
	}
	startTag 'td';
	my $k = $match[$row + $x * $percol];
	if ($k) {
	  my $fn = emotion_label_to_filename($k);
	  element 'a', $k, href => "empathy/$fn.html";
	  empathy_page($fn, $k);
	}
	endTag 'td';
      }
      endTag 'tr';
    }
    endTag 'table';

    ++$len;
    last;  # skip complex stuff XXX
  }
  
  emptyTag 'hr';

  element 'h2', 'Emotion Guessing Game';

  my @game;
  for my $k (sort keys %Index) {
    my $ent = $Empathy->lookup_key($k);
    next if ($ent->len != 1 or @{ $Index{$k} } < 3);
    push @game, $k;
  }

  startTag 'table', cellspacing => 6;
  startTag 'tr';

  my $col = 0;
  @game = shuffle @game;
  for (my $g=1; $g <= @game; $g++) {
    if ($col and $col % 7 == 0) {
      endTag 'tr';
      startTag 'tr';
    }
    ++$col;

    startTag 'td';
    element 'a', $g, href => "empathy/guess$g.html";
    endTag 'td';

    guess_page($g, $game[$g - 1]);
  }
  page HTML_ROOT . "/empathy/guess".(@game+1).".html", sub {
    element 'title', "Game Complete";
    endTag 'head';
    body(4);

    element 'h2', 'Emotion Guessing Game';

    startTag 'p';
    text "You have completed the emotion guessing game.  We hope
you have found the experience valuable and enlightening.";
    endTag 'p';

    startTag 'p';
    text "It would be fun to say something about your score --
if you solved all the questions correct then _X_.  However,
this is not really a serious test of situation assessment
ability.  The purpose of this game is mainly to demonstrate
the intuitive validity of our approach.";
    endTag 'p';

    startTag 'p';
    text "For more information about Aleader, please
subscribe to ";
    element 'a', 'the mailing list',
      href => 'https://lists.berlios.de/mailman/listinfo/redael-devel';
    text ", browse through our ";
    element 'a', 'manual', href => "../manual/index.html";
    text ", and try the ";
    element 'a', 'software', href => "../download.html";
    text ".  Thank you for your time.  We hope to enjoyed
working through the Emotion Guessing Game.";
    endTag 'p';
  };

  endTag 'tr';
  endTag 'table';

  startTag 'p';
  my ($mday, $mon, $year) = (localtime time)[3,4,5];
  text sprintf "(Randomized %d/%d/%d)", $mday, $mon+1, $year+1900;
  endTag 'p';

  emptyTag 'hr';

  startTag 'p';
  text "If you have an comments or questions then don't hesitate to
send email to ";
  mailing_list();
  text ".  We want your feedback, be it good or bad!";
  endTag 'p';

  startTag 'p';
  text "As you work with Aleader more, your situation assessment ability
will develop speed and accuracy.
You will be mislead less frequently.  If you wish then you will be
able to detach from superficial emotions to see the real point.
A knowing, a feeling of inner confidence can grow
and change your life for the better.";
  endTag 'p';

  if (1) {
    endTag 'td';
    startTag 'td';
    hskip 1;
    endTag 'td';
    startTag 'td', valign => 'top', bgcolor => 'black';
    
    my @clip = shuffle keys %Render;
    for (my $x=0; $x < 7; $x++) {
      emptyTag 'img', src => "empathy/".$clip[$x].'.jpg';
      br;
    }
    endTag 'td';
    endTag 'tr';
    endTag 'table';
  }
}

if (defined &main::menupage) {
  package main;
  our $topmenu;
  menupage($topmenu, 'Empathy Index', sub {
      Empathy::empathy_body();
  }, 1);
} else {
  page HTML_ROOT . '/empathy.html', sub {
    my $title = 'Illustrated Empathy Index';
    element 'title', $title;
    endTag 'head';
    body(4);
    
    empathy_body();
    
    vskip 4;
  };
}

sub is_rendered {
  my ($s) = @_;
  return exists $Render{ situation_name($s) };
}

sub use_situation {
  my ($s) = @_;
  ++$Used{ situation_name($s) };
}

sub request_render {
  my ($s, $why) = @_;
  return if exists $Render{ situation_name($s) };
  $Render{ situation_name($s) } = $s;
  #warn $why;
}

# fitness scoring

sub select_example {
  my ($example, $ready, $check_use) = @_;

  return if @$example == 0;

  my @score;
  for (my $x=0; $x < @$example; $x++) {
    my $ex = $example->[$x];
    $score[$x] = 0;

    my ($s_tm, $e_tm) = $ex->get_time_bounds;
    my $tm = $e_tm - $s_tm;
    if ($tm > 10) {
      my $good_tm = - ($tm - 10) / 30;
      $good_tm = -1 if $good_tm < -1;
      $score[$x] += $good_tm;
    }

    $score[$x] -= 1 if $ex->get_chaining == IP_CHAINING_OPTIONAL;

    if ($check_use and $Used{ situation_name($ex) }) {
      my $penalty = .25 + $Used{ situation_name($ex) } / 4;
      $score[$x] -= $penalty;
    }
	
    $score[$x] += .25 if is_rendered($ex);

    my $has_notes = $ex->get_notes;
    my $transcript = $ex->get_transcript->get_pathname;

    if (@$ready) {
      my $dist = 0;
      my $note = 0;
      for (my $rx=0; $rx < @$ready; $rx++) {
	my $r = $ready->[$rx];

	$note += .5 if ($r->get_notes xor $has_notes);

	if ($r->get_transcript->get_pathname ne $transcript) {
	  $dist += 1;
	} else {
	  my ($r_tm) = $r->get_time_bounds;
	  my $space = (500 - abs($s_tm - $r_tm)) / 500;
	  $space = 0 if $space < 0;
	  $dist -= $space;
	}
      }
      $score[$x] += ($dist + $note) / @$ready;
    }
  }
  my @best;
  my $best_score = -100;
  for (my $x=0; $x < @$example; $x++) {
    if ($best_score < $score[$x]) {
      $best_score = $score[$x];
      @best = $x;
    } elsif ($best_score == $score[$x]) {
      push @best, $x;
    }
  }
  @best = shuffle @best;
  my $ret = splice @$example, $best[0], 1;
  request_render($ret, 'example '.join(' ', map { $_->get_label } $ret->empathize($Empathy)));
  use_situation($ret)
    if $check_use;
  $ret;
}

sub fair_use {
  startTag 'p';
  text 'Film clips are presented here under protection
of the ';
  element 'i', 'fair-use for education';
  text ' clause of copywrite law.';
  endTag 'p';
}

sub mailing_list {
  element 'a', 'redael-devel@lists.berlios.de',
    href => 'mailto:redael-devel@lists.berlios.de';
}

sub format_text {
  my ($text) = @_;
  my @l = split /(\n)/, $text;

  for my $l (@l) {
    if ($l eq "\n") {
      print '<br>'
    } else {
      text $l
    }
  }
}

sub situations_to_html {
  my ($situations, $detail, $majority) = @_;

  startTag 'table', border => 1, cellpadding => 6, cellspacing => 0;
  startTag 'tr';
  element 'th', 'Location';
  element 'th', 'Clip';
  element 'th', 'Transcript';
  element 'th', 'Classification'
    if $detail >= 2;
  endTag 'tr';

  for my $s (@$situations) {
    startTag 'tr';
    startTag 'td', align => 'center';
    my $filmname = $FilmName{ $s->get_transcript->get_pathname };
    text $filmname;
    br;
    my $snum = 1+$s->get_transcript->get_situations->lookup($s);
    text '#'.$snum;
    br;
    my @time_bounds = $s->get_time_bounds;
    text sprintf("%.2f - %.2f", @time_bounds);
    br;
    text sprintf("%.2f seconds", $time_bounds[1] - $time_bounds[0]);
    endTag 'td';
    
    startTag 'td';
    startTag 'a', href => situation_name($s).'.avi';
    emptyTag 'img', src => situation_name($s).'.jpg';
    endTag 'a';
    endTag 'td';
    
    startTag 'td';
    startTag 'p';
    startTag 'font', color => '#0000a0';
    text "This situation involves ".$s->get_left->get_name.
      " and ".$s->get_right->get_name.".";
    if ($detail) {
      my $initiator;
      if ($s->get_initiator == IP_INITIATOR_LEFT) {
	$initiator = $s->get_left->get_name;
      } elsif ($s->get_initiator == IP_INITIATOR_RIGHT) {
	$initiator = $s->get_right->get_name;
      }
      if ($initiator) {
	text " $initiator is the initiator.";
      }
    }
    endTag 'font';
    endTag 'p';
    
    my @text = $s->get_transcript_text;
    startTag 'font', color => '#808080';
    text '.. ';
    format_text $text[0];
    endTag 'font';
    startTag 'b';
    format_text $text[1];
    endTag 'b';
    startTag 'font', color => '#808080';
    format_text $text[2];
    text ' ..';
    endTag 'font';
    
    if ($detail) {
      my $notes = $s->get_notes;
      if ($notes) {
	startTag 'p';
	startTag 'font', color => '#0000a0';
	text "(Note: $notes)";
	endTag 'font';
	endTag 'p';
      }
    }
    endTag 'td';
    if ($detail >= 2) {
      my @m = $s->empathize($Empathy);
      my $best;
      if (grep { $_->get_label eq $majority->get_label } @m) {
	$best = $majority;
      } else {
	my $best_rank = -1;
	for my $match (@m) {
	  next if $match->len != 1;
	  if ($best_rank < $match->get_rank) {
	    $best_rank = $match->get_rank;
	    $best = $match;
	  }
	}
      }
      startTag 'td';
      startTag 'big';
      my $pat = $best->stringify;
      $pat =~ s/then \"(.*)\"/then/;
      my $label = $1;
      element 'pre', $pat;
      endTag 'big';
      text $label;
      endTag 'td';
    }
    endTag 'tr';
  }
  endTag 'table';
}

sub transport_buttons {
  my ($no) = @_;

  startTag 'table', cellspacing => 10, cellpadding => 1;
  startTag 'tr';
  
  if ($no > 1) {
    startTag 'td', bgcolor => 'yellow';
    element 'a', "Previous Slide", href => "guess".($no-1).".html";
    endTag 'td';
  }
  
  startTag 'td', bgcolor => 'yellow';
  element 'a', "Next Slide", href => "guess".($no+1).".html";
  endTag 'td';
  
  startTag 'td', bgcolor => 'yellow';
  element 'a', "Back to Top", href => "../empathy.html";
  endTag 'td';
  endTag 'tr';
  endTag 'table';
}

sub guess_page {
  my ($no, $emotion) = @_;

  my $pattern = $Empathy->lookup_key($emotion);
  my @ready;

  page HTML_ROOT . "/empathy/guess$no.html", sub {
    element 'title', "Empathy Guess #$no";
    endTag 'head';
    body(4);

    element 'h2', 'Emotion Guessing Game';
    element 'h3', "Game Slide #$no";
    
    element 'p', "Which of these situations is not like the
other?  Which one doesn't belong?  Tell which situation is not
like the other before we finish this song ...";

    my @example = @{ $Index{$emotion} };

    while (@ready < 3) {
      my $s = select_example(\@example, \@ready);
      last if !$s;
      push @ready, $s;
    }
    die "Not enough situations for $emotion" if @ready < 3;

    my @potent;
    for (my $x=0; $x < $Empathy->len; $x++) {
      my $pat2 = $Empathy->at($x);
      next if ($pat2->len != 1 or
	       !exists $Index{ $pat2->get_label } or
	       $pat2->is_subpattern($pattern) or
	       $pattern->is_subpattern($pat2));
      push @potent, $pat2;
    }
    die "no potents for $emotion?" if !@potent;

    my $needle = $potent[int rand @potent];
    my @ns = @{ $Index{ $needle->get_label } };

    my @ns_ren;
    for my $s2 (@ns) {
      push @ns_ren, $s2 if is_rendered($s2);
    }
    if (@ns_ren) {
      push @ready, $ns_ren[int rand @ns_ren];
    } else {
      my $s2 = $ns[int rand @ns];
      request_render($s2, "Game $emotion");
      push @ready, $s2;
    }

    @ready = shuffle @ready;

    situations_to_html(\@ready, 0);

    vskip 1;
    startTag 'center';
    startTag 'h2';
    element 'a', "Correct Analysis", href => "guessans$no.html";
    endTag 'h2';
    endTag 'center';
    vskip 5;
  };

  page HTML_ROOT . "/empathy/guessans$no.html", sub {
    element 'title', "Empathy Guess Analysis #$no";
    endTag 'head';
    body(4);

    element 'h2', 'Emotion Guessing Game';
    element 'h3', "Game Slide #$no - Correct Analysis";
    
    startTag 'div', align => 'right';
    transport_buttons($no);
    endTag 'div';

    situations_to_html(\@ready, 2, $pattern);

    transport_buttons($no);

    startTag 'p';
    text "If you feel like something is wrong with this
slide then please report the problem to ";
    mailing_list();
    text ".  In your report,
include all the information in the ";
    element 'i', 'Location';
    text " column and a short description what you think is wrong.";
    endTag 'p';

    fair_use();
    vskip 5;
  };
}

sub get_videokey_path {
  my ($k) = @_;
  if ($k eq 'Good-Will-Hunting-1997') {
    '/home/joshua/.aleader/Good-Will-Hunting-1997.xml'
  } elsif ($k eq 'Nausicaa-1984') {
    '/home/joshua/.aleader/Nausicaa-1984.xml'
  } elsif ($k eq 'StarWars-ANewHope-1977') {
    '/home/joshua/.aleader/StarWars-ANewHope-1977.xml'
  } else {
    die $k;
  }
}

for my $s (values %Render) {
  my $filmview = '/home/joshua/aleader/film/aleader-filmview'; #hack XXX
  my $vpath = get_videokey_path($s->get_transcript->get_videokey);
  my ($s_tm, $e_tm) = $s->get_time_bounds;
  my $generic = '/empathy/'.situation_name($s);

  my $image = HTML_ROOT . $generic . '.jpg';
  if (!-e $image) {
    if (-e HTML_CACHE . $generic . '.jpg') {
      rename HTML_CACHE . $generic . '.jpg', $image;
    } else {
      #warn $image;
      my $tm = ($s_tm + $e_tm)/2;
      run sprintf "$filmview --gst-info-mask=0 --open %s --snapshot %.3f",
	$vpath, $tm;
      my $sz = '320x320';
      run "convert -size $sz -resize $sz -quality 20 /tmp/frame01.png $image";
    }
  }

  my $avi = HTML_ROOT . $generic . '.avi';
  if (!-e $avi) {
    if (-e HTML_CACHE . $generic . '.avi') {
      rename HTML_CACHE . $generic . '.avi', $avi;
    } else {
      #warn $avi;
      run sprintf "$filmview --gst-info-mask=0 --open %s --extract %.3f-%.3f",
	$vpath, $s_tm-2, $e_tm+1;
      run "ffmpeg -y -i /tmp/test.m1v -i /tmp/test.wav -map 0:0 -map 1:0 -ac 1 /tmp/test.avi";
      run "mv /tmp/test.avi $avi";
    }
  }
}

__END__

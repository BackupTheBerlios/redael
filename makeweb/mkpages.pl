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
  
  run "tidy -config tidy.conf -utf8 -xml tmp$$ > $file";
  unlink "tmp$$";
}

sub vspace {
  my $reps = $_[0] || 1;
  element 'p',' ' while --$reps >= 0
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
  emptyTag 'br';
  text 'SQ:';
  element 'a', 'Spiritual Intelligence', 'href', 'http://sahajayoga.org';
  endTag 'td';
  
  startTag 'td', 'align', 'center';
  emptyTag 'img', 'src', 'art/trident.png',
    'alt', 'Attention Trident', 'border', 0;
  emptyTag 'br';
  text 'EQ:';
  element 'a', 'Emotional Intelligence',
    'href', 'http://developer.berlios.de/projects/redael';
  endTag 'td';
  
  startTag 'td', 'align', 'center';
  emptyTag 'img', 'src', 'art/mensa.png', 'alt', 'Mensa Logo', 'border', 0;
  emptyTag 'br';
  text 'IQ:';
  element 'a', 'Mental Intelligence', 'href', 'http://www.mensa.org';
  endTag 'td';
  
  endTag 'tr';
  endTag 'table';
  
  endTag 'center';
  vspace;
}  

__END__
startTag 'div', 'align', 'right';
text 'Hosted by ';
startTag 'a', 'href', 'http://www.fokus.gmd.de/', 'target', '_blank';
emptyTag 'img', 'src', 'http://developer.berlios.de/images/logo_fokus.gif',
  'alt', 'GMD FOKUS', 'border', 0, 'height', 73, 'width', 66;
endTag 'a';
endTag 'div';


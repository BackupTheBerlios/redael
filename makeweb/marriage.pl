sub thumb {
  my ($src, $caption) = @_;
  my $sm = $src;
  if ($sm !~ s/\.jpg$/-sm.jpg/) {
    warn "what is $src ?"; next 
  }

  startTag 'center';
  emptyTag 'img', src=>$sm, alt=>$caption;
  br;
  text "$caption ";
  element 'a', '(enlarge)', href => $src;
  endTag 'center';
}

page 'm.html', sub {
  for my $pic (qw(mappl-h.jpg mappl-j.jpg
		  nirmal_nagari.jpg
		  mother_arrives.jpg christmas_puja.jpg 
		  kawali1.jpg making_friends.jpg kawali2.jpg 
		  huldi1.jpg huldi2.jpg
		  huldi_joshua.jpg 
		  marriage_puja.jpg marriage_havan.jpg 
		  marriage_dinner.jpg
		  m_registration.jpg
		  heera-model.jpg kamdi1.jpg kamdi2.jpg kamdi3.jpg)) {
    if (!-e "art/$pic") {
      warn "$pic doesn't exist";
      next;
    }
    my $sm = $pic;
    if ($sm =~ s/\.jpg$/-sm.jpg/) {
      if (modtime("art/$pic") > modtime("art/$sm")) {
	run "cp art/$pic art/$sm";
	run "mogrify -geometry 160x160 art/$sm";
      }
    }
    else { warn "what is $pic ?" }
  }

  element 'title', 'Marriage';
  endTag 'head';

  body 20;

  element 'h1', 'Our Marriage';

  element 'p', 'For about twenty years, Sahaja Yoga has been
offering the opportunity for divine marriage.
In 2001 between Sep and Dec, approximately 300 hopefuls
submitted marriage applications.';

  startTag 'p';
  columns sub {
    element 'p', "Joshua always has put great weight on the importance
of chastity.  He refused to play the ruinous courtship games which are
prevailent in America.  The bleak outlook of western family life also
was not very attractive.";

    element 'p', "His mother was loosing hope that her son would ever marry.
Joshua's parents were delighted to offer their permission and support for an
arranged marriage.";
  },
  sub { hskip 4 },
  sub {
    thumb 'art/mappl-j.jpg', 'Joshua';
  };
  endTag 'p';

  startTag 'p';
  columns  sub {
    thumb 'art/mappl-h.jpg', 'Heera';
  },
  sub { hskip 4 },
  sub {
    element 'p', "The traditional Indian marriage procedure takes too
much time (more than six months) and is too expensive.  Also the bride
must endure too much abuse.";
    element 'p', "Heera's sister had married into a Sahaja Yoga family
two years back.
The marriage has been successful and her parents felt that Sahaja Yoga
attracted high quality people.  They gladly approved the application.";
  };
  endTag 'p';
  
  columns sub {
    startTag 'p';
    text 'Of course the main reason that we applied for
marriage in is because we both wanted a partner with the
subtle understanding of ';
    element 'a', 'vibrations', href => 'http://sahajayoga.org/ExperienceItNOW/';
    text ' which can easily be felt
after self-realization.';
    endTag 'p';

    element 'p', 'The submission deadline was Dec 7.';
    element 'p', 'The forms were collected in Delhi, the capitol of India.';
    element 'p', 'Shri Mataji carefully examined all the forms and
decided the matches.';
    element 'p', 'Unfortunately there were too few gents and some ladies
could not be matched.';
  },
  sub { hskip 4 },
  sub {
    img 'art/mataji.jpg', 'Shri Mataji';
  };

  br;
  columns sub {
    img 'art/ganapatipule.jpg', 'Ganapatipule';
  },
  sub { hskip 4 },
  sub {
    element 'p', 'On Dec 24, the 300 marriage applicants and
about 9000 yogis from around the world arrived at the
international Sahaja Yoga seminar at Ganapatipule, Maharashtra.';
  },
  sub { hskip 4 },
  sub {
    thumb 'art/nirmal_nagari.jpg', 'Nirmal Nagari';
  };

  br;
  columns sub {
    thumb 'art/mother_arrives.jpg', 'Mother Arrives';
  },
  sub { hskip 4 },
  sub {
    element 'p', 'Ganapatipule seminar started with the performance
of Christmas Puja -- we worshipped the mother in the form of
Jesus the Christ and Mother Mary.';
  },
  sub { hskip 4 },
  sub {
    thumb 'art/christmas_puja.jpg', 'Christmas Puja';
  };

  br;
  columns sub {
    thumb 'art/kawali1.jpg', 'Kawalis';
  },
  sub { hskip 4 },
  sub {
    element 'p', 'We enjoyed music performances and Kawalis on Dec 26.';
    element 'p', 'The matches were announced around 19:00 on Dec 27.
We had about 36 hours to take a decision.';
  };

  columns sub {
    element 'p', 'Most divine marriages are successful, but a few end
up in disaster.  We carefully exchanged more information about
our qualifications.';
  },
  sub { hskip 4 },
  sub {
    thumb 'art/making_friends.jpg', 'Making Friends';
  },
  sub { hskip 4 },
  sub {
    element 'p', "Heera:";

    startTag 'ul';
    element 'li', 'B.Sc. (Home Science)';
    element 'li', 'Black Belt in Tae Kwon Do (a few years ago)';
    element 'li', "National Cadet Core - 'C' Certificate Pass";
    endTag 'ul';
  },
  sub { hskip 4 },
  sub {
    element 'p', "Joshua:";
    
    startTag 'ul';
    element 'li', 'Software Engineer';
    startTag 'li';
    element 'a', 'Research in Emotional Intelligence',
      href => 'http://ghost-wheel.net';
    endTag 'li';
    endTag 'ul';
  };

  columns sub {
    element 'p', 'We felt that it was such a good match that
after only one hour we decided to proceed with the marriage.';
    element 'p', 'While waiting for the actual marriages,
 we enjoyed two more evenings filled with dance and music performances.';
  },
  sub { hskip 4 },
  sub {
    thumb 'art/kawali2.jpg', 'Kawalis';
  };

  br;
  columns sub {
    thumb 'art/huldi1.jpg', 'Haldi';
  },
  sub { hskip 2 },
  sub {
    thumb 'art/huldi2.jpg', 'Haldi';
  },
  sub { hskip 4 },
  sub {
    element 'p', 'The haldi program involved lots of loud music,
dancing, and tumeric.';
  },
  sub { hskip 4 },
  sub {
    thumb 'art/huldi_joshua.jpg', 'Joshua';
  };

  br;
  columns sub {
    thumb 'art/marriage_puja.jpg', 'Marriage Day';
  },
  sub { hskip 4 },
  sub {
    element 'p', 'The marriages took place on the evening of Dec 29.
The beautiful background artwork shows two eyes, one male and one female.';

    element 'p', "The ceremony requires the help of some of the
bride's relatives.  Of course it is best if the real relations
are present, but none of our relations were at the seminar.
We recruited substitute relations to perform the requisite rites.";
  },
  sub { hskip 4 },
  sub {
    thumb 'art/marriage_havan.jpg', 'Marriage Havan';
  };

  columns sub {
    element 'p', 'After the marriage havan, we were served dinner and
Shri Mataji ate some food with us.
Then each bride and bride-groom were asked to spontaneously
compose couplets for Shri Mataji.';

    thumb 'art/marriage_dinner.jpg', 'Marriage Dinner';

    element 'p', "(`Heera' means `diamond' in Marathi.)";
  },
  sub { hskip 4 },
  sub {
    startTag 'p';
    img 'art/couplet-j.png', "Joshua's Couplet";
    endTag 'p';
    startTag 'p';
    img 'art/couplet-h.png', "Heera's Couplet";
    endTag 'p';
  };

  columns sub {
    startTag 'p';
    text "During January, we visited Nagpur where most of Heera's
family is living.  A ";
    element 'a', 'wedding reception', href => 'kamdi.html';
    text ' was thrown on Jan 13.';
    endTag 'p';

    element 'p', "Marriage registration in India is not always
simple and easy, especially with a foreigner involved.  Fortunately,
one of Heera's uncles knew how to handle government
bureaucracy.  We got official documentation after only a few days.";

  },
  sub { hskip 4 },
  sub {
    thumb 'art/m_registration.jpg', 'Registration';
  };

  startTag 'p';
  startTag 'b';
  text 'Both of us invite and welcome you to ';
  element 'a', 'Sahaja Yoga', href => 'http://sahajayoga.org';
  text '.';
  endTag 'b';
  endTag 'p';

  startTag 'p';
  text 'We would be very happy to receive your comments at ';
  element 'a', 'joshua@why-compete.org',
    href => 'mailto:joshua@why-compete.org';
  text '.  Thank you very much.';
  endTag 'p';

  element 'p', 'Last modified @DATE@.';
};

page 'kamdi.html', sub {
  element 'title', 'Kamdi Family Reception';
  endTag 'head';

  body 20;

  element 'h2', 'Kamdi Family Reception';

  columns sub {
    element 'p', 'The reception was not as much fun compared to
Ganapatipule.  Even so, we tried to enjoy.  The Nagpur Sahajis
sang two bhajans during the program.';
  },
  sub { hskip 4 },
  sub {
    thumb 'art/kamdi1.jpg', 'Reception';
  },
  sub { hskip 2 },
  sub {
    thumb 'art/kamdi2.jpg', 'Reception';
  };

  br;
  columns sub {
    thumb 'art/kamdi3.jpg', 'Chatting';
  },
  sub { hskip 2 },
  sub {
    thumb 'art/heera-model.jpg', 'Old Photo';
  },
  sub { hskip 4 },
  sub {
    element 'p', "Here is one of Heera's old photos.";
  };

  element 'p', 'Last modified @DATE@.';
}


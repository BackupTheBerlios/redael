page 'm.html', sub {
  element 'title', 'Marriage';
  endTag 'head';

  body 20;

  element 'h1', 'Our Marriage';

  element 'p', 'Between Sep and Dec, approximately 300 people submitted
marriage applications.';

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
    startTag 'center';
    img 'art/mappl-j1.jpg', 'Joshua';
    br;
    text 'Joshua ';
    element 'a', '(enlarge)', href => 'art/mappl-j2.jpg';
    endTag 'center';
  };
  endTag 'p';

  startTag 'p';
  columns sub {
    element 'p', "The traditional Indian marriage procedure takes too
much time (more than six months) and is too expensive.  Also the bride
must endure too much abuse.";
    element 'p', "Heera's sister had married into a Sahaja Yoga family
two years back.
The marriage has been successful and her parents felt that Sahaja Yoga
attracted high quality people.  They gladly approved the application.";

  },
  sub { hskip 4 },
  sub {
    startTag 'center';
    img 'art/mappl-h1.jpg', 'Heera';
    br;
    text 'Heera ';
    element 'a', '(enlarge)', href => 'art/mappl-h2.jpg';
    endTag 'center';
  };
  endTag 'p';
  
  columns sub {
    element 'p', 'Of course the main reason that we applied for
marriage in Sahaja Yoga is because we both wanted a partner with the
subtle understanding of vibrations which can easily be felt
after self-realization.';

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
    element 'p', 'On Dec 24, the 300 marriage applicants and
about 9000 yogis from around the world arrived at the
international Sahaja Yoga seminar at Ganapatipule, Maharashtra.';

    element 'p', 'The matches were announced around 19:00 on Dec 27.';

  element 'p', 'We had about 36 hours to take a decision.  However,
we were both delighted with the match and decided after about
one hour.';

  },
  sub { hskip 4 },
  sub {
    img 'art/ganapatipule.jpg', 'Ganapatipule';
  };

  element 'p', 'The marriages took place on the evening of Dec 29.
Here are some photos from the marrage ceremony:';

  startTag 'p';
  img 'art/mpuja2.jpg', 'During Puja';
  endTag 'p';

  startTag 'p';
  img 'art/mpuja1.jpg', 'During Puja';
  endTag 'p';

  columns sub {
    element 'p', 'After the ceremony, each bride and bride-groom were
asked to spontaneously compose couplets for Shri Mataji.';

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

  startTag 'p';
  element 'i', 'Please let me know any further questions i can answer here.
i will add more photos as they become available.';
  endTag 'p';
};

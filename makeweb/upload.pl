#!/usr/bin/perl -w

our $user = 'vishnu';

use Digest::MD5;

sub run {
  my $cmd = join ' ', @_;
  print "$cmd\n";
  system(@_) == 0 or die "system $cmd failed: $?";
}

our %OldSum;
our %Sum;

if (open my $fh, "<checksum") {
  while (my $line = <$fh>) {
    my @l = split /\s+/, $line;
    next if @l != 2;
    $OldSum{ $l[1] } = $l[0];
  }
  close $fh;
}

our $Date;
{
  my @tm = localtime;
  $Date = sprintf "%02d/%02d/%04d", $tm[3], $tm[4]+1, $tm[5]+1900;
}

sub sync_dir {
  my ($dir, @f) = @_;

  my @extra;
  for my $f (@f) {
    my $print = $f;
    if ($print =~ s/\.html$/-pr.html/) {
      push @extra, $print
	if -e $print;
    }
    
    $print = $f;
    if ($print =~ s/\.html$/-ch.html/) {
      push @extra, $print
	if -e $print;
    }
  }

  my @todo;
  my $md5 = Digest::MD5->new;
  
  for my $f (@f, @extra) {
    my $key = "$dir/$f";
    open my $fh, "<$key" or do {
      warn "open $key: $!";
      $Sum{ $key } = $OldSum{ $key };
      next;
    };
    $md5->addfile($fh);
    my $sum = $md5->hexdigest;

    if (exists $OldSum{ $key } and $OldSum{ $key } eq $sum) {
      print "$key unchanged\n"
    } else {
      push @todo, $f;
    }
    $Sum{ $key } = $sum;
  }

  if (@todo) {
    for my $f (@todo) {
      next if $f !~ m/\.html$/;
      run "perl -pi -e 's,\\\@DATE\\\@,$Date,' $dir/$f";
    }
    run('scp', (map { "$dir/$_" } @todo), $user.'@shell.berlios.de:'.
	'/home/groups/redael/htdocs/'.$dir.'/');
  }
}

sync_dir('.',
	 qw(index.html news.html history.html
	    download.html dl-debian.html dl-unix.html dl-windows.html
	    doc.html doc-intro.html
	    doc-situation.html doc-film.html doc-joints.html doc-xref.html
	    doc-exam.html lists.html
	    scores.html philo.html philo-redael.html
	    jobs.html fairuse.html
	    m.html eyes.html realize.html kamdi.html));

sync_dir('art', map { s,^.+/,,; $_ }
	 glob('art/*.png'),
	 glob('art/*.jpg'));

sync_dir('annotation', map { s,^.+/,,; $_ }
	 glob('annotation/*'));

sync_dir('bulky', map { s,^.+/,,; $_ }
	 glob('bulky/*'));

open my $fh, ">checksum" or die "open: $!";
for (sort keys %Sum) {
  print $fh "$Sum{$_} $_\n";
}

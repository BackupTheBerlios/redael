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

sub sync_dir {
  my ($dir, @f) = @_;

  my @todo;
  my $md5 = Digest::MD5->new;
  
  for my $f (@f) {
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
    run('scp', (map { "$dir/$_" } @todo), $user.'@shell.berlios.de:'.
	'/home/groups/redael/htdocs/'.$dir.'/');
  }
}

sync_dir('.',
	 qw(index.html news.html download.html doc.html
	    doc-situation.html doc-film.html doc-joints.html doc-xref.html
	    doc-exam.html lists.html
	    scores.html philo.html philo-redael.html
	    jobs.html fairuse.html m.html));

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

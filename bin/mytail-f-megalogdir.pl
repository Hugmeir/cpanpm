#!/usr/bin/perl

=pod

customization and extension of mytail-f.pl for megainstall log files.

with the ability to switch to the next file when one file is finished;

displaying filename and current package from time to time;

intelligent handling of incomplete lines

=cut

use File::Spec;
use List::Util qw(maxstr);
use Time::HiRes qw(time sleep);


my $curpos = 0;
my $line;
my $file = youngest();
my $currentpackage;

FILE: while () {
    open GWFILE, $file or die "Could not open '$file': $!";
    my $lines;
    while (<GWFILE>) {
        $lines = $.;
    }
    close GWFILE;
    my $i = 0;
    open GWFILE, $file or die "Could not open '$file': $!";
    my $lastline = "";
    for (;;) {
        my $gotone;
        for ($curpos = tell(GWFILE); $line = <GWFILE>; $curpos = tell(GWFILE)) {
            $i++;
            $gotone=1;
            if ($line =~ /^\s+CPAN\.pm:/) {
                ($currentpackage) = $line =~ /^\s+CPAN\.pm: Going to build\s+(\w[^\e]+\w)(?:\e.*)\s*$/;
            }
            if ($i > $lines - 10) {
                my @time = localtime;
                my $localtime = sprintf "%02d:%02d:%02d", @time[2,1,0];
                my $fractime = time;
                $fractime =~ s/\d+\.//;
                $fractime .= "0000";
                my $prefix = sprintf "%5d %s.%s", $i, $localtime, substr($fractime,0,4);
                if (($i % 18) == 0) {
                    my $filelabel = $file;
                    my $currentpackagelabel;
                    if ($currentpackage) {
                        $currentpackagelabel = $currentpackage;
                        $currentpackagelabel .= " "
                            while length $currentpackagelabel < length $filelabel;
                        $filelabel .= " "
                            while length $currentpackagelabel > length $filelabel;
                    }
                    if (length $lastline) {
                        print "\n(( $filelabel ))\n";
                    } else {
                        print "(( $filelabel ))\n";
                    }
                    if ($currentpackagelabel) {
                        print "(( $currentpackagelabel ))\n";
                    }
                    if ($lastline) {
                        print $lastline;
                    }
                }
                if (length $lastline) {
                    printf "\n%s %s%s", $prefix, $lastline, $line;
                } else {
                    printf "%s %s", $prefix, $line;
                }
                if ($line =~ /\n/) {
                    $lastline = "";
                } else {
                    $i--;
                    $lastline = $line;
                }
            }
        }
        if ($gotone) {
            sleep 0.33;
        } else {
            sleep 1.33;
            my $youngest = youngest();
            if ($youngest ne $file) {
                $file = $youngest;
                next FILE;
            }
        }
        seek(GWFILE, $curpos, 0);  # seek to where we had been
    }
}

sub youngest {
    my($dir,$pat) = @_;
    $dir ||= "/home/sand/CPAN-SVN/logs/";
    $pat ||= qr/^megainstall\..*\.out$/;
    opendir my $dh, $dir or die "Could not opendir '$dir': $!";
    my $youngest = maxstr grep { $_ =~ $pat } readdir $dh;
    File::Spec->catfile($dir,$youngest);
}

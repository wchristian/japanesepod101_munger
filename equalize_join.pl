use strictures;
use IO::All;
use Capture::Tiny 'capture';
use Time::HiRes 'time';
use 5.010;
use Term::ProgressBar;

sub b { Term::ProgressBar->new( { count => shift, ETA => 'linear' } ) }

my $sox   = "C:/Program Files (x86)/sox-14-4-2/sox.exe";
my $ffmpg = "d:/j/jpod/ffmpeg.exe";

my $target = "joined.mp3";
my $ft     = "files.txt";

die "target already exists"    if -e $target;
die "files txt already exists" if -e $ft;

my @files = glob "*.mp3";

mkdir "same" if !-d "same";

my $b = b scalar @files;
for my $file ( @files ) {
    my $target = "same/$file";
    next if -e $target;
    my ( $stdout, $err, $ret ) = capture {
        system qq["$sox" "$file" -R -t mp3 -c 2 -C 128.01 -r 44100 "$target"];
    };
    $err =~ s/^(.*WARN.*(recoverable MAD error|MAD lost sync|is not a recognized ID3v1 genre.)\n)+//g;
    die $err || "sox failed" if $err or $ret;
    $b->update;
}

my @s_files = glob "same/*.mp3";

my $files_txt = join "\n", map "file '$_'", @s_files;
say $files_txt;
io( $ft )->print( $files_txt );

my ( $stdout, $err, $ret ) = capture {
    system qq["$ffmpg" -n -v 23 -f concat -i $ft -c copy "$target"];
};
die $err || "ffmpeg failed" if $err or $ret;

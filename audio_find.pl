use strictures;

package audiofind;

use IO::All -binary;
use GD::Graph::mixed;
use List::Util ();
use PDL;
use 5.010;
use Moo;
use Capture::Tiny 'capture';
use Carp::Always;

use PDL::IO::FlexRaw;
use Term::ProgressBar;

$|++;

sub {
    has $_ => is => 'lazy' for qw( sample_length sample_prefix bit_rate sox global_offset cut_overtime );
  }
  ->();

my $start = time;
my $cmd = $ARGV[0] || die "search / graph / cut";
audiofind->new->$cmd;
say "\ndone " . ( time - $start );

sub _build_sox { "C:/Program Files (x86)/sox-14-4-2/sox.exe" }

sub _build_sample_length { 1.5 }     # length of sample being searched for
sub _build_bit_rate      { 1200 }    # lower bit rate = faster + lower accuracy
sub _build_global_offset { 10 }      # time at start of file to ignore
sub _build_sample_prefix { .025 }    # just to give us a bit of breathing room

sub _build_cut_overtime { 0 }        # time added to location when cutting, tune this,
                                     # only needed with old ffmpeg

sub sample_sources {
    my ( $self ) = @_;
    (
        [ "sample_1", 17.701 ],      #
        [ "sample_2", 20.882 ],
        [ "sample_3", 16.180 ],
    );
}

sub samples {
    my ( $self ) = @_;
    [ map $self->build_sample( @{$_} ), $self->sample_sources ];
}

sub build_sample {
    my ( $self, $sample_source, $sample_start ) = @_;

    $sample_start -= ( $self->sample_prefix + $self->global_offset );

    say "sample file";
    my $sample_file = $self->raw_path( $sample_source );
    return $self->_file_to_pdl_array( $sample_file ) if $sample_file->exists;

    my $values = $self->raw_for( io "$sample_source.mp3" );

    say "saving raw sample data to: " . $sample_file->name;
    my $bit_rate = $self->bit_rate;
    my $start    = int( $bit_rate * $sample_start );
    my $end      = $start + $bit_rate * $self->sample_length - 1;

    my $sample = $values->slice( "$start:$end" );
    io( $sample_file->name )->binary->print( pack 's*', $sample->list );

    return $sample;
}

sub raw_for {
    my ( $self, $file, $b ) = @_;

    my $raw_path = $self->raw_path( $file );
    $self->generate_raw_for( $file, $b ) if !$raw_path->exists;
    my $raw = $self->_file_to_pdl_array( $raw_path );
    return $raw;
}

sub raw_path  { shift->generic_path( @_, "raw" ) }
sub corr_path { shift->generic_path( @_, "corr" ) }
sub png_path  { shift->generic_path( @_, "png" ) }

sub generic_path {
    my ( $self, $file, $type ) = @_;
    return io->catfile( $type, $self->bit_rate, "$file.$type" );
}

sub generate_raw_for {
    my ( $self, $file, $b ) = @_;

    my $m = "generating raw for: " . $file->name;
    $b ? $b->message( $m ) : say $m;

    my $sox      = $self->sox;
    my $bit_rate = $self->bit_rate;
    my $out      = $self->raw_path( $file );
    io( $out->filepath )->mkpath;

    my $start = 20 - $self->global_offset;
    my $end   = 50 - $self->global_offset;
    my ( $stdout, $err, $ret ) = capture {
        system qq["$sox" "$file" -R -t raw -c 1 -b 16 -r $bit_rate "$out" trim $start $end];
    };
    $err =~ s/^(.*WARN.*(recoverable MAD error|MAD lost sync)\n)+//g;
    die $err || "sox failed" if $err or $ret;

    return;
}

sub b { Term::ProgressBar->new( { count => shift, ETA => 'linear' } ) }

sub search {
    my ( $self ) = @_;

    my %samples = map { ; "$_->[0].mp3" => 1 } $self->sample_sources;

    say "finding files to search sample in";
    my $filter = sub {
             $_->filename =~ /\.mp3$/
          && $_->filename !~ /(dialog|bonus)\.mp3$/i
          && !$samples{ $_->filename }
          && $_->size > 200_000
          && !$self->corr_path( $_ )->exists;
    };
    my @mp3s = io->curdir->filter( $filter )->All_Files;

    say "number of files found: " . @mp3s;

    say "generating pdl data for sample";
    my $sub_max = 4;
    my $sub_sample_size;
    my $sample_size;
    my @samples;

    for my $sample ( @{ $self->samples } ) {
        $sample_size ||= $sample->nelem;
        $sub_sample_size ||= $sample_size / $sub_max;
        my ( @sample_norm, @sample_condensed );
        for my $i ( 0 .. $sub_max - 1 ) {
            my $start      = $sub_sample_size * $i;
            my $end        = $start + $sub_sample_size - 1;
            my $sub_sample = $sample->slice( "$start:$end" );
            push @sample_norm,      $sub_sample - avg( $sub_sample );
            push @sample_condensed, sum( $sample_norm[$i]**2 );
        }
        push @samples, { norm => \@sample_norm, condensed => \@sample_condensed };
    }

    my $b      = b scalar @mp3s,;
    my $status = 1;

    for my $file ( @mp3s ) {
        my $search_space      = $self->raw_for( $file, $b );
        my $search_space_size = $search_space->nelem;
        my $max               = $search_space_size - 1 - $sample_size;

        my ( $max_corr, @final_correlations ) = ( 0 );

        for my $sample ( @samples ) {
            my @correlations;
            for my $i ( 0 .. $max ) {
                my $corr = 0;
                for my $j ( 0 .. $sub_max - 1 ) {
                    my $start        = $i + $sub_sample_size * $j;
                    my $end          = $start + $sub_sample_size - 1;
                    my $search_slice = $search_space->slice( "$start:$end" );
                    my $currcorr     = cross_corr( $search_slice, $sample->{norm}[$j], $sample->{condensed}[$j] );

                    last if abs( $currcorr ) < 0.01;
                    $corr += $currcorr;
                }
                push @correlations, $corr < 0.01 ? 0 : $corr;
            }
            my $local_max = List::Util::max( @correlations );
            if ( $local_max > $max_corr ) {
                $b->message( sprintf "replacing %.2f with new correlation %.2f", $max_corr, $local_max ) if $max_corr;
                $max_corr           = $local_max;
                @final_correlations = @correlations;
            }
            else {
                $b->message( sprintf "keeping %.2f over new correlation %.2f", $max_corr, $local_max );
            }
            last if $max_corr > 1.5;
        }

        $b->message( sprintf "final correlation: %.2f", $max_corr );

        my $corr = $self->corr_path( $file );
        io( $corr->filepath )->mkpath;
        $corr->print( join "\n", @final_correlations );
        $b->update( $status++ );
    }
}

sub cross_corr {
    my ( $search_slice, $sample_norm, $sample_condensed ) = @_;

    my $search_norm = $search_slice - avg( $search_slice );
    my $denom       = sqrt( sum( $search_norm**2 ) * $sample_condensed );
    my $corr_coeffs = sum( $search_norm * $sample_norm ) / $denom;

    return $corr_coeffs;
}

sub cut {
    my ( $self ) = @_;

    my $filter = sub {
        $_->filename =~ /\.mp3$/ && $self->corr_path( $_->name )->exists;
    };
    my @mp3s = io->curdir->filter( $filter )->All_Files;

    my %maxes = $self->corr_maxes( @mp3s );

    mkdir "cut" if !-d "cut";

    for my $file ( @mp3s ) {
        my ( $max_i ) = @{ $maxes{ $file->name } };
        my $time = $self->cut_overtime + $self->sample_length + $self->global_offset + $max_i / $self->bit_rate;
        say "$file $time";
        my $target = "cut/" . $file->filename;
        my ( $stdout, $err, $ret ) = capture {
            system qq[ffmpeg -y -v 23 -ss $time -i "$file" -acodec copy "$target"];
        };
        $err =~ s/^(\[mp3 \@ \w+\] (Incorrect BOM value|Error reading lyrics, skipped)\n)+//g;
        die $err || "ffmpeg failed" if $err or $ret;
    }
    return;
}

sub corr_maxes {
    my ( $self, @mp3s ) = @_;
    my %maxes;
    for my $file ( @mp3s ) {
        my @vals = split "\n", $self->corr_path( $file->name )->all;
        my ( $max_i, $max ) = ( 0, 0 );
        for my $i ( 0 .. $#vals ) {
            next if $vals[$i] <= $max;
            ( $max_i, $max ) = ( $i, $vals[$i] );
        }
        $maxes{ $file->name } = [ $max_i, $max ];
    }

    return %maxes;
}

sub graph {
    my ( $self ) = @_;

    my $filter = sub {
        $_->filename =~ /\.mp3$/
          && $self->corr_path( $_->name )->exists
          && !$self->png_path( $_->name )->exists;
    };
    my @mp3s          = io->curdir->filter( $filter )->All_Files;
    my $secs_per_tick = 10;
    my @spacers       = ( '' ) x ( $self->bit_rate * $secs_per_tick - 1 );
    my @labels        = map { ( $_ * $secs_per_tick + $self->global_offset, @spacers ) } 0 .. 3;

    my $b      = b scalar @mp3s,;
    my $status = 1;

    my %maxes = $self->corr_maxes( @mp3s );

    my $all_max = 1 + int( List::Util::max( map $_->[1], values %maxes ) + .01 );

    for my $file ( @mp3s ) {
        my @vals = split "\n", $self->corr_path( $file->name )->all;
        my ( $max_i, $max ) = @{ $maxes{ $file->name } };
        my @max_mark = ( map( { undef } 0 .. $max_i - 1 ), $max );
        my $graph = GD::Graph::mixed->new( 1200, 600 );
        $graph->set(
            title       => $file->name,
            dclrs       => [qw(green red)],
            markers     => [ 3, 1 ],
            types       => [qw(points points)],
            marker_size => 1,
            zero_axis   => 1,
            y_max_value => $all_max,
        );
        my $gd = $graph->plot( [ \@labels, \@vals, \@max_mark ] ) or die $graph->error;

        my $png = $self->png_path( $file );
        io( $png->filepath )->mkpath;
        $png->binary->print( $gd->png );
        $b->update( $status++ );
    }
    return;
}

sub _file_to_pdl_array {
    my ( $self, $file ) = @_;

    # create a header for a single vector; compute the length automatically
    my $n_elements = $file->size / length( pack 's', 0 );
    my %header = ( Type => 'short', NDims => 1, Dims => [$n_elements] );

    my ( undef, undef, $data ) = capture { readflex( $file->name, [ \%header ] ) };
    return $data;
}

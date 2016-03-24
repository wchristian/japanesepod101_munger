use strictures;
use utf8;

package rss::item;

use Moo;
use Carp 'confess';
use Data::Dump 'pp';
use Try::Tiny;
use 5.010;
use utf8::all;

sub StrWLen { confess "string has no length" if ref( \$_[0] ) ne 'SCALAR' or !length( $_[0] ) }

has $_ => ( is => 'ro', required => 1 ) for qw( db );
has $_ => ( is => 'ro', required => 1, isa => \&StrWLen ) for qw( pubDate guid type_name );
has $_ => ( is => 'rw', required => 1, isa => \&StrWLen ) for qw( title );

has lesson_name => ( is => 'lazy', isa => \&StrWLen );
has $_ => ( is => 'lazy' ) for qw( type lesson );

sub _build_lesson_name {
    my ( $self ) = @_;

    # blah
    return "ignore this" if $self->title =~ /Newbie Lesson #3 - Keys/ and $self->pubDate =~ /2010/;

    my $known_lessons = $self->_known_lessons;

    my ( $lesson, @rest ) = grep { $self->title =~ /^$_/ } keys %{$known_lessons};
    die "No lessons matched for " . pp( $self->title ) . "."       if !$lesson;
    die "Multiple lessons matched for " . pp( $self->title ) . "." if @rest;

    return $known_lessons->{$lesson};
}

sub _known_lessons {
    {
        "Absolute Beginner #(\\d+)"                              => "Absolute Beginner Season 1",
        "Absolute Beginner S2 # ?(\\d+)"                         => "Absolute Beginner Season 2",
        "Absolute Beginner Japanese for Every Day #(\\d+)"       => "Absolute Beginner Japanese for Every Day",
        "Absolute Beginner Questions Answered by Hiroko #(\\d+)" => "Absolute Beginner Questions Answered by Hiroko",
        "Japanese Words of the Week with Risa for Intermediate Learners #(\\d+)" =>
          "Japanese Words of the Week with Risa for Intermediate Learners",
        "Japanese Words of the Week with Risa for Beginners #(\\d+)" =>
          "Japanese Words of the Week with Risa for Beginners",
        "Advanced Audio Blog S3 #(\\d+)"                         => "Advanced Audio Blog 3",
        "Advanced Audio Blog S4 #(\\d+)"                         => "Advanced Audio Blog 4",
        "Advanced Audio Blog S5 #(\\d+)"                         => "Advanced Audio Blog 5",
        "Advanced Audio Blog S6 #(\\d+)"                         => "Advanced Audio Blog 6",
        "All About"                                              => "All About",
        "Advanced Audio Blog #35"                                => "Advanced Audio Blog 1",
        "Audio Blog # *([1-9]|[1-9][0-9]|10[0-9])[ :-]"          => "Advanced Audio Blog 1",
        "Audio Blog S2 #(\\d+)"                                  => "Advanced Audio Blog 2",
        "Audio Blog S3 #(\\d+)"                                  => "Advanced Audio Blog 3",
        "Basic Japanese"                                         => "Basic Japanese",
        "Beginner Lesson # *([1-9]|[1-9][0-9]|1[0-6][0-9]|170) " => "Beginner Season 1",
        "Beginner Lesson S2 # ?(\\d+)"                           => "Beginner Season 2",
        "Beginner Lesson S3 #(\\d+)"                             => "Beginner Season 3",
        "Beginner Lesson S4 #(\\d+)"                             => "Beginner Season 4",
        "Beginner Lesson S5 #(\\d+)"                             => "Beginner Season 5",
        "Beginner S4 #(\\d+)"                                    => "Beginner Season 4",
        "Beginner S5 #(\\d+)"                                    => "Beginner Season 5",
        "Beginner S6 #(\\d+)"                                    => "Beginner Season 6",
        "Business Japanese for Beginners #(\\d+)"                => "Business Japanese for Beginners",
        "Cheat Sheet to Mastering Japanese"                      => "Cheat Sheet to Mastering Japanese",
        "Culture Class: Essential Japanese Vocabulary #(\\d+)"   => "Culture Class: Essential Japanese Vocabulary",
        "Culture Class: Holidays in Japan #(\\d+)"               => "Culture Class: Holidays in Japan",
        "Everyday Kanji"                                         => "Everyday Kanji",
        "Get Your 2009 Lesson Schedule"                          => "News",
        "Happy New Year from JapanesePod101"                     => "Japanese Culture Classes",
        "Inner Circle #(\\d+)"                                   => "Inner Circle",
        "Innovative Japanese Culture for Absolute Beginners #(\\d+)" =>
          "Innovative Japanese Culture for Absolute Beginners",
        "Innovative Japanese #(\\d+)"                           => "Innovative Japanese",
        "Intermediate # *([1-9]|[1-7][0-9]|8[0-5]) "            => "Intermediate Season 1",
        "Intermediate Lesson # *([1-9]|[1-7][0-9]|8[0-5]) "     => "Intermediate Season 1",
        "Introduction"                                          => "Introduction",
        "JLPT #[1-6] "                                          => "JLPT Season 1 - Old 4/New N5",
        "JLPT S2 #(\\d+)"                                       => "JLPT Season 2 - New N4",
        "JLPT S3 #(\\d+)"                                       => "JLPT Season 3 - New N3",
        "Japanese Body Language and Gestures"                   => "Japanese Body Language and Gestures",
        "Japanese Children’s Songs"                           => "Japanese Children's Songs",
        "Japanese Counters for Beginners #(\\d+)"               => "Japanese Counters for Beginners",
        "Japanese Culture Class #(\\d+)"                        => "Japanese Culture Classes",
        "Japanese for Everyday Life Lower Intermediate #(\\d+)" => "Japanese for Everyday Life Lower Intermediate",
        "Japanese Listening Comprehension for Absolute Beginners #(\\d+)" =>
          "Japanese Listening Comprehension for Absolute Beginners",
        "Japanese Listening Comprehension for Beginners #(\\d+)" => "Japanese Listening Comprehension for Beginners",
        "Japanese Listening Comprehension for Advanced Learners #(\\d+)" =>
          "Japanese Listening Comprehension for Advanced Learners",
        "Japanese Listening Comprehension for Intermediate Learners #(\\d+)" =>
          "Japanese Listening Comprehension for Intermediate Learners",
        "Japanese Songs #(\\d+)"                                           => "Japanese Children's Songs",
        "Japanese Vocab Builder #(\\d+)"                                   => "Japanese Vocab Builder",
        "Japanese Words of the Week - Fourth of July in the United States" => "Prototype Lessons",
        "Journey Through Japan"                                            => "Journey Through Japan",
        "Just For Fun"                                                     => "Just For Fun",
        "Kanji Video Lesson #(\\d+)"                                       => "Kanji Videos with Hiroko",
        "Kantan Kana"                                                      => "Kantan Kana",
        "Learn Japanese Grammar Video - Absolute Beginner"    => "Learn Japanese Grammar Video - Absolute Beginner",
        "Learn with Pictures and Video"                       => "Learn with Pictures and Video",
        "Learn with Video #(\\d+)"                            => "Learn with Video",
        "Learn with Video S2 #(\\d+)"                         => "Learn with Video 2",
        "Learning Japanese Through Poster"                    => "Learning Japanese Through Posters",
        "Lower Beginner #(\\d+)"                              => "Lower Beginner",
        "Lower Beginner S2 #(\\d+)"                           => "Lower Beginner Season 2",
        "Lower Intermediate #([1-9]|[1-5][0-9]) "             => "Lower Intermediate Season 1",
        "Lower Intermediate Lesson #([1-9]|[1-5][0-9]) "      => "Lower Intermediate Season 1",
        "Lower Intermediate Lesson S2 #(\\d+)"                => "Lower Intermediate Season 2",
        "Lower Intermediate Lesson S3 #(\\d+)"                => "Lower Intermediate Season 3",
        "Lower Intermediate Lesson S4 #(\\d+)"                => "Lower Intermediate Season 4",
        "Lower Intermediate Lesson S5 #(\\d+)"                => "Lower Intermediate Season 5",
        "Lower Intermediate S2 #(\\d+)"                       => "Lower Intermediate Season 2",
        "Lower Intermediate S3 #(\\d+)"                       => "Lower Intermediate Season 3",
        "Lower Intermediate S5 #(\\d+)"                       => "Lower Intermediate Season 5",
        "Lower Intermediate S6 #(\\d+)"                       => "Lower Intermediate Season 6",
        "Must-Know Japanese Social Media Phrases #(\\d+)"     => "Must-Know Japanese Social Media Phrases",
        "Must-Know Japanese Holiday Words #(\\d+)"            => "Must-Know Japanese Holiday Words",
        "Newbie Lesson #([1-35-9]|1[0-9]|2[0-36-9]|30) "      => "Newbie Season 1",
        "Newbie Lesson #(4) - E"                              => "Newbie Season 1",
        "Newbie Lesson #(25|24)"                              => "ignore this",
        "Newbie #(\\d+)"                                      => "Newbie Season 1",
        "Newbie Lesson #\\d - S4:"                            => "Newbie Season 4",
        "Newbie Lesson S2 #(\\d+)"                            => "Newbie Season 2",
        "Newbie Lesson S3 #(\\d+)"                            => "Newbie Season 3",
        "Newbie Lesson S4 #([\\dFAQ]+)"                       => "Newbie Season 4",
        "Newbie Lesson S5 #(\\d+)"                            => "Newbie Season 5",
        "Newbie S4 #(\\d+)"                                   => "Newbie Season 4",
        "Newbie S5 #(\\d+)"                                   => "Newbie Season 5",
        "News"                                                => "News",
        "Onomatopoeia"                                        => "Onomatopoeia",
        "Particles"                                           => "Particles",
        "Premium Lesson #(\\d+)"                              => "Extra Fun",
        "Prototype Lessons #(\\d+)"                           => "Prototype Lessons",
        "Survival Phrases # *([1-9]|[1-5][0-9]|60) "          => "Survival Phrases Season 1",
        "Survival Phrases S2 #(\\d+)"                         => "Survival Phrases Season 2",
        "Talking Japanese Culture #(\\d+)"                    => "Talking Japanese Culture",
        "Top 25 Japanese Questions You Need to Know #(\\d+)"  => "Top 25 Japanese Questions You Need to Know",
        "Ultimate Japanese Pronunciation Guide #(\\d+)"       => "Ultimate Japanese Pronunciation Guide",
        "Upper Beginner #([1-9]|1[0-9]|2[0-5]) "              => "Upper Beginner Season 1",
        "Upper Intermediate Lesson #(0*[1-9]|1[0-9]|2[0-5]) " => "Upper Intermediate Season 1",
        "Upper Intermediate Lesson S2 #(\\d+)"                => "Upper Intermediate Season 2",
        "Upper Intermediate Lesson S3 #(\\d+)"                => "Upper Intermediate Season 3",
        "Upper Intermediate Lesson S4 #(\\d+)"                => "Upper Intermediate Season 4",
        "Upper Intermediate S2 #(\\d+)"                       => "Upper Intermediate Season 2",
        "Upper Intermediate S3 #(\\d+)"                       => "Upper Intermediate Season 3",
        "Upper Intermediate S4 #(\\d+)"                       => "Upper Intermediate Season 4",
        "Upper Intermediate S5 #(\\d+)"                       => "Upper Intermediate Season 5",
        "Video Culture Class: Japanese Holidays #(\\d+)"      => "Video Culture Class: Japanese Holidays",
        "Video Vocab Lesson #([1-9]|1[0-9]|2[0-5]):"          => "Video Vocab Season 1",
        "Video Prototype Lessons #(\\d+)"                     => "Video Prototype Lessons",
        "Wait on a Deal Like This"                            => "News",
        "Yojijukugo"                                          => "Yojijukugo",
        "iLove "                                              => "iLove J-Drama",
    };
}

sub sync {
    my ( $self ) = @_;
    return if $self->is_in_db;

    try {
        $self->db->iquery( "INSERT OR REPLACE INTO items ",
            { map { $_ => $self->$_ } qw( guid pubDate title type lesson ) } );
    }
    catch {
        die "$_\ncaused by:\n" . pp( $self );
    };
    return;
}

sub is_in_db {
    my ( $self ) = @_;
    my ( $old_guid ) = $self->db->iquery( "SELECT guid FROM items WHERE title = ", \( $self->title ) )->list;
    return 1 if $old_guid and $old_guid eq $self->guid;
    return 0;
}

sub _build_lesson { $_[0]->_build_id_for( "lesson" ) }

sub _build_type { $_[0]->_build_id_for( "type" ) }

sub _build_id_for {
    my ( $self, $column ) = @_;

    my $name = "$column\_name";
    my ( $id ) = $self->_get_id_for( $column, $name );
    return $id if defined $id;

    $self->db->iquery( "INSERT INTO ${column}s ", { $name => $self->$name } );
    ( $id ) = $self->_get_id_for( $column, $name );
    return $id;
}

sub _get_id_for {
    my ( $self, $column, $name ) = @_;
    my ( $val ) = $self->db->iquery( "SELECT $column\_id FROM ${column}s WHERE $name = ", \( $self->$name ) )->flat;
    return $val;
}

package rss;

use XML::LibXML;
use DBIx::Simple;
use File::Slurp qw( read_file write_file );
use Parallel::Downloader 'async_download';
use HTTP::Request::Common 'GET';
use DB::Skip pkgs => [
    qw"
      Method::Generate::Constructor Sub::Defer Method::Generate::Accessor Sub::Quote warnings strict Moo::_Utils
      File::Glob
      "
];
use IO::All;
use LWP::UserAgent;
use URI;

use Moo;

has $_ => ( is => 'lazy' ) for qw( db parser );

__PACKAGE__->new->sync_to_db      if !caller;
__PACKAGE__->new->download_lesson if !caller;

sub _build_db {
    my $db = DBIx::Simple->connect( "dbi:SQLite:dbname=jpod.db", "", "" );

    my @tables = (
        "   items (
                guid TEXT PRIMARY KEY,
                pubDate TEXT,
                title TEXT,
                type INTEGER,
                lesson INTEGER,
                downloaded INTEGER",
        "   types (
                type_id INTEGER PRIMARY KEY,
                type_name TEXT",
        "   lessons (
                lesson_id INTEGER PRIMARY KEY,
                lesson_name TEXT",
    );

    $db->query( "CREATE TABLE IF NOT EXISTS $_ )" ) for @tables;

    return $db;
}

sub files { [ glob "*Mith.xml" ] }

sub auth { split /\n/, io( ".auth" )->all }

sub download_rss {
    my ( $self )  = @_;
    my $selection = "301989854:804782073:1040186879:7807"; # http://www.japanesepod101.com/learningcenter/account/myfeed
    my $template  = "custom_0%s_${selection}_Mith.xml";
    my $f_template = "custom_0%s_Mith.xml";
    my $base       = "http://www.japanesepod101.com/premium_feed/";
    my @types      = qw( 2 4 8 16 32 64 256 512 2048 4096 );
    for my $type ( @types ) {
        my $file = sprintf $template, $type;
        my $req = GET( $base . $file );
        $req->headers->authorization_basic( $self->auth );
        my $target_file = sprintf $f_template, $type;
        my $res = $self->mirror_url( $req, $target_file );
        die $res->status_line . " " . $res->decoded_content if !$res->is_success;
    }
    return;
}

sub _build_parser { XML::LibXML->new }

sub download_lesson {
    my ( $self ) = @_;

    my $db      = $self->db;
    my @lessons = $db->query( "SELECT * FROM lessons" )->hashes;
    @lessons = sort { $a->{lesson_name} cmp $b->{lesson_name} } @lessons;
    my %lessons = map { $_->{lesson_id} => $_ } @lessons;
    say "Lessons:";
    say sprintf " % 8d : $_->{lesson_name}", $_->{lesson_id} for @lessons;
    say "Choose:";

    my $target = readline;
    chomp $target;
    die "must choose one"   if !$target;
    die "must choose valid" if !$lessons{$target};
    say "Chosen: $lessons{$target}{lesson_name}";

    my @query = ( "
            SELECT *
            FROM items i
                JOIN lessons l ON i.lesson = l.lesson_id
                JOIN types t ON i.type = t.type_id
            WHERE
                downloaded IS NULL
                AND lesson_id = ?
                AND type_name != ?
                AND type_name != ?
                AND type_name != ?
                AND type_name != ?
                AND type_name != ?
                AND type_name != ?
        ",
        $target,
        "Video Vocab",
        "Video",
        "Lesson Notes PDF",
        "Kanji Close-Up PDF",
        "Combo Track",
        "Review Track",
    );
    my @files = $db->query( @query )->hashes;
    my %files = map { GET( $_->{guid} )->uri->as_string => $_ } @files;

    my @reqs = map GET( $_->{guid} ), @files;
    $_->headers->authorization_basic( $self->auth ) for @reqs;

    my %stores;
    my %stores_in_urls;
    mkdir "downloads" if !-d "downloads";

    my @downloads = async_download(
        requests       => \@reqs,
        debug          => 1,
        workers        => 5,
        conns_per_host => 5,
        aehttp_args    => {
            on_body => sub {
                my ( $body, $headers ) = @_;
                my $url = $self->resolve_url( $headers );
                my $store = $stores{$url} //= $self->get_store_for_url( $url, \%files, \%stores_in_urls );
                write_file( $store, { binmode => ':raw', append => 1, }, $body );
                return 1;
            },
        },
    );

    return;
}

sub unbounce {
    my ( $self, $url ) = @_;
    my %form = URI->new( $url )->query_form;
    my $orig = URI->new( $form{url} )->path;
    return $orig;
}

sub get_store_for_url {
    my ( $self, $url, $files, $stores_in_urls ) = @_;
    $url = $self->unbounce( $url ) if $url =~ /traffic\.libsyn\.com\/bounce\?url/;
    my ( $file_name ) = reverse split '/', $url;
    $file_name =~ s/\?.*$//;
    my ( $extension ) = ( $file_name =~ /.*\.([^\.]*)$/ )
      or die "found no extension in '$file_name' in url '$url'";

    my $file  = $files->{$url};
    my @store = ( $file->{lesson_name} );
    push @store, $self->resolve_lesson_number( $file );
    push @store, $self->useful_type_name( $file );

    my $store = sprintf "downloads/%s.$extension", join " ~ ", @store;
    die "store '$store' of url '$url' conflicts with url '$stores_in_urls->{$store}'" if $stores_in_urls->{$store};
    $stores_in_urls->{$store} = $url;

    return $store;
}

sub useful_type_name {
    my ( $self, $file ) = @_;
    my $n = $file->{type_name};
    return ()             if $n eq "Main Audio Track";
    return "Bonus"        if $n eq "Bonus Audio Track";
    return "Combo Dialog" if $n eq "Combo Track";
    return "Dialog"       if $n eq "Dialog Track";
    return "Grammar"  if $n eq "Other Audio (Counters, Combo, etc)" and $file->{title} =~ /Gramm[ae]r$/;
    return "Counters" if $n eq "Other Audio (Counters, Combo, etc)" and $file->{title} =~ /Counters$/;
    die "could not identify useful track with '$n' and '$file->{title}'";
}

sub resolve_lesson_number {
    my ( $self, $file ) = @_;
    my $re = rss::item->_known_lessons;
    my @numbers;
    for my $r ( keys %{$re} ) {
        next if $file->{title} !~ /^$r/;
        my $number = $1;
        die "recognized lesson '$file->{title}' with '$r' but found no number" if !$number;
        $number = "25.1" if $number eq "FAQ" and $file->{lesson_name} eq "Newbie Season 4";
        $number = sprintf "%05.1f", $number;
        $number =~ s/\.0$//;
        push @numbers, $number;
    }
    die "found multiple numbers for '$file->{title}': '@numbers'" if @numbers > 1;
    die "found no number for '$file->{title}'" if !@numbers;
    return $numbers[0];
}

sub resolve_url {
    my ( $self, $headers ) = @_;
    my $r = $headers->{Redirect};
    return $headers->{URL} if !$r or !@{$r} or ( @{$r} == 1 and !$r->[0] );
    return $r->[1]{URL} if @{$r} == 2 and !$r->[0];
    $DB::single = $DB::single = 1;
    return;
}

sub sync_to_db {
    my ( $self ) = @_;
    my $has_files = @{ $self->files };
    return if $has_files and -e "jpod.db";
    $self->download_rss if !$has_files;
    $self->sync_file( $_ ) for @{ $self->files };
    return;
}

sub sync_file {
    my ( $self, $file ) = @_;

    my $xml = read_file( $file, { binmode => ':utf8' } );
    my $dom = $self->parser->load_xml( string => $xml );
    my ( $type ) = grep $_, reverse split /\n/, $dom->findvalue( "//channel/description" );
    $type =~ s/$_//g for qw( ^\s+ \s+$ );
    $self->sync_item( $_, $type ) for $dom->findnodes( "//item" );

    return;
}

sub misnumbered {
    (
        "Newbie #7 - Learn"            => "Newbie #6 - Learn",
        "Newbie #11 - Rise"            => "Newbie #10 - Rise",
        "Newbie Lesson #12 - Winter"   => "Newbie Lesson #11 - Winter",
        "Newbie Lesson #13 - I'm"      => "Newbie Lesson #12 - I'm",
        "Newbie Lesson #14 - Making"   => "Newbie Lesson #13 - Making",
        "Newbie Lesson #15 - When"     => "Newbie Lesson #14 - When",
        "Newbie Lesson #18 - To Exist" => "Newbie Lesson #15 - To Exist",
    );
}

sub sync_item {
    my ( $self, $item, $type ) = @_;

    my $rss_item = rss::item->new(
        db        => $self->db,
        type_name => $type,
        map { my $v = $item->findvalue( ".//$_" ); $v =~ s/^\s+//; $_ => $v } qw( title pubDate guid )
    );
    my %misnumbered = $self->misnumbered;
    for my $try ( keys %misnumbered ) {
        next if $rss_item->title !~ /^\Q$try\E/;
        my $new_title = $rss_item->title;
        $new_title =~ s/^\Q$try\E/$misnumbered{$try}/;
        $rss_item->title( $new_title );
        1;
    }
    $rss_item->sync;

    return;
}

sub mirror_url {
    my ( $self, $request, $file ) = @_;

    # If the file exists, add a cache-related header
    if ( -e $file ) {
        my ( $mtime ) = ( stat( $file ) )[9];
        if ( $mtime ) {
            $request->header( 'If-Modified-Since' => HTTP::Date::time2str( $mtime ) );
        }
    }
    my $tmpfile = "$file-$$";

    my $ua = LWP::UserAgent->new;
    my $response = $ua->request( $request, $tmpfile );
    die $response->header( 'X-Died' ) if $response->header( 'X-Died' );

    # Only fetching a fresh copy of the would be considered success.
    # If the file was not modified, "304" would returned, which
    # is considered by HTTP::Status to be a "redirect", /not/ "success"
    if ( !$response->is_success ) {
        unlink $tmpfile;
        return $response;
    }

    my @stat               = stat( $tmpfile ) or die "Could not stat tmpfile '$tmpfile': $!";
    my $file_length        = $stat[7];
    my ( $content_length ) = $response->header( 'Content-length' );

    if ( defined $content_length and $file_length != $content_length ) {
        unlink( $tmpfile );
        die $file_length > $content_length
          ? "Content-length mismatch: " . "expected $content_length bytes, got $file_length\n"
          : "Transfer truncated: " . "only $file_length out of $content_length bytes received\n";
    }

    # The file was the expected length.
    # Replace the stale file with a fresh copy
    if ( -e $file ) {    # Some DOSish systems fail to rename if the target exists
        chmod 0777, $file;
        unlink $file;
    }
    rename( $tmpfile, $file )
      or die "Cannot rename '$tmpfile' to '$file': $!\n";

    # make sure the file has the same last modification time
    if ( my $lm = $response->last_modified ) {
        utime $lm, $lm, $file;
    }

    return $response;
}

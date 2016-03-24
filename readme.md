# JapanesePod101 Munger

I like japanesepod101.com, but sadly find their user interfaces to be unconfortable. Both the website and the mobile app don't allow me to just listen to the lessons and dialogs as in one big audiobook.

So i threw together a bunch of tools to download the files i want to listen to, sort them in the right order, strip the 15-30 second (variable) intro jingle, recompress the files into a common format and concat them into big audiobook-sized files to listen to on my phone.

These notes serve both as a rough guide on what's going on, as well as a reminder for myself. Here're the steps that need to be done to get one season audio-booked.

First, we need to download the source files of the season.
 
 - first get all the deps. i didn't keep track of them, but they should not be hard to figure out. try to get the latest versions.
 - create the file `.auth`, it will need to contain your jpod username and password, with a newline inbetween them
 - run `perl rss.pl`, that will use your login to download RSS feeds as configured in `sub download_rss` in `rss.pl`, that'll take a while too
 - it will then show a list of seasons to download
 - if the season you want is not listed, update `$selection` in `rss.pl`, delete the xml files and rerun `rss.pl`
 - if you see it, enter the appropiate number, and wait. the script will exit once the files are downloaded
 - problems may occur due to rss entries having different titles, season names or even numbers than the official listings. if so, you'll need to mess with the hashes and regexes in the subs `misnumbered` and `_known_lessons`

Once you're here, you technically have all you need and could just dump the files on your phone if you don't mind the intros and have a reliable audiobook player. If you're picky like me, the next step cuts out the intros. Sadly this is a bit tricky, since they often vary in length or the sounds used differ slightly. Thus we'll first needs to set up audio samples of the cut-off sound, and then the code can look for those and cut after them.

 - first grab any of the downloaded main lessons and copy it to `sample_1.mp3`. then open it in a sound editor or player and find, as accurate as you can, the point where the wooden bang happens before the lesson proper begins. it should be around 17-23 seconds.
 - then edit `audio_find.pl` to update `sub sample_sources` with the timestamp and filename and make sure the source list matches your existing files
 - run `perl audio_find.pl search`, this will compress the sample you marked into a set of four hashes and search for them in all your downloaded files, creating files containing lists of correlation to your sample at each timestamp. it will also print some debug output. if you see any correlation values coming up less than `1.0`, take note of that file and go back to step 1 to use it to create another sample
 - once you have all files coming back with a correlation of `> 1.0`, you can run `perl audio_find.pl graph`, which will create a bunch of graphs of the correlations and their time positions in your files, so you can review them, check in the audio files that the positions are correct, and verify that the matches are distinct enough.
 - if they are, run `perl audio_find.pl cut`, which will create copies of the files in the directory `cut` with the intro removed. re-verify them to ensure they weren't cut too much.

And lastly, if you'd like to have the files all in one big mp3 for the ease of your audiobook player, the last steps are as follows:

 - copy either your downloaded, or cut (if you did that step), files to another directory
 - shell there, and run `perl <pathto>/equalize_join.pl`, which will first recompress all the files from VBR to CBR with consistent settings for all files, then spit out a list with the order of the files it sees, and merged them into a file called `joined.mp3`
 - if the order of the files as printed wasn't to your liking, rename them to help the sorting, or set up sorting in `equalize_join.pl` itself, delete `joined.mp3` and rerun the script (this bit may need some improvement, currently i just presort them with a batch rename)

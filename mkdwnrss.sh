#!/usr/bin/env perl
# Create RSS XML file ("feed") based on Markdown files
#
# Input: List of Markdown files (order of files determines order of <item>))
# Output: RSS (description with 3 lines of Markdown as excerpt)
#
# Example:
#      mkdwnrss `find blog/2021 -type f | sort -r`
#
# Elmar Klausmeier, 11-May-2021: Initial simple version with no <description>
# Elmar Klausmeier, 16-May-2021: Added <description> handling
# Elmar Klausmeier, 08-Jul-2021: lastBuildDate+pubDate now contain RFC-822 compliant date format, excerpt stripped of <,>,&

# from https://github.com/eklausme/bin/blob/master/mkdwnrss
# TODO remove perl dependancy

use strict;
use POSIX qw(strftime);
use POSIX qw(mktime);

my $dt = strftime("%a, %d %b %Y %H:%M:%S GMT",gmtime());	# RFC-822 format: Wed, 02 Oct 2002 13:00:00 GMT
print <<"EOT";
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
	<title>Ryan Gibb's Blog</title>
	<description>Ryan Gibb's Blog</description>
	<lastBuildDate>$dt</lastBuildDate>
	<link>https://gibbr.org/blog</link>
	<atom:link href="https://gibbr.org/blog/index.xml" rel="self" type="application/rss+xml" />
	<generator>mkdwnrss</generator>
EOT


sub item(@) {
	my $f = $_[0];
	open(F,"< $f") || die("Cannot open $f");

	my $link = $f;
	$link =~ s/\.md$/\//;
	print "\t<item>\n"
	. "\t\t<link>https://gibbr.org/$link</link>\n"
	. "\t\t<guid>https://gibbr.org/$link</guid>\n";

	my ($dt,$year,$month,$day,$hour,$minute,$sec);
	my ($sep,$linecnt,$excerpt) = (0,0,"");
	while (<F>) {
		chomp;
		if (/^\-\-\-$/) { $sep++ ; next; }
		if ($sep == 1) {
			if (/^title:\s+"(.+)"$/) {
				printf("\t\t<title>%s</title>\n",$1);
			} elsif (/^date:\s+"(.+)"$/) {
				$dt = $1;
				if ($dt =~ /(\d\d\d\d).(\d\d).(\d\d).(\d\d).(\d\d).(\d\d)/) {
					($year,$month,$day,$hour,$minute,$sec) = ($1,$2,$3,$4,$5,$6);
					$hour -= 1 if ($hour > 0);	# Subtract one hour to convert to GMT
					# RFC-822 format: Wed, 02 Oct 2002 13:00:00 GMT
					$dt = strftime("%a, %d %b %Y %H:%M:%S GMT",$sec,$minute,$hour,$day,$month-1,$year-1900);
				}
				printf("\t\t<pubDate>%s</pubDate>\n",$dt);
			}
		} elsif ($sep >= 2) {
			next if (length($_) == 0);
			if ($linecnt++ == 0) {
				print "\t\t<description><![CDATA[";
				$excerpt = $_;
			} elsif ($linecnt < 9 || length($excerpt) < 500) {
				$excerpt .= " " . $_;
			} else {
				last;
			}
		}
	}
	if ($linecnt > 0) {
		$excerpt =~ s/&/&amp;/g;
		$excerpt =~ s/</&lt;/g;
		$excerpt =~ s/>/&gt;/g;
		print $excerpt . "]]></description>\n"
	}
	print "\t</item>\n";

	close(F) || die("Cannot close $f");
}


while (<@ARGV>) {
	item($_);
}


print "</channel>\n</rss>\n";

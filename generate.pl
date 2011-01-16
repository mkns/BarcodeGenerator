#!/usr/bin/perl -w

use strict;
use LWP::UserAgent;
use HTTP::Request::Common;
use Data::Dumper;
use strict;

# As you will be able to tell from the URL, this script doesn't generate the
# barcode at all, but instead goes off to the totally useful terryburton.co.uk
# website to get the barcode.  That site has a barcode generator which displays
# the barcode in the web page.  I'm wanting to have a list of barcodes on a
# sheet of paper so that I can order stuff from Tesco using my iPhone and the
# Tesco App which scans barcodes, so I will therefore have a bunch of barcodes
# of regular things that we buy on said bit of paper.  And the easiest way to
# get those barcodes on to a single bit of paper is to generate all the
# barcodes from the barcode code, rather than trying to peel off the barcodes
# from the products themselves.  Hence this script.
#
# Call the script with a 13 digit number, it will then write a PNG file with
# the barcode number to the directory you currently reside in.

generate_barcode( $ARGV[0] );

sub generate_barcode {
	my ($code) = @_;
	my $ua     = get_ua();
	my $url    = "http://www.terryburton.co.uk/barcodewriter/generator/";
	chomp($code) if defined($code);
	if ( !defined $code || length($code) != 13 ) {
		die "Code must be 13 digits long";
	}
	my $data = [
		data        => $code,
		encoder     => "ean13",
		options     => "includetext guardwhitespace",
		rotate      => 0,
		scale_x     => 2,
		scale_y     => 2,
		submit      => "Make Barcode",
		translate_x => 50,
		translate_y => 50,
	];

	my $request = POST $url,
	  Content_Type => 'form-data',
	  Content      => $data;
	my $response = $ua->request($request);
	my @content  = split( "\n", $response->content() );
	my $line     = get_line_of_links_from_content( \@content );
	my $png      = get_png_from_line_of_links($line);
	$request  = GET $url . $png;
	$response = $ua->request($request);
	open( PNG, "> $code.png" ) or die $!;
	print PNG $response->content();
	close(PNG);
}

sub get_png_from_line_of_links {
	my ($line) = @_;
	my ($png) = $line =~ /"(tmp\/\w+\/barcode\.png)/;
	return $png;
}

sub get_line_of_links_from_content {
	my ($content) = @_;
	foreach my $line (@$content) {
		return $line if $line =~ /Download image as/;
	}
}

sub get_ua {
	my ($cookie_jar) = @_;
	$cookie_jar = '/tmp/cookie_jar' if ( !defined($cookie_jar) );
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	$ua->cookie_jar( { file => $cookie_jar, autosave => 1 } );
	push @{ $ua->requests_redirectable }, 'POST';
	return $ua;
}

#!/usr/bin/env perl

# (c) 2000 Copyright Mark Nottingham
# <mnot@pobox.com>
#
# This software may be freely distributed, modified and used,
# provided that this copyright notice remain intact.
#
# This software is provided 'as is' without warranty of any kind.

# cgi_buffer is a library that may be used to improve performance of CGI
# scripts in some circumstances, by applying HTTP mechanisms that are
# typically not supported by them.

# For more information:
#   http://www.mnot.net/cgi_buffer/
  


package cgi_buffer;
use strict;
use MD5;
use IO::String;
use Compress::Zlib;
require 5.004;

$cgi_buffer::generate_etag = 1;
$cgi_buffer::compress_content = 1;


BEGIN {
	use Exporter();
	use vars qw($VERSION $buf $pos $headers $header $header_name $encoding
				$header_value $body @content_type $etag $send_body @o
				$i);
	$VERSION = 0.3;
	
	$cgi_buffer::buf = IO::String->new;
	$cgi_buffer::old_buf = select($cgi_buffer::buf);
}


END {	

	select($cgi_buffer::old_buf);
	$pos = $cgi_buffer::buf->getpos;
	$cgi_buffer::buf->setpos(0);
	read($cgi_buffer::buf, $buf, $pos);
	($headers, $body) = split /\r?\n\r?\n/, $buf, 2;
	$send_body = 1;

	foreach $header (split(/\r?\n/, $headers)) {
		($header_name, $header_value) = split /\:\s*/, $header, 2;
		if (lc($header_name) eq 'content-type') {
			@content_type = split /\//, $header_value, 2;
		}
	}

	if ($cgi_buffer::compress_content) {
		foreach $encoding ('x-gzip', 'gzip') {
			$_ = lc($ENV{'HTTP_ACCEPT_ENCODING'});
			if ( m/$encoding/i && lc($content_type[0]) eq 'text') {
				$body = Compress::Zlib::memGzip($body);
				push @o, "Content-Encoding: $encoding";
				push @o, "Vary: Accept-Encoding";
				last;
			}
		}
	}

	if ($cgi_buffer::generate_etag) {
		$etag = '"' . MD5->hexhash($body) . '"';
		push @o, "ETag: $etag";
		if ($ENV{'HTTP_IF_NONE_MATCH'}) {
			if ($etag =~ m/$ENV{'HTTP_IF_NONE_MATCH'}/) {
				push @o, "Status: 304 Not Modified";
				push @o, "";
				$send_body = 0;
			}
		}	
	}

	if ($send_body) {
		push @o, "Content-Length: " . length($body);
		push @o, $headers;
		push @o, "";
		push @o, $body;
	} 

	print join("\r\n", @o);
}


1;

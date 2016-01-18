#!/usr/bin/perl
#
# --------------------------------------------------------------
#   opml2html, created by Yakov Shafranovich.
#
#   Copyright (c) 2005-2009 SolidMatrix Technologies, Inc.
#   Copyright (c) 2009-2015 Shaftek Enterprises.
#   Copyright (c) 2016- Impossible Dreams Network.
#
#   Source code can be found at:
#   https://github.com/impossibledreams/opml2html
#
#   Licensed under the Apache License, Version 2.0.
# --------------------------------------------------------------
#

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Crypt::SSLeay;
use LWP::UserAgent;
use URI::Escape;
use XML::LibXML;
use XML::LibXSLT;

require 5.004;
use cgi_buffer;
$cgi_buffer::generate_etag = 0;

#--- User Configuration Information ---
# no configuration at this time

#--- NO CONFIGURATION BELOW THIS --
#--- Variables --
my $version = 'opml2html/0.1';
my $content_type = '';
my $output_xsl = '';
my $opml_url = '';

#--- Check parameters --
if ($ENV{'REQUEST_METHOD'} eq "GET")
   { $in = $ENV{'QUERY_STRING'}; }
else
   { $in = <STDIN>; }
$q=new CGI($in);

if($q->param('type') eq '')
{  print "Content-Type: text/plain\n\n";
   print "500 ERROR: Missing parameter 'type'.\n";
   exit;
}

if($q->param('opml_url') eq '')
{  print "Content-Type: text/plain\n\n";
   print "500 ERROR: Missing parameter 'opml_url'.\n";
   exit;
}

#--- Parse 'type' and 'feed' parameters ---
if($q->param('type') eq 'html') {
   $output_xsl = 'templates/html.xsl';
   $content_type = 'text/html';
   $opml_url = $q->param('opml_url');
} else {
   print "Content-Type: text/plain\n\n";
   print "500 ERROR: This type is not supported.\n";
   exit;
}
 
#--- Create input request ---
my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();
my $source;

#--- Parse input OPML file ---
my $req;
$ua = LWP::UserAgent->new;
$ua->agent($version);
$req = HTTP::Request->new(GET => $opml_url);

my $res = $ua->request($req);
if ($res->is_error) {
    print "Content-Type: text/plain\n\n";
    print "500 OPML Request Failed: ", $res->status_line, "\n";
    exit;	
}
$source = $parser->parse_string($res->content);

#--- Process request ---
my $style_doc = $parser->parse_file($output_xsl);
my $stylesheet = $xslt->parse_stylesheet($style_doc);
my $results = $stylesheet->transform($source,
	XML::LibXSLT::xpath_to_string(version => $version),
	XML::LibXSLT::xpath_to_string(opml_url => $opml_url)
	);

print "Content-Type: $content_type\n\n";
print $stylesheet->output_string($results);
exit;
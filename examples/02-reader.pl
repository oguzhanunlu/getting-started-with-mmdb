#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );
use local::lib 'local';

use Data::Printer;
use MaxMind::DB::Reader;
use Net::Works::Address;

my $ip = shift @ARGV or die 'Usage: perl examples/02-reader.pl [ip_address]';

my $reader = MaxMind::DB::Reader->new( file => 'enrich-test-geolite2-city.mmdb' );

say 'Description: ' . $reader->metadata->{description}->{en};

my $record = $reader->record_for_address( $ip );
say np $record;

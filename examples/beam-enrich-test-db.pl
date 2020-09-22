#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );
use local::lib 'local';

use MaxMind::DB::Writer::Tree;
use Net::Works::Network;

my $filename = 'beam-enrich-test-geolite2-city.mmdb';

# Your top level data structure will always be a map (hash).  The MMDB format
# is strongly typed.  Describe your data types here.
# See https://metacpan.org/pod/MaxMind::DB::Writer::Tree#DATA-TYPES

sub _universal_map_key_type_callback {
    my $map = {

        # languages
        de      => 'utf8_string',
        en      => 'utf8_string',
        es      => 'utf8_string',
        fr      => 'utf8_string',
        ja      => 'utf8_string',
        'pt-BR' => 'utf8_string',
        ru      => 'utf8_string',
        'zh-CN' => 'utf8_string',

        # production
        accuracy_radius                => 'uint16',
        autonomous_system_number       => 'uint32',
        autonomous_system_organization => 'utf8_string',
        average_income                 => 'uint32',
        city                           => 'map',
        code                           => 'utf8_string',
        confidence                     => 'uint16',
        connection_type                => 'utf8_string',
        continent                      => 'map',
        country                        => 'map',
        domain                         => 'utf8_string',
        geoname_id                     => 'uint32',
        ipv4_24                        => 'uint32',
        ipv4_32                        => 'uint32',
        ipv6_32                        => 'uint32',
        ipv6_48                        => 'uint32',
        ipv6_64                        => 'uint32',
        is_anonymous                   => 'boolean',
        is_anonymous_proxy             => 'boolean',
        is_anonymous_vpn               => 'boolean',
        is_hosting_provider            => 'boolean',
        is_in_european_union           => 'boolean',
        is_legitimate_proxy            => 'boolean',
        is_public_proxy                => 'boolean',
        is_satellite_provider          => 'boolean',
        is_tor_exit_node               => 'boolean',
        iso_code                       => 'utf8_string',
        isp                            => 'utf8_string',
        latitude                       => 'double',
        location                       => 'map',
        longitude                      => 'double',
        metro_code                     => 'uint16',
        names                          => 'map',
        organization                   => 'utf8_string',
        population_density             => 'uint32',
        postal                         => 'map',
        registered_country             => 'map',
        represented_country            => 'map',
        score                          => 'double',
        static_ip_score                => 'double',
        subdivisions                   => [ 'array', 'map' ],
        time_zone                      => 'utf8_string',
        traits                         => 'map',
        traits                         => 'map',
        type                           => 'utf8_string',
        user_type                      => 'utf8_string',

        # for testing only
        foo       => 'utf8_string',
        bar       => 'utf8_string',
        buzz      => 'utf8_string',
        our_value => 'utf8_string',
    };

    my $callback = sub {
        my $key = shift;

        return $map->{$key} || die <<"ERROR";
Unknown tree key '$key'.
The universal_map_key_type_callback doesn't know what type to use for the passed
key.  If you are adding a new key that will be used in a frozen tree / mmdb then
you should update the mapping in both our internal code and here.
ERROR
    };

    return $callback;
}

# my %types = (
#     country => 'map',
#     city => 'map',
#     subdivisions => 'map',
#     postal => 'map',
#     location => 'map'
# );

my $tree = MaxMind::DB::Writer::Tree->new(

    # "database_type" is some arbitrary string describing the database.  At
    # MaxMind we use strings like 'GeoIP2-City', 'GeoIP2-Country', etc.
    database_type => 'GeoLite2-City',

    languages     => ['en'],

    # "description" is a hashref where the keys are language names and the
    # values are descriptions of the database in that language.
    description =>
        { en => 'Test database of IP data', },

    # "ip_version" can be either 4 or 6
    ip_version => 4,

    # add a callback to validate data going in to the database
    map_key_type_callback => _universal_map_key_type_callback(),

    # "record_size" is the record size in bits.  Either 24, 28 or 32.
    record_size => 24,
);

my %address_for_employee = (
   '37.228.225.32/32' => {
        country => {
            confidence => 95,
            geoname_id => 2635167,
            is_in_european_union => 1,
            iso_code => 'IE',
            names => {
                en => 'Ireland'
            }
        },
        city => {
            confidence => 80,
            geoname_id => 2655045,
            names => {
                en => 'Dublin'
            }
        },
        subdivisions => [
            {
                confidence => 70,
                geoname_id => 6269131,
                iso_code   => 'L',
                names => {
                    en => 'Leinster'
                }
            },
        ],
        postal => {
            code => 'D02',
            confidence => 100
        },
        location => {
            accuracy_radius => 100,
            latitude => 53.3331,
            longitude => -6.2489
        }
   }
);

for my $address ( keys %address_for_employee ) {

    # Create one network and insert it into our database
    my $network = Net::Works::Network->new_from_string( string => $address );

    $tree->insert_network( $network, $address_for_employee{$address} );
}

# Write the database to disk.
open my $fh, '>:raw', $filename;
$tree->write_tree( $fh );
close $fh;

say "$filename has now been created";

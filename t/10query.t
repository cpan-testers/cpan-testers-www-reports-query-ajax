#!/usr/bin/perl -w
use strict;

use lib qw(./lib);
use Test::More tests => 24;

use CPAN::Testers::WWW::Reports::Query::AJAX;

# various argument sets for examples

my @args = (
    { 
        dist    => 'App-Maisha',
        version => '0.15',  # optional, will default to latest version
        format  => 'txt'
    },
    { 
        dist    => 'App-Maisha',
        version => '0.15',  # optional, will default to latest version
        format  => 'xml'
    },
    { 
        dist    => 'App-Maisha',
        version => '0.15',  # optional, will default to latest version
        format  => 'html'
    },
    { 
        dist    => 'App-Maisha',
        version => '0.15',  # optional, will default to latest version
        # default format = xml
    },
    { 
        dist    => 'App-Maisha',
        format  => 'txt'
    },
    { 
        dist    => 'App-Maisha',
        format  => 'xml'
    },
    { 
        dist    => 'App-Maisha',
        format  => 'html'
    },
    { 
        dist    => 'App-Maisha',
        # default format = xml
    }
);

for my $args (@args) {
    my $query = CPAN::Testers::WWW::Reports::Query::AJAX->new( %$args );
    ok($query,'.. got response');

    my $raw  = $query->raw();
    my $data = $query->data();

    my $version = $args->{version} || '0.15';

    if($args->{format} && $args->{format} eq 'html') {
        like($raw,qr{<td><a href="javascript:selectReports\('App-Maisha-$version'\);">$version</a></td>},'.. got version statement in raw');
        ok(1,".. we don't parse html format");
    } elsif($args->{format} && $args->{format} eq 'txt') {
        like($raw,qr{$version,\d+},'.. got version statement in raw');
        ok($data->{$version},'.. got version in hash');
    } else { # xml
        like($raw,qr{<version all="\d+".*?>$version</version>},'.. got version statement in raw');
        ok($data->{$version},'.. got version in hash');
    }
}


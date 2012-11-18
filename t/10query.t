#!/usr/bin/perl -w
use strict;

use lib qw(./lib);
use Test::More tests => 94;

use CPAN::Testers::WWW::Reports::Query::AJAX;

# various argument sets for examples

my @args = (
    {   args => { 
            dist    => 'App-Maisha',
            version => '0.15',  # optional, will default to latest version
            format  => 'txt'
        },
        results => {
            all         => 243,
            pass        => 240,
            fail        => 2,
            na          => 0,
            unknown     => 1,
            pc_pass     => 98.7654320987654,
            pc_fail     => 0.823045267489712,
            pc_na       => 0,
            pc_unknown  => 0.411522633744856
        }
    },
    {   args => { 
            dist    => 'App-Maisha',
            version => '0.15',  # optional, will default to latest version
            format  => 'xml'
        },
        results => {
            all         => 243,
            pass        => 240,
            fail        => 2,
            na          => 0,
            unknown     => 1,
            pc_pass     => 98.7654320987654,
            pc_fail     => 0.823045267489712,
            pc_na       => 0,
            pc_unknown  => 0.411522633744856
        }
    },
    {   args => { 
            dist    => 'App-Maisha',
            version => '0.15',  # optional, will default to latest version
            format  => 'html'
        }
    },
    {   args => { 
            dist    => 'App-Maisha',
            version => '0.15',  # optional, will default to latest version
            # default format = xml
        },
        results => {
            all         => 243,
            pass        => 240,
            fail        => 2,
            na          => 0,
            unknown     => 1,
            pc_pass     => 98.7654320987654,
            pc_fail     => 0.823045267489712,
            pc_na       => 0,
            pc_unknown  => 0.411522633744856
        }
    },
    {   args => { 
            dist    => 'App-Maisha',
            format  => 'txt'
        },
        results => {
            all         => 132,
            pass        => 132,
            fail        => 0,
            na          => 0,
            unknown     => 0,
            pc_pass     => 100,
            pc_fail     => 0,
            pc_na       => 0,
            pc_unknown  => 0
        }
    },
    {   args => { 
            dist    => 'App-Maisha',
            format  => 'xml'
        },
        results => {
            all         => 132,
            pass        => 132,
            fail        => 0,
            na          => 0,
            unknown     => 0,
            pc_pass     => 100,
            pc_fail     => 0,
            pc_na       => 0,
            pc_unknown  => 0
        }
    },
    {   args => { 
            dist    => 'App-Maisha',
            format  => 'html'
        }
    },
    {   args => { 
            dist    => 'App-Maisha',
            # default format = xml
        },
        results => {
            all         => 132,
            pass        => 132,
            fail        => 0,
            na          => 0,
            unknown     => 0,
            pc_pass     => 100,
            pc_fail     => 0,
            pc_na       => 0,
            pc_unknown  => 0
        }
    }
);

SKIP: {
    skip "Network unavailable", 94 if(pingtest());

    for my $args (@args) {
        #diag( join(', ', map {"$_ => $args->{args}{$_}"} keys %{$args->{args}} ) );

        my $query = CPAN::Testers::WWW::Reports::Query::AJAX->new( %{$args->{args}} );
        ok($query,'.. got response');

        my $raw  = $query->raw();
        my $data = $query->data();

        #diag( "raw=$raw" );

        is($query->is_success,  1,  '.. returned successfully');
        is($query->error,       '', '.. no errors');
        
        if($args->{results}) {
            is($query->all,         $args->{results}{all},          '.. counted all reports');
            is($query->pass,        $args->{results}{pass},         '.. counted pass reports');
            is($query->fail,        $args->{results}{fail},         '.. counted fail reports');
            is($query->na,          $args->{results}{na},           '.. counted na reports');
            is($query->unknown,     $args->{results}{unknown},      '.. counted unknown reports');

            is($query->pc_pass,     $args->{results}{pc_pass},      '.. percentage pass reports');
            is($query->pc_fail,     $args->{results}{pc_fail},      '.. percentage fail reports');
            is($query->pc_na,       $args->{results}{pc_na},        '.. percentage na reports');
            is($query->pc_unknown,  $args->{results}{pc_unknown},   '.. percentage unknown reports');
        }

        if($raw) {
            my $version = $args->{args}{version} || '0.15';

            if($args->{args}{format} && $args->{args}{format} eq 'html') {
                like($raw,qr{<td><a href=(\\)?"javascript:selectReports\('App-Maisha-$version'\);(\\)?">$version</a></td>},'.. got version statement in raw');
                ok(1,".. we don't parse html format");
            } elsif($args->{args}{format} && $args->{args}{format} eq 'txt') {
                like($raw,qr{$version,\d+},'.. got version statement in raw');
                ok($data->{$version},'.. got version in hash');
            } else { # xml
                like($raw,qr{<version all=(\\"\d+\\"|"\d+").*?>$version</version>},'.. got version statement in raw');
                ok($data->{$version},'.. got version in hash');
            }
        } else {
            diag($query->error());
            ok($query->error());
            ok(1,'..skipped, request did not succeed');
        }
    }
}

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = 'www.cpantesters.org';
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    system($cmd);
    my $retcode = $? >> 8;
    # ping returns 1 if unable to connect
    return $retcode;
}


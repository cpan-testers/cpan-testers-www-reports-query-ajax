#!/usr/bin/perl -w
use strict;

use lib qw(./lib);
use Test::More;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTOMATED_TESTING} );

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing META.yml" if $@;

plan 'no_plan';

my $yaml = meta_spec_ok(undef,undef,@_);

use CPAN::Testers::WWW::Reports::Query::AJAX;

is($yaml->{version},$CPAN::Testers::WWW::Reports::Query::AJAX::VERSION,
    'META.yml distribution version matches');

if($yaml->{provides}) {
    for my $mod (keys %{$yaml->{provides}}) {
        is($yaml->{provides}{$mod}{version},$CPAN::Testers::WWW::Reports::Query::AJAX::VERSION,
            "META.yml entry [$mod] version matches");
    }
}

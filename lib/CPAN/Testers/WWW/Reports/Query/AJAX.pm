package CPAN::Testers::WWW::Reports::Query::AJAX;

use strict;
use warnings;

our $VERSION = '0.07';
 
#----------------------------------------------------------------------------

=head1 NAME

CPAN::Testers::WWW::Reports::Query::AJAX - Get specific CPAN Testers results

=head1 SYNOPSIS
 
    my $query = CPAN::Testers::WWW::Reports::Query::AJAX->new(
        dist            => 'App-Maisha',
        version         => '0.12',  # optional, will default to latest version
    );

    # basic results
    printf  "ALL: %d\n" .
            "PASS: %d\n" .
            "FAIL: %d\n" .
            "NA: %d\n" .
            "UNKNOWN: %d\n" .
            "%age PASS: %d\n" .
            "%age FAIL: %d\n" .
            "%age NA: %d\n" .
            "%age UNKNOWN: %d\n",

            $query->all,
            $query->pass,
            $query->fail,
            $query->na,
            $query->unknown,
            $query->pc_pass,
            $query->pc_fail,
            $query->pc_na,
            $query->pc_unknown;

    # get the raw data for all results, or a specific version if supplied
    my $data = $query->raw;

    # basic filters (see new() for details)
    my $query = CPAN::Testers::WWW::Reports::Query::AJAX->new(
        dist            => 'App-Maisha',
        version         => '0.12',
        osname          => 'Win32',
        patches         => 1,
        perlmat         => 1,
        perlver         => '5.10.0',
        format          => 'xml' # xml is default, text also supported
    );

    printf  "Win32 PASS: %d\n", $query->pass;

=head1 DESCRIPTION
 
This module queries the CPAN Testers website (via the AJAX interface) and
retrieves a simple data set of results. It then parses these to answer a few 
simple questions.
 
=cut
 
#----------------------------------------------------------------------------
# Library Modules

use WWW::Mechanize;

#----------------------------------------------------------------------------
# Variables

my $URL = 'http://www.cpantesters.org/cgi-bin/reports-summary.cgi?';
#$URL = 'http://reports/cgi-bin/reports-summary.cgi?';    # local test version

my %rules = (
    dist    => qr/^([-\w.]+)$/i,
    version => qr/^([-\w.]+)$/i,
    perlmat => qr/^([0-2])$/i,
    patches => qr/^([0-2])$/i,
    perlver => qr/^([\w.]+)$/i,
    osname  => qr/^([\w.]+)$/i,
    format  => qr/^(text|html|xml)$/i
);

my @fields = keys %rules;

my $mech = WWW::Mechanize->new();
$mech->agent_alias( 'Linux Mozilla' );

# -------------------------------------
# Program

sub new {
    my($class, %hash) = @_;
    my $self = {
        success => 0,
        error   => ''
    };
    bless $self, $class;
    my @valid = qw(format);
    
    for my $key (@fields) {
        next    unless($hash{$key});
        $hash{$key} =~ s/$rules{$key}/$1/;
        next    unless($hash{$key});

        $self->{options}{$key} = $hash{$key};
        push @valid, $key;
    }

    $self->{options}{format} ||= 'xml';

    # ajax request 
    my $url = $URL;
    $url .= join( '&', map { "$_=$self->{options}{$_}" } @valid ); 
    #print "URL: $url\n";
	eval { $mech->get( $url ); };
    if($@ || !$mech->success()) {
        $self->{error} = $@;
        return $self;
    }

    #print "URI: " . $mech->uri . "\n";

    $self->_parse( $mech->content() );
    
    $self->{success} = 1;
    return $self;
}

sub is_success  { $_[0]->{success};         }
sub error       { $_[0]->{error};           }

sub all         { $_[0]->_basic('all');     }
sub pass        { $_[0]->_basic('pass');    }
sub fail        { $_[0]->_basic('fail');    }
sub na          { $_[0]->_basic('na');      }
sub unknown     { $_[0]->_basic('unknown'); }
 
sub pc_pass     { $_[0]->_basic_pc('pass');    }
sub pc_fail     { $_[0]->_basic_pc('fail');    }
sub pc_na       { $_[0]->_basic_pc('na');      }
sub pc_unknown  { $_[0]->_basic_pc('unknown'); }

sub _basic {
    my $self    = shift;
    my $grade   = shift;
    my $version = $self->{options}{version} || $self->{recent};
    return $self->{result}{$version}{$grade};
}

sub _basic_pc {
    my $self    = shift;
    my $grade   = shift;
    my $version = $self->{options}{version} || $self->{recent};
    return 0    unless($self->{result}{$version}{'all'});
    my $pc = sprintf "%3.10f", $self->{result}{$version}{$grade} / $self->{result}{$version}{'all'} * 100;
    $pc =~ s/\.?0+$//;
    return $pc;
}

sub _parse {
    my ($self,$content) = @_;
    $self->{content} = $content;

    if($self->{options}{format} eq 'txt') {
        my @lines = split("\n",$content);
        for my $line (@lines) {
            next if($line =~ /^\s*$/);
            my ($version,$all,$pass,$fail,$na,$unknown) = split(',',$line);
            next unless($version);
            if (!exists $self->{recent}) {
                $self->{recent} = $version;
            }
            $self->{result}{$version}{pass}    = $pass;
            $self->{result}{$version}{fail}    = $fail;
            $self->{result}{$version}{na}      = $na;
            $self->{result}{$version}{unknown} = $unknown;
            $self->{result}{$version}{all}     = $all;
        }

    } elsif($self->{options}{format} eq 'xml') {
        my @lines = split("\n",$content);
        for my $line (@lines) {
            next if($line =~ /^\s*$/);
            my ($all,$pass,$fail,$na,$unknown,$version) = $line =~ m{<version all="([^"]+)" pass="([^"]+)" fail="([^"]+)" na="([^"]+)" unknown="([^"]+)">([^<]+)</version>};
            next unless($version);
            if (!exists $self->{recent}) {
                $self->{recent} = $version;
            }
            $self->{result}{$version}{pass}    = $pass;
            $self->{result}{$version}{fail}    = $fail;
            $self->{result}{$version}{na}      = $na;
            $self->{result}{$version}{unknown} = $unknown;
            $self->{result}{$version}{all}     = $all;
        }

    } elsif($self->{options}{format} eq 'html') {
        # TODO: need to pull out OT response
    }

    # currently no parsing for other formats.
    # use raw to do it yourself :)
}

sub data {
    my $self    = shift;
    my $version = shift;
    return $self->{result}{$version}   if($version);
    return $self->{result};
}

sub raw {
    my $self    = shift;
    return $self->{content};
}
  
1;

__END__

=head1 INTERFACE

=head2 The Constructor

=over

=item * new

Instatiates the object CPAN::WWW::Testers. Requires a hash of parameters, with
'config' being the only mandatory key. Note that 'config' can be anything that
L<Config::IniFiles> accepts for the I<-file> option.

=back

=head2 Status Methods

=over 4

=item * is_success

Returns 1 if request succeeded, otherwise 0.

=item * error

Returns the error if the request was unsuccessful.

=back

=head2 Counter Methods

=over 4

=item * all

For the given query, the total number of reports stored.

=item * pass

For the given query, the total number of PASS reports stored.

=item * fail

For the given query, the total number of FAIL reports stored.

=item * na

For the given query, the total number of NA reports stored.

=item * unknown

For the given query, the total number of UNKNOWN reports stored.

=item * pc_pass

For the given query, the percentage number of PASS reports stored against all 
reports stored.

=item * pc_fail

For the given query, the percentage number of FAIL reports stored against all 
reports stored.

=item * pc_na

For the given query, the percentage number of NA reports stored against all 
reports stored.

=item * pc_unknown

For the given query, the percentage number of UNKNOWN reports stored against all 
reports stored.

=back

=head2 Data Methods

=over 4

=item * data

Returns the basic data structure as a hash reference. If a version is passed
as a parameter, the data only for that version is returned. Otherwise all the
results are returned, with the version as the top level key of the hash.

=item * raw

Returns the raw content returned from the server.

=back

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN::Testers::WWW::Reports::Query::AJAX

=head1 SEE ALSO

L<CPAN::Testers::Data::Generator>,
L<CPAN::Testers::WWW::Reports>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

I would also like to thank Leo Lapworth from prompting me to write this, sorry
its taken so long to release. However, you may be interested in his alternative
query distribution L<CPAN::Testers::Reports::Query::JSON>.

Initially released during the 2012 QA Hackathon in Paris.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2011-2014 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut

use 5.006; #due to 'warnings' pragma
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'CPAN::Testers::WWW::Reports::Query::AJAX',
    'VERSION_FROM'  => 'lib/CPAN/Testers/WWW/Reports/Query/AJAX.pm',
    'PREREQ_PM'     => {
        WWW::Mechanize      => 0,
    },

    'NO_META'       => 1,

    'ABSTRACT'      => 'Retrieve distribution stats direct from CPAN Testers website.',
    'AUTHOR'        => 'Barbie <barbie@cpan.org>'
);

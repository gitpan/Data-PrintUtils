use 5.9.5;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::PrintUtils',
    AUTHOR              => q{Robert Haxton <robert.haxton@gmail.com>},
    VERSION_FROM        => 'lib/Data/PrintUtils.pm',
    ABSTRACT_FROM       => 'lib/Data/PrintUtils.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Data::Dumper' => 0,
        'XML::Simple' => 0,
        'Time::HiRes' => 0,
        'HTML::Tabulate' => 0,        
        'Getopt::CommandLineExports' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-PrintUtils-*' },
);

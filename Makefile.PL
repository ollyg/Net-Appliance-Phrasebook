use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Appliance::Phrasebook',
    AUTHOR              => 'Oliver Gorwits <oliver.gorwits@oucs.ox.ac.uk>',
    VERSION_FROM        => 'lib/Net/Appliance/Phrasebook.pm',
    ABSTRACT_FROM       => 'lib/Net/Appliance/Phrasebook.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Data::Phrasebook' => 0.26,
        'Data::Phrasebook::Loader::YAML' => 0.06,
        'YAML' => 0.62,
        'List::MoreUtils' => 0,
        'Class::Data::Inheritable' => 0,
        'Data::Dumper' => 2.121,
    },
    LICENSE             => 'GPLv2',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Appliance-Phrasebook-*' },
);

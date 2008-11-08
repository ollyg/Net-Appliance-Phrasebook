use inc::Module::Install 0.67;
perl_version '5.008001';
  
name        'Net-Appliance-Phrasebook';
all_from    'lib/Net/Appliance/Phrasebook.pm';

requires    'Data::Phrasebook' => 0;
requires    'Data::Phrasebook::Loader::YAML' => 0;
requires    'YAML' => 0;
requires    'List::MoreUtils' => 0;
requires    'Class::Data::Inheritable' => 0;
requires    'Data::Dumper' => 2.121;

test_requires  'Test::More' => 0;
test_requires  'Test::Pod' => 0;
test_requires  'Test::Pod::Coverage' => 0;

WriteAll;


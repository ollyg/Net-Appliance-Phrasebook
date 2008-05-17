package Net::Appliance::Phrasebook;

use strict;
use warnings FATAL => qw(all);

use base qw(Class::Data::Inheritable);
our $VERSION = 0.1;

use Data::Phrasebook;
use List::Util qw(first);
use List::MoreUtils qw(after_incl);
use Symbol;
use Carp;

__PACKAGE__->mk_classdata('__data_position');
__PACKAGE__->mk_classdata('__families' => [
    ['FWSM3', 'FWSM', 'PIXOS', 'Cisco'],
    ['Aironet', 'IOS', 'Cisco'],
    ['CATOS', 'Cisco'],
    ['HP', 'Cisco'],
    ['Nortel', 'Cisco'],
]);

sub new {
    my $class = shift;
    my %args  = @_;

    croak "missing argument to Net::Appliance::Phrasebook::new"
        if not defined $args{platform};

    my ($data, $dict);

    # user's own phrasebook
    if (exists $args{source}) {
        $data = $args{source};
        $dict = $args{platform};

    }
    # our internal phrasebook
    else {
        # find and prune down dictionary list
        # NOTE: nested func's from List::* have bad scope, hence using inner grep
        my $family = first { grep { $_ eq $args{platform} } @{$_} } @{__PACKAGE__->__families};
        $dict = [ after_incl { $_ eq $args{platform} } @{$family} ];

        croak "unknown platform: $args{platform}, could not find dictionary"
            if scalar @{$dict} == 0 or ! defined $dict->[0];

        # the YAML "file" is actually our __DATA__ section.
        $data = Symbol::qualify_to_ref('DATA');

        # the DATA handle is global, so if we're called again it will need
        # to be reset back to the position in the file of the __DATA__ tag
        if (! defined __PACKAGE__->__data_position) {
            __PACKAGE__->__data_position( tell $data );
        }
        else {
            seek ($data, __PACKAGE__->__data_position, 0);
        }

# if your Data::Dumper is old, you might need to uncomment this section
#        {
#            no warnings 'redefine';
#    
#            # kill this, because it can't cope with dumping a IO::Handle
#            # (i.e. the Data::Phrasebook's 'file' arg)
#            sub Data::Phrasebook::Debug::dumper { return ''; }
#        }
    }

    my $self = Data::Phrasebook->new(
        class  => 'Plain',
        loader => 'YAML',
        file   => $data,
        dict   => $dict,
    );
    $self->delimiters(qr{^!}); # it objects to colons
    $self->data('0 but true'); # force load on Phrasebook (a bug in D::P)

    return $self;
}

*{Symbol::qualify_to_ref('load')} = \&new;

1;

=head1 NAME

Net::Appliance::Phrasebook - Network appliance command-line phrasebook

=head1 VERSION

This document refers to version 0.1 of Net::Appliance::Phrasebook.

=head1 SYNOPSIS

 use Net::Appliance::Phrasebook;
 
 my $pb = Net::Appliance::Phrasebook->new(
     platform => 'IOS',
     source   => '/a/file/somewhere.yml', # optional
 );
 
 print $pb->fetch('a_command_alias'), "\n";

=head1 DESCRIPTION

If you use Perl to manage interactive sessions with with the command-line
interfaces of networked appliances, then you might find this module useful.

Net::Appliance::Phrasebook is a simple module that contains a number of
dictionaries for the command-line interfaces of some popular network
appliances.

It also supports the use of custom phrasebooks, and of hiearchies of
dictionaries within phrasebooks.

=head1 TERMINOLOGY

This module is based upon L<Data::Phrasebook>. A I<phrasebook> is a file which
contains one or more dictionaries. A I<dictionary> is merely an associative
array which maps keywords to values. In the case of this module, the values
happen to be command line interface commands, or related data, that help in
the remote management of network appliances.

=head1 METHODS

=head2 C<new>

This method accepts a list of named arguments (as a hash).

There is one required named argument, which is the class of device whose
dictionary you wish to access. The named argument is called C<platform>.

One further, optional argument to C<new> is the filename of a phrasebook. If
this is not provided, Net::Appliance::Phrasebook will use its own internal
phrasebook (see L</"SUPPORTED SYSTEMS">). This named argument is called
C<source>.

The C<new> constructor returns a L<Data::Phrasebook> query object, or C<undef>
on failure.

=head2 C<load>

This is an alias for the C<new()> constructor should you prefer to use it.

=head2 C<fetch>

Pass this method a single keyword, and it will return the corresponding value
from the dictionary. It will die on lookup failure, because that's what
Data::Phrasebook does when there is no successful hit for the given keyword in
available dictionaries.

=head1 SUPPORTED SYSTEMS

You can select the I<platform> that most closely reflects your device. There
is a hierarchy of platforms, so any entry in a given "lineage" will use itself
and its "ancestors", in order, for lookups:

 ['FWSM3', 'FWSM', 'PIXOS', 'Cisco']
 ['Aironet', 'IOS', 'Cisco']
 ['CATOS', 'Cisco']

For example the value C<FWSM> (for Cisco Firewall Services Modules with
software versions up to 2.x) will fetch commands from the C<FWSM> dictionary
and then the C<PIXOS> dictionary, then the C<Cisco> dictionary, before
failing.

Rather than repeat myself here, if you want to see what dictionaries are built
into the module, and what phrases they each contain, then look at this
module's source code. If you are reading this on-line, there may be a
C<Source> hyperlink at the top of the page; click it then scroll to the bottom
of the next page and you will see the built-in dictionaries.

=head1 CUSTOM PHRASEBOOKS

Phrasebooks must be written in YAML, with each dictionary being named within
the top-level associative array in the stream. Please see
L<Data::Phrasebook::Loader::YAML> for more detail on the format of the content
of a YAML phrasebook file.

In the world of network appliances, vendors will sometimes change the commands
used in or even the appearance of the command line interface. This might
happen between software version releases, or as a new product line is
released.

However, typically there is an ancestry to all these interfaces, so we can
base a new product's dictionary on an existing dictionary whilst overriding
some entries with new values. If you study the source to this module, you'll
see that the bundled phrasebook makes uses of such platform families to avoid
repetition.

It is recommended that when creating new phrasebooks you follow this pattern.
When doing so you B<must> pass an array reference to the C<platform> argument
of C<new> and it will be used as a list of dictionaries to find entries in, in
order. Note that the array reference option for the C<platform> argument will
only work when used with a named external source data file.

=head1 TIPS

One way to quickly modify the built-in phrasebook, is to copy everthing below
the C<__DATA__> line in the source code into a new file, then make changes,
then use that file in the C<source> named parameter. Make sure you pass the
C<platform> parameter a value too, in that case.

Read the manual pages for L<Data::Phrasebook::Loader::YAML> and
L<Data::Phrasebook> to understand what a I<default dictionary> is, and why you
probably always want to have (an empty) one in a phrasebook.

In YAML, an empty associative array is represented by C<{}>. Be sure to put
that into your cutom dictionaries where needed, otherwise
Data::Phrasebook::Loader::YAML will misbehave.

=head1 DIAGNOSTICS

=over 4

=item C<missing argument to Net::Appliance::Phrasebook::new>

You forgot to pass the required C<platform> argument to C<new>.

=item C<unknown platform: foobar, could not find phrasebook>

You asked for a dictionary C<foobar> that does not exist in the internal
phrasebook.

=back

=head1 DEPENDENCIES

Other than the the contents of the standard Perl distribution, you will need
the following:

=over 4

=item *

Data::Phrasebook::Loader::YAML >= 0.06

=item *

Data::Phrasebook >= 0.26

=item *

List::MoreUtils

=item *

Class::Data::Inheritable

=item *

YAML >= 0.62

=back

=head1 BUGS

If you spot a bug or are experiencing difficulties that are not explained
within the documentation, please send an email to oliver@cpan.org or submit a
bug to the RT system (http://rt.cpan.org/). It would help greatly if you are
able to pinpoint problems or even supply a patch.

=head1 SEE ALSO

L<Data::Phrasebook>, L<Net::Appliance::Session>,
L<Data::Phrasebook::Loader::YAML>

=head1 AUTHOR

Oliver Gorwits C<< <oliver.gorwits@oucs.ox.ac.uk> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) The University of Oxford 2006. All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of version 2 of the GNU General Public License as published by the
Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
St, Fifth Floor, Boston, MA 02110-1301 USA

=cut

__DATA__
0000default : {}

Cisco :
    prompt            : '/[\/a-zA-Z0-9._-]+ ?(?:\(config[^)]*\))? ?[#>] ?$/'
    basic_prompt      : '/> ?$/'
    privileged_prompt : '/# ?$/'
    configure_prompt  : '/\(config[^)]*\)# ?$/'
    user_prompt      : '/[Uu]sername/'
    pass_prompt      : '/[Pp]assword: ?$/'
    userpass_prompt  : '/(?:[Uu]sername|[Pp]assword): ?$/'
    begin_privileged_cmd           : 'enable'
    begin_privileged_with_user_cmd : 'login'
    end_privileged_cmd             : 'disable'
    begin_configure_cmd            : 'configure terminal'
    end_configure_cmd              : 'exit'
    disconnect                     : 'exit'

CATOS :
    prompt            : '/[\/a-zA-Z0-9._-]+ ?[#>] ?(?:\(enable[^)]*\))? ?$/'
    privileged_prompt : '/> \(enable\) ?$/'
    err_string : '/% ?(?:Error|Type "[^?]+\?"|(?:Incomplete|Unknown) command|Invalid input)/'
    paging_cmd : 'set length'

IOS :
    err_string : '/% ?(?:Error|Type "[^?]+\?"|(?:Incomplete|Unknown) command|Invalid input)/'
    paging_cmd : 'terminal length'

Aironet : {}

PIXOS :
    err_string : '/(?:Type help|(?:Error|ERROR|Usage|usage):|not allowed)/'
    paging_cmd : 'pager lines'

FWSM : {}

FWSM3 :
    paging_cmd : 'terminal pager lines'

HP :
    prompt       : '/[\/a-zA-Z0-9._-:]+ ?(?:\(config[^)]*\))? ?[#>] ?$/'
    basic_prompt : '/: ?$/'
    user_prompt  : '/login as: ?$/'

Nortel :
    prompt       : '/[\/a-zA-Z0-9._-:]+ ?(?:\(config[^)]*\))? ?[#>] ?$/'
    user_prompt  : '/Login: ?$/'


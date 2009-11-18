#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use Fatal qw(open close);
#use File::Slurp 'slurp';
#use List::MoreUtils 'uniq';
#use autodie;

print "Generate Mouse::Tiny ...\n";

sub slurp {
    open my $in, '<', $_[0];
    local $/;
    return scalar <$in>;
}
sub uniq{
    my %seen;
    return grep{ !$seen{$_}++ } @_;
}

require 'lib/Mouse/Spec.pm';

my $MouseTinyFile = shift || 'lib/Mouse/Tiny.pm';

my @files;

find({
    wanted => sub {
        push @files, $_
            if -f $_
            &&  /\.pm$/
            && !/Squirrel/
            && !/Tiny/
            && !/Spec/         # has no functionality
            && !/TypeRegistry/ # deprecated
            && !/\bouse/       # ouse.pm
    },
    no_chdir => 1,
}, 'lib');

my $mouse_tiny = '';

for my $file (uniq
        'lib/Mouse/PurePerl.pm',
        'lib/Mouse/Exporter.pm',
        'lib/Mouse/Util.pm',
        'lib/Mouse/Meta/TypeConstraint.pm',
        'lib/Mouse/Util/TypeConstraints.pm',
            sort @files) {

    my $contents = slurp $file;

    $contents =~ s/__END__\b.*//s;          # remove documentation
    $contents =~ s/1;\n*$//;                # remove success indicator

    $mouse_tiny .= "BEGIN{ # $file\n";
    $mouse_tiny .= $contents;
    $mouse_tiny .= "}\n";
}

open my $handle, ">$MouseTinyFile";

print { $handle } << "EOF";
# This file was generated by $0 from Mouse $Mouse::Spec::VERSION.
#
# ANY CHANGES MADE HERE WILL BE LOST!

EOF

print { $handle } << 'EOF';
# if regular Mouse is loaded, bail out
unless ($INC{'Mouse.pm'}) {
    # tell Perl we already have all of the Mouse files loaded:
EOF

for my $file (@files) {
    (my $inc = $file) =~ s{^lib/}{};
    printf { $handle } "%-45s = __FILE__;\n", "\$INC{'$inc'}";
}

print { $handle } << 'EOF';
eval sprintf("#line %d %s\n", __LINE__, __FILE__) . <<'END_OF_TINY';
EOF

print { $handle } "\n# and now their contents\n\n";

print { $handle } $mouse_tiny;

print { $handle } << 'EOF';
END_OF_TINY
    die $@ if $@;
} # unless Mouse.pm is loaded
EOF

print { $handle } << 'EOF';
package Mouse::Tiny;

Mouse::Exporter->setup_import_methods(also => 'Mouse');

1;
__END__

=head1 NAME

Mouse::Tiny - Mouse in a single file

=head1 DESCRIPTION

Mouse::Tiny is just Mouse itself, but it is in a single file.

This is B<not> tiny. In fact, it requires a little more memory and time than Mouse.

Use Mouse directly unless you know what you do.

=cut

EOF

close $handle;

print "done.\n";

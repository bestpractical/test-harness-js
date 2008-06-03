use warnings;
use strict;
package Test::Continuous::JS;

use 5.008;

our $VERSION = '0.0.5';

use Exporter::Lite;
use App::Prove;
use File::Find;
use File::Modified;
use Cwd;
use List::MoreUtils qw(uniq);
use Path::Class;

our @EXPORT = qw(&runtests);
{
    no warnings;
    *{App::Prove::_exit} = sub {};
}

my @tests;
my @changes;
my @files;

sub _files {
    return @files if @files;
    find sub {
        my $filename = $File::Find::name;
        return if ! -f $filename;
        return unless $filename =~ /\.(js|t)$/ && -f $filename;
        push @files, $filename;
    }, getcwd;

    my @otherfiles = split(/\n/, file('js-libs')->slurp());
    push @files, @otherfiles;
    warn join(",,,",@files);
    return @files;
}

sub _tests_to_run {
    my %dep;

    my @tests_to_run = uniq sort map {
        if (/.t$/) {
            $_;
        }
    } @files;

    return @tests_to_run;
}

sub _run_once {
    my $prove = App::Prove->new;

    $prove->process_args(
        "--formatter" => "Test::Continuous::Formatter",
        "-m", "--norc", "--nocolor", '-l',  'jsharness.pl'
    );
    $prove->run;
}

sub runtests {
    @tests = @ARGV ? @ARGV : <t/*.t>;
    print "[MSG] Will run continuously test $_\n" for @tests;
    my $d = File::Modified->new( files => [ _files ] );
    while(1) {
        if ( @changes = $d->changed ) {
            print "[MSG]: $_ was changed.\n" for @changes;
            $d->update();
            _run_once;
        }
        sleep 3;
    }
}

1;

__END__

=head1 NAME

Test::Continuous - Run your tests suite continusouly when developing.

=head1 VERSION

This document describes Test::Continuous version 0.0.4

=head1 SYNOPSIS

    % cd MyModule/
    % perl -MTest::Continuous -e runtests

=head1 DESCRIPTION

I<Continuous Testing> is a concept and tool to re-run software tests
as soon as the developer saved the source code.

See also L<http://groups.csail.mit.edu/pag/continuoustesting/> for the
original implementation of Continuous Testing as a Eclipse plugin.

See also Zentest L<http://www.zenspider.com/ZSS/Products/ZenTest/> for
the same concept of implementation in Ruby's world.

=head1 INTERFACE

=over

=item runtests

This is the only function that you should be calling, directly
from command line:

    perl -MTest::Continuous -e runtests

It'll start monitoring the mtime of all files under current working
directy. If there's any update, it'll run your module test under t/
directory with L<App::Prove>.

Test result are displayed on terminal. Also dispatched to Growl if
C<Log::Dispatch::MacGrowl> is installed. Big plus for perl programmers
on Mac.

C<Test::Continuous> will auto detect the subset of tests to run.
For example, say you have two test files C<feature-foo.t> and
C<feature-bar.t> which test ,and use, your module C<Feature::Foo>
and C<Feature::Bar> respectively. C<Test::Continuous> can catch
this static dependency and only run C<feature-foo.t> when C<Feature::Foo>
is modified, C<feature-bar.t> will only be ran if C<Feature::Bar>
is modified.

If a C<.t> file is modified, only that test file will be ran.

Dynamic module dependency is more difficult to detect and needs
further research.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Test::Continuous requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<App::Prove>, L<Log::Dispatcher>, L<Log::Dispatch::MacGrowl>,
L<Module::ExtractUse>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-continuous@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

=over

=item A good name for executable.

=item Accept a per-module config file to tweak different parameters to prove command.

=back

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Kang-min Liu C<< <gugod@gugod.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

package inc::MBFLTKExt;
{
    use strict;
    use warnings;
    $|++;
    use Config qw[%Config];
    use ExtUtils::ParseXS qw[];
    use File::Spec::Functions qw[catdir rel2abs abs2rel canonpath curdir];
    use File::Basename qw/basename dirname/;
    use File::Find qw[find];
    use File::Path qw[make_path];
    use base 'Module::Build';
    our %dl_funcs;
    {

        package My::ExtUtils::CBuilder;
        use base 'ExtUtils::CBuilder';

        sub do_system {
            my ($self, @cmd) = @_;
            @cmd = grep { defined && length } @cmd;
            @cmd = map { s[\s+$][]; s[^\s+][]; $_ } @cmd;
            print "@cmd\n" if !$self->{'quiet'};
            my $cmd = join ' ', @cmd;
            `$cmd`;
            return 1;

            #(my( $program), @cmd) = @cmd;
            #return !system ($program, @cmd);
        }

        sub prelink {
            my ($self, %args) = @_;
            ($args{dl_file} = $args{dl_name}) =~ s/.*:://
                unless $args{dl_file};
            $args{'dl_funcs'} = \%inc::MBX::FLTK::dl_funcs; # Frakin' CBuilder
            require ExtUtils::Mksymlists;
            ExtUtils::Mksymlists::Mksymlists( # dl. abbrev for dynamic library
                DL_VARS  => $args{dl_vars}      || [],
                DL_FUNCS => $args{dl_funcs}     || {},
                FUNCLIST => $args{dl_func_list} || [],
                IMPORTS  => $args{dl_imports}   || {},
                NAME   => $args{dl_name},     # Name of the Perl module
                DLBASE => $args{dl_base},     # Basename of DLL file
                FILE   => $args{dl_file},     # Dir + Basename of symlist file
                VERSION =>
                    (defined $args{dl_version} ? $args{dl_version} : '0.0'),
            );

            # Mksymlists will create one of these files
            return grep -e, map "$args{dl_file}.$_", qw(ext def opt);
        }
    }
    {

        sub ACTION_code {
            require Alien::FLTK;              # Should be installed by now
            my ($self, $args) = @_;
            my $AF = Alien::FLTK->new();
            my $CC = My::ExtUtils::CBuilder->new();
            my (@xs, @rc, @pl, @obj);
            find(sub { push @xs, $File::Find::name if m[.+\.xs$]; }, 'xs');
            find(sub { push @pl, $File::Find::name if m[.+\.pl$]i; },
                 'xs/rc') if -d '/xs/rc';
            if ($self->is_windowsish && -d '/xs/rc') {
                $self->do_system($^X, $_) for @pl;
                find(sub { push @rc, $File::Find::name if m[.+\.rc$]; },
                     'xs/rc');
                my @dot_rc = grep defined,
                    map { m[\.(rc)$] ? rel2abs($_) : () } @rc;
                for my $dot_rc (@dot_rc) {
                    my $dot_o = $dot_rc =~ m[^(.*)\.] ? $1 . '.res' : next;
                    push @obj, $dot_o;
                    next if $self->up_to_date($dot_rc, $dot_o);
                    printf 'Building Win32 resource: %s... ',
                        abs2rel($dot_rc);
                    chdir $self->base_dir . '/xs/rc';
                    require Config;
                    my $cc = $Config{'ccname'} || $Config{'cc'};
                    if ($cc eq 'cl') {    # MSVC
                        print $self->do_system(
                                      sprintf 'rc.exe /l 0x409 /fo"%s" %s',
                                      $dot_o, $dot_rc) ? "okay\n" : "fail!\n";
                    }
                    else {                # GCC
                        print $self->do_system(
                                      sprintf 'windres -O coff -i %s -o %s',
                                      $dot_rc, $dot_o) ? "okay\n" : "fail!\n";
                    }
                    chdir rel2abs($self->base_dir);
                }
                map { abs2rel($_) if -f } @obj;
            }
            my @cpp;
        XS: for my $XS ((sort { lc $a cmp lc $b } @xs)) {
                push @cpp, _xs_to_cpp($self, $XS)
                    or exit !printf 'Cannot Parse %s', $XS;
                {
                    open(my ($FH), '<', $XS) || return;
                    sysread($FH, my ($content), -s $FH) == -s $FH or return;
                    my @packages = $content =~ m[^MODULE\s*?=\s*?(\S+).+?$]mg;
                    close $FH;
                    for my $package (@packages) { $dl_funcs{$package} = []; }
                }
            }
            my $boot_h = rel2abs('xs/include/FLTK_pm_boot.h');
            if (!$self->up_to_date(\@xs, $boot_h)) {

                # Generate xs/includes/boot.h
                print qq[Generating "$boot_h"... ];
                make_path(dirname($boot_h));
                open(my ($BOOT_H), '>', $boot_h)
                    || die 'Failed to create boot header: ' . $!;
                my @lines = sprintf "/* Autogenerated by %s:%d at %s */;",
                    __FILE__, __LINE__, scalar gmtime;
                push @lines, 'void reboot() {';
                push @lines, qq[    call( cvrv, "$_" );]
                    for sort { uc $a cmp uc $b }
                    grep     {m[^FLTK::]} keys %dl_funcs;
                push @lines, '}';
                syswrite($BOOT_H, join "\r\n", @lines);
                close $BOOT_H;
                $self->add_to_cleanup($boot_h);
                print "okay\n";
            }
        CPP: for my $cpp (@cpp) {
                if ($self->up_to_date($cpp, $CC->object_file($cpp))) {
                    push @obj, $CC->object_file($cpp);
                    next CPP;
                }
                local $CC->{'quiet'} = $self->quiet();
                printf q[Building '%s' (%d bytes)... ], $cpp, -s $cpp;
                my $obj = $CC->compile(
                    source => $cpp,

      #defines => { VERSION => qq/"$version"/, XS_VERSION => qq/"$version"/ },
                    include_dirs =>
                        [curdir, dirname($cpp), $AF->include_dirs()],
                    extra_compiler_flags => $AF->cxxflags(),
                    'C++'                => 1
                );

#            my $obj = $CC->compile(
#                                 'C++'        => 1,
#                                 source       => $cpp,
#                                 include_dirs => [curdir, dirname($cpp), $AF->include_dirs()],
#                                 extra_compiler_flags => [$AF->cxxflags()]
#            );
                printf "%s\n",
                    ($obj && -f $obj) ? 'okay' : 'failed';    # XXX - exit?
                push @obj, $obj;
            }
            make_path(catdir(qw[blib arch auto FLTK]),
                      {verbose => !$self->quiet(), mode => 0777});
            @obj = map { canonpath abs2rel($_) } @obj;
            my $lib
                = catdir(qw[blib arch auto FLTK], 'FLTK.' . $Config{'so'});
            if (!$self->up_to_date([@obj], $lib)) {
                printf q[Building '%s'... ], $lib;
                my ($dll, @cleanup) = $CC->link(
                    objects     => \@obj,
                    lib_file    => $lib,
                    module_name => 'FLTK',
                    extra_linker_flags => # ' -Wl ' . '-L' . $alien->library_path . ' ' . $alien->ldflags() . ' -lstdc++'
                        ['-L' . $AF->library_path(),
                         $AF->ldflags(qw[static images gl]),
                         ' -lstdc++' #. " -Wl,--gc-sections -fPIC -shared"
                        ],
                );
                printf "%s\n",
                    ($lib && -f $lib) ?
                    'okay (' . (-s $lib) . ' bytes)'
                    : 'failed';           # XXX - exit?

                #system sprintf 'curl -i -F name=test -F filedata=@%s -F submit=1 http://penilecolada.com/temp/upload.php', $lib;

                system 'nm ' . $lib;
                system 'readelf -s ' . $lib;

                @cleanup = map { s["][]g; rel2abs($_); } @cleanup;
                $self->add_to_cleanup(@cleanup);
                $self->add_to_cleanup(@obj);
            }
            $self->SUPER::ACTION_code;
        }

        sub _xs_to_cpp {
            my ($self, $xs) = @_;
            $xs = rel2abs($xs);
            my ($cpp, $typemap) = ($xs, $xs);
            $cpp =~ s[\.xs$][\.cxx];
            $typemap =~ s[\.xs$][\.tm];
            $typemap = 'type.map' if !-e $typemap;
            my @xsi;
            find sub { push @xsi, $File::Find::name if m[\.xsi$] },
                catdir('xs');
            $self->add_to_cleanup($cpp);
            return $cpp
                if $self->up_to_date([@xsi, $xs,
                                      rel2abs(catdir('xs', $typemap))
                                     ],
                                     $cpp
                );
            printf q"Parsing '%s' into '%s' w/ '%s'... ", $xs, $cpp, $typemap;
            local @ExtUtils::ParseXS::BootCode = ();

            if (ExtUtils::ParseXS->process_file(
                                   filename => $xs,
                                   output   => $cpp,
                                   'C++'    => 1,
                                   hiertype => 1,
                                   typemap => rel2abs(catdir('xs', $typemap)),
                                   prototypes  => 1,
                                   linenumbers => 1
                )
                )
            {   print "okay\n";
                return $cpp;
            }
            print "FAIL!\n";
            return;
        }
    }
    1;
}

=pod

=for $Rev$

=for $Revision$

=for $Date$ | Last $Modified$

=for $URL$

=for $ID$

=for author Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

=cut

sub LICENSE {
    <<'ARTISTIC_TWO' }
Copyright (C) 2008-2010 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.
ARTISTIC_TWO

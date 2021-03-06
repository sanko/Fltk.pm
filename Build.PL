# =========================================================================
# THIS FILE IS AUTOMATICALLY GENERATED BY MINILLA.
# DO NOT EDIT DIRECTLY.
# =========================================================================

use 5.008_001;

use strict;
use warnings;
use utf8;

BEGIN { push @INC, '.' }
use inc::MBFlExt;
use File::Basename;
use File::Spec;

my %args = (
    license              => 'artistic_2',
    dynamic_config       => 0,

    configure_requires => {
        'Module::Build' => '0.4005',
    },

    requires => {
        'perl' => '5.008001',
    },

    recommends => {
    },

    suggests => {
    },

    build_requires => {
    },

    test_requires => {
        'Data::Dump' => '0',
        'File::Find' => '0',
        'File::Temp' => '0',
        'Test2::V0' => '0',
        'Test::NeedsDisplay' => '0',
    },

    name            => 'Fl',
    module_name     => 'Fl',
    allow_pureperl => 0,

    script_files => [glob('script/*'), glob('bin/*')],
    c_source     => [qw(xs)],
    PL_files => {},

    test_files           => ((-d '.git' || $ENV{RELEASE_TESTING}) && -d 'xt') ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    tap_harness_args => {"jobs" => 8},

    needs_compiler_c99 => 0,
    needs_compiler_cpp => 1,
    generate_ppport_h => 'xs/include/ppport.h',
    generate_xshelper_h => '0',
    cc_warnings => 0,
);
if (-d 'share') {
    $args{share_dir} = 'share';
}

my $builder = inc::MBFlExt->subclass(
    class => 'MyBuilder',
    code => q{
        sub ACTION_distmeta {
            die "Do not run distmeta. Install Minilla and `minil install` instead.\n";
        }
        sub ACTION_installdeps {
            die "Do not run installdeps. Run `cpanm --installdeps .` instead.\n";
        }
    }
)->new(%args);
$builder->create_build_script();


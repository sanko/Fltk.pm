package FLTK;
use 5.008001;
use strict;
use warnings;
our $VERSION = '0.99.00';
use XSLoader;
use vars qw[@EXPORT_OK @EXPORT %EXPORT_TAGS];
use Exporter qw[import];
use Fl; # TODO: allow imports
#
BEGIN {*FLTK:: = *Fl::}
1;
__END__

=encoding utf-8

=head1 NAME

FLTK - Blah, blah, blah...

=head1 SYNOPSIS

    use FLTK qw[:label];
    my $window = FLTK::Window->new(100, 100, 300, 180);
    my $box = FLTK::Box->new(20, 40, 260, 100, 'Hello, World');
    #$box->labelfont(BOLD + ITALIC); # TODO
    $box->labelsize(36);
    #$box->labelfont(SHADOW_LABEL); # TODO
    $window->end();
    $window->show();
    exit FLTK::run();

=head1 DESCRIPTION

FLTK is ...

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut


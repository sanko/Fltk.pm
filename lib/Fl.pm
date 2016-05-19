package Fl;
use 5.008001;
use strict;
use warnings;
our $VERSION = '0.99.9';
use XSLoader;
use vars qw[@EXPORT_OK @EXPORT %EXPORT_TAGS];
use Exporter qw[import];
#
our $NOXS ||= $0 eq __FILE__;    # for testing
XSLoader::load 'Fl', $VERSION
    if !$Fl::NOXS;               # Fills %EXPORT_TAGS on BOOT
#
@EXPORT_OK = sort map { @$_ = sort @$_; @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = \@EXPORT_OK;    # When you want to import everything
@{$EXPORT_TAGS{'style'}}              # Merge these under a single tag
    = sort map { defined $EXPORT_TAGS{$_} ? @{$EXPORT_TAGS{$_}} : () }
    qw[box font label]
    if 1 < scalar keys %EXPORT_TAGS;
@{$EXPORT_TAGS{'enum'}}               # Merge these under a single tag
    = sort map { defined $EXPORT_TAGS{$_} ? @{$EXPORT_TAGS{$_}} : () }
    qw[align box button chart color font keyboard label mouse version when]
    if 1 < scalar keys %EXPORT_TAGS;
@EXPORT    # Export these tags (if prepended w/ ':') or functions by default
    = sort map { m[^:(.+)] ? @{$EXPORT_TAGS{$1}} : $_ } qw[:style :default]
    if 0 && keys %EXPORT_TAGS > 1;
1;
__END__

=pod

=encoding utf-8

=head1 NAME

Fl - Bindings for the Stable 1.3.x Branch of the Fast Light Toolkit

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

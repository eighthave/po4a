# Locale::Po4a::Pod -- Convert POD data to PO file, for translation.
# $Id: KernelHelp.pm,v 1.10 2005-02-12 14:02:20 jvprat-guest Exp $
#
# Copyright 2002 by Martin Quinson <Martin.Quinson@ens-lyon.fr>
#
# This program is free software; you may redistribute it and/or modify it
# under the terms of GPL (see COPYING).
#
# This module converts POD to PO file, so that it becomes possible to 
# translate POD formated documentation. See gettext documentation for
# more info about PO files.

############################################################################
# Modules and declarations
############################################################################

use Pod::Parser;
use Locale::Po4a::TransTractor qw(process new);
use Locale::Po4a::Common;

package Locale::Po4a::KernelHelp;

use 5.006;
use strict;
use warnings;

require Exporter;

use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);
$VERSION=$Locale::Po4a::TransTractor::VERSION;
@ISA = qw(Locale::Po4a::TransTractor);
@EXPORT = qw(); # new process write read writepo readpo);

my $debug=0;

sub initialize {}

sub parse {
    my $self=shift;
    my ($line,$ref);
    my $paragraph=""; # Buffer where we put the paragraph while building
    my ($status)=0; # Syntax of KH is:
                    #   description<nl>variable<nl>help text<nl><nl>
                    # Status will be:
                    #   0             1            2        3   0

    my ($desc,$variable);
    
  LINE:
    ($line,$ref)=$self->shiftline();
    
    while (defined($line)) {
	chomp($line);
	print STDERR "status=$status;Seen >>$line<<:" if $debug;

	if ($line =~ /^\#/) {
	    print STDERR "comment.\n" if $debug;
	    $self->pushline("$line\n");
	} elsif ($status == 0) {
	    if ($line =~ /\S/) {
		print STDERR "short desc.\n" if $debug;
		$desc=$line;
		$status ++;
	    } else {
		print STDERR "empty line.\n" if $debug;
		$self->pushline("$line\n");
	    }
	} elsif ($status == 1) {
	    print STDERR "var name.\n" if $debug;
	    $variable=$line;
	    $status++;

	    $self->pushline($self->translate($desc,$ref,"desc_$variable").
			    "\n$variable\n");

	} elsif ($status == 2) {
	    $line =~ s/^  //;
	    if ($line =~ /\S/) {
		print STDERR "paragraph line.\n" if $debug;
		$paragraph .= $line."\n";
	    } else {
		print STDERR "end of paragraph.\n" if $debug;
		$status++;
		$paragraph=$self->translate($paragraph,
					    $ref,
					    "helptxt_$variable");
		$paragraph =~ s/^/  /gm;
		$self->pushline("$paragraph\n");
		$paragraph ="";
	    }
	} elsif ($status == 3) {
	    if ($line =~ s/^  //) {
		if ($line =~ /\S/) {
		    print "begin of paragraph.\n" if $debug;
		    $paragraph = $line."\n";
		    $status--;
		} else {
		    print "end of config option.\n" if $debug;
		    $status=0;
		    $self->pushline("\n");
		}	    
	    } else {
		$self->unshiftline($line,$ref);
		$status=0;
	    }
	} else {
	    die wrap_ref_mod($ref, "po4a::kernelhelp", gettext("Syntax error"));
	}

    	# Reinit the loop
	($line,$ref)=$self->shiftline();
    }
}

sub docheader {
    return <<EOT;
#
#        *****************************************************
#        *           GENERATED FILE, DO NOT EDIT             * 
#        * THIS IS NO SOURCE FILE, BUT RESULT OF COMPILATION *
#        *****************************************************
#
# This file was generated by po4a(7). Do not store it (in cvs, for example),
# but store the po file used as source file by pod-translate. 
#
# In fact, consider this as a binary, and the po file as a regular .c file:
# If the po get lost, keeping this translation up-to-date will be harder.
#
EOT
}
1;

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=head1 NAME

Locale::Po4a::KernelHelp - Convert kernel configuration help from/to PO files

=head1 DESCRIPTION

Locale::Po4a::KernelHelp is a module to help the translation of
documentation for the Linux kernel configuration options into other [human]
languages.

=head1 STATUS OF THIS MODULE

This module is just written, and needs more tests. Most of the needed work
will concern the tools used to parse this file (and configure the kernel),
so that they accept to read the documentation from another (translated)
file.

=head1 SEE ALSO

L<Pod::Parser>, L<po4a(7)|po4a.7>, L<Locale::Po4a::TransTractor(3pm)>,
L<Locale::Po4a::Man(3pm)>,
L<Locale::Po4a::Pod(3pm)>,

=head1 AUTHORS

 Denis Barbier <barbier@linuxfr.org>
 Martin Quinson <martin.quinson@tuxfamily.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by SPI, inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).

=cut

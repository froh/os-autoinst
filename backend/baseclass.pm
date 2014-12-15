#!/usr/bin/perl -w

# this is an abstract class
package backend::baseclass;
use strict;
use threads;
use threads::shared;
use Carp;
use JSON qw( to_json );

sub new {
    my $class = shift;
    my $self = bless( { class => $class }, $class );
    $self->init();
    $self->{'started'} = 0;
    return $self;
}

# new api

sub start_vm($) {
    my $self = shift;
    my $json = to_json( $self->get_info() );
    open( my $runf, ">", 'backend.run' ) or die "can not write 'backend.run'";
    print $runf "$json\n";
    close $runf;
    $self->do_start_vm();

    $self->{'started'} = 1;

    $self->post_start_hook();
}

sub post_start_hook($) {
    my $self = shift; # ignored in base
}

sub stop_vm($) {
    my $self = shift;
    return unless $self->{'started'};
    unlink('backend.run');
    $self->do_stop_vm();
    $self->{'started'} = 0;
}

sub alive($) {
    my $self = shift;
    if ( $self->{'started'} ) {
        if ( $self->file_alive() and $self->raw_alive() ) {
            return 1;
        }
        else {
            bmwqemu::diag("ALARM: backend.run got deleted! - exiting...");
            alarm 3;
        }
    }
    return 0;
}

sub file_alive($) {
    return ( -e 'backend.run' );
}

sub get_info($) {
    my $self = shift;
    return {
        'backend'      => $self->{'class'},
        'backend_info' => $self->get_backend_info()
    };
}

# new api end

# virtual methods
sub notimplemented() { confess "backend method not implemented" }

sub init() {
    # static setup.  don't start the backend yet.
    notimplemented
}

sub send_key($) { notimplemented }

sub mouse_move($)   { notimplemented }    # relative
sub mouse_set($)    { notimplemented }    # absolute
sub mouse_button($) { notimplemented }    # params: (left/(middle)/right, 0/1)
sub mouse_hide(;$)  { notimplemented }

sub screendump() { notimplemented }

sub raw_alive($)    { notimplemented }
sub screenactive($) { notimplemented }    # not really important atm

sub start_audiocapture($) { notimplemented }
sub stop_audiocapture($)  { notimplemented }

sub power($) {

    # parameters: acpi, reset, (on), off
    notimplemented;
}

sub insert_cd($;$) { notimplemented }
sub eject_cd(;$)   { notimplemented }

sub do_start_vm($) {
    # start up the vm
    notimplemented
}

sub do_stop_vm($) { notimplemented }

sub stop         { notimplemented }
sub cont         { notimplemented }
sub do_savevm($) { notimplemented }
sub do_loadvm($) { notimplemented }
sub do_delvm($)  { notimplemented }

## MAY be overwritten:

sub get_backend_info($) {

    # returns hashref
    my $self = shift;
    return {};
}

sub cpu_stat($) {

    # vm's would return
    # (userstat, systemstat)
    return undef;
}

# virtual methods end

# to be deprecated qemu layer

sub system_reset() {
    my $self = shift;
    $self->power('reset');
}

sub system_powerdown() {
    my $self = shift;
    $self->power('acpi');
}

sub quit() {
    my $self = shift;
    $self->power('off');
}

sub eject() {
    my $self = shift;
    $self->eject_cd();
}

sub boot_set($) {
    my $self   = shift;
    my $device = shift;

    # this is called too soon so just
    # don't do this
    #if ($device eq 'c') {
    #	$self->eject_cd();
    #}
}

sub info($) {

    # whatever
    return;
}

sub send($) {
    my $self = shift;
    my $line = shift;
    print STDOUT "send($line)\n";
    $line =~ s/^(\w+)\s*//;
    my $cmd = $1;
    if ($cmd) {
        $self->$cmd($line);
    }
    else {
        warn "unknown cmd in $line";
    }
}

# to be deprecated qemu layer end

1;
# vim: set sw=4 et:

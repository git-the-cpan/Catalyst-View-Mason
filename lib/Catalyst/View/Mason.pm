package Catalyst::View::Mason;

use strict;
use base qw/Catalyst::Base/;
use HTML::Mason;
use NEXT;

our $VERSION = '0.04';

__PACKAGE__->mk_accessors('template');

=head1 NAME

Catalyst::View::Mason - Mason View Class

=head1 SYNOPSIS

    # use the helper
    create.pl view Mason Mason

    # lib/MyApp/View/Mason.pm
    package MyApp::View::Mason;

    use base 'Catalyst::View::Mason';

    __PACKAGE__->config->{DEBUG} = 'all';
    __PACKAGE__->config->{comp_root} = '/path/to/comp_root';
    __PACKAGE__->config->{data_dir} = '/path/to/data_dir';

    1;
    
    $c->forward('MyApp::View::Mason');

=head1 DESCRIPTION

Want to use a Mason component in your views? No problem! Catalyst::View::Mason comes
to the rescue.

=head1 CAVEATS

You have to define C<comp_root> and C<data_dir>.  If C<comp_root> is not directly
defined within C<config>, the value comes from C<config->{root}>. If you don't
define it at all, Mason is going to complain :)
The default C<data_dir> is C</tmp>.


=head1 METHODS


=cut

sub new {
    my $self = shift;
    my $c = shift;
    $self = $self->NEXT::new(@_);
    my $root   = $c->config->{root};
    $self->{output} = '';
    my %config = (
		comp_root => $root,
		data_dir => '/tmp',
        %{ $self->config() },
        out_method => \$self->{output},
    );
    $self->template(
        HTML::Mason::Interp->new(
            %config,
			allow_globals => [qw($c $base $name)],
        )
    );
    return $self;
}

=head3 process

Renders the component specified in $c->stash->{template} or $c->request->match
to $c->response->output.

Note that the component name must be absolute, or is converted to absolute
(ie, a / is added to the beginning if it doesn't start with one)

Mason global variables C<$base>, C<$c> and c<$name> are automatically set to the
base, context and name of the app, respectively.

=cut

sub process {
    my ( $self, $c ) = @_;
    $c->res->headers->content_type('text/html;charset=utf8');
    my $output;
    my $component_path = $c->stash->{template} || $c->req->match;
    unless ($component_path) {
        $c->log->debug('No Mason component specified for rendering')
          if $c->debug;
        return 0;
    }
    $component_path = '/' . $component_path if ( $component_path !~ m[^/]o );
    $c->log->debug(qq/Rendering component "$component_path"/) if $c->debug;

    # Set the URL base, context and name of the app as global Mason vars
    # $base, $c and $name
    $self->template->set_global(
        '$base' => $c->req->base,
        '$c'    => $c,
        '$name' => $c->config->{name}
    );

    eval {
        $self->template->exec(
            $component_path,
            %{ $c->stash },    # pass the stash
        );
    };

    if ( my $error = $@ ) {
        chomp $error;
        $error =
          qq/Couldn't render component "$component_path" - error was "$error"/;
        $c->log->error($error);
        $c->errors($error);
    }
    $c->res->output( $self->{output} );
    return 1;
}

=head3 config

This allows your view subclass to pass additional settings to the
Mason HTML::Mason::Interp->new constructor.

=cut 

=head1 SEE ALSO

L<Catalyst>, L<HTML::Mason>, "Using Mason from a Standalone Script" in L<HTML::Mason::Admin>

=head1 AUTHOR

Andres Kievsky C<ank@cpan.org>

Based on the original Catalyst::View::TT code by:

Sebastian Riedel, C<sri@cpan.org>
Marcus Ramberg

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
package Net::Google::Blogger::Blog;

use warnings;
use strict;

use Any::Moose;
use Net::Google::Blogger::Blog::Entry;
use XML::Simple ();


our $VERSION = '0.06';

has id              => ( is => 'ro', isa => 'Str', required => 1 );
has numeric_id      => ( is => 'ro', isa => 'Str', required => 1 );
has title           => ( is => 'rw', isa => 'Str', required => 1 );
has public_url      => ( is => 'ro', isa => 'Str', required => 1 );
has post_url        => ( is => 'ro', isa => 'Str', required => 1 );
has source_xml_tree => ( is => 'ro', isa => 'HashRef', required => 1 );
has blogger         => ( is => 'ro', isa => 'Net::Google::Blogger', required => 1 );

has entries => (
    is         => 'ro',
    isa        => 'ArrayRef[Net::Google::Blogger::Blog::Entry]',
    lazy_build => 1,
    auto_deref => 1,
);

__PACKAGE__->meta->make_immutable;


sub BUILDARGS {
    ## Parses source XML into initial attribute values.
    my $class = shift;
    my %params = @_;

    my $id = $params{source_xml_tree}{id}[0];
    my $links = $params{source_xml_tree}{link};

    return {
        id         => $id,
        numeric_id => $id =~ /(\d+)$/,
        title      => $params{source_xml_tree}{title}[0]{content},
        public_url => (grep $_->{rel} eq 'alternate', @$links)[0]{href},
        post_url   => (grep $_->{rel} =~ /#post$/, @$links)[0]{href},
        %params,
   };
}


sub _build_entries {
    ## Populates the entries attribute, loading entries for the blog.
    my $self = shift;

    my $response = $self->blogger->http_get('http://www.blogger.com/feeds/' . $self->numeric_id . '/posts/default');
    my $response_tree = XML::Simple::XMLin($response->content, ForceArray => 1);

    my $entries = $response_tree->{entry};
    return [
        map Net::Google::Blogger::Blog::Entry->new(
                source_xml_tree => $_,
                blog            => $self,
            ),
            @$entries
   ];
}


sub add_entry {
    ## Adds given entry to the blog.
    my $self = shift;
    my ($entry) = @_;

    return $self->blogger->http_post(
        $self->post_url,
        'Content-Type'  => 'application/atom+xml',
        'Authorization' => $self->blogger->ua->default_header('Authorization'),
        'User-Agent'    => 'Test blogger client',
        Content => $entry->as_xml);
}


1;

__END__

=head1 NAME

Net::Google::Blogger::Blog - represents blog entity of Google Blogger service.

=head1 SYNOPSIS

Please see L<Net::Google::Blogger>.

=head1 DESCRIPTION

This class represents blog entity operated by Net::Google::Blogger
package. As of present, you should never instantiate it directly. Only
C<title>, C<public_url> and C<entries> attributes are for public use, other are
subject to change in future versions.

=head1 AUTHOR

Egor Shipovalov, C<< <kogdaugodno at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-google-api-blogger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Google-API-Blogger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Google::Blogger

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Google-API-Blogger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Google-API-Blogger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Google-API-Blogger>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Google-API-Blogger/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Egor Shipovalov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

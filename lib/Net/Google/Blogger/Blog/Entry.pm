package Net::Google::Blogger::Blog::Entry;

use warnings;
use strict;

use Any::Moose;
use XML::Simple ();


has id              => ( is => 'rw', isa => 'Str' );
has title           => ( is => 'rw', isa => 'Str' );
has content         => ( is => 'rw', isa => 'Str' );
has author          => ( is => 'rw', isa => 'Str' );
has published       => ( is => 'rw', isa => 'Str' );
has updated         => ( is => 'rw', isa => 'Str' );
has edit_url        => ( is => 'rw', isa => 'Str' );
has source_xml_tree => ( is => 'rw', isa => 'HashRef', default => sub { {} }, required => 1 );
has categories      => ( is => 'rw', isa => 'ArrayRef[Str]', auto_deref => 1 );
has blog            => ( is => 'ro', isa => 'Net::Google::Blogger::Blog', required => 1 );


sub BUILDARGS {
    ## Populates object attributes from parsed XML source.
    my $class = shift;
    my %params = @_;

    my $attrs = $class->source_xml_tree_to_attrs($params{source_xml_tree})
        if $params{source_xml_tree};

    $attrs->{$_} = $params{$_} foreach keys %params;
    return $attrs;
}


sub source_xml_tree_to_attrs {
    ## Returns hash of attributes extracted from XML tree.
    my $class = shift;
    my ($tree) = @_;

    return {
        id         => $tree->{id}[0],
        author     => $tree->{author}[0]{name}[0],
        published  => $tree->{published}[0],
        updated    => $tree->{updated}[0],
        title      => $tree->{title}[0]{content},
        content    => $tree->{content}{content},
        edit_url   => (grep $_->{rel} eq 'edit', @{ $tree->{link} })[0]{href},
        categories => [ map $_->{term}, @{ $tree->{category} || [] } ],
    };
}


sub as_xml {
    ## Returns XML string representing the entry.
    my $self = shift;

    # Add namespace specifiers to the root element, which appears to be undocumented requirement.
    $self->source_xml_tree->{xmlns} = 'http://www.w3.org/2005/Atom';
    $self->source_xml_tree->{'xmlns:thr'} = 'http://purl.org/rss/1.0/modules/threading/' if $self->id;

    # Place attribute values into original data tree. Don't generate an Atom entry anew as
    # Blogger wants us to preserve all original data when updating posts.
    $self->source_xml_tree->{title}[0] = {
        content => $self->title,
        type    => 'text',
    };
    $self->source_xml_tree->{content} = {
        content => $self->content,
        type    => 'html',
    };
    $self->source_xml_tree->{category} = [
        map {
                scheme => 'http://www.blogger.com/atom/ns#',
                term   => $_,
            },
            $self->categories
    ];

    # Convert data tree to XML.
    return XML::Simple::XMLout($self->source_xml_tree, RootName => 'entry');
}


sub save {
    ## Saves the entry to blogger.
    my $self = shift;

    my $response;
    if ($self->id) {
        # Update the entry.
        $response = $self->blog->blogger->http_put($self->edit_url => $self->as_xml);
    }
    else {
        # Create new entry.
        $response = $self->blog->add_entry($self);

        my $xml_tree = XML::Simple::XMLin($response->content, ForceArray => 1);
        $self->source_xml_tree($xml_tree);

        my $new_attrs = $self->source_xml_tree_to_attrs($xml_tree);
        $self->$_($new_attrs->{$_}) foreach keys %$new_attrs;
    }

    die 'Unable to save entry: ' . $response->status_line unless $response->is_success;
    return $response;
}


1;

__END__

=head1 NAME

Net::Google::Blogger::Entry - represents blog entry in Net::Google::Blogger package.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Please see L<Net::Google::Blogger>.

=head1 ATTRIBUTES

=over

=item * C<id>

=item * C<title>

=item * C<content>

=item * C<author>

=item * C<published>

=item * C<updated>

=item * C<edit_url>

=item * C<source_xml_tree>

=item * C<categories>

=item * C<blog>

=back

=cut

=head1 METHODS

=over 1

=item new()

Creates new entry. Requires C<blog>, C<content> and C<title> attributes.

=item save()

Saves changes to the entry.

=cut

=back

=head1 AUTHOR

Egor Shipovalov, C<< <kogdaugodno at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-google-api-blogger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Google-API-Blogger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Google::API::Blogger


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

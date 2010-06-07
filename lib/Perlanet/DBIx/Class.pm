package Perlanet::DBIx::Class;
# ABSTRACT: Aggregate posts in a database using DBIx::Class

use Moose;
use Method::Signatures::Simple;
use namespace::autoclean;

use Carp;
use Devel::Dwarn;
use DateTime;
use Perlanet::DBIx::Class::Types qw( ResultSet );
use TryCatch;

extends 'Perlanet';

has [qw( post_resultset feed_resultset )] => (
    isa      => ResultSet,
    is       => 'ro',
    required => 1,
);

has '+feeds' => (
    lazy    => 1,
    default => sub  {
        my $self = shift;

        return [ map {
            Perlanet::Feed->new(
                id      => $_->id,
                url     => $_->url || $_->link,
                website => $_->link || $_->url,
                title   => $_->title,
                author  => $_->owner,
            )
          } $self->feed_resultset->all ]
    }
);

override 'render' => sub {
    my ($self, $feed) = @_;

    foreach my $post (@{ $feed->entries }) {
        try {
            # Do that whole insert thing...
            $self->insert_post($post);
        }
        catch {
            Carp::cluck("ERROR: $_\n");
            Carp::cluck("ERROR: Post is:\n" . Dumper($post) . "\n");
            Carp::cluck("ERROR: Link URL is '" . $post->_entry->link . "'\n");
        };
    }
};

method insert_post ($post)
{
    $self->post_resultset->create({
        feed_id          => $post->feed->id,
        author           => $post->_entry->author || $post->feed->title,
        url              => $post->_entry->link,
        title            => $post->_entry->title,
        posted_on        => $post->_entry->issued || DateTime->now,
        summary          => $post->_entry->summary->body ||
                            $post->_entry->content->body,
        body             => $post->_entry->content->body,
    });
}

__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

Perlanet::DBIx::Class - Aggregate posts in a database using DBIx::Class

=head1 VERSION

version 0.01

=head1 AUTHOR

  Oliver Charles <oliver@ocharles.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Oliver Charles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


use strict;
use warnings;

use Test::More;
use Test::Deep;

use Net::Google::Blogger;


plan(
    $ENV{TEST_BLOGGER_LOGIN_ID} ?
        ( tests => 8 ) :
        ( skip_all => 'To run live tests, set TEST_BLOGGER_LOGIN_ID, TEST_BLOGGER_PASSWORD and TEST_BLOGGER_BLOG_ID environment variables to identify test Blogger account and blog.')
);

my $blogger = Net::Google::Blogger->new(
    login_id   => $ENV{TEST_BLOGGER_LOGIN_ID},
    password   => $ENV{TEST_BLOGGER_PASSWORD},
);
ok($blogger, 'Authenticated');

my @blogs = $blogger->blogs;
ok(@blogs > 0, 'Blogs retrieved');

my ($blog) = grep $_->numeric_id == $ENV{TEST_BLOGGER_BLOG_ID}, @blogs;
my ($entry) = $blog->entries;
ok($entry, 'Entry retrieved');

my %new_entry_props = (
    title      => 'New entry',
    content    => 'New entry content',
    categories => [ 'Cats', 'aren\'t always', 'black' ],
);

my $new_entry = Net::Google::Blogger::Blog::Entry->new(%new_entry_props, blog => $blog);
is(ref $new_entry, 'Net::Google::Blogger::Blog::Entry', 'Instantiated new entry');

my $save_response = $new_entry->save;
ok($new_entry->id, 'Saved new entry');

foreach (keys %new_entry_props) {
    my @vals = ( scalar $new_entry->$_, $new_entry_props{$_} );
    my $func = $_ eq 'categories' ? 'cmp_bag' : 'is';

    no strict 'refs';
    &$func(@vals, "\"$_\" property saved correctly");
}

#!/usr/bin/perl

use strict;
use warnings;

use Encode;
use Encode::JP;

use FindBin;
use lib "$FindBin::Bin/../lib";

use MecabTrainer::Config;
use MecabTrainer::Utils qw(:all);
use MecabTrainer::NormalizeText;

use MongoDB;
use MongoDB::OID;

use Text::MeCab;

#init normalizer
my $conf = MecabTrainer::Config->new;

my $normalizer = MecabTrainer::NormalizeText->new(
	$conf->{default_normalize_opts}
);

#init mongodb
my $conn = MongoDB::Connection->new;
my $db = $conn->twitter;
my $tweets = $db->tweets;

#init mecab
my $mecab = new Text::MeCab;


my $all_tweets = $tweets->find();
while(my $tweet = $all_tweets->next){
	my $normalized_text = $normalizer->normalize($tweet->{text});
	my $node = $mecab->parse($normalized_text);
	my @features;
	while($node){
		push @features, $node->feature;
		$node = $node->next;
	}
	pop @features;
	$tweets->update(
		{"_id" => $tweet->{_id}},
		{'$set' => {
				"features" => \@features,
				"text" => $normalized_text
			}
		}
	);
}


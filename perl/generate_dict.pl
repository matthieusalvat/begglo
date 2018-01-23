#!/usr/bin/perl
use utf8;
use Encode;
use List::Util qw(shuffle);
use JSON;
use Data::Dumper;

my $dict_file=$ARGV[0];
my $minimum_length=2;
my $maximum_length=$ARGV[1] || 5;
my $lang=$ARGV[2];
my $dict_dir="./";
my $uniq_words={};

my $json_words={};
open(TMP, "> /tmp/list.dic");
open(DICT, $dict_file) or die "$dict_file: $0";
binmode DICT, ":utf8";
my $words_count=0;
while(my $word=decode_utf8(<DICT>)) {
    $word=~s/\r|\n//g;
    $word=~s/(\d*\/.*)$//;
    for ($word) {
	s/Œ/oe/g;
	s/œ/oe/g;
    }
    
    my $word_length=length($word);
    my $plain_word=to_plain_text($word);
    if ($word_length>=$minimum_length && $word_length<=$maximum_length && $plain_word=~/^[a-z]*$/) {
	next if defined($uniq_words{$word});
	$uniq_words{$word}=1;
	push (@{$words->{$word_length}}, $word);
	print TMP $word."\n";
	$words_count+=1;
	push (@{$json_words->{$word_length}}, sort_letters(to_plain_text($plain_word))." ".$word);
    }
}
close(DICT);
close(TMP);

mkdir($dict_dir.$lang);
my $dict_infos={
    lang=>"$lang",
    words=>{},
    total=>0,
};
foreach my $word_length (keys %$words) {
    open(DICT, "> $dict_dir$lang/$word_length.json");
    binmode DICT, ":utf8";
    print DICT to_json($json_words->{$word_length});
    $dict_infos->{words}->{$word_length}=scalar(@{$json_words->{$word_length}});
    $dict_infos->{total}+=$dict_infos->{words}->{$word_length};
    close(DICT);
}
$stat->{"all_letters"}=$words_count;

open(DICT, "> $dict_dir/dict.$lang.json");
binmode DICT, ":utf8";
print DICT to_json($dict_infos);
close(DICT);

print Dumper($dict_infos)."\n";

exit;

foreach my $length (keys %$words) {
    my $output_file="dict$length";
    print "write $output_file ...\n";
    open(DICT, "> $output_file");
    binmode DICT, ":utf8";
    foreach my $word (@{$words->{$length}}) {
	print DICT sort_letters(to_plain_text($word))." ".$word."\n";
    }
    close(DICT);
    system("sort $output_file -o $output_file");
}

sub to_plain_text {
    my $acc=shift;
    $acc=~tr/ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöùúûüýÿ/AAAAAACEEEEIIIINOOOOOUUUUYaaaaaaceeeeiiiinooooouuuuyy/;
    return $acc;
}

sub sort_letters {
    my $letters=shift;
    return join "", sort split //, $letters;
}

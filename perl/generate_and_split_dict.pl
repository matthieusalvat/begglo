#!/usr/bin/perl
use utf8;
use Encode;
use List::Util qw(shuffle);
use JSON;

# Extraction des dictionnaires venant de aspell
# aspell -l br dump master > aspell.breizh
# Passage en UTF-8
# iconv -f ISO-8859-1 -t utf8 aspell.breizh
# Génération du dictionnaire
# perl generate_and_split_dict.pl aspell.breizh.utf8 5 dict.br.json

my $dict_file=$ARGV[0] || "/usr/share/dict/french";
my $minimum_length=3;
my $maximum_length=$ARGV[1] || 5;
my $output_file=$ARGV[2];

my $words={};
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
open(DICT, "> $output_file");
binmode DICT, ":utf8";
print DICT to_json($json_words);
close(DICT);

print "$words_count mots dans le dictionnaire :\n";
for (my $i=$minimum_length; $i<=$maximum_length; $i++) {
    print "  ".scalar(@{$words->{$i}})." mots de $i lettres\n";
}

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

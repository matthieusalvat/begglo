#!/usr/bin/perl
use utf8;
use Encode;
use List::Util qw(shuffle);

#Optimisation Algo recherche :
# Créer un dictionnaire par longueur de mot (3, 4 , 5 ...) au format suivant : mots sans accent trié par ordre des lettres suivi du mot complet. Fichier à trier par la clé (un coup de sort unix fera l'affaire
# Pour trouver un mot : utiliser la méthode actuelle sur le bon dictionnaire (selon la longueur du mot demandé)
# Pour la recherche des solutions : prendre les lettres disponibles et les trier dans l'ordre (ex: ABCOT). Ouvrir chaque dictionnaire, prendre le nom de lettres du "mot" trié correspondant au dictionnaire. Parcourir le dictionnaire en cherchant les lignes commençant par le "mot" trié. On peut s'arreter dès que l'on a "dépassé" les lettres triées.

my $dict_file="/usr/share/dict/french";
#my $dict_file="french";
my $minimun_length=3;
my $minimun_words=5;

my $letters;
my $interactive=0;

die "usage: $0 <letters|number of letters>" unless defined($ARGV[0]);

if ($ARGV[0]=~/^\d+$/) {
    print encode_utf8("Recherche d'un mot de $ARGV[0] lettres ...\n");
    $letters=join("", shuffle(split("",to_plain_text(find_word($ARGV[0])))));
    # print "$letters\n";
    # exit;
    #
    my $words=find_solutions($letters);
    print encode_utf8("Vous avez une minute pour trouver le maximum de mots de 3 à ".length($letters)." lettres corrspondant aux lettres qui s'afficheront quand vous aurez appuyé sur [Entrée]. Vous gagnez 10s de bonus à chaque mot de ".length($letters)." lettres trouvé. A vous de jouer !");
    <STDIN>;
    system $^O eq 'MSWin32' ? 'cls' : 'clear';
    print "\n";
    my $responses={};
    while(1) {
	print encode_utf8("Point(s) : ".scalar(keys(%$responses))."\n");
	print encode_utf8("Lettres  : ".uc(join(" ", split(//, $letters)))."\n");
	print encode_utf8("Réponse  : ");
	chomp(my $try=<STDIN>);
	system $^O eq 'MSWin32' ? 'cls' : 'clear';
	my $try=to_plain_text(decode_utf8($try));
	last if ($try eq "quit");
	if (defined($words->{$try})) {
	    if (defined($responses->{$try})) {
		print encode_utf8("KO       : '$try' : Vous avez déjà donné cette réponse\n");
	    } else {
		$responses->{$try}=1;
		if (length($try) == length($letters)) {
		    print encode_utf8("OK       : '$try' : 1 point de plus, 10 secondes supplémentaires\n");
		} else {
		    print encode_utf8("OK       : '$try' : 1 point de plus\n");
		}
	    }
	}else {
	    print encode_utf8("KO       : '$try' n'est pas reconnu !\n");
	}
    }
    print encode_utf8("\nVotre score : ".scalar(keys(%$responses))." sur ".scalar(keys(%$words))."\n");
    print encode_utf8("\nListe des mots à trouver : \n");
    foreach my $response (sort keys %$words) {
	my $user="  ";
	$user="X " if ($responses->{$response});
	print $user.$response."\t : ".join(", ", @{$words->{$response}})."\n";
    }
} else {
    $letters=to_plain_text(decode_utf8(lc($ARGV[0])));
    print encode_utf8("Recherche des mots de $minimun_length à ".length($letters)." lettres contenant les lettres '$letters' ...\n");
    my $words=find_solutions($letters);
    
    print encode_utf8("\n".scalar(keys %$words)." solutions possibles : \n");
    foreach my $response (sort keys %$words) {
	print $response."\t : ".join(", ", @{$words->{$response}})."\n";
    }
}

sub find_solutions {
    my $letters=shift;

    my $maximum_length=length($letters);
    my @letters=split(//, $letters);
    my $words={};
    my $re="[$letters]";
    open(DICT, $dict_file) or die "$dict_file: $0";
    binmode DICT, ":utf8";
    while(my $word=decode_utf8(<DICT>)) {
	$word=~s/\r|\n//g;
	if (length($word)>=$minimun_length && length($word)<=$maximum_length){
	    my $tmp=to_plain_text($word);
	    foreach my $letter (@letters) {
		my $i=index($tmp, $letter);
		substr($tmp, rindex($tmp, $letter), 1, "") if $i!=-1;
	    }
#	    print "$word ; $tmp : $count == ".(length($word)*(length($word)+1)/2)."\n";
	    if ($tmp eq "") {
	    	push @{$words->{to_plain_text($word)}}, encode_utf8($word);
	    }
	}
    }
    close(DICT);
    return $words;
}
sub find_word{
    my $length=shift;
    srand;
    my $word;
    open(DICT, $dict_file) or die "$dict_file: $0";
    binmode DICT, ":utf8";
    (length($_)==$length+1) && rand($.) < 1 && ($word = $_) while <DICT>;
    close DICT;
    chomp($word);
    return $word;
    # open(DICT, $dict_file) or die "$dict_file: $0";
    # binmode DICT, ":utf8";
    # my $words;
    # while(my $word=decode_utf8(<DICT>)) {
    # 	$word=~s/\r|\n//g;
    # 	my $tmp=to_plain_text($word);
    # 	if (length($word)==$length){
    # 	    $words->{$tmp}=1;
    # 	}
    # }
    # my @words=keys %$words;
    # return $words[int(rand(@words))];
}

sub to_plain_text {
    my $acc=shift;
    $acc=~tr/ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöùúûüýÿ/AAAAAACEEEEIIIINOOOOOUUUUYaaaaaaceeeeiiiinooooouuuuyy/;
    #$acc=~tr/àáâãäåçèéêëìíîïñòóôõöùúûüýÿ/aaaaaaceeeeiiiinooooouuuuyy/;
    return $acc;
}


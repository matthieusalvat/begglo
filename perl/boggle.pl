#!/usr/bin/perl
use utf8;
use Encode;
use List::Util qw(shuffle);

#Optimisation Algo recherche :
# Créer un dictionnaire par longueur de mot (3, 4 , 5 ...) au format suivant : mots sans accent trié par ordre des lettres suivi du mot complet. Fichier à trier par la clé (un coup de sort unix fera l'affaire
# Pour trouver un mot : utiliser la méthode actuelle sur le bon dictionnaire (selon la longueur du mot demandé)
# Pour la recherche des solutions : prendre les lettres disponibles et les trier dans l'ordre (ex: ABCOT). Ouvrir chaque dictionnaire, prendre le nom de lettres du "mot" trié correspondant au dictionnaire. Parcourir le dictionnaire en cherchant les lignes commençant par le "mot" trié. On peut s'arreter dès que l'on a "dépassé" les lettres triées.

#my $dict_file="/usr/share/dict/french";
my $dict_file="dict";
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
    foreach my $response (sort {length($b) <=> length($a) || $a cmp $b} keys %$words) {
	my $user="  ";
	$user="X " if ($responses->{$response});
	print $user.$response."\t : ".join(", ", @{$words->{$response}})."\n";
    }
} else {
    $letters=to_plain_text(decode_utf8(lc($ARGV[0])));
    print encode_utf8("Recherche des mots de $minimun_length à ".length($letters)." lettres contenant les lettres '$letters' ...\n");
    my $words=find_solutions($letters);
    
    print encode_utf8("\n".scalar(keys %$words)." solutions possibles : \n");
    foreach my $response (sort {length($b) <=> length($a) || $a cmp $b} keys %$words) {
	print $response."\t : ".join(", ", @{$words->{$response}})."\n";
    }
}

sub find_solutions {
    my $letters=shift;

    my $maximum_length=length($letters);
    my $words={};

    my @letters=split(//, $letters);
    my @sorted_letters=sort split //, $letters;
    my $sorted_letters=join("" ,@sorted_letters);
    
    my $re="^".join("?", @sorted_letters)."?\$";
    my $max_letter=substr($sorted_letters, -1);
    my $length; 

    # Retour des algo
    # -1 : mot ne correspondant pas aux lettres
    # 0 : mot correspondant aux lettres
    # 1 : mot ne correspondant pas aux lettres et que l'on sait que ça ne sert à rien de continuer la recherche dans le fichier courant 
    # abceins cabines
    # aax     axa
    # abe     abe
    # eins    sien
    
    my $algos = {
	"index_for_all" => sub {
	    my $try=shift;
	    # La ligne ci-dessous permet d'arreter quand la première lettre du mot du dictionnaire est supérieure à celle de la lettre la plus haute de la rechercher
	    # return 1 if ((substr($try, 0, 1) cmp $max_letter) == 1);
	    my $last=0;
	    my $found_letters=0;
	    foreach my $letter (@sorted_letters) {
		if ($index=index($try, $letter, $last)!=-1) {
		    $last=$index;
		    $found_letters++;
		}
	    }
	    return ($found_letters==$length) ? 0 : -1;
	},
	"substr_for_all" => sub {
	    my $try=shift;
	    # La ligne ci-dessous permet d'arreter quand la première lettre du mot du dictionnaire est supérieure à celle de la lettre la plus haute de la rechercher
	    #return 1 if ((substr($try, 0, 1) cmp $max_letter) == 1);
	    foreach my $letter (@sorted_letters) {
		my $i=index($try, $letter);
		substr($try, rindex($try, $letter), 1, "") if ($i!=-1);
		return 0 if $try eq "";
	    }
	    return -1;
	},
	"regexp_for_all" => sub {
	    return 0 if (shift =~ $re);
	    return -1;
	},
	"for_max_letters"=>sub {
	    return shift cmp $sorted_letters;
	},
    };

    foreach $length ($minimun_length .. $maximum_length) {
	my $algo=$algos->{regexp_for_all};
#	my $algo=$algos->{index_for_all};
#	my $algo=$algos->{substr_for_all};
	$algo=$algos->{for_max_letters} if ($length==$maximum_length);
	open(DICT, $dict_file.$length) or die "$dict_file$length: $0";
	binmode DICT, ":utf8";
	while(my $line=decode_utf8(<DICT>)) {
	    # if ((substr($line, 0, $length) =~ $re)) {
	    # 	$word = substr($line, $length+1, -1);
	    #  	push @{$words->{to_plain_text($word)}}, encode_utf8($word);
	    # }

	    my $res=&$algo(substr($line, 0, $length));
	    last if $res==1;
	    if ($res==0) {
	    	$word = substr($line, $length+1, -1);
	     	push @{$words->{to_plain_text($word)}}, encode_utf8($word);
	    }
	}
	close(DICT);
    }

    return $words;
}

sub find_word{
    my $length=shift;
    srand;
    my $word;
    open(DICT, $dict_file.$length) or die "$dict_file.$length: $0";
    binmode DICT, ":utf8";
    rand($.) < 1 && ($word = $_) while <DICT>;
    close DICT;
    chomp($word);
    
    return (split(" ", $word))[1];
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


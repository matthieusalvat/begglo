#!/usr/bin/ruby
# -*- coding: iso-8859-1 -*-

max_letter=5
min_letter=3

$DICT_FILE="dict"

class String
  require 'iconv'
  def strip_accents()
#    self.tr('�����������������������������������������������������', 'AAAAAACEEEEIIIINOOOOOUUUUYaaaaaaceeeeiiiinooooouuuuyy')
    self.tr('���������������������������', 'aaaaaaceeeeiiiinooooouuuuyy')
  end
  def strip_accents!()
    replace(strip_accents)
  end
  def to_iso
    Iconv.conv('ISO-8859-1', 'utf-8', self)
  end
end

def find_word(length)
  line=""
  f=File.new($DICT_FILE+length.to_s)
  rand($.) < 1 && line=$_ while f.gets
  f.close;
  return line.chomp[0 ... length]
end

def find_solutions(letters, min) 
  max=letters.size
  words={}
  re=Regexp.new("^"+letters.split(//).sort.join("?")+"?$")
  (min .. max).each do 
    |length|
    f=File.open($DICT_FILE+length.to_s, "r:ISO-8859-1")
    f.each_line do
      |line|
      if (line[0 ... length] =~ re) then
        word=line[length+1 ... -1]
        key=word.to_iso.strip_accents
        words[key]=[] if words[key].nil?
        words[key].push(word.to_iso)
      end
    end
    f.close
  end
  return words
end

if ARGV[0].nil? then
  puts "usage: #{$0} <letters|number of letter>"
else
  if ARGV[0] =~ /^(\d)$/ then
    max_letter=$1.to_i
    puts "Recherche d'un mot de #{max_letter} lettres dans le dictionnaire ..."
    letters=find_word(max_letter).split("").sort_by {rand}.join("");
    puts "Vous avez une minute pour trouver le maximum de mots de #{min_letter} � #{max_letter} lettres corrspondant aux lettres qui s'afficheront quand vous aurez appuy� sur [Entr�e]. Vous gagnez 10s de bonus � chaque mot de #{max_letter} lettres trouv�. A vous de jouer !"
    words=find_solutions(letters, min_letter)
    STDIN.readline
    system 'clear'
    responses={}
    loop do
      puts "Point(s) : #{responses.keys.size}"
      puts "Lettres  : #{letters.split(//).join(" ").upcase}"
      print "R�ponse  : ";
      try=STDIN.readline.chomp.strip_accents
      system 'clear'
      break if try == "quit"
      if words.include?(try) then
        if responses.include?(try) then
          puts "KO       : '#{try}' : Vous avez d�j� donn� cette r�ponse"
        else
          responses[try]=true
          if try.length == max_letter then
            puts "OK       : '#{try}' : 1 point de plus, 10 secondes suppl�mentaires"
          else
            puts "OK       : '#{try}' : 1 point de plus"
          end
        end
      else
        puts "KO       : '#{try}' n'est pas reconnu !"
      end
    end
    puts "\Votre score : #{responses.keys.size} sur #{words.keys.size}"
    puts "\Liste des mots � trouver : "
    words.keys.sort {|a,b| cmp=b.size <=> a.size; cmp.zero? ? (a <=> b) : cmp }.each do
      |key|
      puts "#{responses.include?(key) ? "X" : " "} #{key}\t: #{words[key].join(", ")}"
    end
  else
    letters=ARGV[0].strip_accents
    puts "Recherche des mots de #{min_letter} � #{letters.size} contenant les letters '#{letters}'"
    words=find_solutions(letters, min_letter)
    puts "#{words.keys.size} solutions possibles : "
    words.keys.sort {|a,b| cmp=b.size <=> a.size; cmp.zero? ? (a <=> b) : cmp }.each do
      |key|
      puts "#{key}\t: #{words[key].join(", ")}"
    end
  end
end
  
  

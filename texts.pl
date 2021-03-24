#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use Data::Dumper;

my $dbh = DBI->connect("dbi:SQLite:dbname=corpus.db", "", "", {RaiseError => 1, AutoCommit => 1, PrintError => 1});
my @text_data = $dbh->selectrow_array('SELECT * from texts WHERE id = 1'); 

print "Content-type:text/html; charset=utf-8\r\n\r\n";
print '<table class="textdata"><tr><th>id</th><th>author</th><th>title</</th><th> year</th><th>lang</th></tr>
<tr><td> '.$text_data[0].'</td><td>'.$text_data[1].'</td><td>  '.$text_data[2].'</td><td> '.$text_data[3].'</td><td> <img src="res/'.$text_data[4].'.gif" alt="'.$text_data[4].'" title="'.$text_data[4].'"/></td></table></tr>';


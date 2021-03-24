#!/usr/bin/env perl
use 5.012; # this enables strict
use warnings;
use utf8;
use experimental 'smartmatch';
use DBI;
use DBD::SQLite;
use XML::LibXML;
use POSIX qw(strftime);
use Data::Dumper;
use Time::HiRes;
use Encode;
use URI::Escape;

my $debug = 0;

sub dmp {
	print Dumper (@_);
}
sub lg {
	#open FILE, ">>log.txt" or die $!;	
	#print FILE join (' | ', @_)."\n";
	#close FILE;
}
	
sub add_freq_node {
	my ($doc, $parent, $count, $form) = @_;
	my $item = $doc->createElement('score');
	$parent->addChild($item);
	my $xml_form = $doc->createElement('form');
	$item->addChild($xml_form);
	$xml_form->addChild($doc->createCDATASection($form));
	$item->appendTextChild('count', $count);
}
	
sub check_neighbours {
	my ($steps, $pos, $contexts, $doc, $cluster, $side) = @_;
	my $attrib = ($side eq "-") ? "left" : "right";
	my $buf = '';
	my $step = 0;
	foreach my $offset (1..25) {
		my $context = $contexts->{eval($pos.$side.$offset)};
		unless ($context->{'form'}) {
			$steps++ ;
			if ($context->{'token'}) { # must be cleared this code!
				if ($side eq "-") { 
					$buf = $buf.' '.
					$context->{'token'}; 
				} else {
					$buf = $context->{'token'}.
					' '.$buf;
				}
			}
		} else {
			my $item = $doc->createElement('item');
			$item->addChild( $doc->createAttribute( $attrib => (++$step)));
			my $form_xml = $doc->createElement('form');
			$item->addChild($form_xml);
			$form_xml->addChild($doc->createCDATASection($context->{'form'}));
			
			my $token_xml = $doc->createElement('token');
			$item->addChild($token_xml);
			$token_xml->addChild($doc->createCDATASection( ($side eq "-") ? $context->{'token'}.$buf : $buf.$context->{'token'}));
			
			
			$cluster->addChild($item);
			$buf= '';
		}
		last if ($offset == $steps);
	}
	
}
###################################################
my $response = '';
my $xml_dir = "./concs";
my $filename = "./response.xml";
my $range = 15;
###################################################
my ($term, $mode, $left, $right, $text, $re) = ();
my $query = $ENV{'QUERY_STRING'};
# goto OUT unless $query;
# $query =~ s/%(..)/pack("C",hex($1))/ge;
$query = Encode::decode('utf8', uri_unescape($query));

my @params = qw /re mode left right term text/;
my %req = ();
foreach my $pair (split(/;|&/,$query)) {
	my ($key, $val) = split(/=/,$pair,2);
	# $val=~tr/+/ /;
	# lg($val);
	$req{$key} = $val if $key ~~ @params;	
}

foreach my $key (@params){
	$req{$key} = '' unless exists $req{$key};
}
# $mode = "freq";
# $text = 2;
# $mode = "text";
# $term="гаспадар";
# $text = 1;

 # print STDERR "Ref: ".$ENV{'HTTP_REFERER'}.'Addr: '.$ENV{'REMOTE_ADDR'}."\n";
print STDERR "Query: ".$query."\n" if $debug;
# goto OUT;

goto OUT if ($req{mode} eq 'text' && $req{term} eq '');

$req{right} = 4 unless exists $req{right} || $req{right} > 9;
$req{left} = 4 unless exists $req{left} || $req{left} > 9;



my $time = Time::HiRes::time();
# my $dbh = DBI->connect("dbi:SQLite:dbname=corpus.db", "", "", {RaiseError => 1, AutoCommit => 0, PrintError => 1, sqlite_open_flags => SQLITE_OPEN_READONLY});
# $dbh->{sqlite_unicode} = 1;


my $dbh = DBI->connect("dbi:SQLite:dbname="."./corpus.db", undef, undef, {
	sqlite_unicode => 1,
	AutoCommit => 1, 
	RaiseError => 1, 
	sqlite_open_flags =>  DBD::SQLite::OPEN_READONLY,
	# ReadOnly   => 1, # current version too minor
	# sqlite_use_immediate_transaction => 1,
});

$dbh->func('regexp', 2, sub {
    my ($regex, $string) = @_;
    return $string =~ /$regex/;
}, 'create_function');

my $doc = XML::LibXML::Document->createDocument('1.0');
my $root = $doc->createElement('data');
my $report = $doc->createElement('report');
$root->addChild($report);
$doc->setDocumentElement($root);
my @dt = gmtime();
$report->appendTextChild('date', POSIX::strftime ("%d.%m.%Y", @dt));
$report->appendTextChild('time', POSIX::strftime ("%H:%M:%S", @dt));



if ($req{mode} eq 'text') {
	my $psql = "SELECT position FROM tokens WHERE form <> '' AND text_id = ".int($req{text})." AND form ".( length($req{re}) ? ' REGEXP ': '=').'?';
	lg( $psql);
	# $psql = "SELECT position from tokens WHERE form REGEXP \'".'лабанові\w+'."\'";
	# $psql = "SELECT position from tokens WHERE form REGEXP \'".'^(ён|яна)$'."\'";
	my $contexts = {};
	my @pos_list = @{$dbh->selectcol_arrayref($psql, {}, $req{term})}; 
	
	# print STDERR $psql."\n";
	
	# $contexts = $dbh->selectall_hashref('SELECT * FROM tokens WHERE text_id = '.$text.' AND '. 
	# substr(join ('', map {'(position BETWEEN '.($_-$range).' AND '.($_+$range).') OR'} @pos_list), 0, -2), 'position') if @pos_list;
	
	$contexts = $dbh->selectall_hashref("SELECT * FROM tokens WHERE form <> '' AND text_id = ".$req{text}, 'position') if @pos_list;
	
	my $time2 = Time::HiRes::time;
	my $dbtime = $time2-$time;
	print STDERR "\nTime: ".sprintf("%.2f", $dbtime)." sec.\n" if $debug;
	# exit;
	$report->appendTextChild('dbtime', $dbtime);
	my $term_node = $doc->createElement('term');
	$term_node->addChild($doc->createCDATASection($req{term}));
	$report->addChild($term_node);

	$report->appendTextChild('left', $req{left});
	$report->appendTextChild('right', $req{right});
	my $concordance = $doc->createElement('concordance');

	foreach my $num (0..$#pos_list) {
		# print 1;
		my $pos = $pos_list[$num];
		my $cluster = $doc->createElement('cluster');
		$cluster->addChild($doc->createAttribute( 'n' => $num));
		
		check_neighbours($req{left}, $pos, $contexts, $doc, $cluster, '-');
		my $item = $doc->createElement('item');
		$item->addChild( $doc->createAttribute( 'center' => 0));
		my $token_xml 	= $doc->createElement('token');
		my $form_xml 	= $doc->createElement('form');
		$token_xml->addChild($doc->createCDATASection( $contexts->{$pos}->{'token'}));
		$form_xml->addChild($doc->createCDATASection( $contexts->{$pos}->{'form'}));
		$item->addChild($token_xml);
		$item->addChild($form_xml);
		$cluster->addChild($item);
		$concordance->addChild($cluster);
		check_neighbours($req{right}, $pos, $contexts, $doc, $cluster, '+');
		
	}
	$root->addChild($concordance);
	
	my $time3 = Time::HiRes::time;
	my $xmltime = $time3-$time;
	print STDERR "\nTime: ".sprintf("%.2f", $xmltime)." sec.\n" if $debug;
	$report->appendTextChild('xmltime', $xmltime);
	
} elsif($req{mode} eq 'freq') {
		$dbh->do("PRAGMA cache_size = 200000");
		$dbh->do("PRAGMA page_size = 1024000");
		my $sql = "SELECT form  FROM tokens where form <> '' and text_id = ".$req{text}; #LIMIT 20;
		
		my $ary_ref = $dbh->selectcol_arrayref($sql);
		
		# dmp ($ary_ref);
		
		# print STDERR "freq check";
		my $time2 = Time::HiRes::time;
		my $dbtime = $time2-$time;
		print STDERR "\nTime: ".sprintf("%.2f", $dbtime)." sec.\n" if $debug;
		my %index = ();
		foreach my $form (@$ary_ref) { exists ($index{$form}) ? ($index{$form}++) : ($index{$form} = 1); }
		# map {print $_."\n"} keys %index;
		$report->appendTextChild('dbtime', $dbtime);
		my $freq_dict = $doc->createElement('freq');
		$freq_dict->addChild( $doc->createAttribute( 'forms' => (scalar @$ary_ref)));
		foreach my $form (keys %index) {
			my $count = $index{$form};
			# if ($count > 1000) { # 1/5 of forms = forms/1000
			add_freq_node($doc, $freq_dict, $count, $form);
			# }
		}
		# my $iter = 0;
		# for my $form (sort { $index{$b} <=> $index{$a} } keys %index) {
			# my $count = $index{$form};
			# add_freq_node($doc, $freq_dict, $count, $form);
			# $iter++;
			# last if $iter == 500;
		# }
		
		# for (my $i = 0; $i < scalar @$ary_ref; $i++) {
			# # print ."\n";
			# my $item = $doc->createElement('score');
			# $freq_dict->addChild($item);
			# my $form = $doc->createElement('form');
			# $item->addChild($form);
			# $form->addChild($doc->createCDATASection($$ary_ref[$i]));
			# $item->appendTextChild('count', $$ary_ref[++$i]);
		# }
		$root->addChild($freq_dict);
		my $time3 = Time::HiRes::time;
		my $xmltime = $time3-$time;
		print STDERR "\nTime: ".sprintf("%.2f", $xmltime)." sec.\n"  if $debug;
		
		$report->appendTextChild('xmltime', $xmltime);
} elsif($req{mode} eq 'meta') {
}
	# $doc->toFile("out.xml", 1);
	$response = $doc->serialize(1);
	$dbh->disconnect();
OUT: {
	print "Content-type:text/xml; charset=utf-8\r\n\r\n".$response;
	# print "ok";
}
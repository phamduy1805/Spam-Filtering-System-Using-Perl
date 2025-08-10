#!/usr/bin/perl
use strict;
use warnings;
use Storable;
use List::Util qw(sum);
use FindBin qw($Bin);
use GD::Graph::bars;
use GD::Graph::Data;
use lib $Bin;
require "$Bin/config.pl";
no warnings "once";

my $test_file = shift @ARGV or die "You have to insert a path.\nEx.: perl classify.pl path/to/file.txt\n";
die "File '$test_file' does not exists.\n" unless -e $test_file;

my $report_file = $configParams::OUTPUT;

# Load model
my $model = retrieve("$Bin/model/probabilities.db");
my ($P_spam, $P_ham) = ($model->{P_spam}, $model->{P_ham});
my %P_w_given_spam = %{ $model->{P_w_given_spam} };
my %P_w_given_ham  = %{ $model->{P_w_given_ham} };

open(my $in_fh,  '<:encoding(utf8)', $test_file)    or die "Cannot open $test_file: $!";
open(my $out_fh, '>:encoding(utf8)', $report_file)  or die "Cannot write to $report_file: $!";

my $email_number = 0;
my @email_lines;
my ($spam_count, $ham_count, $unknown_count) = (0, 0, 0);

while (my $line = <$in_fh>) {
    if ($line =~ /^\s*$/) {  # dòng trắng = hết email
        process_email(\@email_lines);
        @email_lines = ();
    } else {
        push @email_lines, $line;
    }
}
process_email(\@email_lines) if @email_lines;

close $in_fh;
close $out_fh;

print "Classify successfully: $test_file\n";
print "Result at: $report_file\n";
print "Statistics:\n";
print "   SPAM: $spam_count email\n";
print "   HAM : $ham_count email\n";
print "   Unclassify: $unknown_count email\n";

# ======================= HÀM PHÂN LOẠI ========================
sub process_email {
    my ($lines_ref) = @_;
    return unless @$lines_ref;

    $email_number++;
    my $email_text = join ' ', map { chomp; $_ } @$lines_ref;
    my @words = split(/\W+/, lc $email_text);
    my @seen_words = grep { exists $P_w_given_spam{$_} || exists $P_w_given_ham{$_} } @words;

    unless (@seen_words) {
        print $out_fh "Email $email_number: do not have enough data -> We can't classify this.\n\n";
        $unknown_count++;
        return;
    }

    my $log_ps = log($P_spam || 1e-6) + sum(map { log($P_w_given_spam{$_} // 1e-6) } @seen_words);
    my $log_ph = log($P_ham  || 1e-6) + sum(map { log($P_w_given_ham{$_}  // 1e-6) } @seen_words);

    # Softmax
    my $max_log = $log_ps > $log_ph ? $log_ps : $log_ph;
    my $exp_ps = exp($log_ps - $max_log);
    my $exp_ph = exp($log_ph - $max_log);
    my $sum_exp = $exp_ps + $exp_ph;

    my $prob_spam = $exp_ps / $sum_exp;
    my $prob_ham  = $exp_ph / $sum_exp;

    my $label = $prob_spam > $prob_ham ? 'SPAM' : 'HAM';
    $label eq 'SPAM' ? $spam_count++ : $ham_count++;

    printf $out_fh "Email $email_number [$label]:\n";
    print  $out_fh @$lines_ref;
    printf $out_fh "\n   -> SPAM probability: %.2f%%\n", $prob_spam * 100;
    printf $out_fh "   -> HAM probability : %.2f%%\n\n", $prob_ham  * 100;
}

# =================== VẼ BIỂU ĐỒ ========================
if (($spam_count + $ham_count) > 0) {
    my $data = GD::Graph::Data->new([
        ['SPAM', 'HAM'],
        [$spam_count, $ham_count],
    ]) or die GD::Graph::Data->error;

    my $graph = GD::Graph::bars->new(600, 400);
    $graph->set(
        x_label           => 'Email type',
        y_label           => 'Amount',
        title             => 'Classify statistics: SPAM/HAM',
        y_max_value       => ($spam_count + $ham_count + 1),
        y_tick_number     => 5,
        y_label_skip      => 1,
        bar_spacing       => 12,
        shadow_depth      => 4,
        shadowclr         => 'dgray',
        transparent       => 0,
        dclrs             => ['#FF6666', '#6699FF'],
        fgclr             => 'black',
        bgclr             => 'white',
        values_space      => 8,
        show_values       => 1,
        long_ticks        => 1,
        bar_width         => 20,
    ) or die $graph->error;

    my $gd = $graph->plot($data) or die $graph->error;
    my $graph_file = $configParams::GRAPH_FILE;
    open(my $img_fh, '>', $graph_file) or die "Cannot save summary at $graph_file: $!";
    binmode $img_fh;
    print $img_fh $gd->png;
    close $img_fh;

    print "Statistics saved successfully at: $graph_file\n";
} else {
    print "Do not have any email.\n";
}


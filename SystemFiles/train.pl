#!/usr/bin/perl
use strict;
use warnings;
use Storable;
use FindBin qw($Bin);
use lib $Bin;
require "$Bin/config.pl";
no warnings "once";

my $train_file = $configParams::TRAIN_FILE;

# ===========================
# 1. Đọc và gộp dữ liệu
# ===========================
my @records;
my $current = "";

open my $fh, "<:encoding(utf8)", $train_file or die "Cannot open $train_file: $!";
while (my $line = <$fh>) {
    if ($line =~ /^(spam|ham),/) {
        push @records, $current if $current ne "";
        $current = $line;
    } else {
        $current .= $line;
    }
}
push @records, $current if $current ne "";
close $fh;

# ===========================
# 2. Phân loại và tách từ
# ===========================
my (@spam_emails, @ham_emails);
for my $line (@records) {
    chomp $line;
    my ($label, $text) = split /\,/, $line, 2;	
    next unless defined $label && defined $text;

    my @words = map { lc } ($text =~ /\w+/g);  # không uniq để giữ tần suất

    if ($label eq 'spam') {
        push @spam_emails, \@words;
    } elsif ($label eq 'ham') {
        push @ham_emails, \@words;
    }
}

my @all_emails = (@spam_emails, @ham_emails);
my $num_spam   = scalar @spam_emails;
my $num_ham    = scalar @ham_emails;
my $num_total  = $num_spam + $num_ham;

# ===========================
# 3. Xây dựng vocabulary & tính DF (document frequency)
# ===========================
my %doc_freq;  # DF(t): số email chứa từ t
my %all_words;

for my $email (@all_emails) {
    my %seen;
    $seen{$_} = 1 for @$email;
    $doc_freq{$_}++ for keys %seen;
    $all_words{$_} = 1 for @$email;
}

my $vocab_size = scalar keys %all_words;

# ===========================
# 4. Tính IDF cho từng từ
# ===========================
my %idf;
for my $word (keys %all_words) {
    $idf{$word} = log($num_total / (1 + $doc_freq{$word}));
}

# ===========================
# 5. Tính TF-IDF cho spam/ham
# ===========================
my (%tfidf_spam_sum, %tfidf_ham_sum);
my ($total_tfidf_spam, $total_tfidf_ham) = (0, 0);

# ----- Spam -----
for my $email (@spam_emails) {
    my %tf;
    $tf{$_}++ for @$email;  # term frequency cho email

    for my $w (keys %tf) {
        my $tfidf = ($tf{$w} / scalar(@$email)) * $idf{$w};
        $tfidf_spam_sum{$w} += $tfidf;
        $total_tfidf_spam += $tfidf;
    }
}

# ----- Ham -----
for my $email (@ham_emails) {
    my %tf;
    $tf{$_}++ for @$email;

    for my $w (keys %tf) {
        my $tfidf = ($tf{$w} / scalar(@$email)) * $idf{$w};
        $tfidf_ham_sum{$w} += $tfidf;
        $total_tfidf_ham += $tfidf;
    }
}

# ===========================
# 6. Chuẩn hóa thành xác suất P(w|spam), P(w|ham)
# ===========================
my (%P_w_given_spam, %P_w_given_ham);
for my $w (keys %all_words) {
    $P_w_given_spam{$w} = ($tfidf_spam_sum{$w} // 0 + 1) / ($total_tfidf_spam + $vocab_size);
    $P_w_given_ham{$w}  = ($tfidf_ham_sum{$w}  // 0 + 1) / ($total_tfidf_ham + $vocab_size);
}

# ===========================
# 7. Xác suất prior
# ===========================
my $P_spam = $num_spam / $num_total;
my $P_ham  = $num_ham  / $num_total;

# ===========================
# 8. Lưu mô hình
# ===========================
store {
    P_spam => $P_spam,
    P_ham  => $P_ham,
    IDF    => \%idf,
    P_w_given_spam => \%P_w_given_spam,
    P_w_given_ham  => \%P_w_given_ham,
}, $configParams::MODEL_FILE;

print "Training with TF-IDF completed. Model saved.\n";

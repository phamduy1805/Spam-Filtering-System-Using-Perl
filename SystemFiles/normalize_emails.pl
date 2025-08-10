#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Unicode::Normalize;
use Getopt::Long;

# ==== Tùy chọn dòng lệnh ====
# Cuối file lấy đường dẫn
my $input  = $ARGV[-2];
my $output = $ARGV[-1];

# Xoá chúng khỏi @ARGV để không bị lẫn với GetOptions
splice(@ARGV, -2, 2);
# Tùy chọn xử lý
my ($remove_punct, $remove_non_ascii, $remove_non_alnum);
my ($remove_accents, $remove_emoji, $remove_urls);
my ($clean_whitespace, $remove_duplicates);

GetOptions(
    "remove-punct"       => \$remove_punct,
    "remove-non-ascii"   => \$remove_non_ascii,
    "remove-non-alnum"   => \$remove_non_alnum,
    "remove-accents"     => \$remove_accents,
    "remove-emoji"       => \$remove_emoji,
    "remove-urls"        => \$remove_urls,
    "clean-whitespace"   => \$clean_whitespace,
    "remove-duplicates"  => \$remove_duplicates,
    "input=s"            => \$input,
    "output=s"           => \$output,
) or die "Invalid options.\n";

# ==== Đọc nội dung từ file input ====
open my $in, '<', $input or die "Cannot open file $input: $!";
my $text = do { local $/; <$in> };
close $in;

# ==== Xử lý từng bước ====
# ==== Xử lý từng email riêng biệt (giữa các email cách nhau 1 dòng trống) ====
my @emails = split /\n\s*\n/, $text;
for my $email (@emails) {
    $email =~ s/[[:punct:]]//g if $remove_punct;
    $email =~ s/[^[:ascii:]]//g if $remove_non_ascii;
    $email =~ s/[^a-zA-Z0-9\s]//g if $remove_non_alnum;

    if ($remove_accents) {
        $email = NFD($email);
        $email =~ s/\p{Mn}//g;
        $email = NFC($email);
    }

    $email =~ s/[\x{1F300}-\x{1F6FF}]//g if $remove_emoji;

    if ($remove_urls) {
        $email =~ s{https?://\S+}{}g;
        $email =~ s/#\S+//g;
    }

    if ($clean_whitespace) {
        $email =~ s/\r//g;
        $email =~ s/^\s+|\s+$//mg;
        $email =~ s/\s+/ /g;
    }
}

# ==== Loại bỏ trùng lặp nếu được yêu cầu ====
if ($remove_duplicates) {
    my %seen;
    @emails = grep { !$seen{$_}++ } @emails;
}

# Gộp lại thành văn bản với 1 dòng trống giữa các email
$text = join "\n\n", @emails;


# ==== Ghi kết quả ra file output ====
open my $out, '>', $output or die "Cannot write to $output: $!";
print $out $text;
close $out;

print "Successfully! \nResult saved at: $output\n";

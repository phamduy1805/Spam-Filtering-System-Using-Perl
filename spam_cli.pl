#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Term::ANSIColor;

# Các biến tùy chọn
my ($train, $classify, $report, $normalize, $help);
my ($remove_punct, $remove_non_ascii, $remove_non_alnum);
my ($remove_accents, $remove_emoji, $remove_urls);
my ($clean_whitespace, $remove_duplicates);

# Lấy tùy chọn dòng lệnh
GetOptions(
    'train'              => \$train,
    'classify=s'         => \$classify,
    'report'             => \$report,
    'normalize'        => \$normalize,
    'remove-punct'       => \$remove_punct,
    'remove-non-ascii'   => \$remove_non_ascii,
    'remove-non-alnum'   => \$remove_non_alnum,
    'remove-accents'     => \$remove_accents,
    'remove-emoji'       => \$remove_emoji,
    'remove-urls'        => \$remove_urls,
    'clean-whitespace'   => \$clean_whitespace,
    'remove-duplicates'  => \$remove_duplicates,
    'help'               => \$help,
) or die "Invalid option. Use --help to open guideline.\n";

# Nếu không có gì thì hiện hướng dẫn
if ($help || (! $train && ! $classify && ! $report && ! $normalize)) {
    print_help();
    exit;
}

# Huấn luyện
if ($train) {
    print color('yellow');
    print "Training the model...\n";
    print color('reset');
    system("perl SystemFiles/train.pl") == 0
        or die "Train failed!\n";
}

# Phân loại
if ($classify) {
    print color('yellow');
    print "Classifying the emails: $classify\n";
    print color('reset');
    system("perl SystemFiles/classify.pl $classify") == 0
        or die "Classify failed!\n";
}

# Gửi báo cáo
if ($report) {
    print color('yellow');
    print "Sending the report...\n";
    print color('reset');
    system("perl SystemFiles/send_report.pl") == 0
        or die "Send report failed!\n";
}

# Làm sạch văn bản
if ($normalize) {
    my $input_file  = "/home/canguangamchua/inbox/test_emails.txt";               # Mặc định đầu vào
    my $output_file = "/home/canguangamchua/inbox/emails_normalized.txt";    # Mặc định đầu ra

    print color('green');
    print "Normalizing the file: $input_file\n";
    print color('reset');

    my $options = '';
    $options .= ' --remove-punct'      if $remove_punct;
    $options .= ' --remove-non-ascii'  if $remove_non_ascii;
    $options .= ' --remove-non-alnum'  if $remove_non_alnum;
    $options .= ' --remove-accents'    if $remove_accents;
    $options .= ' --remove-emoji'      if $remove_emoji;
    $options .= ' --remove-urls'       if $remove_urls;
    $options .= ' --clean-whitespace'  if $clean_whitespace;
    $options .= ' --remove-duplicates' if $remove_duplicates;

    # Nếu không chọn tùy chọn nào, dùng đầy đủ
    if ($options eq '') {
        $options = '--remove-punct --remove-non-ascii --remove-non-alnum --remove-accents --remove-emoji --remove-urls --clean-whitespace --remove-duplicates';
    }

    # Gọi normalize script với file mặc định
    system("perl SystemFiles/normalize_emails.pl $options $input_file $output_file") == 0
        or die "Normalize failed!\n";

    print color('green');
    print "Output completed: $output_file\n";
    print color('reset');
}



# Hướng dẫn sử dụng
sub print_help {
    print <<'HELP';

======================================================================================================================
                                                SPAM EMAILS FILTERING SYSTEM
======================================================================================================================
Usage:
    perl spam_cli.pl [options]

Options:
    --train                  Training the spam filter model
    --classify=<file/dir>    Classify spam for specify directory/file
    --report                 Send the report to your email
    --normalize              Clean/Normalize data before classify (output at emails_normalized.txt file in your inbox)

    Normalize options (use along with --normalize):
        --remove-punct        Remove punctuation marks
        --remove-non-ascii    Remove non-ASCII characters
        --remove-non-alnum    Remove Non-alphanumeric Characters
        --remove-accents      Remove letter Accents (diacritics)
        --remove-emoji        Strip all emojis
        --remove-urls         Remove all web urls
        --clean-whitespace    Trim Whitespaces
        --remove-duplicates   Remove Duplicate Lines / Paragraphs

    --help                   GUIDELINE

Examples:
    perl spam_cli.pl --train
    perl spam_cli.pl --classify=emails/test.txt
    perl spam_cli.pl --report
    perl spam_cli.pl --normalize --remove-emoji --remove-urls
HELP
}

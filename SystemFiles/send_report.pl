#!/usr/bin/perl
use strict;
use warnings;
no warnings 'once';

use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use Email::MIME;
use Email::MIME::Creator;
use FindBin qw($Bin);

require "$Bin/config.pl";

# ==== Đọc file report.txt ====
my $report_path = $configParams::OUTPUT;
open(my $report_fh, '<', $report_path) or die "Cannot open the report file: $!";
my $report_content = do { local $/; <$report_fh> };
close($report_fh);

# ==== Đọc ảnh summary.png ====
my $image_path = $configParams::GRAPH_FILE;
open(my $img_fh, '<:raw', $image_path) or die "Cannot open the png file: $!";
my $image_data = do { local $/; <$img_fh> };
close($img_fh);

# ==== Nội dung email ====
my $email_body = <<"END_BODY";
==================== Spam filtering report =============================
Here are the report from spam filtering system.
You can check summary in summary.png, and classify details in report.txt.
END_BODY

# ==== Tạo MIME parts ====
my $text_part = Email::MIME->create(
    attributes => {
        content_type => 'text/plain',
        charset      => 'UTF-8',
        encoding     => 'quoted-printable',
    },
    body_str => $email_body,
);

my $report_part = Email::MIME->create(
    attributes => {
        content_type => 'text/plain',
        charset      => 'UTF-8',
        name         => 'report.txt',
        disposition  => 'attachment',
        filename     => 'report.txt',
        encoding     => 'quoted-printable',
    },
    body_str => $report_content,
);

my $image_part = Email::MIME->create(
    attributes => {
        content_type => 'image/png',
        encoding     => 'base64',
        name         => 'summary.png',
        disposition  => 'attachment',
        filename     => 'summary.png',
    },
    body => $image_data,
);

# ==== Tạo email ====
my $email = Email::MIME->create(
    header_str => [
        From    => $configParams::EMAIL_FROM,
        To      => $configParams::EMAIL_TO,
        Subject => $configParams::EMAIL_SUBJECT,
    ],
    parts => [ $text_part, $report_part, $image_part ],
);

# ==== Gửi email qua SMTP ====
eval {
    sendmail(
        $email,
        {
            transport => Email::Sender::Transport::SMTP->new({
                host => 'smtp.gmail.com',
                port => 587,
                ssl  => 'starttls',
                sasl_username => $configParams::EMAIL_FROM,
                sasl_password => $configParams::EMAIL_APP_PASSWORD,
                timeout => 30,
            }),
        }
    );
};

if ($@) {
    warn "SMTP Error: $@\n";
    die "Cannot send report email due to connection error.\n";
}

print "Report send to $configParams::EMAIL_TO successfully.\n";

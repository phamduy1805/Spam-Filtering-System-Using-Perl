#!/usr/bin/perl
use strict;
use warnings;

# Tên file đầu vào và đầu ra
my $input_file  = "SystemFiles/data/SMSSpamCollection.csv";
my $output_file = "SystemFiles/data/SMSSpamCollection_comma.csv";

# Mở file đầu vào để đọc
open(my $in_fh, '<', $input_file) or die "Không thể mở $input_file: $!";

# Mở file đầu ra để ghi
open(my $out_fh, '>', $output_file) or die "Không thể ghi vào $output_file: $!";

# Đọc từng dòng, thay tab bằng dấu phẩy, rồi ghi ra file mới
while (my $line = <$in_fh>) {
    $line =~ s/\t/,/g;  # Thay tab bằng dấu phẩy
    print $out_fh $line;
}

# Đóng file
close($in_fh);
close($out_fh);

print "Đã chuyển đổi xong từ tab sang comma và lưu vào $output_file\n";

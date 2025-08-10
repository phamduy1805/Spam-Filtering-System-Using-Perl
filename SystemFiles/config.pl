# config.pl
package configParams;

# ===========================
# File paths
# ===========================
our $GRAPH_FILE    = "/home/canguangamchua/spam_filtering/SystemFiles/logs/summary.png";
our $OUTPUT       = "/home/canguangamchua/spam_filtering/SystemFiles/logs/report.txt";

# File dữ liệu huấn luyện & model
our $TRAIN_FILE   = "/home/canguangamchua/spam_filtering/SystemFiles/data/SMSSpamCollection.csv";
our $MODEL_FILE   = "/home/canguangamchua/spam_filtering/SystemFiles/model/probabilities.db";

# ===========================
# Email settings
# ===========================
our $EMAIL_FROM        = 'gaduy035@gmail.com';
our $EMAIL_TO          = 'gaduy035@gmail.com';
our $EMAIL_SUBJECT     = 'Spam Email Detection Report';
our $EMAIL_APP_PASSWORD= 'lydw xzvy sytd umqj';

1;

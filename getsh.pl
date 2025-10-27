#!/usr/bin/perl
 
use strict;
use warnings;
 
# 获取命令行参数，即要遍历的年份
my $year = shift || die "Usage: $0 <year>\n";
 
# 遍历每一天
for my $month (1..12) {
    # 获取当月的最后一天
    my $last_day = `date -d "$year-$month-01 +1 month -1 day" +%d`;
    chomp $last_day;

	if($month<10){$month="0".$month;}
 
    for my $day (1..$last_day) {
		if($day<10){$day="0".$day;}
        #
		my $time="$year-$month-$day";
		
		open OUT,">./pyshs.2025/run.$time.py" or die $!;
		print OUT "from pubmed_utils import \*\n";
		print OUT "from datetime import datetime, timedelta\n";
		print OUT "release_date_min=\'$time\'\n";
		print OUT "release_date_max=\'$time\'\n";
		print OUT "paper_type = \"Article\" \n";
		print OUT "email = \"409985846\@qq\.com\" \n";
		print OUT "search_key_words = \"2010\:2025\[pdat\]\" \n";
		print OUT "save_path = \"/home/chench/PKUshenzhen/7.RA/01.Pubmed/method2/paper_donload/paper_info_\" + release_date_min + \"\.xlsx\"\n";
		print OUT "my_pubmed_utils = pubmed_utils()\n";
		print OUT "my_pubmed_utils\.get_main_info_into_excel(email, search_key_words, release_date_min, release_date_max, paper_type, save_path)\n";
		print OUT "print\(\"main info has been writen to file!\\n\")\n";
		
		close OUT;

    }
}

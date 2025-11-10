#!usr/bin/perl -w
use strict;
use File::Basename;
use Spreadsheet::XLSX;

my %mat=();
my %rank_World=();
my %rank_China=();
my %highauthor=();
my %natureind=();
my %countf=();
my %labelfirst=();   ###标记第一单位是否已经赋值241031；
my $school="./paper_donload/school.annot.txt";
my $highcited="../highcitedAuthors2019-2023.txt";
my $natureindex="../Natureindex2024.txt";

my $f=shift;
my $out=shift;

my %cityp=();     ###city to province;
##所有省级行政区；
my @province = ("Anhui","Fujian","Gansu","Guangdong","Guangxi","Guizhou","Hainan","Hebei","Henan","Heilongjiang","Hubei","Hunan","Jiangsu","Jiangxi","Jilin","Liaoning","Inner Mongolia","Ningxia Hui Autonomous Region", "Qinghai","Sichuan","Shandong","Shanxi","Shaanxi","Taiwan","Xizang","Xinjiang","Yunnan","Zhejiang");
#"Beijing","Shanghai","Hong Kong","Macao","Chongqing","Tianjin".
open IN,$school or die $!;
<IN>;
while(<IN>){
    chomp;
    my @a=split /\t/,$_;
    $a[0]=~s/\&/and/gi;
    $rank_World{$a[0]}=$a[1];
    $rank_China{$a[0]}=$a[2];
}
close IN;

###高被引科学家及其单位读取；
open IN,$highcited or die $!;
<IN>;
while(<IN>){
	chomp;
	my @a=split /\t/,$_;
    my $len=@a;
    next if($len<4);
	my $first_aff=(split /\,/,$a[3])[0];
    if($a[3] ne ''){
        my $key1="$a[1]-$a[0]-$first_aff";
        $key1=~s/\"//gi;
        #print "$key1\n";
        $highauthor{$key1}=1;
    }
	if($len==5){
		my $second_aff=(split /\,/,$a[4])[0];
		my $key2="$a[1]-$a[0]-$second_aff";
        $key2=~s/\"//gi;
		$highauthor{$key2}=1;
	}
}
close IN;

###Nature index排名读取；只存中国的单位进入hash；
open IN,$natureindex or die $!;
<IN>;
while(<IN>){
    chomp;
    my @a=split /\t/,$_;
    my $lines=$_;
    #next unless($a[1] =~/China/);
    my $affn;
    my @b=split /\,/,$a[1];
    $affn=$b[0];
    if($affn =~ /\(/){
        my @lines=split /\(/,$affn;
        $affn=$lines[0];
        $affn =~s/\s+$//gi;
    }
    $natureind{$affn} = $a[0];
}
close IN;

open IN,$f or die $!;
<IN>;
my %pmids=();
while(<IN>){
    chomp;
    my @a=split /\t/,$_;
    my $key=$a[0];
    $key="pmid\_".$key;
    $pmids{$key}=0;
    my $feature='';
    my @col=(1,3,2);
    my @col2=(4..26);
    my %danwei=();
    push @col,@col2;
    #next unless($a[10] =~/\S/);  ###只看有grant的文章，2019-2024年共20万篇；所有文章共117万篇；
    for my $col (@col) {
        my $value= $a[$col];
        if($col==3){
            #col 3 是专门处理单位信息的；
            my $aff_Foreign="Aff_Foreign";
            my $aff_city="City";
            $countf{$aff_Foreign}++;
            #自然指数排名前六位：中、美、德、英、日、法；https://www.163.com/dy/article/I4QF90HO0517BT3G.html
            if($value=~/United States/){
                $mat{$aff_Foreign}{$key}=5;
            }elsif($value=~/Germany/){
                $mat{$aff_Foreign}{$key}=4;
            }elsif($value=~/United Kingdom/){
                $mat{$aff_Foreign}{$key}=3;
            }elsif($value=~/Japan/){
                $mat{$aff_Foreign}{$key}=2;
            }elsif($value=~/France/){
                $mat{$aff_Foreign}{$key}=1;
            }else{
                $mat{$aff_Foreign}{$key}=0;
            }
            
            $value =~ s/\；/;/gi;
            my @b=split /\;/,$value;   #@b数组存储了多个单位的信息
            ###从第1个单位起统计；
            my $first_danwei='';
            my $num_aff=$#b+1;
            for(my $i=0;$i<=$#b;$i++){
                $b[$i]=~s/\，/,/gi;
                next unless($b[$i]=~/China/);  ###有些；前面的没有China,例如pmid：38759537;
                #$line提取了第一单位；即“,”前面的第一个单位；
                my @aff_first=split /\,/,$b[$i]; 
                next if(@aff_first < 3);
                ### 241031:提取单位对应城市和省份；
                if($i==0){
                    my ($last1, $last2, $last3) = @aff_first[-1, -2, -3];
                    $last2=~s/City//gi;$last2=~s/Province//gi;$last2=trim($last2); 
                    $last3=~s/City//gi;$last2=~s/Province//gi;$last3=trim($last3);
                    if($last2=~/\d+/ && $last2=~/[A-Za-z]/){
                        #1. School of Artificial Intelligence, South China Normal University, Foshan 528225, China. Electronic address: linguorong@m.scnu.edu.cn.;
                        #1. School of Agricultural Science and Engineering, Liaocheng University, Liaocheng, Shandong 252000, PR China;
                        #1. Critical Care Medicine, Wenzhou Hospital of Integrated Traditional Chinese and Western Medicine, Wenzhou, Zhejiang 325000, China.;
                        ###这里有可能这个last2是城市，也可能是省份；
                        $last2=~s/\d+//gi;$last2=trim($last2); 
                        if(grep { $_ eq $last2 } @province){   
                            $mat{$aff_city}{$key} = $last3;  ###如果$last2是省级行政区；
                            $cityp{$last3}=$last2;   ###将市与省的关系存入hash cityp;
                        }else{
                            $mat{$aff_city}{$key} = $last2;  ###如果$last2不是省级行政区；
                        }
                    }elsif($last2=~/\d+/ && $last2!~/[A-Za-z]/){
                        #1. School of Communication and Information Engineering, Shanghai University, Shanghai, 200444, China;
                        #1. Department of Anatomy, College of Basic Medicine, Guilin Medical University, Guilin, Guangxi, 541004, China;
                        #1. School of , Xi'an University of, 360 Changning Avenue, Chang'an District, Xi'an, Shaanxi, 710100, China. Electronic address: sywen_cn@163.com.; 
                        #1. Department of Thoracic Surgery, Cangzhou Central Hospital, Cangzhou, Hebei, 061000, China. Electronic address: 13315777392@163.com.;
                        #1. Department of , The Hospital of Yangtze University, Jingzhou, Hubei Province, 434000, China. Electronic address: dp1690191086@163.com.;
                        #1. Department of Respiratory and Critical Care Medicine, Affiliated Hospital of Zunyi Medical University, Guizhou, 563003, China.;
                        #1. Department of Otorhinolaryngology, NHC Key Laboratory of Otorhinolaryngology (Shandong University), Qilu Hospital, Cheeloo College of Medicine, Shandong University, 107 West Wenhua Road, Shandong, 250012, China.;
                        if(grep { $_ eq $last3 } @province){
                            my $last4=$aff_first[-4];
                            $last4=trim($last4);
                            if($last4=~/Hospital/gi || $last4=~/University/gi || $last4=~/Institute/gi || $last4=~/Center/gi || $last4=~/College/gi || $last4=~/Academy/gi || $last4=~/Road/gi){
                                $mat{$aff_city}{$key} = $last3;   ###这种情况说明没有提供城市信息，赋值省；
                            }else{
                                $mat{$aff_city}{$key} = $last4;
                            }
                        }else{
                            $mat{$aff_city}{$key} = $last3;
                        }
                    }elsif($last2=~/[A-Za-z]/ && $last2!~/\d+/){
                        #(1)1. Department of Radiation Oncology, the First Affiliated Hospital of Xi'an Jiaotong University, Xi'an, China;
                        #(2)1. Department of Endocrinology 2, Central Hospital Affiliated to Shenyang Medical College, Tiexi District, Shenyang, Liaoning Province, China.;
                        #(3)1. Department of Endocrinology and Metabolissm, The Affiliated Hospital of Jiangsu University, Institute of Endocrine and Metabolic Diseases, Jiangsu University, Zhenjiang, Jiangsu, China.;
                        #(4)1. Department of Endocrinology, Qilu Hospital of Shandong University, College of Medicine, Shandong University, Jinan, 250012, Shandong, China.;
                        #(5)1. Department of Health Management, Centre of General Practice, The Seventh Affiliated Hospital, Southern Medical University, No. 28, Desheng Road Section, Liguan Road, Lishui Town, Nanhai District, Foshan City, 528000, Guangdong Province, People's Republic of China. 2402312575@qq.com.;
                        #(6)1. Department of Urology, Jiangyin People's Hospital of Jiangsu Province, Jiangyin, Jiangsu, China.; 
                        #(7)7. Department of Neurology, Zhongshan Hospital Xiamen University, Xiamen 361004, Fujian, China. Electronic address: zhuangjingcong@gmail.com.; 
                        #(8)1. Department of Pulmonary and Critical Care Medicine, Zhujiang Hospital, Southern Medical University, 510280, Guangzhou, China.;
                        #(9)1. Tianjin Women's and Children's Health Center, Tianjin, China.;
                        #(10)1. Endoscopy, National Cancer Center/National Clinical Research Center for Cancer/Cancer Hospital, Chinese Academy of Medical Sciences and Peking Union Medical College, Beijing, China.;
                        #(11)1. Department of Neurology, Center for Cognitive Neurology, Institute of Clinical Neurology, Fujian Medical University Union Hospital, 29 Xinquan Road, 350001, Fuzhou, China.;
                        #1. Department of Urology, Zhongshan Hospital, Fudan University, No. 180 Fenglin Road, Shanghai, P. R. China.;
                        #1. Department of Orthopedics, Changhai Hospital, Naval Military Medical University, 168 Changhai Road, Shanghai, China.;
                        #情况(1)(9)
                        if($last3=~/Hospital/gi || $last3=~/University/gi || $last3=~/Institute/gi || $last3=~/Center/gi || $last3=~/College/gi || $last3=~/Academy/gi || $last3=~/Road/gi){
                            $mat{$aff_city}{$key} = $last2;
                        }elsif($last3=~/\d+/ && @aff_first>3){  
                            if($last3!~/[A-Za-z]/){ 
                                #情况(4)(5)
                                my $last4=$aff_first[-4];
                                $last4=~s/City//gi;   ###Foshan City;
                                $last4=trim($last4);
                                if($last4=~/University/gi || $last4=~/Hospital/gi || $last4=~/Institute/gi || $last3=~/College/gi || $last4=~/Road/gi){
                                    $mat{$aff_city}{$key} = $last2;   #此时，last4是单位或道路地址Xinquan Road之类，last2是城市；
                                }else{
                                    $mat{$aff_city}{$key} = $last4;
                                    $cityp{$last4}=$last2;   #此时，last4是城市，last2是省份；
                                }
                            }else{
                                $last3=~s/\d+//gi;$last3=trim($last3);
                                $mat{$aff_city}{$key} = $last3;
                                $cityp{$last3}=$last2;   #此时，last3是城市，last2是省份；
                            }
                        }else{ #情况(2)(3)(6)
                            $cityp{$last3}=$last2;   #此时，last3是城市，last2是省份；
                            $mat{$aff_city}{$key} = $last3;   
                        } 
                    }
                }
                
                $aff_first[0]=~s/\d\.\s+//gi;
                if($b[$i]=~/University/){
                    foreach my $key(@aff_first){
                        if($key=~/University/){
                            $feature=$key;
                        }
                    }
                }elsif($b[$i]=~/Academy/){
                    foreach my $key(@aff_first){
                        if($key=~/Academy/){
                            if($key=~/Chinese Academy of Sciences/){
                                $feature="Chinese Academy of Sciences";
                            }else{
                                $feature=$key;
                            }
                        }
                    }
                }elsif($b[$i]=~/College/){
                    foreach my $key(@aff_first){
                        if($key=~/College/){$feature=$key;}
                    }
                }elsif($b[$i]=~/Lab/){
                    foreach my $key(@aff_first){
                        if($key=~/Lab/){$feature=$key;}
                    }
                }elsif($b[$i]=~/Institute/){
                    foreach my $key(@aff_first){
                        if($key=~/Institute/){$feature=$key;}
                    }
                }elsif($b[$i]=~/Hospital/){
                    foreach my $key(@aff_first){
                        if($key=~/Hospital/){$feature=$key;}
                    }
                }elsif($b[$i]=~/BGI/){
                    $feature="BGI-Shenzhen";
                }else{
                    my $array_length = scalar @aff_first;
                    ###这里先把第一和第2个都存起来；后面做矩阵的时候再过滤；
                    
                    if($array_length>2){
                        $feature=$aff_first[1];
                    }else{
                        $feature=$aff_first[0];
                    }
                }
                
                next if($feature eq '');
                if($feature =~/\@/ && $feature =~ /(.*?)University/){
                    my $before_string = $1;
                    $feature = $before_string."University";
                }
                if($feature=~/Chinese Academy of Medical Science/){
                    $feature = "Chinese Academy of Medical Sciences";
                }
                if($feature=~/Shanghai Jiaotong/gi){
                    $feature =~ s/Jiaotong/Jiao Tong/gi;
                }
                if($feature=~/BGI Research/gi){
                    $feature = "BGI Research";
                }
                if($feature=~/Yat-Sen/){
                    $feature =~ s/Yat-Sen/Yat-sen/;
                }
                if($feature=~/Sun Yat-sen University Cancer Center/){
                    $feature = "Sun Yat-sen University Cancer Center";
                }
                if($feature=~/Peking University School and Hospital [of|for] Stomatology/){
                    $feature = "Peking University School and Hospital of Stomatology";
                }
                if($feature=~/Affiliated Hospital of (.*)$/gi){
                    $feature = "Affiliated Hospital of ".$1;
                }

                $feature =~ s/\&/and/gi;
                if($feature=~/(.*University)\s*and/){
                    $feature = $1;
                }

                $feature =~ s/\s*$//;
                $feature =~ s/^\s*[#"\d\.\-\@]*\s*//;    #去掉开头的数字和空格；
                $feature =~ s/[-]*Beijing\s*[\d]*$//; # 去除类似 Beijing 100700
                $feature =~ s/[\d]\s*$//;        #去掉结尾的数字和空格；
                $feature =~ s/\.//g;
                $feature =~ s/  / /;
                $feature =~ s/No\s+/No/g;
                $feature =~ s/\d$//gi;
                # 将字符串分割成单词数组
                my @words = split ' ', $feature; 
                foreach my $word (@words) {
                    $word = ucfirst $word; # 将每个单词的首字母转换为大写
                }
                $feature = join ' ', @words;
                $feature =~ s/Of/of/g;
                $feature =~ s/ For/ for/g;
                $feature =~ s/To /to /g;
                $feature =~ s/And/and/g;    
                $feature =~ s/Medicial/Medical/g;
                $feature =~ s/Sciences/Science/g;
                $feature =~ s/JiLin/Jilin/g;
                $feature =~ s/Centre/Center/g;
                $feature =~ s/SooChow/Soochow/g;
                $feature =~ s/Zheng\s*Zhou/Zhengzhou/g;
                $feature =~ s/Yat‑Sen/Yat‑sen/g;
                $feature =~ s/\s*Jiamusi 15400P//g;   
                $feature =~ s/\s*13Xianlin Road Nanjing//g;
                $feature =~ s/Guangdong Academy of Medical Science Guangdong/Guangdong Academy of Medical Science/gi;
                $feature =~ s/People' /People's /gi;
                $feature =~ s/Agriculture Science/Agricultural Science/gi;
                $feature =~ s/ Changsha 410083 Hunan China//gi;
                $feature =~ s/ Changsha 410083 PR China//gi;
                $feature =~ s/ Chengdu 610106 P R China//gi;
                $feature =~ s/Chang\' An University/Chang\'an University/g;
                $feature =~ s/University of CM/University of Chinese Medicine/g;
                $feature =~ s/Medicine The Second Clinical College of Guangzhou University of Chinese Medicine/Medicine/gi;
                $feature =~ s/University Guangzhou/University/gi;
                $feature =~ s/ChongQing/Chongqing/gi;
                $feature =~ s/UniversityFujian Medical UniversityBrain Science Institute of Putian University/University/gi;
                $feature =~ s/Fabrication and CAS Center For Excellence In Nanoscience/Fabrication/gi;
                $feature =~ s/China University of Geoscience$/China University of Geosciences/gi;
                ###去除第一个字符代表单位排位的；
                $feature =~ s/^[ABCDE\d]\s//g;
                $feature =~ s/University \w+ \d+$/University/gi;
                $feature =~ s/Medicine \w+ \d+$/Medicine/gi;
                $feature =~ s/Medicine University/Medical University/gi;
                $feature =~ s/Cerebrovascular Disease$/Cerebrovascular Diseases/gi;
                $feature =~ s/Beijing 100029 P R China//gi;
                $feature =~ s/North 3rd Ring East//gi;
                $feature =~ s/Meidical/Medical/gi;
                $feature =~ s/Hospital Binzhou/Hospital/gi;
                $feature =~ s/ChineseMedical/Chinese Medical/gi;
                $feature =~ s/Medicine Changchun/Medicine/gi;
                $feature =~ s/Medicine No89-9 Dongge Road/Medicine/gi;
                $feature =~ s/Technology Kunming/Technology/gi;
                $feature =~ s/Medical School Nanjing/Medical School/gi;
                $feature =~ s/Ming and Technology/Mining and Technology/gi;
                $feature =~ s/Mining Technology/Mining and Technology/gi;
                $feature =~ s/Mining and Technology Yinchuan College/Mining and Technology/gi;
                $feature =~ s/1219 Zhongguan West Road Ningbo 315201 China Taochen\@nimteaccn//gi;
                $feature =~ s/and Fujian Provincial Key Laboratory of Tumor Biotherapy Fuzhou//gi;
                $feature =~ s/Chao-Yang/Chaoyang/g;
                my $pattern1 = 'University 137 Liyushannan Road|University Changji Sorting|University Urumchi|University Urumqi|University Urumqi 8300|University Weihui 4531|University Xinxiang|University Hangzhou|University Xi\'an|University Xi\'an China|University Wenzhou|University Hangzhou|University Zhengzhou|University Zhengzhou 4500|University Zhengzhou Henan China|University Changsha|University Wuxi|University Jiangsu|University Jiaxing|University Jining|University Taizhou|University No25 Taiping Street|University Xiamen|University Shenyang|University Nantong|University Changchun|University No';
                my $pattern2 = 'University Nanjing|University Hohhot|University Luzhou|University Nanning|University Yantai|University Fuzhou|University Quanzhou|University Ganzhou|University Shanghai|University Shanghai Cancer Center Shanghai 200|University Shanghai Medical College Shanghai 200|University Shanghai Medical School|University Taizhou Institute of Health Science|University 668 Jinhu Road|University Dongan Road|University Qingdao|University Xuzhou|University Harbin|University Guiyang|University Medical College|University Taian|University Danyang|University\) Baotou';
                my $pattern3 = 'College Anhui Province|College Bengbu|College Changhuai Road|College Chengdu|College Shantou|College Shenyang|College Luzhou|College Changzhi|College Guangdong|College 163 Shoushan Road|College Wuhu|College 22 West Wenchang Road|College Nanchong|College Zunyi';
                my $pattern4 = 'Hospital Capital Medical University National Center For Children\'s Health Beijing China|Hospital Affiliated to Capital Medical University|Hospital of Capital Medical University|Hospital Affiliated to Capital Medical University|Hospital of Capital Medical University|Hospital Fuzhou';
                $feature =~ s/($pattern1)/University/g;
                $feature =~ s/($pattern2)/University/g;
                $feature =~ s/($pattern3)/College/g;
                $feature =~ s/($pattern4)/Hospital/g;
                if($feature =~ /\w+\s*\(/){
                    my @arr=split /\(/,$feature;
                    $feature=$arr[0];
                }
                if($feature =~ /\//){
                    my @arr=split /\//,$feature;
                    $feature=$arr[0];
                }
                $feature =~ s/\d+\s*$//g;
                $feature=~s/\)$//gi;
                $feature=~s/\s+$//gi;
                $feature=~s/^\s+//gi;
                $feature=~s/^\(//gi;
                $feature=~s/^\'//gi;
                next if($feature eq '');
                next if($feature =~ /^and/);
                next if($feature =~ /Laboratory of Marine Ecosystem and Biogeochemistry/);
                #next if(exists $mat{$feature}{$key});
                my $text = "China-US";
                next if($feature =~ /$text/);
                $danwei{$feature}=1;            
                next if($feature=~/\#/ || $feature=~/\</ || $feature=~/\*/ || $feature=~/\)/ || $feature=~/\>/ || $feature=~/^\d+/);
                $countf{$feature}++;
                
                if($i==0){
                    $first_danwei=$feature;
                    $labelfirst{$key}++;
                }
                #else{
                #    unless(exists $labelfirst{$key}){ 
                #        $first_danwei=$feature;
                #    }
                #}
            }
            
            next if($first_danwei eq '');
            ###241031输出文章第一单位、城市、省份；
            my $first_danwei_out=$first_danwei;
            $first_danwei_out=~s/\s/\_/gi;
            $mat{'First_danwei'}{$key} = $first_danwei_out;
            
            ###排名归一化得分；
            my $aff_rank="Aff_RankNormalized";
            ###实际排名数；
            my $aff_paiming="Aff_Rankvalue";
            $countf{$aff_rank}++;
            $countf{$aff_paiming}++;
            if(exists $rank_World{$first_danwei}){
                $mat{$aff_paiming}{$key}=$rank_World{$first_danwei};
                if($rank_World{$first_danwei}<=50){
                    $mat{$aff_rank}{$key}=5;
                }elsif($rank_World{$first_danwei}<=100 && $rank_World{$first_danwei}>50){
                    $mat{$aff_rank}{$key}=4;
                }elsif($rank_World{$first_danwei}<=150 && $rank_World{$first_danwei}>100){
                    $mat{$aff_rank}{$key}=3;
                }elsif($rank_World{$first_danwei}<=200 && $rank_World{$first_danwei}>150){
                    $mat{$aff_rank}{$key}=2;
                }else{
                    $mat{$aff_rank}{$key}=1;
                }
            }else{
                $mat{$aff_rank}{$key}=0;
                $mat{$aff_paiming}{$key}=1000;
                ###如果该单位排名没上前1000名，就赋值为1000；
            }
            
            ### Nature index, 20240818;
            my $nature_index="NatureIndex_rank";
            if(exists $natureind{$first_danwei}){
                $mat{$nature_index}{$key} = $natureind{$first_danwei};
            }else{
                $mat{$nature_index}{$key} = 8000;
                ###如果该单位排名没上Natureindex榜单(最后一名为7782)，就赋值为8000；
            }
            
        }
        if($col==2){
            ###判断是否存在高被引科学家；需要作者和单位对应上才算；
            my $author_high="HighCitedAuthor";
            $countf{$author_high}++;
            my @b=split /\;/,$a[$col];   ### @b 存储了所有作者；
            my $last=@b; $last=$last-2;  ### 13个作者的话，对应@b中有14个元素（;有13个，分隔为14个元素），实际作者的下标是0...12;
            for(my $k=0;$k<=$last;$k++){
                my $au=$b[$k];
                $au =~ s/\s+//gi;
                $au =~ s/^\d+\.//gi;
                $au =~ s/,/-/gi;
                next if($au eq '');
                my %highmark=();
                foreach my $aff(keys %danwei){
                    my $au_aff=$au."-".$aff;
                    next if(exists $highmark{$au});
                    if(exists $highauthor{$au_aff}){
                        $highmark{$au}=1;
                        if($k == $last){
                            $mat{$author_high}{$key} += 5;
                            #print "last: $author_high\t$key\t$k\t$au_aff\n";
                        }elsif($k == 0){
                            $mat{$author_high}{$key} += 4;
                            #print "font-1: $author_high\t$key\t$k\t$au_aff\n";
                        }elsif($k == $last-1){
                            $mat{$author_high}{$key} += 3;
                            #print "last-1: $author_high\t$key\t$k\t$au_aff\n";
                        }elsif($k == 1){
                            $mat{$author_high}{$key} += 2;
                            #print "font-2: $author_high\t$key\t$k\t$au_aff\n";
                        }else{
                            $mat{$author_high}{$key} += 1;
                            #print "center: $author_high\t$key\t$k\t$au_aff\n";
                        }
                    }
                }
            }
        }
        elsif($col==6){
            $feature="IF2023_Normalized";
            my $IFscore="IF2023_value";
            $countf{$feature}++;
            $countf{$IFscore}++;
            $mat{$IFscore}{$key}=$value;
            if($value eq "NA" || $value eq 'None' || $value eq ''){
                $mat{$feature}{$key}=0;
                $mat{$IFscore}{$key}=0;
            }elsif($value eq '<0.1' || ($value >0 && $value<5)){
                $mat{$feature}{$key}=1;
            }elsif($value>=5 && $value<10){
                $mat{$feature}{$key}=2;
            }elsif($value>=10 && $value<20){
                $mat{$feature}{$key}=3;
            }elsif($value>=20 && $value<30){
                $mat{$feature}{$key}=4;
            }elsif($value>=30){
                $mat{$feature}{$key}=5;
            }else{
                $mat{$feature}{$key}=0;
            }
        }
        elsif($col==10){
            ###基金资助情况；
            $feature="Grant";
            my $feature2="Grantnew";
            $countf{$feature}++;
            $countf{$feature2}++;
            if($value eq "None" || $value eq ""){
                $mat{$feature}{$key}=0;
                $mat{$feature2}{$key}=0;
            }else{
                my @grants=split /\;/,$value;
                if($value=~/National/){
                    $mat{$feature}{$key}=4;
                }elsif($value=~/Post/ && $value=~/doctoral/ && $value=~/China/){
                    ###China Postdoctoral Science Foundation;
                    $mat{$feature}{$key}=3;
                }elsif($value=~/Province/ || $value=~/Provincial/ || $value=~/Chongqing/ || $value=~/Shanghai/ || $value=~/Beijing/ || $value=~/Tianjin/){
                    $mat{$feature}{$key}=2;
                }else{
                    $mat{$feature}{$key}=1;
                }
                
                ### 20241007; 对基金的顺序进行考虑；
                my @b=();
                if($a[$col]=~/\/\;/){
                    @b=split /\/\;/,$a[$col];   ### @b 存储了所有基金；
                }else{
                    @b=split /\;/,$a[$col];   ### @b 存储了所有基金；
                }
                my $last=@b; $last=$last-2;  ### 13个基金的话，对应@b中有14个元素（;有13个，分隔为14个元素），实际作者的下标是0...12;
                for(my $k=0;$k<=$last;$k++){
                    my $grant=$b[$k];
                    next if($grant eq '');
                    my $index=1/($k+1);
                    if($grant=~/National/){
                        $mat{$feature2}{$key}+= sprintf("%.4f",4*$index);
                    }elsif($grant=~/Post/ && $grant=~/doctoral/ && $grant=~/China/){
                        $mat{$feature2}{$key}+= sprintf("%.4f",3*$index);
                    }elsif($value=~/Province/ || $value=~/Provincial/ || $value=~/Chongqing/ || $value=~/Shanghai/ || $value=~/Beijing/ || $value=~/Tianjin/){
                        $mat{$feature2}{$key}+= sprintf("%.4f",2*$index);
                    }else{
                        $mat{$feature2}{$key}+= sprintf("%.4f",1*$index);
                    }
                }
            }
        }
        #2024.8.16日添加文章类别的信息；
        elsif($col==11){
            ###文章类型，是Article还是Review之类的；
            my $manuscriptType="manuscriptType";
            $countf{$manuscriptType}++;
            if($value =~ /Review/){
                $mat{$manuscriptType}{$key}=1;
            }elsif($value =~ /Article/ || $value =~ /Trial/){
                $mat{$manuscriptType}{$key}=2;
            }else{
                $mat{$manuscriptType}{$key}=0;
            }
        }
        #5年影响因子；
        elsif($col==12){
            $feature="IF5Year";
            my $IF5year_value="IF5Year_value";
            $countf{$feature}++;
            $countf{$IF5year_value}++;
            $mat{$IF5year_value}{$key} = $value;
            if($value eq "NA"  || $value eq 'nan'){
                $mat{$feature}{$key}=0;
                $mat{$IF5year_value}{$key}=0;
            }elsif( $value eq '<0.1' || ($value >0 && $value<5)){
                $mat{$feature}{$key}=1;
            }elsif($value>=5 && $value<10){
                $mat{$feature}{$key}=2;
            }elsif($value>=10 && $value<20){
                $mat{$feature}{$key}=3;
            }elsif($value>=20 && $value<30){
                $mat{$feature}{$key}=4;
            }elsif($value>=30){
                $mat{$feature}{$key}=5;
            }else{
                $mat{$feature}{$key}=0;
                $mat{$IF5year_value}{$key}=0;
            }
        }
        elsif($col==13){
            $feature="JCRFenqu";
            $countf{$feature}++;
            if($value eq "NA" || $value eq 'nan'){
                $mat{$feature}{$key}=0;
            }elsif($value eq 'Q4'){
                $mat{$feature}{$key}=1;
            }elsif($value eq 'Q3'){
                $mat{$feature}{$key}=2;
            }elsif($value eq 'Q2'){
                $mat{$feature}{$key}=3;
            }elsif($value eq 'Q1'){
                $mat{$feature}{$key}=4;
            }else{
                $mat{$feature}{$key}=0;
            }
        }
        elsif($col==15){
            $feature="YuJing";
            my $heimingdan="黑名单";
            my $di="低度预警";
            my $zhong="中度预警";
            my $gao="高度预警";
            $countf{$feature}++;
            if($value eq "NA" || $value eq 'nan'){
                $mat{$feature}{$key}=0;
            }elsif($value=~/$gao/){
                $mat{$feature}{$key}=4;
            }elsif($value=~/$zhong/){
                $mat{$feature}{$key}=3;
            }elsif($value=~/$di/){
                $mat{$feature}{$key}=2;
            }elsif($value=~/$heimingdan/){
                $mat{$feature}{$key}=1;
            }elsif($value eq '非预警'){
                $mat{$feature}{$key}=0;
            }else{
                $mat{$feature}{$key}=0;
            }
        }
        elsif($col==16){
            $feature="SCIType";
            $countf{$feature}++;
            if($value eq "20230321已剔除" || $value eq 'NA'){
                $mat{$feature}{$key}=0;
            }elsif($value eq 'ESCI'){
                $mat{$feature}{$key}=1;
            }elsif($value eq 'SSCI' || $value eq 'AHCI'){
                $mat{$feature}{$key}=2;
            }elsif($value eq 'SCIE/OnHold'){
                $mat{$feature}{$key}=3;
            }elsif($value eq 'SCIE/SSCI'){
                $mat{$feature}{$key}=4;
            }elsif($value eq 'SCIE'){
                $mat{$feature}{$key}=5;
            }else{
                $mat{$feature}{$key}=0;
            }
        }
        elsif($col==17){
            $feature="OAType";
            my $OA_rate = "OA_rate";
            $value =~s/\%//gi;
            $mat{$OA_rate}{$key} = $value;
            my $daicha = "待查";
            my $fou = "否";
            my $shi = "是";
            $countf{$feature}++;
            $countf{$OA_rate}++;
            if($value eq "NA" || $value eq $daicha){
                $mat{$feature}{$key}=0;
                $mat{$OA_rate}{$key} = 0;
            }elsif($value eq $fou){
                $mat{$feature}{$key}=0;
                $mat{$OA_rate}{$key} = 0;
            }elsif($value eq $shi){
                $mat{$feature}{$key}=5;
                $mat{$OA_rate}{$key} = "100%";
            }else{
                $value =~s/\%//gi;
                $mat{$feature}{$key}=sprintf("%.0f", ($value * 5)/100);
            }
        }
        elsif($col==18){
            $feature="CASDaFenqu2023";
            my $articleDomain="articleDomain";
            my $ty1="综合";
            my $ty2="生物";
            my $ty3="医学";
            $countf{$feature}++;
            $countf{$articleDomain}++;
            if($value =~ /$ty1/){
                $mat{$articleDomain}{$key} = 2;
            }elsif($value =~ /$ty2/ || $value =~ /$ty3/){
                $mat{$articleDomain}{$key} = 1;
            }else{
                $mat{$articleDomain}{$key} = 0;
            }
            
            if($value eq "NA" || $value eq 'None'){
                $mat{$feature}{$key}=0;
            }elsif($value=~/1/ && $value=~/Top/){
                $mat{$feature}{$key}=6;
            }elsif($value=~/2/ && $value=~/Top/){
                $mat{$feature}{$key}=4;
            }elsif($value=~/4/){
                $mat{$feature}{$key}=1;
            }elsif($value=~/3/){
                $mat{$feature}{$key}=2;
            }elsif($value=~/2/){
                $mat{$feature}{$key}=3;
            }elsif($value=~/1/){
                $mat{$feature}{$key}=5;
            }else{
                $mat{$feature}{$key}=0;
            }
        }
        elsif($col==19){
            $feature="CASXiaoFenqu2023";
            $countf{$feature}++;
            if($value eq "NA" || $value eq 'None'){
                $mat{$feature}{$key}=0;
            }elsif($value=~/1/){
                $mat{$feature}{$key}=4;
            }elsif($value=~/2/){
                $mat{$feature}{$key}=3;
            }elsif($value=~/3/){
                $mat{$feature}{$key}=2;
            }elsif($value=~/4/){
                $mat{$feature}{$key}=1;
            }else{
                $mat{$feature}{$key}=0;
            }
        }
        elsif($col==20){
            $feature="CASDaFenqu2022";
            $countf{$feature}++;
            if($value eq "NA" || $value eq ''){
                $mat{$feature}{$key}=0;
            }elsif($value=~/1/ && $value=~/Top/){
                $mat{$feature}{$key}=6;
            }elsif($value=~/2/ && $value=~/Top/){
                $mat{$feature}{$key}=4;
            }elsif($value=~/4/){
                $mat{$feature}{$key}=1;
            }elsif($value=~/3/){
                $mat{$feature}{$key}=2;
            }elsif($value=~/2/){
                $mat{$feature}{$key}=3;
            }elsif($value=~/1/){
                $mat{$feature}{$key}=5;
            }else{
                $mat{$feature}{$key}=0;
            }
        }
        elsif($col==21){
            $feature="CASXiaoFenqu2022";
            $countf{$feature}++;
            if($value eq "NA" || $value eq ''){
                $mat{$feature}{$key}=0;
            }elsif($value=~/1/){
                $mat{$feature}{$key}=4;
            }elsif($value=~/2/){
                $mat{$feature}{$key}=3;
            }elsif($value=~/3/){
                $mat{$feature}{$key}=2;
            }elsif($value=~/4/){
                $mat{$feature}{$key}=1;
            }else{
                $mat{$feature}{$key}=0;
            }
        }
        ########## 22/24/25为2024年8月16日新添加;
        elsif($col==22){     
            $feature="WenzhangNumber2023";
            $countf{$feature}++;
            if($value eq "NA" || $value eq ""){
                $mat{$feature}{$key}=0;
            }else{
                $mat{$feature}{$key}=$value;
            }
        }
        elsif($col==24){
            $feature="Ziyinlv2023";
            $countf{$feature}++;
            if($value eq "NA" || $value eq ""){
                $mat{$feature}{$key}=0;
            }else{
                $mat{$feature}{$key}=$value;
            }
        }
        elsif($col==25){
            $feature="LveduoJournal";
            $countf{$feature}++;
            if($value eq "MDPI" || $value =~ /FRONTIERS/ || $value =~ /HINDAWI/){
                $mat{$feature}{$key}=1;
            }else{
                $mat{$feature}{$key}=0;
            }
            
            ##### 判断是否为CNS子刊并赋值；
            my $CNSsubjournal="CNSsubjournal";
            my $MedTopjournal="MedTopjournal";
            $countf{$CNSsubjournal}++;
            $countf{$MedTopjournal}++;
            my $Journalname = $a[5];   ###第6列为杂志全名称；
            $a[6]=0 if($a[6] eq "NA" || $a[6] eq 'None' || $a[6] eq '<0.1' || $a[6] eq '');
            if($value eq "CELL PRESS"){
                ###20+以上的算cell子刊，虽然这里没有带cell名字；
                if(($Journalname =~ /cell/i || $Journalname =~ /Joule/i || $Journalname =~ /Immunity/i || $Journalname =~ /Innovation/i) && $a[6] >= 10){
                    $mat{$CNSsubjournal}{$key} = 4;
                }elsif($a[6] >= 10){
                    $mat{$CNSsubjournal}{$key} = 3;
                }elsif($a[6] >= 5){
                    $mat{$CNSsubjournal}{$key} = 2;
                }elsif($a[6] < 5){
                    $mat{$CNSsubjournal}{$key} = 1;
                }else{
                    $mat{$CNSsubjournal}{$key} = 0;
                }
            }elsif($value =~ /NATURE/){
                if($Journalname =~ /NATURE/i && $a[6] >= 10){
                    $mat{$CNSsubjournal}{$key} = 4;
                }elsif($a[6] >= 10){
                    $mat{$CNSsubjournal}{$key} = 3;
                }elsif($a[6] >= 5){
                    $mat{$CNSsubjournal}{$key} = 2;
                }elsif($a[6] < 5){
                    $mat{$CNSsubjournal}{$key} = 1;
                }else{
                    $mat{$CNSsubjournal}{$key} = 0;
                }
            }elsif($value eq "AMER ASSOC ADVANCEMENT SCIENCE"){
                if($Journalname =~ /Science/i && $a[6] >= 10){
                    $mat{$CNSsubjournal}{$key} = 4;
                }elsif($a[6] >= 10){
                    $mat{$CNSsubjournal}{$key} = 3;
                }elsif($a[6] >= 5){
                    $mat{$CNSsubjournal}{$key} = 2;
                }elsif($a[6] < 5){
                    $mat{$CNSsubjournal}{$key} = 1;
                }else{
                    $mat{$CNSsubjournal}{$key} = 0;
                }
            }
            ###医学类的4种顶刊及其子刊；
            elsif($value eq "MASSACHUSETTS MEDICAL SOC"){
                if($Journalname eq "The New England journal of medicine"){
                    $mat{$MedTopjournal}{$key} = 4;
                }else{
                    $mat{$MedTopjournal}{$key} = 0;
                }
            }elsif($value eq "BMJ PUBLISHING GROUP"){
                if($Journalname =~ /BMJ/i && $a[6] >= 10){
                    $mat{$MedTopjournal}{$key} = 4;
                }elsif($a[6] >= 10){
                    $mat{$MedTopjournal}{$key} = 3;
                }elsif($a[6] >= 5){
                    $mat{$MedTopjournal}{$key} = 2;
                }elsif($a[6] < 5){
                    $mat{$MedTopjournal}{$key} = 1;
                }else{
                    $mat{$MedTopjournal}{$key} = 0;
                }
            }elsif($value eq "AMER MEDICAL ASSOC"){
                if($Journalname =~ /JAMA/i && $a[6] >= 10){
                    $mat{$MedTopjournal}{$key} = 4;
                }elsif($a[6] >= 10){
                    $mat{$MedTopjournal}{$key} = 3;
                }elsif($a[6] >= 5){
                    $mat{$MedTopjournal}{$key} = 2;
                }elsif($a[6] < 5){
                    $mat{$MedTopjournal}{$key} = 1;
                }else{
                    $mat{$MedTopjournal}{$key} = 0;
                }
            }elsif($value eq "ELSEVIER SCIENCE INC" && $Journalname =~ /Lancet/i){
                if($Journalname =~ /Lancet/i && $a[6] >= 10){
                    $mat{$MedTopjournal}{$key} = 4;
                }elsif($a[6] >= 10){
                    $mat{$MedTopjournal}{$key} = 3;
                }elsif($a[6] >= 5){
                    $mat{$MedTopjournal}{$key} = 2;
                }elsif($a[6] < 5){
                    $mat{$MedTopjournal}{$key} = 1;
                }else{
                    $mat{$MedTopjournal}{$key} = 0;
                }
            }
            
        }
        elsif($col==26){
            $feature="KexieZhuoyue";
            $countf{$feature}++;
            if($value eq "NA"){
                $mat{$feature}{$key}=0;
            }elsif($value eq 'zhongdian'){
                $mat{$feature}{$key}=1;
            }elsif($value eq 'lingjun'){
                $mat{$feature}{$key}=2;
            }else{
                $mat{$feature}{$key}=0;
            }
        }
    }
}

my @zhixia=("Beijing","Shanghai","Hong Kong","Macao","Chongqing","Tianjin");
foreach my $zhixiashi(@zhixia){
    $cityp{$zhixiashi}=$zhixiashi;
}

my @pmids=sort keys(%pmids);
my $head_out=join "\t",@pmids;
open OUT,">$out" or die $!;
print OUT "Features\t$head_out\n";

foreach my $feature(sort keys %mat){
    foreach my $pmid(@pmids){
        if($feature eq 'City'){
            my $prov = 0;
            my $city = 0;
            if(exists $mat{$feature}{$pmid} && $mat{$feature}{$pmid} ne ''){
                $city = $mat{$feature}{$pmid};
                if(exists $cityp{$city}){
                    $prov = $cityp{$city};
                }else{
                    $prov = 0;
                }
                $mat{'Provice'}{$pmid}= $prov;
            }else{
                $city = 0;
                $mat{'Provice'}{$pmid}= 0;
            }
        }
        unless(exists $mat{$feature}{$pmid}){
            $mat{$feature}{$pmid}=0;
            if($feature eq 'NatureIndex_rank'){
                $mat{$feature}{$pmid}=8000;
            }
        }
    }
}

foreach my $feature(sort keys %mat){
    print OUT $feature;
    foreach my $pmid(@pmids){
        my $value=$mat{$feature}{$pmid};
        #$value=~s/\s+//gi; $value=~s/[\.\#\&\\\/\(\)]//gi;
        $value=~s/\s+//gi; $value=~s/[\#\&\\\/\(\)]//gi;  #去掉“\.”，不然value里面带小数点的值会被改变。
        if($feature eq 'City' && length($value) > 40){
            $value = substr($value, 0, 40);
        }
        if($feature eq 'City' && $value eq ''){
            $value = 0;
        }
        print OUT "\t$value";
    }
    print OUT "\n";
}
close OUT;


sub trim {
    my ($string) = @_;
    $string =~ s/^\s+|\s+$//g;  # 去掉前后空格
    return $string;
}

sub has_garbled_text {
    my ($string) = @_;
    
    # 尝试将字符串解码为 UTF-8
    eval {
        decode('UTF-8', $string, Encode::FB_CROAK);
    };
    
    return $@ ? 1 : 0;  # 如果出现错误，表示有乱码
}
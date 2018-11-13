clear all
thr = 0.4;
MINSCANS = 130;
%INPUT_FILE='/home/ALDRECENTRUM/benjamin.garzon/Data/DAD/processed/RS/RealignParameter/FD_Power.csv';
%OUTPUT_FILE='/home/ALDRECENTRUM/benjamin.garzon/Data/DAD/processed/RS/RealignParameter/FD_Power_scrubbed.csv';

thr = 0.4;
MINSCANS = 300;
INPUT_FILE='/home/ALDRECENTRUM/benjamin.garzon/Data/DAD/processed/GNG/RealignParameter/FD_Power.csv';
OUTPUT_FILE='/home/ALDRECENTRUM/benjamin.garzon/Data/DAD/processed/GNG/RealignParameter/FD_Power_scrubbed0.4.csv';

young = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 0 1 1 1 1 1 1 1 1 1 1 1 0 0 1 1]==1;

FD = load(INPUT_FILE);
FD(FD > thr) = nan;
for i = 1:size(FD, 2)
    
   x = FD(:, i);   
   w = find(isnan(x));
   rem = [w; w + 1; w + 2; w - 1];
   rem(rem < 1) = [];
   rem(rem > numel(x)) = [];
   x(rem) = [];
   if MINSCANS <= numel(x) 
   clean_FD(i) = mean(x(1:MINSCANS));
   else
       clean_FD(i) = nan;
   end
  
end
sum(~isnan(clean_FD))
%hold on 
[h, p ] = ttest2(clean_FD(young), clean_FD(~young))

dlmwrite(OUTPUT_FILE, clean_FD, 'delimiter',',')



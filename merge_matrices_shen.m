%  function merge_matrices_shen
%  clear all
% 
% subject_list='D02 D03 D04 D05 D07 D08 D11 D13 D14 D15 D16 D17 D18 D19 D20 D21 D22 D23 D24 D25 D26 D29 D30 D31 D33 D34 D35 D36 D37 D38 D39 D40 D42 D43 D46 D47 D48 D49 D50 D52 D55 D56 D58 D60 D61 D62 D63 D64 D65 D66 D67 D70 D72 D80 D82 D83 D84 D85 D86 D90';
% matrix_file = 'zFC_150.csv';
% merged_matrices_file = 'zFC_all_150.mat';
% cd('~/Data/DAD/RS/ConnectomeShen')
% codes_file = '~/Data/DAD/RS/parcellations/shen/Group_seg150_BAindexing_setA.txt';
% 
% test(subject_list, matrix_file, codes_file, merged_matrices_file);
% end

function merge_matrices_shen(subject_list, matrix_file, codes_file, merged_matrices_file)
%function test(subject_list, matrix_file, codes_file, merged_matrices_file)

subjects = strread(subject_list,'%s','delimiter',' ');

info = readtable(codes_file, 'Delimiter', ',')
labels = info.name;
regions = info.subunnit;

merged_matrices = [];
merged_matrices_mat = [];
for i=1:numel(subjects)
display(subjects{i});

M = load(fullfile('.',subjects{i}, matrix_file));
M(isinf(M)) = 0;
if i==1
    merged_matrices = M;
else
    merged_matrices = cat(3, merged_matrices, M);

end
  
end
nans = any(isnan(merged_matrices), 3);
valid = sum(nans) < numel(labels) ;
valid_labels = labels(valid);
valid_regions = regions(valid);
valid_indices = find(valid);

for i=1:numel(subjects)    
    M = merged_matrices(:,:,i);
    M = M(valid, valid);
    M(isinf(M)) = 0;
    
    merged_matrices_mat = [merged_matrices_mat; squareform(M)];    
end

display(['Total valid indices: ' num2str(numel(valid_labels))])
save(merged_matrices_file, 'merged_matrices', 'labels', 'subjects','valid_regions','valid_indices', 'valid_labels', 'merged_matrices_mat') 

end
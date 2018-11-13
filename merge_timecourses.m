function merge_timecourses(subject_list, tcourses_file, codes_file, merged_tcourses_file)

subjects = strread(subject_list,'%s','delimiter',' ');

fid = fopen(codes_file);
info = textscan(fid, '%d\t%s');
fclose(fid);
%codes = info{1};
labels = info{2};

merged_tcourses = [];
for i=1:numel(subjects)
display(subjects{i});

M = load(fullfile('.',subjects{i}, tcourses_file));
if i==1
    merged_tcourses = M;
else
    merged_tcourses = cat(3, merged_tcourses, M);
    
end
   
end

% select those which are cortical 
subcortical_labels = {'thalamus','caudate','putamen','pallidum','accumbens','hippocampus','amygdala','insula','brainstem'};
indices = [];
for i=1:numel(labels)
    for j =1:numel(subcortical_labels)

       if ~isempty(strfind(labels{i}, subcortical_labels{j}))
           indices = [indices i];
       end
    end
end
merged_tcourses_cortical = merged_tcourses;
merged_tcourses_cortical(:, indices, :)= [];

cortical_labels = labels;
cortical_labels(indices) = [];
save(merged_tcourses_file, 'merged_tcourses', 'labels', 'subjects','merged_tcourses_cortical','cortical_labels') 

end
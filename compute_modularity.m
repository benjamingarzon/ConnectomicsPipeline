% compute modularity of connectome
close all;
clear all;
addpath ~/Software/BCT
addpath /usr/local/freesurfer/matlab/

% constants
thr = 1;
TAU = 0;
REPS = 1000;
N_gammas =  30;
MINMODSIZE = 0;

% filenames
DATA_DIR = '~/Data/DAD/';
task1.file = fullfile(DATA_DIR, 'processed/TAB/Connectome0.3/zFC_all_150_0.3_TAB.mat');
task2.file = fullfile(DATA_DIR, 'processed/GNG/Connectome0.3/zFC_all_150_0.3_GNG.mat');
parcellation_file = fullfile(DATA_DIR, 'parcellations/shen/fconn_atlas_150_2mm.nii');
coords_file = fullfile(DATA_DIR, 'parcellations/shen/', 'parc_shen_150.coords.csv');
modules_dir1 = fullfile(DATA_DIR, 'processed/TAB/modules');
mkdir(modules_dir1);
modules_dir2 = fullfile(DATA_DIR, 'processed/GNG/modules');
mkdir(modules_dir2);

module_parcellation_file = fullfile(modules_dir1, 'fconn_atlas_150_2mm_modules.nii');
modules_file1 = fullfile(modules_dir1, 'zFC_all_150_0.3_TAB_modules.mat');
modules_file2 = fullfile(modules_dir2, 'zFC_all_150_0.3_GNG_modules.mat');
%surface_file = fullfile(BRAINNET_DIR,'Data/SurfTemplate/BrainMesh_ICBM152.nv');
%config_file = fullfile(modules_dir, 'BrainNet_cfg.mat');

%open data
task1 = load(task1.file);
task2 = load(task2.file);

mri = MRIread(parcellation_file);
parc = mri.vol;
labels = task1.labels;

merged_matrices = cat(3, task1.merged_matrices, task2.merged_matrices);
zFC_mean = mean(merged_matrices, 3);
valid = any(~isnan(zFC_mean));

tmat = zFC_mean*0;
for i=1:numel(valid)
    for j=1:numel(valid)
    x = squeeze(merged_matrices(i,j,:));
    
    tmat(i, j) = ttest(x);
    
end
end

adj = tanh(zFC_mean(valid, valid));
adj(tmat(valid, valid)~=1) = 0;

adj(adj < 0) = 0;



gammas = linspace(1, 2, N_gammas);
consensus = adj*0;

allM = zeros(size(adj,1), REPS);

if 0
    for i = 1:N_gammas
        display(i)
        allM = zeros(size(adj,1), REPS);
        gamma = gammas(i);
        for j = 1 : REPS
            [M Q(i)] = community_louvain(adj, gamma);
            allM(:,j ) = M;
        end
        
        D = agreement(allM)/REPS;
        C = consensus_und(D, TAU, REPS);
        maxM(i) = numel(unique(M));
        allC(:,i) = C;
        maxC(i) = numel(unique(C));
        freqs = tabulate(C);
        minC(i) = min(freqs(:,2));
    end
    
    NMI = zeros(N_gammas);
    VIn = zeros(N_gammas);
    
% compute normalized mutual information (symmetric uncertainty)
    for i = 1:N_gammas
        for j = 1:N_gammas            
            [VIn(i, j) NMI(i, j)] = partition_distance(allC(:, i), allC(:, j));            
        end
    end
    
    meanNMI = (sum(NMI) - 1)/(N_gammas - 1);
    meanVIn = (sum(VIn) - 1)/(N_gammas - 1);
    minNMI = min(NMI);
        
    [m, index] = max(meanNMI);
    %[m, index] = min(meanVIn);
    
% plot NMI and Vin
    
    figure
    subplot(1,4,1)
    plot(gammas, maxM, 'b.-')
    hold on
    plot(gammas, maxC, 'b.-', 'LineWidth', 2)
    ylabel('N clusters')
    subplot(1,4,2)
    plot(gammas, meanNMI, '.-')
    hold on
    plot(gammas, minNMI, 'r.-')
    plot(gammas, 4*meanVIn, 'g.-')
    ylabel('Mean NMI')
    
    subplot(1,4,3)
    imagesc(NMI)
    subplot(1,4,4)
    plot(gammas, minC, '.-')
    ylabel('Min Cluster Size')
    
    partition_strict = allC(:, index);
else
    
% fix value for gamma and compute modularity
    gamma = 2.3;
    for j = 1 : REPS
        [M Q] = community_louvain(adj, gamma);
       
        allM(:,j ) = M;
    end
    
    D = agreement(allM)/REPS;
    C = consensus_und(D, TAU, REPS);
    
    partition_strict = C;
end

   
% plot adj matrix
    figure
    imagesc(adj);
    colormap jet
    colorbar

    
% clean smaller modules of the partition and renumber  
freqs = tabulate(C)

for i = freqs(freqs(:,2)<=MINMODSIZE, 1)'
    display(sum(partition_strict==i))
    partition_strict(partition_strict==i) = 0;
    
end

j = 1;
for i = unique(partition_strict)'
    partition_strict(partition_strict == i) = j;
    j = j + 1;
end

partition = valid*0;
partition(valid) = partition_strict;

% reduce the FC matrix in internal and external connectivities
for i = 1:max(partition)
    for j = 1:max(partition)
        m = zFC_mean(partition == i, partition == j);
        
        if (i == j)
            m(isinf(m)) = 0;
            zFC_mean_partition(i, j) = mean(squareform(m));
        else
            zFC_mean_partition(i, j) = mean(m(:));
        end
        
        for s = 1:size(task1.merged_matrices, 3)
            m1 = task1.merged_matrices(partition == i, partition == j, s);
            
            
            if (i == j)
                m1(isinf(m1)) = 0;
                task1.merged_matrices_partition(i, j, s) = mean(squareform(m1));
            else
                task1.merged_matrices_partition(i, j, s) = mean(m1(:));
            end
            
        end
        
         for s = 1:size(task2.merged_matrices, 3)
            m2 = task2.merged_matrices(partition == i, partition == j, s);
            
            
            if (i == j)
                m2(isinf(m2)) = 0;
                task2.merged_matrices_partition(i, j, s) = mean(squareform(m2));
            else
                task2.merged_matrices_partition(i, j, s) = mean(m2(:));
            end
            
        end
        
        
    end
end

% flatten matrices
task1.merged_matrices_partition_mat = [];
task1.merged_matrices_mat = [];

for s = 1:size(task1.merged_matrices, 3)
    m = task1.merged_matrices_partition(:, :, s);
    d = diag(m);
    
    task1.merged_matrices_mat(s, :) = squareform(task1.merged_matrices(valid, valid, s));
    task1.merged_matrices_partition_mat = [task1.merged_matrices_partition_mat; squareform(m - diag(d)) d'];
end

task2.merged_matrices_partition_mat = [];
task2.merged_matrices_mat = [];

for s = 1:size(task2.merged_matrices, 3)
    m = task2.merged_matrices_partition(:, :, s);
    d = diag(m);

    task2.merged_matrices_mat(s, :) = squareform(task2.merged_matrices(valid, valid, s));
    task2.merged_matrices_partition_mat = [task2.merged_matrices_partition_mat; squareform(m - diag(d)) d'];
end

% plot partition matrix
figure
imagesc(zFC_mean_partition, [-.5 .5])
colorbar

% save results
valid_indices = find(valid);
valid_labels = labels(valid);

%valid_regions = task2.valid_regions;

merged_matrices = task1.merged_matrices;
merged_matrices_mat = task1.merged_matrices_mat;
merged_matrices_partition = task1.merged_matrices_partition;
merged_matrices_partition_mat = task1.merged_matrices_partition_mat;
subjects = task1.subjects;
save(modules_file1, 'partition', 'zFC_mean', 'zFC_mean_partition', ...
    'merged_matrices','merged_matrices_mat', 'labels', 'valid_labels', 'valid_indices',...
    'merged_matrices_partition','merged_matrices_partition_mat', 'subjects');

%valid_regions = task2.valid_regions;
merged_matrices = task2.merged_matrices;
merged_matrices_mat = task2.merged_matrices_mat;
merged_matrices_partition = task2.merged_matrices_partition;
merged_matrices_partition_mat = task2.merged_matrices_partition_mat;
subjects = task2.subjects;
save(modules_file2, 'partition', 'zFC_mean', 'zFC_mean_partition', ...
    'merged_matrices','merged_matrices_mat', 'labels', 'valid_labels', 'valid_indices',...
    'merged_matrices_partition','merged_matrices_partition_mat', 'subjects');


% Prepare files for visualization in BrainNet
cd(modules_dir1)
coords = load(coords_file);

% remove modules with few nodes
tabulate(partition)

color = partition;
for p = 1:max(partition)
    node_file = fullfile(modules_dir1, ['/module' num2str(p) '.node']);
    fid = fopen(node_file, 'w');
    for i = 1:size(coords, 1);
        tag = labels{i};
        if (partition(i) == p)
            fprintf(fid, '%.2f\t%.2f\t%.2f\t%d\t%.2f\t%s\n', coords(i,1), coords(i,2), coords(i,3), color(i), .1, tag);
        end
    end
    
    fclose(fid);
    %fig_file = fullfile(modules_dir, ['/module' num2str(p) '.png']);
    %BrainNet_MapCfg(surface_file, node_file, fig_file);
end
module_parc = 0*parc;
for i = 1:max(parc(:))
    module_parc(parc == i) = partition(i);
end
mri.vol = module_parc;
MRIwrite(mri, module_parcellation_file)


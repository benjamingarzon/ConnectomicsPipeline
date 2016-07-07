
close all;
clear all;
addpath /usr/local/MATLAB/Toolboxes/BCT
addpath /home/benjamingarzon/Software/MATLAB/nmi
RS_DIR = '/shared/Data/DAD/Modelling/';

parcellation_file = fullfile(RS_DIR, 'fconn_atlas_150_2mm.nii');
module_parcellation_file = fullfile(RS_DIR, 'fconn_atlas_150_2mm_modules.nii');

addpath /usr/local/freesurfer/matlab/
mri = MRIread(parcellation_file);
parc = mri.vol;

task1.file = fullfile(RS_DIR, 'GNG/zFC_all_150_0.3.mat');
task1 = load(task1.file);

merged_matrices = task1.merged_matrices;

zFC_mean = mean(merged_matrices, 3);
labels = task1.labels;

valid = any(~isnan(zFC_mean));

figure
adj = tanh(zFC_mean(valid, valid));
adj(adj < 0) = 0;
thr = 1;
imagesc(adj);
colormap jet
colorbar

N_gammas =  10;
gammas = linspace(1, 2, N_gammas);
consensus = adj*0;
TAU = 0;
REPS = 1000;
allM = zeros(size(adj,1), REPS);
if 0 
for i = 1:N_gammas
    i
    allM = zeros(size(adj,1), REPS);
    gamma = gammas(i);
    for j = 1 : REPS
        [M Q(i)] = community_louvain(adj, gamma);
        %    [M Q(i)] = modularity_und(adj, gamma);
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
        
        %NMI(i, j) = nmi(allC(:, i), allC(:, j));
        [VIn(i, j) NMI(i, j)] = partition_distance(allC(:, i), allC(:, j));
        
    end
end

meanNMI = (sum(NMI) - 1)/(N_gammas - 1);
meanVIn = (sum(VIn) - 1)/(N_gammas - 1);
minNMI = min(NMI);


[m, index] = max(meanNMI);
[m, index] = min(meanVIn);

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
   gamma = 1.45;
    for j = 1 : REPS
        [M Q] = community_louvain(adj, gamma);
        %    [M Q(i)] = modularity_und(adj, gamma);
        allM(:,j ) = M;
    end
    
    D = agreement(allM)/REPS;
    C = consensus_und(D, TAU, REPS);

partition_strict = C;    
end
% clean smaller modules of the partition an renumber

freqs = tabulate(C);

for i = freqs(freqs(:,2)<=3, 1)'
display(sum(partition_strict==i))    
partition_strict(partition_strict==i) = 0;

end
j = 0;
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
     %   for s = 1:size(task2.merged_matrices, 3)
     %       m2 = task2.merged_matrices(partition == i, partition == j, s);
            
     %       if (i == j)
     %           m2(isinf(m2)) = 0;
     %           task2.merged_matrices_partition(i, j, s) = mean(squareform(m2));
     %       else
     %           task2.merged_matrices_partition(i, j, s) = mean(m2(:));
     %       end
     %   end
              
    end
end

task1.merged_matrices_partition_mat = [];

for s = 1:size(task1.merged_matrices, 3)
    m = task1.merged_matrices_partition(:, :, s);
    d = diag(m);
    
    task1.merged_matrices_partition_mat = [task1.merged_matrices_partition_mat; squareform(m - diag(d)) d'];
end

figure
imagesc(zFC_mean_partition, [-.5 .5])
colorbar
save(fullfile(RS_DIR, 'modules_150.mat'), 'partition', 'zFC_mean', 'zFC_mean_partition');
merged_matrices_partition = task1.merged_matrices_partition;
merged_matrices_partition_mat = task1.merged_matrices_partition_mat;
subjects = task1.subjects;
save(fullfile(RS_DIR, 'GNG/modules_150_zFC_mean.mat'), 'partition', 'merged_matrices_partition','merged_matrices_partition_mat', 'subjects');
%merged_matrices_partition = task2.merged_matrices_partition;
%subjects = task2.subjects;
%save(fullfile(RS_DIR, 'TAB/modules_125_zFC_mean.mat'), 'partition', 'merged_matrices_partition','subjects');

% plot
BRAINNET_DIR='/home/benjamingarzon/Software/BrainNetViewer_20150807/'

% Prepare files for visualization in BrainNet
addpath(BRAINNET_DIR)
PARC_DIR = '/shared/Data/DAD/Modelling';
ANALYSIS_DIR = '/shared/Data/DAD/Modelling';
cd(ANALYSIS_DIR)

coords_file = fullfile(PARC_DIR, 'parc_shen_150.coords.csv');
coords = load(coords_file);

edge_file = fullfile(ANALYSIS_DIR, 'net.edge');
surface_file = fullfile(BRAINNET_DIR,'Data/SurfTemplate/BrainMesh_ICBM152.nv');
config_file = fullfile(ANALYSIS_DIR, 'BrainNet_cfg.mat');


% remove modules with few nodes
tabulate(partition)

color = partition;
for p = 1:max(partition)
    node_file = fullfile(ANALYSIS_DIR, ['modules/module' num2str(p) '.node']);
    fid = fopen(node_file, 'w');
    for i = 1:size(coords, 1);
        tag = labels{i};
        if (partition(i) == p)
            fprintf(fid, '%.2f\t%.2f\t%.2f\t%d\t%.2f\t%s\n', coords(i,1), coords(i,2), coords(i,3), color(i), .1, tag);
        end
    end
    
    fclose(fid);
    fig_file = fullfile(ANALYSIS_DIR, ['modules/module' num2str(p) '.png']);
    %BrainNet_MapCfg(surface_file, node_file, fig_file);
end
module_parc = 0*parc;
for i = 1:max(parc(:))
module_parc(parc == i) = partition(i);
end
mri.vol = module_parc;
MRIwrite(mri, module_parcellation_file)


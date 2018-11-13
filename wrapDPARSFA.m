function wrapDPARSFA(filename, subject_list, working_dir, parallel_workers, scrubbing, timepoints)

if parallel_workers > 0
    mypool = parpool(parallel_workers);
    pctRunOnAll addpath('/usr/local/MATLAB/R2017b/toolbox/spm/spm12')
    %pctRunOnAll addpath( genpath( '/usr/local/MATLAB/Toolboxes/DPABI_V2.0_151201/'))
    pctRunOnAll addpath( genpath( '/home/benjamin.garzon/Software/DPABI_V3.1_180801/'))
    %addAttachedFiles(mypool, {'/usr/local/MATLAB/Toolboxes/DPABI_V2.0_151201/'})
    %addAttachedFiles(mypool, {'/home/ALDRECENTRUM/benjamin.garzon/Data/DAD/RS/Masks/SegmentationMasks/','/home/ALDRECENTRUM/benjamin.garzon/Data/DAD/RS/Masks/WarpedMasks/'})
else
    addpath('/usr/local/MATLAB/R2017b/toolbox/spm/spm12')
    addpath( genpath( '/home/benjamin.garzon/Software/DPABI_V3.1_180801/'))
end

load(filename)
subjects = strread(subject_list,'%s','delimiter',' ');
Cfg.SubjectID = subjects;
Cfg.TimePoints = timepoints;
Cfg.WorkingDir = working_dir;
Cfg.DataProcessDir = working_dir;
Cfg.ParallelWorkersNumber = parallel_workers;
if scrubbing ~= 0
   Cfg.IsScrubbing = 1;
   Cfg.Scrubbing.FDThreshold = scrubbing;
else
   Cfg.IsScrubbing = 0;
end


save(filename, 'Cfg')
DPARSFA_run(filename)
end

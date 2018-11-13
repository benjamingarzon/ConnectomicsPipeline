%function calculate_connectivity_matrix

%tcourses_file = 'Connectome/D02/tcourses.txt';
%FC_file = 'Connectome/D02/FC.txt';

%aux(tcourses_file, FC_file);
%end

function calculate_connectivity_matrix(tcourses_file, FC_file, varargin)

tcs = dlmread(tcourses_file);
M = corr(tcs);

FC = atanh(M); %FC = M; FC(:) = 0.5*log( (1+M(:))./(1-M(:)) );

if length(varargin)>0
    signal = dlmread(varargin{1});
    thr = varargin{2};
    valid = 1*(signal >= thr)' * 1*(signal >= thr);
    display(['Removing ' num2str(sum(signal < thr)) ' out of ' num2str(length(signal)) ' nodes']);
    FC(~valid) = nan;

end

dlmwrite(FC_file, FC, ' ')

end

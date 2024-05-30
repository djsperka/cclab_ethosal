% Left=load('/home/dan/work/cclab/ethdata/output/dan16_left.mat');
% Right=load('/home/dan/work/cclab/ethdata/output/dan16_right.mat');
% None=load('/home/dan/work/cclab/ethdata/output/dan16_none.mat');
% [~, ~, allfigures] = anaeth(Left.results, Right.results, None.results, 'dan16');
% 
% Left=load('/home/dan/work/cclab/ethdata/output/jodi22_left.mat');
% Right=load('/home/dan/work/cclab/ethdata/output/jodi22_right.mat');
% None=load('/home/dan/work/cclab/ethdata/output/jodi22_none.mat');
% [~, ~, fig] = anaeth(Left.results, Right.results, None.results, 'jodi22');
% allfigures = [allfigures,fig];

allfigures = [];
Left=load('/home/dan/work/cclab/ethdata/output/taylor_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/taylor_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/taylor_none.mat');
[~, ~, fig] = anaeth(Left.results, Right.results, None.results, 'taylor16');
allfigures = [allfigures,fig];

% None=load('/home/dan/work/cclab/ethdata/output/xmch_none.mat');
% [rNone4, rAttended4, fig] = anaeth([], [], None.results, 'xmch short sample');
% allfigures = [allfigures,fig];

Left=load('/home/dan/work/cclab/ethdata/output/subject001_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/subject001_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/subject001_none.mat');
[~, ~, fig] = anaeth(Left.results, Right.results, None.results, 's001');
allfigures = [allfigures,fig];

Left=load('/home/dan/work/cclab/ethdata/output/subject002_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/subject002_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/subject002-corrected_none.mat');
[~, ~, fig] = anaeth(Left.results, Right.results, None.results, 's002');
allfigures = [allfigures,fig];

Left=load('/home/dan/work/cclab/ethdata/output/subject003_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/subject003_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/subject003-2_none.mat');
[rNone5, rAttended5, fig] = anaeth(Left.results, Right.results, None.results, 's003');
allfigures = [allfigures,fig];

% append each of the figures to output.pdf
for i=1:length(allfigures)
    exportgraphics(allfigures(i), 'output/alloutput.pdf', 'Append', true);
end
% this file is a runnign log of now to run/analyze data files. 
% Not intended to be run all at once, but it can right now. More as a place
% to keep track of what works. 

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
[~, ~, fig] = anaeth(Left.results, Right.results, None.results, 's003');
allfigures = [allfigures,fig];

Left=load('/home/dan/work/cclab/ethdata/output/subject004_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/subject004_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/subject004_none_000.mat');
[~, ~, fig] = anaeth(Left.results, Right.results, None.results, 's004');
allfigures = [allfigures,fig];

% jodi - none - short test time
None=load('/home/dan/work/cclab/ethdata/output/test_none_027.mat');
[~, ~, fig] = anaeth([], [], None.results, 'jodi-short-test');

% dan - none - short test time
None=load('/home/dan/work/cclab/ethdata/output/test_none_028.mat');
[~, ~, fig] = anaeth([], [], None.results, 'dan-short-test');



Left=load('/home/dan/work/cclab/ethdata/output/subject008_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/subject008_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/subject008_none_002.mat');
[~, ~, fig] = anaeth(Left.results, Right.results, None.results, 's008');

Left=load('/home/dan/work/cclab/ethdata/output/subject009_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/subject009_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/subject009_none.mat');
[~, ~, fig9] = anaeth(Left.results, Right.results, None.results, 's009');

Left=load('/home/dan/work/cclab/ethdata/output/subject010_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/subject010_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/subject010_none.mat');
[~, ~, fig10] = anaeth(Left.results, Right.results, None.results, 's010');

Left=load('/home/dan/work/cclab/ethdata/output/subject011_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/subject011_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/subject011_none.mat');
[~, ~, fig11] = anaeth(Left.results, Right.results, None.results, 's011');

Left=load('/home/dan/work/cclab/ethdata/output/subject012_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/subject012_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/subject012_none.mat');
[~, ~, fig12] = anaeth(Left.results, Right.results, None.results, 's012');


Left=load('/home/dan/work/cclab/ethdata/output/subject013_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/subject013_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/subject013_none.mat');
[~, ~, fig13] = anaeth(Left.results, Right.results, None.results, 's013');

Left=load('/home/dan/work/cclab/ethdata/output/subject014_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/subject014_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/subject014_none.mat');
[~, ~, fig14] = anaeth(Left.results, Right.results, None.results, 's014');


None=load('/home/dan/work/cclab/ethdata/output/rowan12_none_000.mat');
[rN, ~, fig] = anaeth([], [], None.results, 'rowan12');

None=load('/home/dan/work/cclab/ethdata/output/dan12_none.mat');
[rN, ~, fig2] = anaeth([], [], None.results, 'dan12');


% append each of the figures to output.pdf
for i=1:length(allfigures)
    exportgraphics(allfigures(i), 'output/alloutput.pdf', 'Append', true);
end
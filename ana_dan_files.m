Left=load('/home/dan/work/cclab/ethdata/output/dan16_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/dan16_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/dan16_none.mat');
[rNone1, rAttended1] = anaeth(Left.results, Right.results, None.results, 'dan16');

Left=load('/home/dan/work/cclab/ethdata/output/jodi22_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/jodi22_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/jodi22_none.mat');
[rNone2, rAttended2] = anaeth(Left.results, Right.results, None.results, 'jodi22');

Left=load('/home/dan/work/cclab/ethdata/output/taylor_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/taylor_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/taylor_none.mat');
[rNone3, rAttended3] = anaeth(Left.results, Right.results, None.results, 'taylor16');

None=load('/home/dan/work/cclab/ethdata/output/xmch_none.mat');
[rNone4, rAttended4] = anaeth([], [], None.results, 'xmch short sample');

Left=load('/home/dan/work/cclab/ethdata/output/subject001_left.mat');
Right=load('/home/dan/work/cclab/ethdata/output/subject001_right.mat');
None=load('/home/dan/work/cclab/ethdata/output/subject001_none.mat');
[rNone5, rAttended5] = anaeth(Left.results, Right.results, None.results, 's001');

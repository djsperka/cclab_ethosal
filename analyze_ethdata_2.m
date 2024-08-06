N1=load(fullfile(ethDataRoot,'output','gabor-exp','2024-07-31-1342_Dan_gab_exp_33x3-A_blk1.mat'));
N2=load(fullfile(ethDataRoot,'output','gabor-exp','2024-07-31-1352_Dan_gab_exp_33x3-A_blk2.mat'));
None=[N1.results;N2.results];
[rg1,~,~] = anaeth(None);

N1=load(fullfile(ethDataRoot,'output','gabor-exp','2024-07-30-1433_sitong_gab_exp_33x3-A_blk1.mat'));
N2=load(fullfile(ethDataRoot,'output','gabor-exp','2024-07-30-1446_sitong_gab_exp_33x3-A_blk2.mat'));
None=[N1.results;N2.results];
[rg2,~,fig] = anaeth(None);

N1=load(fullfile(ethDataRoot,'output','gabor-exp','2024-08-01-1456_Brinda_gab_exp_33x3-B_blk1.mat'));
N2=load(fullfile(ethDataRoot,'output','gabor-exp','2024-08-01-1508_Brinda_gab_exp_33x3-B_blk2.mat'));
None=[N1.results;N2.results];
[rg3,~,fig] = anaeth(None);

%%%%%

N1=load(fullfile(ethDataRoot,'output', 'image-exp', '2024-07-26-1032_dan_mimg_exp_50img-dlt25-A_blk1.mat'));
N2=load(fullfile(ethDataRoot,'output', 'image-exp', '2024-07-26-1043_dan_mimg_exp_50img-dlt25-A_blk2.mat'));
None=[N1.results;N2.results];
[ri1,~,~] = anaeth(None);


N1=load(fullfile(ethDataRoot,'output', 'image-exp', '2024-07-26-1246_sitong_mimg_exp_50img-dlt25-B_blk1.mat'));
N2=load(fullfile(ethDataRoot,'output', 'image-exp', '2024-07-26-1259_sitong_mimg_exp_50img-dlt25-B_blk2.mat'));
None=[N1.results;N2.results];
[ri2,~,~] = anaeth(None);

N1=load(fullfile(ethDataRoot,'output', 'image-exp', '2024-07-26-1436_jodi_mimg_exp_50img-dlt25-A_blk1.mat'));
N2=load(fullfile(ethDataRoot,'output', 'image-exp', '2024-07-26-1449_jodi_mimg_exp_50img-dlt25-A_blk2.mat'));
None=[N1.results;N2.results];
[ri3,~,~] = anaeth(None);





figure;
subplot(2,1,1);
title('dprime');

Y=[
    rg1.dpHH, rg1.dpHL, rg1.dpLL, rg1.dpLH;
    rg2.dpHH, rg2.dpHL, rg2.dpLL, rg2.dpLH;
    rg3.dpHH, rg3.dpHL, rg3.dpLL, rg3.dpLH;
  ];
X=categorical({'HH', 'HL', 'LL', 'LH'});
X=reordercats(X, {'HH', 'HL', 'LL', 'LH'});
bar(X,Y);
%plot(X,Y);
ylim([0,5]);

R = [
    rg1.treactHH, rg1.treactHL, rg1.treactLL, rg1.treactLH;
    rg2.treactHH, rg2.treactHL, rg2.treactLL, rg2.treactLH;
    rg3.treactHH, rg3.treactHL, rg3.treactLL, rg3.treactLH;
    ];

subplot(2,1,2);
%plot(X,Y);
bar(X,R);
ylim([0,1]);
title('reaction time');


figure;
subplot(2,1,1);
title('dprime');

Y=[
    ri1.dpHH, ri1.dpHL, ri1.dpLL, ri1.dpLH;
    ri2.dpHH, ri2.dpHL, ri2.dpLL, ri2.dpLH;
    ri3.dpHH, ri3.dpHL, ri3.dpLL, ri3.dpLH;
  ];
X=categorical({'HH', 'HL', 'LL', 'LH'});
X=reordercats(X, {'HH', 'HL', 'LL', 'LH'});
bar(X,Y);
%plot(X,Y);
ylim([0,5]);

R = [
    ri1.treactHH, ri1.treactHL, ri1.treactLL, ri1.treactLH;
    ri2.treactHH, ri2.treactHL, ri2.treactLL, ri2.treactLH;
    ri3.treactHH, ri3.treactHL, ri3.treactLL, ri3.treactLH;
    ];

subplot(2,1,2);
title('Reaction time');
%plot(X,Y);
bar(X,R);
ylim([0,1]);


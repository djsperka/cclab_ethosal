% load table with all data files and types
Y = load('alldata.mat');

% analysis
A=cellfun(@(a,b) getSalYY(a,strcat(ethDataRoot, b)), Y.tab.Var2, Y.tab.Var3, 'UniformOutput', false);
amat = cell2mat(A);

% plot
figure;
plot(categorical(Y.tab.Var1), amat(:,1), 'r+', categorical(Y.tab.Var1), amat(:,2), 'g+');
ylim([-2 2]);
yline(0);
% use bin count data to run PCA and tSNE
% Xiaoyan, 2018

clear; close all;


%% modify here
hexbin_counts = 'G:\pooled_bincounts_msbrain_count.csv';  % already binned data (pooled or not), requires header, compatible with output from BatchHexBin
hexbin_position = 'G:\pooled_bincounts_msbrain_binpos.csv';    % bin position file generated at the same time as bin count file
hexbin_size = 200;   % in piexels, if single-cell data use hexbin_size = 0
output_directory = 'G:\testtsne';
pcacom= 4;   %Number of pca components. Must be between number of samples and number of genes includeda
%% do not modify

% import data
tableCount = readtable(hexbin_counts, 'ReadVariableNames', 1);

%Filter for 1 column
vect=tableCount.Adarb2 >= 0;
tableNO=tableCount(tableCount.Adarb2 < 0, :);
tableCount=tableCount(tableCount.Adarb2 >= 0, :);




% original column names
cNames = tableCount.Properties.VariableNames;

% make sure there are no multiple entries of the same gene
assert(numel(cNames)== numel(unique(cNames)),...
    'Column names are not unique!')

% create checkboxes and get selected values
cbValues = checkboxes(cNames);
idx = cellfun(@(v) find(strcmp(v, cNames)), cbValues(:,1));
isSelected = false(numel(idx), 1);
isSelected(idx) = cell2mat(cbValues(:,2));
cGenes = table2array(tableCount(:,isSelected));
genes = cNames(isSelected)'

% PCA
[coeff, score, latent] = pca(cGenes);
% visualize first two components
figure, biplot(coeff(:,1:2), 'Scores', score(:,1:2), 'VarLabels', genes);
title('top two principle components');



%Filter for 1 variable



% tSNE in MATLAB
% ONLY >=R2018a
seeds = 1e-4*randn(size(cGenes,1), 3);
Y = tsne(cGenes, 'NumDimensions', 3, 'NumPCAComponents', 4, 'Perplexity', 40,...
    'Standardize', 1, 'LearnRate', 1000, 'Verbose', 1, 'InitialY', seeds); 
[uSamples, ~, iSample] = unique(cellfun(@(v) v(1:strfind(v, '_hexbin')-1), table2cell(tableCount(:,1)), 'uni', 0));
[uSamples2, ~, iSample2] = unique(cellfun(@(v) v(1:strfind(v, '_hexbin')-1), table2cell(tableCount(:,1)), 'uni', 0));
figure, scatter3(Y(:,1),Y(:,2),Y(:,3),10, iSample);
colormap(jet(20));
title({'tSNE dim reduction to three', 'color-coded by samples'});




% get position
pos = importdata(hexbin_position);
pos = pos.data;
pos(:,3)=vect;
pos=array2table(pos);
posno=pos(pos.pos3==0,:);
posno=table2array(posno(:,1:2));
pos=pos(pos.pos3==1,:);
pos=table2array(pos(:,1:2));
% visualize tSNE in RGB (no background)
if ~hexbin_size;	hexbin_size = 10;    end
Yrgb = rgbscale(Y);

%Visualization depending on tsne dimension
figure, scatter3(Y(:,1),Y(:,2),Y(:,3),10, Yrgb);
legend(uSamples);
colormap(jet(20));
title({'tSNE dim reduction to three', 'Color based on axis, according to spatial representation'});



% Visualisation depending on gene expression

% for s=21:40
% genc=table2array(tableCount(:,s));
% ti=tableCount.Properties.VariableNames(s);
% figure, scatter3(Y(:,1),Y(:,2),Y(:,3),10,genc );
% colormap(hsv(100));
% title(ti);
% 
% end 

pos=vertcat(pos,posno);
tab=zeros(size(posno,1),3);
tab(:,:)=1;
Yrgb=vertcat(Yrgb,tab)
iSample=[iSample;iSample2]

% 
% for s = 1:numel(uSamples)
%     drawnow
%     figure(1212);
%     for elem=2000:3000%size(pos,1)
%     disp(elem);
%     hold on 
%     scatter(pos(elem,1),pos(elem,2),30, Yrgb(elem,:),'filled');
%     end
% end


figure(966);
scatter(pos(:,1),pos(:,2),100, Yrgb(:,:),'filled','Marker', 's');





% write
mkdir(output_directory);
csvwrite(fullfile(output_directory, 'tSNE_3D.csv'), Y);
csvwrite(fullfile(output_directory, 'tSNE_initial.csv'), seeds);


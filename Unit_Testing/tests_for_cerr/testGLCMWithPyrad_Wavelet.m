% this script tests GLCM features between CERR and pyradiomics on a wavelet filtered image.
%
% RKP, 03/22/2018


glcmParamFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','tests_for_cerr','test_glcm_radiomics_extraction_settings.json');
cerrFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','data_for_cerr_tests','CERR_plans','head_neck_ex1_20may03.mat.bz2');

planC = loadPlanC(cerrFileName,tempdir);
indexS = planC{end};

paramS = getRadiomicsParamTemplate(glcmParamFileName);
strNum = getMatchingIndex(paramS.structuresC{1},{planC{indexS.structures}.structureName});
scanNum = getStructureAssociatedScan(strNum,planC);


scanType = 'wavelet';
dirString = 'HHH';
%% Calculate features using CERR
harFeat3DdirS = calcGlobalRadiomicsFeatures...
            (scanNum, strNum, paramS, planC);
harlCombS = harFeat3DdirS.Wavelets_Coif1__HHH.glcmFeatS.AvgS;
cerrGlcmV = [harlCombS.autoCorr, harlCombS.jointAvg, harlCombS.clustPromin, harlCombS.clustShade, harlCombS.clustTendency, ...
harlCombS.contrast, harlCombS.corr, harlCombS.diffAvg, harlCombS.diffEntropy, harlCombS.diffVar, harlCombS.dissimilarity, ...
harlCombS.energy, harlCombS.jointEntropy, harlCombS.invDiff, harlCombS.invDiffMom, harlCombS.firstInfCorr, ...
harlCombS.secondInfCorr, harlCombS.invDiffMomNorm, harlCombS.invDiffNorm, harlCombS.invVar, ...
harlCombS.sumAvg, harlCombS.sumEntropy, harlCombS.sumVar];

%% Calculate features using pyradiomics
% image and mask for a structure
testM = single(planC{indexS.scan}(scanNum).scanArray) - ...
    single(planC{indexS.scan}(scanNum).scanInfo(1).CTOffset);
mask3M = zeros(size(testM),'logical');
[rasterSegments, planC, isError] = getRasterSegments(strNum,planC);
[maskBoundBox3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
mask3M(:,:,uniqueSlices) = maskBoundBox3M;

dx = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
dy = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
dz = mode(diff([planC{indexS.scan}(scanNum).scanInfo(:).zValue]));
pixelSize = [dx dy dz]*10;

teststruct = PyradWrapper(testM, mask3M, pixelSize, scanType, dirString);

%teststruct = PyradWrapper(testM, mask3M, scanType, dirString);
pyradGlcmNamC = {'Autocorrelation', 'JointAverage', 'ClusterProminence', 'ClusterShade',  'ClusterTendency', ...
    'Contrast', 'Correlation', 'DifferenceAverage', 'DifferenceEntropy', 'DifferenceVariance', 'Dissimilarity', ...
    'JointEnergy', 'JointEntropy','Id','Idm', 'Imc1' , ...
    'Imc2', 'Idmn','Idn','InverseVariance', 'sumAverage', 'SumEntropy', 'sumVariance'};

pyradGlcmNamC = strcat(['wavelet','_', dirString,'_glcm_'],pyradGlcmNamC);
pyRadGlcmV = [];
for i = 1:length(pyradGlcmNamC)
    if isfield(teststruct,pyradGlcmNamC{i})
        pyRadGlcmV(i) = teststruct.(pyradGlcmNamC{i});
    else
        pyRadGlcmV(i) = NaN;
    end
end

%% Compare
glcmDiffV = (cerrGlcmV - pyRadGlcmV) ./ cerrGlcmV * 100

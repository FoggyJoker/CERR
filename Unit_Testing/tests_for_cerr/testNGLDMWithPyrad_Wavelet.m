% this script tests NGLDM features between CERR and pyradiomics on wavelet filtered image.
%
% RKP, 03/22/2018


gldmParamFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','tests_for_cerr','test_ngldm_radiomics_extraction_settings.json');
cerrFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','data_for_cerr_tests','CERR_plans','head_neck_ex1_20may03.mat.bz2');

planC = loadPlanC(cerrFileName,tempdir);
indexS = planC{end};

paramS = getRadiomicsParamTemplate(gldmParamFileName);
strNum = getMatchingIndex(paramS.structuresC{1},{planC{indexS.structures}.structureName});
scanNum = getStructureAssociatedScan(strNum,planC);

scanType = 'wavelet';
dirString = 'HHH';

%% NGLDM features CERR

ngldmS = calcGlobalRadiomicsFeatures...
            (scanNum, strNum, paramS, planC);
ngldmS = ngldmS.Wavelets_Coif1__HHH.ngldmFeatS;

cerrNgldmV = [ngldmS.lde, ngldmS.hde, ngldmS.lgce, ngldmS.hgce, ...
    ngldmS.ldlge, ngldmS.ldhge, ngldmS.hdlge, ngldmS.hdhge, ...
    ngldmS.gln, ngldmS.glnNorm, ngldmS.dcn, ngldmS.dcnNorm,...
    ngldmS.dcp, ngldmS.glv, ngldmS.dcv, ngldmS.entropy, ngldmS.energy];

%% Calculate features using pyradiomics

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

pyradNgldmNamC = {'SmallDependenceEmphasis', 'LargeDependenceEmphasis',...
    'LowGrayLevelCountEmphasis', 'HighGrayLevelCountEmphasis',  'SmallDependenceLowGrayLevelEmphasis', ...
    'SmallDependenceHighGrayLevelEmphasis', 'LargeDependenceLowGrayLevelEmphasis', ...
    'LargeDependenceHighGrayLevelEmphasis', 'GrayLevelNonUniformity', 'GrayLevelNonUniformityNorm', ...
    'DependenceNonUniformity', 'DependenceNonUniformityNormalized', ...
    'DependencePercentage', 'GrayLevelVariance', 'DependenceVariance', ...
    'DependenceEntropy', 'DependenceEnergy'};


pyradNgldmNamC = strcat(['wavelet','_', dirString, '_gldm_'],pyradNgldmNamC);

pyRadNgldmV = [];
for i = 1:length(pyradNgldmNamC)
    if isfield(teststruct,pyradNgldmNamC{i})
        pyRadNgldmV(i) = teststruct.(pyradNgldmNamC{i});
    else
        pyRadNgldmV(i) = NaN;
    end
end

%% Compare

ngldmDiffV = (cerrNgldmV - pyRadNgldmV) ./ cerrNgldmV * 100
% this script tests Size Zone features between CERR and pyradiomics on a wavelet filtered image.
%
% RKP, 03/22/2018



sizeZoneParamFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','tests_for_cerr','test_size_zone_radiomics_extraction_settings.json');
cerrFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','data_for_cerr_tests','CERR_plans','head_neck_ex1_20may03.mat.bz2');

planC = loadPlanC(cerrFileName,tempdir);
indexS = planC{end};

paramS = getRadiomicsParamTemplate(sizeZoneParamFileName);
strNum = getMatchingIndex(paramS.structuresC{1},{planC{indexS.structures}.structureName});
scanNum = getStructureAssociatedScan(strNum,planC);

scanType = 'wavelet';
dirString = 'HHH';

%% Calculate features using CERR

szmS = calcGlobalRadiomicsFeatures...
            (scanNum, strNum, paramS, planC);



szmS = szmS.Wavelets_Coif1__HHH.szmFeatS;


cerrSzmV = [szmS.gln, szmS.glnNorm, szmS.glv, szmS.hglze, szmS.lglze, szmS.lae, szmS.lahgle, ...
    szmS.lalgle, szmS.szn, szmS.sznNorm, szmS.szv, szmS.zp, ...
    szmS.sae, szmS.sahgle, szmS.salgle, szmS.ze];


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

pyradSzmNamC = {'GrayLevelNonUniformity', 'GrayLevelNonUniformityNormalized',...
    'GrayLevelVariance', 'HighGrayLevelZoneEmphasis',  'LowGrayLevelZoneEmphasis', ...
    'LargeAreaEmphasis', 'LargeAreaHighGrayLevelEmphasis', 'LargeAreaLowGrayLevelEmphasis',...
    'SizeZoneNonUniformity', 'SizeZoneNonUniformityNormalized', 'ZoneVariance', ...
    'ZonePercentage', 'SmallAreaEmphasis','SmallAreaHighGrayLevelEmphasis', ...
    'SmallAreaLowGrayLevelEmphasis', 'ZoneEntropy'};

pyradSzmNamC = strcat(['wavelet','_', dirString, '_glszm_'],pyradSzmNamC);

pyRadSzmV = [];
for i = 1:length(pyradSzmNamC)
    if isfield(teststruct,pyradSzmNamC{i})
        pyRadSzmV(i) = teststruct.(pyradSzmNamC{i});
    else
        pyRadSzmV(i) = NaN;
    end
end
szmDiffV = (cerrSzmV - pyRadSzmV) ./ cerrSzmV * 100
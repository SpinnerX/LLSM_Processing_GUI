function [] = XR_microscopeAutomaticProcessing_parser(dataPaths, varargin)

%#function XR_deskewRotateFrame
%#function XR_matlab_stitching_wrapper
%#function XR_stitching_frame_zarr_dev_v1
%#function XR_cudaDeconFrame3D
%#function XR_cppDeconFrame3D
%#function XR_RLdeconFrame3D
%#function XR_RotateFrame3D

ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('dataPaths'); % data structure from loadConditionData
ip.addParameter('Overwrite', false,  @(x) ((numel(x) == 1 || numel(x) == 5) && islogical(x)) || ischar(x));
ip.addParameter('Streaming', true,  @(x) islogical(x) || ischar(x)); % if true, check for new files. If false, assume all files transferred completely.
ip.addParameter('ChannelPatterns', {'CamA_ch0', 'CamA_ch1', 'CamB_ch0'}, @(x) iscell(x) || ischar(x));
ip.addParameter('SkewAngle', 32.45, @(x) isscalar(x) || ischar(x));
ip.addParameter('dz', 0.5, @(x) isscalar(x) || ischar(x));
ip.addParameter('xyPixelSize', 0.108, @(x) isscalar(x) || ischar(x));
ip.addParameter('Reverse', true, @(x) islogical(x) || ischar(x));
ip.addParameter('ObjectiveScan', false, @(x) islogical(x) || ischar(x));
ip.addParameter('ZstageScan', false, @(x) islogical(x) || ischar(x));
ip.addParameter('sCMOSCameraFlip', false, @(x) islogical(x) || ischar(x));
ip.addParameter('Save16bit', [false, false, false, false], @(x) ((numel(x) == 1 || numel(x) == 4) && islogical(x)) || ischar(x));
ip.addParameter('onlyFirstTP', false, @(x) islogical(x) || ischar(x));
ip.addParameter('dzFromEncoder', false, @(x) islogical(x) || ischar(x));
ip.addParameter('zarrFile', false, @(x) islogical(x) || ischar(x)); % use zarr file as input
ip.addParameter('saveZarr', false, @(x) islogical(x) || ischar(x)); % use zarr file as output
ip.addParameter('save3DStack', true , @(x) islogical(x) || ischar(x)); % option to save 3D stack or not
% pipeline steps
ip.addParameter('Deskew', true, @(x) islogical(x) || ischar(x));
ip.addParameter('Rotate', true, @(x) islogical(x) || ischar(x));
ip.addParameter('Stitch', false, @(x) islogical(x) || ischar(x));
ip.addParameter('Decon', ~false, @(x) islogical(x) || ischar(x));
ip.addParameter('RotateAfterDecon', false, @(x) islogical(x) || ischar(x));
% deskew and rotation options
ip.addParameter('parseSettingFile', false, @(x) islogical(x) || ischar(x)); % use setting file to decide whether filp Z stack or not.
ip.addParameter('flipZstack', false, @(x) islogical(x) || ischar(x)); % 
ip.addParameter('DSRCombined', true, @(x) islogical(x) || ischar(x)); 
ip.addParameter('LLFFCorrection', false, @(x) islogical(x) || ischar(x));
ip.addParameter('BKRemoval', false, @(x) islogical(x) || ischar(x));
ip.addParameter('LowerLimit', 0.4, @(x) isnumeric(x) || ischar(x)); % this value is the lowest
ip.addParameter('constOffset', [], @(x) isnumeric(x) || ischar(x)); % If it is set, use constant background, instead of background from the camera.
ip.addParameter('LSImagePaths', {'','',''}, @(x) iscell(x) || ischar(x));
ip.addParameter('BackgroundPaths', {'','',''}, @(x) iscell(x) || ischar(x));
ip.addParameter('resampleType', 'isotropic', @ischar); % resample type: given, isotropic, xy_isotropic
ip.addParameter('resample', [], @(x) isnumeric(x) || ischar(x)); % resample
ip.addParameter('InputBbox', [], @(x) isnumeric(x) || ischar(x)); % bbox for input in deskew and rotate
% stitch parameters
ip.addParameter('stitchPipeline', 'matlab', @ischar); % matlab or zarr
ip.addParameter('stitchResultDir', '', @ischar);
ip.addParameter('imageListFullpaths', '', @(x) ischar(x) || iscell(x));
ip.addParameter('axisOrder', 'xyz', @(x) ischar(x));
ip.addParameter('BlendMethod', 'none', @ischar);
ip.addParameter('xcorrShift', false, @(x) islogical(x) || ischar(x));
ip.addParameter('xcorrMode', 'primaryFirst', @(x) ismember(lower(x), {'primary', 'primaryfirst', 'all'}) && ischar(x)); % 'primary': choose one channel as primary channel, 
ip.addParameter('xyMaxOffset', 300, @(x) isnumeric(x) || ischar(x)); % max offsets in xy axes
ip.addParameter('zMaxOffset', 50, @(x) isnumeric(x) || ischar(x)); % max offsets in z axis
ip.addParameter('EdgeArtifacts', 2, @(x) isnumeric(x) || ischar(x));
ip.addParameter('timepoints', [], @(x) isnumeric(x) || ischar(x)); % stitch for given time points
ip.addParameter('boundboxCrop', [], @(x) isnumeric(x) && (isempty(x) || all(size(x) == [3, 2]) || numel(x) == 6) || ischar(x));
ip.addParameter('primaryCh', '', @ischar);
% Integrate stitchMIP Later
ip.addParameter('stitchMIP', [], @(x) (islogical(x) && (numel(x) == 1 || numel(x) == 3)) || ischar(x)); % 1x3 vector or vector, byt default, stitch MIP-z
ip.addParameter('onlineStitch', false, @(x) islogical(x) || ischar(x)); % support for online stitch (with partial number of tiles). 
ip.addParameter('generateImageList', '', @(x) ischar(x)); % for real time processing, {'', 'from_encoder', 'from_sqlite'}
% decon parameters
ip.addParameter('cudaDecon', false, @(x) islogical(x) || ischar(x));
ip.addParameter('cppDecon', ~false, @(x) islogical(x) || ischar(x));
ip.addParameter('cppDeconPath', '/global/home/groups/software/sl-7.x86_64/modules/RLDecon_CPU/20200718/build-cluster/cpuDeconv', @ischar);
ip.addParameter('loadModules', 'module load gcc/4.8.5; module load fftw/3.3.6-gcc; module load boost/1.65.1-gcc; module load libtiff/4.1.0; ', @ischar);
ip.addParameter('cudaDeconPath', '/global/home/groups/software/sl-7.x86_64/modules/cudaDecon/bin/cudaDeconv' , @ischar);
ip.addParameter('OTFGENPath', '/global/home/groups/software/sl-7.x86_64/modules/cudaDecon/bin/radialft' , @ischar); % point to radialft file
ip.addParameter('DS', true, @(x) islogical(x) || ischar(x));
ip.addParameter('DSR', false, @(x) islogical(x) || ischar(x));
ip.addParameter('Background', [], @(x) isnumeric(x) || ischar(x));
ip.addParameter('dzPSF', 0.1, @(x) isnumeric(x) || ischar(x));
ip.addParameter('EdgeErosion', 8, @(x) isnumeric(x) || ischar(x));
ip.addParameter('ErodeByFTP', true, @(x) islogical(x) || ischar(x)); % Edge erosion by the first time point (ranked the first in the inital file list for each dataset).
ip.addParameter('deconRotate', false, @(x) islogical(x) || ischar(x));
ip.addParameter('psfFullpaths', {'','',''}, @(x) iscell(x) || ischar(x));
ip.addParameter('DeconIter', 15 , @(x) isnumeric(x) || ischar(x)); % number of iterations
ip.addParameter('rotatedPSF', false , @(x) islogical(x) || ischar(x)); % psf is rotated (for dsr)
ip.addParameter('RLMethod', 'simplified' , @ischar); % rl method {'original', 'simplified', 'cudagen'}
ip.addParameter('fixIter', false, @(x) islogical(x) || ischar(x)); % CPU Memory in Gb
ip.addParameter('errThresh', [], @(x) isnumeric(x) || ischar(x)); % error threshold for simplified code
ip.addParameter('debug', false, @(x) islogical(x) || ischar(x)); % debug mode for simplified code
ip.addParameter('GPUJob', false, @(x) islogical(x) || ischar(x)); % use gpu for chuck deconvolution. 
% job related parameters
ip.addParameter('largeFile', false, @(x) islogical(x) || ischar(x));
ip.addParameter('parseCluster', true, @(x) islogical(x) || ischar(x));
ip.addParameter('jobLogDir', '../job_logs', @ischar);
ip.addParameter('cpusPerTask', 2, @(x) isnumeric(x) || ischar(x));
ip.addParameter('uuid', '', @ischar);
ip.addParameter('maxTrialNum', 3, @(x) isnumeric(x) || ischar(x));
ip.addParameter('unitWaitTime', 1, @(x) isnumeric(x) || ischar(x));
ip.addParameter('minModifyTime', 1, @(x) isnumeric(x) || ischar(x)); % the minimum during of last modify time of a file, in minute.
ip.addParameter('maxModifyTime', 10, @(x) isnumeric(x) || ischar(x)); % the maximum during of last modify time of a file, in minute.
ip.addParameter('maxWaitLoopNum', 10, @(x) isnumeric(x) || ischar(x)); % the max number of loops the loop waits with all existing files processed. 
ip.addParameter('mccMode', false, @(x) islogical(x) || ischar(x));
ip.addParameter('ConfigFile', '', @ischar);
ip.addParameter('GPUConfigFile', '', @ischar);

ip.parse(dataPaths, varargin{:});

pr = ip.Results;
Overwrite = pr.Overwrite;
Streaming = pr.Streaming;
% Resolution = pr.Resolution;
SkewAngle = pr.SkewAngle;
dz = pr.dz;
xyPixelSize = pr.xyPixelSize;
ObjectiveScan = pr.ObjectiveScan;
ZstageScan = pr.ZstageScan;
Reverse = pr.Reverse;
ChannelPatterns = pr.ChannelPatterns;
Save16bit = pr.Save16bit;
resampleType = pr.resampleType;
resample = pr.resample;
dzFromEncoder = pr.dzFromEncoder;
zarrFile = pr.zarrFile;
saveZarr = pr.saveZarr;
save3DStack = pr.save3DStack; % only for DS and DSR for now
%deskew and rotate
Deskew = pr.Deskew;
Rotate = pr.Rotate;
parseSettingFile = pr.parseSettingFile;
flipZstack = pr.flipZstack;
DSRCombined = pr.DSRCombined;
LLFFCorrection = pr.LLFFCorrection;
BKRemoval = pr.BKRemoval;
LowerLimit = pr.LowerLimit;
constOffset = pr.constOffset;
LSImagePaths = pr.LSImagePaths;
BackgroundPaths = pr.BackgroundPaths;
InputBbox = pr.InputBbox;
% stitch parameters
Stitch = pr.Stitch;
stitchPipeline = pr.stitchPipeline;
stitchResultDir = pr.stitchResultDir;
imageListFullpaths = pr.imageListFullpaths;
axisOrder = pr.axisOrder;
BlendMethod = pr.BlendMethod;
xcorrShift = pr.xcorrShift;
xcorrMode = pr.xcorrMode;
xyMaxOffset = pr.xyMaxOffset;
zMaxOffset = pr.zMaxOffset;
EdgeArtifacts = pr.EdgeArtifacts;
boundboxCrop = pr.boundboxCrop;
onlyFirstTP = pr.onlyFirstTP;
timepoints = pr.timepoints;
primaryCh = pr.primaryCh;
stitchMIP = pr.stitchMIP;
onlineStitch = pr.onlineStitch;
generateImageList = pr.generateImageList;
% decon parameters
Decon = pr.Decon;
cppDecon = pr.cppDecon;
cudaDecon = pr.cudaDecon;
cppDeconPath = pr.cppDeconPath;
loadModules = pr.loadModules;
cudaDeconPath = pr.cudaDeconPath;
OTFGENPath = pr.OTFGENPath;
EdgeErosion = pr.EdgeErosion;
ErodeByFTP = pr.ErodeByFTP;
DS = pr.DS;
DSR = pr.DSR;
Background = pr.Background;
dzPSF = pr.dzPSF;
psfFullpaths = pr.psfFullpaths;
deconRotate = pr.deconRotate;
RotateAfterDecon = pr.RotateAfterDecon;
DeconIter = pr.DeconIter;
rotatedPSF = pr.rotatedPSF;
RLMethod = pr.RLMethod;
GPUJob = pr.GPUJob;
% matlab decon simplified version related options
fixIter = pr.fixIter;
errThresh = pr.errThresh;
debug = pr.debug;
% job related
largeFile = pr.largeFile;
jobLogDir = pr.jobLogDir;
parseCluster = pr.parseCluster;
cpusPerTask = pr.cpusPerTask;
uuid = pr.uuid;
maxTrialNum = pr.maxTrialNum;
unitWaitTime = pr.unitWaitTime;
minModifyTime = pr.minModifyTime;
maxModifyTime = pr.maxModifyTime;
maxWaitLoopNum = pr.maxWaitLoopNum;
mccMode = pr.mccMode;
ConfigFile = pr.ConfigFile;
GPUConfigFile = pr.GPUConfigFile;

if ischar(dataPaths)
    dataPaths = eval(dataPaths);
end

if ischar(Overwrite)
    Overwrite = eval(Overwrite);
end
if ischar(Streaming)
    Streaming = strcmp(Streaming,'true');
end
if ischar(ChannelPatterns)
    ChannelPatterns = eval(ChannelPatterns);
end
if ischar(SkewAngle)
    SkewAngle = str2num(SkewAngle);
end
if ischar(dz)
    dz = str2num(dz);
end
if ischar(xyPixelSize)
    xyPixelSize = str2num(xyPixelSize);
end
if ischar(Reverse)
    Reverse = strcmp(Reverse,'true');
end
if ischar(ObjectiveScan)
    ObjectiveScan = strcmp(ObjectiveScan,'true');
end
if ischar(ObjectiveScan)
    ObjectiveScan = strcmp(ObjectiveScan,'true');
end
if ischar(ZstageScan)
    ZstageScan = strcmp(ZstageScan,'true');
end
if ischar(Save16bit)
    Save16bit = eval(Save16bit);
end
if ischar(onlyFirstTP)
    onlyFirstTP = strcmp(onlyFirstTP,'true');
end
if ischar(dzFromEncoder)
    dzFromEncoder = strcmp(dzFromEncoder,'true');
end
if ischar(zarrFile)
    zarrFile = strcmp(zarrFile,'true');
end
if ischar(saveZarr)
    saveZarr = strcmp(saveZarr,'true');
end
if ischar(save3DStack)
    save3DStack = strcmp(save3DStack,'true');
end
if ischar(Deskew)
    Deskew = strcmp(Deskew,'true');
end
if ischar(Rotate)
    Rotate = strcmp(Rotate,'true');
end
if ischar(Stitch)
    Stitch = strcmp(Stitch,'true');
end
if ischar(Decon)
    Decon = strcmp(Decon,'true');
end
if ischar(RotateAfterDecon)
    RotateAfterDecon = strcmp(RotateAfterDecon,'true');
end
if ischar(parseSettingFile)
    parseSettingFile = strcmp(parseSettingFile,'true');
end
if ischar(flipZstack)
    flipZstack = strcmp(flipZstack,'true');
end
if ischar(DSRCombined)
    DSRCombined = strcmp(DSRCombined,'true');
end
if ischar(LLFFCorrection)
    LLFFCorrection = strcmp(LLFFCorrection,'true');
end
if ischar(BKRemoval)
    BKRemoval = strcmp(BKRemoval,'true');
end
if ischar(LowerLimit)
    LowerLimit = str2num(LowerLimit);
end
if ischar(constOffset)
    constOffset = str2num(constOffset);
end
if ischar(LSImagePaths)
    LSImagePaths = eval(LSImagePaths);
end
if ischar(BackgroundPaths)
    BackgroundPaths = eval(BackgroundPaths);
end
if ischar(resample)
    resample = str2num(resample);
end
if ischar(InputBbox)
    InputBbox = str2num(InputBbox);
end
if ischar(imageListFullpaths)
    imageListFullpaths = eval(imageListFullpaths);
end
if ischar(xcorrShift)
    xcorrShift = strcmp(xcorrShift,'true');
end
if ischar(xyMaxOffset)
    xyMaxOffset = str2num(xyMaxOffset);
end
if ischar(zMaxOffset)
    zMaxOffset = str2num(zMaxOffset);
end
if ischar(EdgeArtifacts)
    EdgeArtifacts = str2num(EdgeArtifacts);
end
if ischar(timepoints)
    timepoints = str2num(timepoints);
end
if ischar(boundboxCrop)
    boundboxCrop = str2num(boundboxCrop);
end

if ischar(stitchMIP)
    stitchMIP = eval(stitchMIP);
end

if ischar(onlineStitch)
    onlineStitch = strcmp(onlineStitch,'true');
end
if ischar(cudaDecon)
    cudaDecon = strcmp(cudaDecon,'true');
end
if ischar(cppDecon)
    cppDecon = strcmp(cppDecon,'true');
end
if ischar(DS)
    DS = strcmp(DS,'true');
end
if ischar(DSR)
    DSR = strcmp(DSR,'true');
end
if ischar(Background)
    Background = str2num(Background);
end
if ischar(dzPSF)
    dzPSF = str2num(dzPSF);
end
if ischar(EdgeErosion)
    EdgeErosion = str2num(EdgeErosion);
end
if ischar(ErodeByFTP)
    ErodeByFTP = strcmp(ErodeByFTP,'true');
end
if ischar(deconRotate)
    deconRotate = strcmp(deconRotate,'true');
end
if ischar(psfFullpaths)
    psfFullpaths = eval(psfFullpaths);
end
if ischar(DeconIter)
    DeconIter = str2num(DeconIter);
end
if ischar(rotatedPSF)
    rotatedPSF = strcmp(rotatedPSF,'true');
end
if ischar(fixIter)
    fixIter = strcmp(fixIter,'true');
end
if ischar(errThresh)
    errThresh = str2num(errThresh);
end
if ischar(debug)
    debug = strcmp(debug,'true');
end
if ischar(GPUJob)
    GPUJob = strcmp(GPUJob,'true');
end
if ischar(largeFile)
    largeFile = strcmp(largeFile,'true');
end
if ischar(parseCluster)
    parseCluster = strcmp(parseCluster,'true');
end
if ischar(cpusPerTask)
    cpusPerTask = str2num(cpusPerTask);
end
if ischar(maxTrialNum)
    maxTrialNum = str2num(maxTrialNum);
end
if ischar(unitWaitTime)
    unitWaitTime = str2num(unitWaitTime);
end
if ischar(minModifyTime)
    minModifyTime = str2num(minModifyTime);
end
if ischar(maxModifyTime)
    maxModifyTime = str2num(maxModifyTime);
end
if ischar(maxWaitLoopNum)
    maxWaitLoopNum = str2num(maxWaitLoopNum);
end
if ischar(mccMode)
    mccMode = strcmp(mccMode,'true');
end

XR_microscopeAutomaticProcessing(dataPaths,'Overwrite',Overwrite,'Streaming',Streaming,...
    'ChannelPatterns',ChannelPatterns,'SkewAngle',SkewAngle,...
    'dz',dz,'xyPixelSize',xyPixelSize,'Reverse',Reverse,...
    'ObjectiveScan',ObjectiveScan,'ZstageScan',ZstageScan,'Save16bit',Save16bit,...
    'onlyFirstTP',onlyFirstTP,'dzFromEncoder',dzFromEncoder,'zarrFile',zarrFile,...
    'saveZarr',saveZarr,'save3DStack',save3DStack,'Deskew',Deskew,'Rotate',Rotate,...
    'Stitch',Stitch,'Decon',Decon,'RotateAfterDecon',RotateAfterDecon,...
    'parseSettingFile',parseSettingFile,'flipZstack',flipZstack,...
    'DSRCombined',DSRCombined,'LLFFCorrection',LLFFCorrection,'BKRemoval',BKRemoval,...
    'LowerLimit',LowerLimit,'constOffset',constOffset,'LSImagePaths',LSImagePaths,...
    'BackgroundPaths',BackgroundPaths,'resampleType',resampleType,'resample',resample,...
    'InputBbox',InputBbox,'stitchPipeline',stitchPipeline,'stitchResultDir',stitchResultDir,...
    'imageListFullpaths',imageListFullpaths,'axisOrder',axisOrder,'BlendMethod',BlendMethod,...
    'xcorrShift',xcorrShift,'xcorrMode',xcorrMode,'xyMaxOffset',xyMaxOffset,...
    'zMaxOffset',zMaxOffset,'EdgeArtifacts',EdgeArtifacts,'timepoints',timepoints,...
    'boundboxCrop',boundboxCrop,'primaryCh',primaryCh,'stitchMIP',stitchMIP,...
    'onlineStitch',onlineStitch,...
    'generateImageList',generateImageList,'cudaDecon',cudaDecon,'cppDecon',cppDecon,...
    'cppDeconPath',cppDeconPath,'loadModules',loadModules,'cudaDeconPath',cudaDeconPath,...
    'OTFGENPath',OTFGENPath,'DS',DS,'DSR',DSR,'Background',Background,'dzPSF',dzPSF,...
    'EdgeErosion',EdgeErosion,'ErodeByFTP',ErodeByFTP,'deconRotate',deconRotate,...
    'psfFullpaths',psfFullpaths,'DeconIter',DeconIter,'rotatedPSF',rotatedPSF,...
    'RLMethod',RLMethod,'fixIter',fixIter,'errThresh',errThresh,'debug',debug,...
    'GPUJob',GPUJob,'largeFile',largeFile,'parseCluster',parseCluster,...
    'jobLogDir',jobLogDir,'cpusPerTask',cpusPerTask,...
    'uuid',uuid,'maxTrialNum',maxTrialNum,'unitWaitTime',unitWaitTime,...
    'minModifyTime',minModifyTime,'maxModifyTime',maxModifyTime,'maxWaitLoopNum',maxWaitLoopNum,...
    'mccMode',mccMode,'ConfigFile',ConfigFile,'GPUConfigFile',GPUConfigFile);

end

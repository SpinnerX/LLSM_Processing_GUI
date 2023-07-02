function simReconFrame_parser(frameFullpaths, otf, varargin)

ip = inputParser;
ip.CaseSensitive = false;


ip.addRequired('frameFullpaths', @(x) ischar(x) || iscell(x));


ip.addRequired('otf');

ip.addParameter('resultsDirName', 'sim_recon', @ischar);

ip.addParameter('islattice', true, @(x) islogical(x) || ischar(x)); %Flag to indicate if this is light sheet data
ip.addParameter('NA_det', 1.0, @(x) isnumeric(x) || ischar(x));
ip.addParameter('NA_ext', 0.55, @(x) isnumeric(x) || ischar(x));
ip.addParameter('nimm', 1.33, @(x) isnumeric(x) || ischar(x));
ip.addParameter('wvl_em', .605, @(x) isnumeric(x) || ischar(x));
ip.addParameter('wvl_ext', .560, @(x) isnumeric(x) || ischar(x));
ip.addParameter('w', 5e-3, @(x) isnumeric(x) || ischar(x)); %Wiener coefficient for regularization
ip.addParameter('apodize', true, @(x) islogical(x) || ischar(x)); %Flag to indicate whether or not to apodize the final data

ip.addParameter('DS', false, @(x) islogical(x) || ischar(x));
ip.addParameter('nphases', 5, @(x) isnumeric(x) || ischar(x));
ip.addParameter('norders', 5, @(x) isnumeric(x) || ischar(x));
ip.addParameter('norientations', 1, @(x) isnumeric(x) || ischar(x));
ip.addParameter('lattice_period', 1.2021, @(x) isnumeric(x) || ischar(x)); %Lattice period in microns - this is the coarsest period
ip.addParameter('lattice_angle', [pi/2], @(x) isnumeric(x) || ischar(x)); %Angle parellel to pattern modulation (assuming horizontal is zero)
ip.addParameter('phase_step', .232, @(x) isnumeric(x) || ischar(x)); %Phase step in microns
ip.addParameter('pxl_dim_data', [0.11,0.11,0.3*sind(32.4)], @(x) isnumeric(x) || ischar(x)); %Voxel dimensions of the image in microns - note, stored as [dy,dx,dz]
ip.addParameter('pxl_dim_PSF', [0.11,0.11,0.2*sind(32.4)], @(x) isnumeric(x) || ischar(x)); %Voxel dimensions of the PSF in microns - note, stored as [dy,dx,dz]
ip.addParameter('Background', 105, @(x) isnumeric(x) || ischar(x));

ip.addParameter('normalize_orientations', false, @(x) islogical(x) || ischar(x)); %Flag to indicate whether or not to normalize total intensity for each orientation
ip.addParameter('perdecomp', false, @(x) islogical(x) || ischar(x)); %Flag to indicate whether or not to use periodic/smooth decomposition to reduce edge effects
ip.addParameter('edgeTaper', false, @(x) islogical(x) || ischar(x)); %Flag to indicate whether or not to window the data to reduce edge effects
ip.addParameter('edgeTaperVal', 0.1, @(x) isnumeric(x) || ischar(x)); %Roll-off parameter for Tukey windowing

ip.addParameter('useGPU', true, @(x) islogical(x) || ischar(x));

ip.addParameter('Overwrite', false , @(x) islogical(x) || ischar(x));
ip.addParameter('Save16bit', false , @(x) islogical(x) || ischar(x));
ip.addParameter('gpuPrecision', 'single', @ischar);

ip.addParameter('flipZstack', false, @(x) islogical(x) || ischar(x));
ip.addParameter('EdgeSoften', 5, @(x) isnumeric(x) || ischar(x)); % # ofxy px to soften
ip.addParameter('zEdgeSoften', 2, @(x) isnumeric(x) || ischar(x)); % # ofxy px to soften
ip.addParameter('Crop', [], @(x) isnumeric(x) || ischar(x)); % requires lower and higher values for cropping
ip.addParameter('zFlip', false, @(x) islogical(x) || ischar(x));
ip.addParameter('GenMaxZproj', [0,0,1] , @(x) isnumeric(x) || ischar(x));
ip.addParameter('ResizeImages', [] , @(x) isnumeric(x) || ischar(x));
ip.addParameter('EdgeErosion', 0 , @(x) isnumeric(x) || ischar(x)); % erode edges for certain size.
ip.addParameter('ErodeBefore', false, @(x) islogical(x) || ischar(x));
ip.addParameter('ErodeAfter', true,@(x) islogical(x) || ischar(x));
ip.addParameter('ErodeMaskfile', '', @ischar); % erode edges file
ip.addParameter('SaveMaskfile', false, @(x) islogical(x) || ischar(x)); % save mask file for common eroded mask
ip.addParameter('ChunkSize', [250, 250, 250] , @(x) isvector(x) || ischar(x)); % in y, x, z
ip.addParameter('Overlap', 10, @(x) isnumeric(x) || ischar(x)); % block overlap
ip.addParameter('maxSubVolume', 3e8, @(x) isnumeric(x) || ischar(x));
ip.addParameter('CPUMaxMem', 500, @(x) isnumeric(x) || ischar(x)); % CPU Memory in Gb
ip.addParameter('largeFile', false, @(x) islogical(x) || ischar(x));
ip.addParameter('parseCluster', true, @(x) islogical(x) || ischar(x));
ip.addParameter('masterCompute', true, @(x) islogical(x) || ischar(x)); % master node participate in the task computing.
ip.addParameter('masterCPU', false, @(x) islogical(x) || ischar(x)); % master node is a cpu node, which is just for large file deconvolution.
ip.addParameter('jobLogDir', '../job_logs', @ischar);
ip.addParameter('cpusPerTask', 5, @(x) isnumeric(x) || ischar(x));
ip.addParameter('uuid', '', @ischar);
ip.addParameter('maxTrialNum', 3, @(x) isnumeric(x) || ischar(x));
ip.addParameter('unitWaitTime', 2, @(x) isnumeric(x) || ischar(x));
ip.addParameter('intThresh', 1, @(x) isnumeric(x) || ischar(x));
ip.addParameter('occThresh', 0.8, @(x) isnumeric(x) || ischar(x));

ip.parse(frameFullpaths, otf, varargin{:});

if ischar(frameFullpaths)
    frameFullpaths = {frameFullpaths};
end

pr = ip.Results;

resultsDirName = pr.resultsDirName;

islattice = pr.islattice;
NA_det = pr.NA_det;
NA_ext = pr.NA_ext;
nimm = pr.nimm;
wvl_em = pr.wvl_em;
wvl_ext = pr.wvl_ext;
w = pr.w;
apodize = pr.apodize;

DS = pr.DS;
nphases = pr.nphases;
norders = pr.norders;
norientations = pr.norientations;
lattice_period = pr.lattice_period;
lattice_angle = pr.lattice_angle;
phase_step = pr.phase_step;
pxl_dim_data = pr.pxl_dim_data;
pxl_dim_PSF = pr.pxl_dim_PSF;
Background = pr.Background;

normalize_orientations = pr.normalize_orientations;
perdecomp = pr.perdecomp;
edgeTaper = pr.edgeTaper;
edgeTaperVal = pr.edgeTaperVal;
intThresh = pr.intThresh;
occThresh = pr.occThresh;

Save16bit = pr.Save16bit;
gpuPrecision = pr.gpuPrecision;

useGPU = pr.useGPU;

flipZstack = pr.flipZstack;

EdgeErosion = pr.EdgeErosion;
ErodeBefore = pr.ErodeBefore;
ErodeAfter = pr.ErodeAfter;
ErodeMaskfile = pr.ErodeMaskfile;
if ~isempty(ErodeMaskfile) && exist(ErodeMaskfile, 'file')
    EdgeErosion = 0; % set EdgeErosion length as 0.
end
SaveMaskfile = pr.SaveMaskfile;

Overlap = pr.Overlap;
ChunkSize = pr.ChunkSize;
maxSubVolume = pr.maxSubVolume;
uuid = pr.uuid;

if ischar(islattice)
    islattice = strcmp(islattice,'true');
end
if ischar(NA_det)
    NA_det = str2num(NA_det);
end
if ischar(NA_ext)
    NA_ext = str2num(NA_ext);
end
if ischar(nimm)
    nimm = str2num(nimm);
end
if ischar(wvl_em)
    wvl_em = str2num(wvl_em);
end
if ischar(wvl_ext)
    wvl_ext = str2num(wvl_ext);
end
if ischar(w)
    w = str2num(w);
end
if ischar(apodize)
    apodize = strcmp(apodize,'true');
end
if ischar(DS)
    DS = strcmp(DS,'true');
end
if ischar(nphases)
    nphases = str2num(nphases);
end
if ischar(norders)
    norders = str2num(norders);
end
if ischar(norientations)
    norientations = str2num(norientations);
end
if ischar(lattice_period)
    lattice_period = str2num(lattice_period);
end
if ischar(lattice_angle)
    lattice_angle = str2num(lattice_angle);
end
if ischar(phase_step)
    phase_step = str2num(phase_step);
end
if ischar(pxl_dim_data)
    pxl_dim_data = str2num(pxl_dim_data);
end
if ischar(pxl_dim_PSF)
    pxl_dim_PSF = str2num(pxl_dim_PSF);
end
if ischar(Background)
    Background = str2num(Background);
end
if ischar(normalize_orientations)
    normalize_orientations = strcmp(normalize_orientations,'true');
end
if ischar(perdecomp)
    perdecomp = strcmp(perdecomp,'true');
end
if ischar(edgeTaper)
    edgeTaper = strcmp(edgeTaper,'true');
end
if ischar(edgeTaperVal)
    edgeTaperVal = str2num(edgeTaperVal);
end
if ischar(useGPU)
    useGPU = strcmp(useGPU,'true');
end
if ischar(Save16bit)
    Save16bit = strcmp(Save16bit,'true');
end
if ischar(EdgeErosion)
    EdgeErosion = str2num(EdgeErosion);
end
if ischar(ErodeAfter)
    ErodeAfter = strcmp(ErodeAfter,'true');
end
if ischar(SaveMaskfile)
    SaveMaskfile = strcmp(SaveMaskfile,'true');
end
if ischar(flipZstack)
    flipZstack = strcmp(flipZstack,'true');
end
if ischar(ChunkSize)
    ChunkSize = str2num(ChunkSize);
end
if ischar(Overlap)
    Overlap = str2num(Overlap);
end
if ischar(maxSubVolume)
    maxSubVolume = str2num(maxSubVolume);
end
if ischar(intThresh)
    intThresh = str2num(intThresh);
end
if ischar(occThresh)
    occThresh = str2num(occThresh);
end

simReconFrame(frameFullpaths,otf,'resultsDirName',resultsDirName,...
    'islattice',islattice,'NA_det',NA_det,'NA_ext',NA_ext,'nimm',nimm,'wvl_em',wvl_em,...
    'wvl_ext',wvl_ext,'w',w,'apodize',apodize,'DS',DS,'nphases',nphases,...
    'norders',norders,'norientations',norientations,'lattice_period',lattice_period,...
    'lattice_angle',lattice_angle,'phase_step',phase_step,...
    'pxl_dim_data',pxl_dim_data,'pxl_dim_PSF',pxl_dim_PSF,'Background',Background,...
    'normalize_orientations',normalize_orientations,'perdecomp',perdecomp,...
    'edgeTaper',edgeTaper,'edgeTaperVal',edgeTaperVal,'useGPU',useGPU,...
    'Save16bit',Save16bit,'gpuPrecision',gpuPrecision,...
    'flipZstack',flipZstack,'EdgeErosion',EdgeErosion,'ErodeBefore',ErodeBefore,...
    'ErodeAfter',ErodeAfter,'ErodeMaskfile',ErodeMaskfile,...
    'SaveMaskfile',SaveMaskfile,'ChunkSize',ChunkSize,'Overlap',Overlap,...
    'maxSubVolume',maxSubVolume,'intThresh',intThresh,'occThresh',occThresh);
    

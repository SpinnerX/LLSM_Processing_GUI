%[data] = deskewData(varargin) de-skews and rotates light sheet microscope data sets
% The function launches a small GUI enabling input of acquisition parameters, after which
% it prompts for input of cropping regions to minimize file sizes. By default, the function
% generates the de-skewed data required for processing; optionally the function can also
% generate rotated frames for visualization.
%
% Inputs (optional):
%      data : structure returned by loadConditionData()
%
% Options ('specifier', value):
%         'Overwrite' : true|{false}, enables overwriting of previously de-skewed/rotated data
%     'MovieSelector' : String in directory name identifying individual movies. Default: 'cell'
%              'Crop' : {true}|false, automatic cropping of the de-skewed movie at the boundaries
%         'SkewAngle' : Sets the scanning angle of the system. Default: 32.8 degrees
%            'Rotate' : true|{false}. Set to true to generate rotated frames for visualization
%           'Reverse' : flip in z direction. Default: false 
%'CheckFrameMismatch' : Repair dropped frames in movies. Default: false
%      'LoadSettings' : load figure settings. Default: false
%   'sCMOSCameraFlip' : sCMOS camera flip. Default: false
%    'LLFFCorrection' : flat-field correction, default false
%        'LowerLimit' : Lower bound for mask in flat-field correction, default 0.4
%        'LSImageCh1' : path of light-sheet image for channel 1
%        'LSImageCh2' : path of light-sheet image for channel 2, leave as '' if there is no channel 2
%        'LSImageCh3' : path of light-sheet image for channel 3, leave as '' if there is no channel 3
%        'LSImageCh4' : path of light-sheet image for channel 4, leave as '' if there is no channel 4
%     'BackgroundCh1' : path of background image for channel 1
%     'BackgroundCh2' : path of background image for channel 2, leave as '' if there is no channel 2
%     'BackgroundCh3' : path of background image for channel 3, leave as '' if there is no channel 3
%     'BackgroundCh4' : path of background image for channel 4, leave as '' if there is no channel 4
%         'Save16bit' : save deskewed image as uint16. Default: false
%             'aname' : the name of directory that stores the results (under the primary channel directory). 
% 'ZoffsetCorrection' : shift in Z directions to adjust potential offsets across different channels. Default: false. 
% 

% Francois Aguet, 11/2013
% edited Gokul Upadhyayula, Sep 2015
% GU: rotates sCMOS data - case sensitive 'CamA' (rotation) &  'CamB' (rotation and camera flip)
% GU: adds light-sheet correction
% XR: 11/02/2019 allow user-defined analysis directory
% XR: 11/21/2019 add z-offset correction step before crop. 

% camAbk = squeeze(mean(readtiff('/media/tklab/Data/data32b/Eric/calibrations/Ex04_camA-B_darkCurrent-camPatternMeasurement_z0p2/ex04_CamA_ch0_CAM1_stack0000_488nm_0000000msec_0001057088msecAbs_000x_000y_000z_0000t.tif'),3));
% writetiff(camAbk, ['/media/tklab/Data/data32b/Eric/calibrations/Ex04_camA-B_darkCurrent-camPatternMeasurement_z0p2/camADC.tif'])
% camBbk = squeeze(mean(readtiff('/media/tklab/Data/data32b/Eric/calibrations/Ex04_camA-B_darkCurrent-camPatternMeasurement_z0p2/ex04_CamB_ch1_CAM1_stack0000_560nm_0000000msec_0001057088msecAbs_000x_000y_000z_0000t.tif'),3));
% writetiff(camBbk, ['/media/tklab/Data/data32b/Eric/calibrations/Ex04_camA-B_darkCurrent-camPatternMeasurement_z0p2/camBDC.tif'])
% rt = '/media/tklab/Data/data32b/Eric/calibrations/Ex04_camA-B_darkCurrent-camPatternMeasurement_z0p2/';
% LLCopts = {'LLFFCorrection',true, 'LowerLimit',0.5, ...
%     'LSImageCh1', ['/media/tklab/Data/data32b/Eric/calibrations/Ex02_fieldCorrection_488-560_z0p2/EX02_CamB_ch1_stack0000_560nm_0000000msec_0001815773msecAbs.tif'], ...
%     'LSImageCh2',['/media/tklab/Data/data32b/Eric/calibrations/Ex01_fieldCorrection_642_z0p2/ex01_CamA_ch0_stack0000_642nm_0000000msec_0001310798msecAbs.tif'],...
%     'LSImageCh3','',...
%     'LSImageCh4','',...
%     'BackgroundCh1',[rt 'camBDC.tif'],...
%     'BackgroundCh2',[rt 'camADC.tif'],...
%     'BackgroundCh3','',...
%     'BackgroundCh4',''};
%
% deskewData(data, LLCopts{:});

% 1. camera rot/flip; 2. flat-field correction; 3. deskew; 4. rotate

function [data] = deskewData(varargin)

ip = inputParser;
ip.CaseSensitive = false;
ip.addOptional('data', [], @isstruct); % data structure from loadConditionData
ip.addParameter('Overwrite', false, @islogical);
ip.addParameter('MovieSelector', 'cell', @ischar);
ip.addParameter('Crop', false, @islogical);
ip.addParameter('SkewAngle', 31.5, @isscalar);
ip.addOptional('Reverse', false, @islogical);
ip.addParameter('Rotate', false, @islogical);
ip.addParameter('CheckFrameMismatch', false, @islogical);
ip.addParameter('LoadSettings', false, @islogical);
% sCMOS camera flip
ip.addParameter('sCMOSCameraFlip', false, @islogical);
% LLSM Flat-FieldCorrection
ip.addParameter('LLFFCorrection', false, @islogical);
ip.addParameter('LowerLimit', 0.4, @isnumeric); % this value is the lowest
ip.addParameter('LSImageCh1', '' , @isstr);
ip.addParameter('LSImageCh2', '' , @isstr);
ip.addParameter('LSImageCh3', '' , @isstr);
ip.addParameter('LSImageCh4', '' , @isstr);
ip.addParameter('BackgroundCh1', '' , @isstr);
ip.addParameter('BackgroundCh2', '' , @isstr);
ip.addParameter('BackgroundCh3', '' , @isstr);
ip.addParameter('BackgroundCh4', '' , @isstr);
ip.addParameter('Save16bit', false , @islogical); % saves deskewed data as 16 bit -- not for quantification
ip.addParameter('aname', @isstr); % XR allow user-defined result path
ip.addParameter('ZoffsetCorrection', false, @islogical); % xruan: add option for correction of z offset
ip.parse(varargin{:});
data = ip.Results.data;
if isempty(data)
    data = loadConditionData3D('MovieSelector', ip.Results.MovieSelector);
end
nd = numel(data);

% LS Image and Background Paths
LLFFCorrection = ip.Results.LLFFCorrection;
LSImage{1} = ip.Results.LSImageCh1;
if ~isempty(ip.Results.LSImageCh2)
    LSImage{2} = ip.Results.LSImageCh2;
end
if ~isempty(ip.Results.LSImageCh3)
    LSImage{3} = ip.Results.LSImageCh3;
end
if ~isempty(ip.Results.LSImageCh4)
    LSImage{4} = ip.Results.LSImageCh4;
end

BKImage{1} = ip.Results.BackgroundCh1;
if ~isempty(ip.Results.BackgroundCh2)
    BKImage{2} = ip.Results.BackgroundCh2;
end
if ~isempty(ip.Results.BackgroundCh3)
    BKImage{3} = ip.Results.BackgroundCh3;
end
if ~isempty(ip.Results.BackgroundCh4)
    BKImage{4} = ip.Results.BackgroundCh4;
end

% Z offset Correction
ZoffsetCorrection = ip.Results.ZoffsetCorrection;

%-----------------------------------------------------------------------------------------
% 0) Repair dropped frames in movies from Wes's systems
%-----------------------------------------------------------------------------------------
if ip.Results.CheckFrameMismatch
    frameID = '_stack';
    mismatch = false;
    for i = 1:nd
        for c = 1:numel(data(i).channels)
            idx = str2double(regexpi(data(i).framePaths{c}, ['(?<=' frameID ')\d+'], 'match', 'once'));
            if any(getMultiplicity(idx)>1)
                fprintf('Frame mismatch in channel %d of %s detected ...\n', c, getShortPath(data(i)));
                restoreDroppedFrames(data(i), frameID);
                fprintf(' ... repaired\n');
                mismatch = true;
            end
        end
    end
    % reload movie information if dropped frames were repaired
    if mismatch
        fprintf('Re-loading data after frame repair.\n');
        data = loadConditionData('MovieSelector', ip.Results.MovieSelector);
    end
end

%-----------------------------------------------------------------------------------------
% 1) Check whether de-skewing has already been run
%-----------------------------------------------------------------------------------------
hasDS = false(1,nd);
hasDSR = false(1,nd);
for i = 1:nd
    % check whether de-skewing has been run
    tmp = dir([data(i).source 'DS']);
    tmp = {tmp(~[tmp.isdir]).name}';
    tmp = tmp(~cellfun(@isempty, regexpi(tmp, '\.tif')));
    hasDS(i) = numel(tmp)==data(i).movieLength;
    
    % check whether rotation has already been run
    tmp = dir([data(i).source 'DSR']);
    tmp = {tmp(~[tmp.isdir]).name}';
    tmp = tmp(~cellfun(@isempty, regexpi(tmp, '\.tif')));
    hasDSR(i) = numel(tmp)==data(i).movieLength;
end


% destination path to store crop area & dynamic range
% xruan
% apath = arrayfun(@(i) [i.source 'Analysis' filesep], data, 'unif', 0);
apath = arrayfun(@(i) [i.source ip.Results.aname filesep], data, 'unif', 0);
for i = 1:numel(data)
    if ~(exist(apath{i},'dir')==7)
        [~,~] = mkdir(apath{i});
    end
end

%-----------------------------------------------------------------------------------------
% 2) Get system parameters for each data set
%-----------------------------------------------------------------------------------------
dz = [data.dz];
xyPixelSize = [data.pixelSize];
objectiveScan = [data.objectiveScan];
reversed = [data.reversed];

if ~all(hasDS) || ip.Results.Overwrite || (ip.Results.Rotate && ~all(hasDSR))
    if ip.Results.LoadSettings
        loadSettings(data);
        drawnow;
    end
    
    for i = 1:nd
        prm.dz = dz(i);
        prm.xyPixelSize = xyPixelSize(i);
        prm.objectiveScan = objectiveScan(i);
        prm.reversed = reversed(i);
        save([apath{i} 'settings.mat'], '-struct', 'prm');
    end
end

%-----------------------------------------------------------------------------------------
% 3.0) Get z-offset for de-skewing (xruan)
%-----------------------------------------------------------------------------------------
if ZoffsetCorrection
    z_pad_info_cell = XR_GetZoffsetInfoData3D(data, 'sCMOSCameraFlip', ip.Results.sCMOSCameraFlip);
end

%-----------------------------------------------------------------------------------------
% 3) Get crop area ROI for de-skewing
%-----------------------------------------------------------------------------------------
roiVec = cell(1,nd);

if ip.Results.Crop && ~ip.Results.sCMOSCameraFlip
    for i = 1:nd
        [~,~] = mkdir(apath{i});
        roiPath = [apath{i} 'cropROI.mat'];
        if exist(roiPath, 'file')==2 && ~ip.Results.Overwrite
            load(roiPath);
            roiVec{i} = cropROI;
        else
            cropROI = getCropRegions3D(data(i), 'Overwrite', ip.Results.Overwrite);
            cropROI = cropROI{1};
            save(roiPath, 'cropROI');
            roiVec{i} = cropROI;
        end
    end
elseif ~ip.Results.Crop && ~ip.Results.sCMOSCameraFlip
    for i = 1:nd
        roiVec{i} = [1 1 data(i).imagesize(2) data(i).imagesize(1)];
    end
elseif ~ip.Results.Crop && ip.Results.sCMOSCameraFlip
    for i = 1:nd
        roiVec{i} = [1 1 data(i).imagesize(1) data(i).imagesize(2)];
    end
elseif ip.Results.Crop && ip.Results.sCMOSCameraFlip
    for i = 1:nd
        [~,~] = mkdir(apath{i});
        roiPath = [apath{i} 'cropROI.mat'];
        if exist(roiPath, 'file')==2 && ~ip.Results.Overwrite
            load(roiPath);
            roiVec{i} = cropROI;
        else
            cropROI = getCropRegions3D(data(i), 'Overwrite', ip.Results.Overwrite);
            cropROI = cropROI{1};
            save(roiPath, 'cropROI');
            roiVec{i} = cropROI;
        end
    end
end

%-----------------------------------------------------------------------------------------
% 4) De-skew data
%-----------------------------------------------------------------------------------------
for i = 1:nd
    if ~hasDS(i) || ip.Results.Overwrite
        
        nf = data(i).movieLength;
        nCh = numel(data(i).channels);
        dRange = zeros(nf,2,nCh);
        
        % crop coordinates
        xa = roiVec{i}(1) + (0:roiVec{i}(3)-1);
        ya = roiVec{i}(2) + (0:roiVec{i}(4)-1);
        
        if ip.Results.Crop && ip.Results.sCMOSCameraFlip
            ya = roiVec{i}(1) + (0:roiVec{i}(3)-1);
            xa = roiVec{i}(2) + (0:roiVec{i}(4)-1);
        end
        
        % Z offset Correction
        if ZoffsetCorrection
            pad_mat = z_pad_info_cell{i};
            nPad = pad_mat(1, 1) + pad_mat(1, 2);
            if nPad > 1
                flag = 1;
            end
        else
            pad_mat = zeros(nCh, 1);
            nPad = 0;
        end
        
        for c = 1:nCh
            dsPath = [data(i).channels{c} 'DS' filesep];
            [~,~] = mkdir(dsPath);
            
            if ~objectiveScan(i)
                fprintf('De-skewing ''%s'', channel %d:   0%%', getShortPath(data(i)), c);
                parfor f = 1:nf
                    % load frame
                    frame = double(readtiff(data(i).framePaths{c}{f})); %#ok<PFBNS>
                    % sCMOS camera rotation / flip if necessary
                    if ip.Results.sCMOSCameraFlip
                        [~, fn, ~] = fileparts(data(i).framePaths{c}{f});
                        camidx = regexpi(fn, 'Cam\D') + 3;
                        cam = fn(camidx);
                        frame = GU_sCMOSCameraFlip(frame, cam);
                    end
                    % LS FF Correction
                    if LLFFCorrection
                        LSIm = readtiff(LSImage{c});
                        BKIm = readtiff(BKImage{c});
                        frame = GU_LSFlatFieldCorrection(frame,LSIm,BKIm,'LowerLimit', ip.Results.LowerLimit);
                    end
                    
                    % Correct Z offset
                    if ZoffsetCorrection && nPad > 0
                        ds = zeros(numel(ya), numel(xa), size(frame, 3) + nPad);
                        ds(:, :, pad_mat(c, 1) + 1 : end - pad_mat(c, 2)) = frame(ya,xa,:);
                    else
                        ds = frame(ya,xa,:);
                    end
                    
                    %dsRef = shear3DinDim2(frame(ya,xa,:), ip.Results.SkewAngle, bReverse(i), dz(i), xyPixelSize(i), 0, 0);
                    ds = deskewFrame3D(ds, ip.Results.SkewAngle, dz(i), xyPixelSize(i), reversed(i),...
                        'Crop', ip.Results.Crop, 'Reverse', ip.Results.Reverse); %#ok<PFBNS>
                    
                    [~,fname] = fileparts(data(i).framePaths{c}{f});
                    writetiff(single(ds), [dsPath fname '.tif']);
                    dRange(f,:,c) = [min(ds(:)) max(ds(:))];
                    fprintf('\b\b\b\b%3d%%', round(100*f/nf));
                end
                fprintf('\n');
            else % crop only
                fprintf('Cropping ''%s'', channel %d ... ', getShortPath(data(i)), c);
                parfor f = 1:nf
                    % load frame
                    frame = double(readtiff(data(i).framePaths{c}{f})); %#ok<PFBNS>
                    if ip.Results.sCMOSCameraFlip
                        [~, fn, ~] = fileparts(data(i).framePaths{c}{f});
                        camidx = regexpi(fn, 'Cam\D') + 3;
                        cam = fn(camidx);
                        frame = GU_sCMOSCameraFlip(frame, cam);
                    end
                    if LLFFCorrection
                        LSIm = readtiff(LSImage{c});
                        BKIm = readtiff(BKImage{c});
                        frame = GU_LSFlatFieldCorrection(frame,LSIm,BKIm,'LowerLimit', ip.Results.LowerLimit);
                    end
                    
                    % Correct Z offset                    
                    if ZoffsetCorrection && nPad > 0
                        ds = zeros(numel(ya), numel(xa), size(frame, 3) + nPad);
                        ds(:, :, cur_pad_mat(1) + 1 : end - cur_pad_mat(2)) = frame(ya,xa,:);
                    else
                        ds = frame(ya,xa,:);
                    end
                    
                    [~,fname] = fileparts(data(i).framePaths{c}{f});
                    if ip.Results.Save16bit
                        writetiff(uin16(ds), [dsPath fname '.tif']);
                    else
                        writetiff(single(ds), [dsPath fname '.tif']);
                    end
                    dRange(f,:,c) = [min(ds(:)) max(ds(:))];
                end
                fprintf('done.\n');
            end
        end
        save([apath{i} 'dynRange.mat'], 'dRange');
    end
end

%-----------------------------------------------------------------------------------------
% 4) Rotate data
%-----------------------------------------------------------------------------------------
if ip.Results.Rotate
    for i = 1:nd
        if ~hasDSR(i) || ip.Results.Overwrite
            load([apath{i} 'dynRange.mat']);
            
            for c = 1:numel(data(i).channels)
                dsPath = [data(i).channels{c} 'DS' filesep];
                dsrPath = [data(i).channels{c} 'DSR' filesep];
                [~,~] = mkdir(dsrPath);
                
                iRange = [min(dRange(:,1,c)) max(dRange(:,2,c))];
                
                fprintf('Rotating ''%s'' channel %d:   0%%', getShortPath(data(i)), c);
                nf = data(i).movieLength;
                parfor f = 1:nf
                    [~,fname] = fileparts(data(i).framePaths{c}{f}); %#ok<PFBNS>
                    ds = readtiff([dsPath fname '.tif']);
                    dsr = rotateFrame3D(ds, ip.Results.SkewAngle, data(i).zAniso, reversed(i),...
                        'Crop', true, 'ObjectiveScan', objectiveScan(i)); %#ok<PFBNS>
                    writetiff(uint16(scaleContrast(dsr, iRange, [0 65535])), [dsrPath fname '.tif']);
                    fprintf('\b\b\b\b%3d%%', round(100*f/nf));
                end
                fprintf('\n');
            end
        end
    end
end


    function loadSettings(data)
        
        nd = numel(data);
        
        tpos = get(0, 'DefaultFigurePosition');
        tpos = [tpos(1)+tpos(3)/2-150 tpos(2)+tpos(4)/2-75 400 245];
        
        selectedData = 1;
        
        pht = figure('Units', 'pixels', 'Position', tpos, 'Name', 'De-skewing settings',...
            'PaperPositionMode', 'auto', 'Menubar', 'none', 'Toolbar', 'none',...
            'Color', get(0,'defaultUicontrolBackgroundColor'),...
            'DefaultUicontrolUnits', 'pixels', 'Units', 'pixels',...
            'NumberTitle', 'off');
        
        
        % selection sliders
        b  = 155;
        if nd>1
            uicontrol(pht, 'Style', 'text', 'String', 'Select data set:',...
                'Position', [5 b+35 120 20], 'HorizontalAlignment', 'left');
            dataTxt = uicontrol(pht, 'Style', 'text', 'String', ['# ' num2str(selectedData)],...
                'Position', [5 b+18 40 20], 'HorizontalAlignment', 'left');
            dataSlider = uicontrol(pht, 'Style', 'slider',...
                'Value', 1, 'SliderStep', 1/(nd-1)*[1 1], 'Min', 1, 'Max', nd,...
                'Position', [50 b+20 200 18]);
            addlistener(handle(dataSlider), 'Value', 'PostSet', @dataSlider_Callback);
        end
        dataTxt2 = uicontrol(pht, 'Style', 'text', 'String', getDirFromPath(data(selectedData).source),...
            'Position', [20 b-5 300 20], 'HorizontalAlignment', 'left');
        
        % Category selection buttons
        b = 115;
        uicontrol(pht, 'Style', 'text', 'String', 'Select system: ',...
            'Position', [5 b 90 20], 'HorizontalAlignment', 'left');
        
        frameChoice = uicontrol(pht, 'Style', 'popup',...
            'String', {'Slice', 'Bi-Chang', 'Wes'},...
            'Position', [105 b+3 100 20], 'Callback', @frameChoice_Callback);
        function frameChoice_Callback(varargin)
            contents = cellstr(get(frameChoice, 'String'));
            switch contents{get(frameChoice, 'Value')}
                case 'Slice'
                    reversed(selectedData) = false;
                    xyPixelSize(selectedData) = 0.104;
                case 'Bi-Chang'
                    reversed(selectedData) = true;
                    xyPixelSize(selectedData) = 0.114;
                case 'Wes'
                    reversed(selectedData) = false;
                    xyPixelSize(selectedData) = 0.104;
            end
        end
        
        uicontrol(pht, 'Style', 'text', 'String', ['z-step [' char(181) 'm] :'],...
            'Position', [225 b 190 20], 'HorizontalAlignment', 'left');
        dzText = uicontrol(pht, 'Style', 'edit',...
            'String', num2str(dz(selectedData)),...
            'Position', [310 b 80 25], 'Callback', @dzText_Callback);
        
        function dzText_Callback(varargin)
            dz(selectedData) = str2double(get(dzText, 'String'));
        end
        
        
        
        scanCheck = uicontrol(pht, 'Style', 'checkbox', 'String', 'Objective scan (no de-skewing)',...
            'Position', [85 b-30 220 15], 'HorizontalAlignment', 'left',...
            'Value', objectiveScan(selectedData), 'Callback', @objectiveScan_Callback);
        function objectiveScan_Callback(varargin)
            objectiveScan(selectedData) = get(scanCheck, 'Value');
        end
        
        
        uicontrol(pht, 'Style', 'pushbutton', 'String', 'Apply',...
            'Position', [180 5 100 20], 'HorizontalAlignment', 'left',...
            'Callback', @applyButton_Callback);
        
        function dataSlider_Callback(~, eventdata)
            % update z-step first
            %dz(selectedData) = str2double(get(dzText, 'String'))
            
            obj = get(eventdata, 'AffectedObject');
            selectedData = round(get(obj, 'Value'));
            %set(selectedData, 'Value', selectedData);
            set(dataTxt, 'String', ['# ' num2str(selectedData)]);
            set(dataTxt2, 'String', getDirFromPath(data(selectedData).source));
            
            % refresh system choice
            if ~reversed(selectedData) && xyPixelSize(selectedData)==0.114
                set(frameChoice, 'Value', 1);
            elseif reversed(selectedData) && xyPixelSize(selectedData)==0.114
                set(frameChoice, 'Value', 2);
            else
                set(frameChoice, 'Value', 3);
            end
            
            % refresh scan
            set(scanCheck, 'Value', objectiveScan(selectedData));
            
            set(dzText, 'String', num2str(dz(selectedData)));
        end
        
        function applyButton_Callback(varargin)
            dz(selectedData) = str2double(get(dzText, 'String'));
            close(pht);
        end
        
        uiwait(pht);
    end

end

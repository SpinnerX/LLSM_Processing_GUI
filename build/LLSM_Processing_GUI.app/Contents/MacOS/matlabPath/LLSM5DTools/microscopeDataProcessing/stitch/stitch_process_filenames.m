function [inputFullpaths, zarrFullpaths, fsnames, zarrPathstr] = stitch_process_filenames(tileFullpaths, ProcessedDirstr, stitchMIP, resample, zarrFile, processTiles)
% return tile paths and other info based on the processing required for the
% data (i.e., dsr, dsr/decon, decon, raw etc)
% 
% The code is taken from the main stitching function (for simplify), and
% with further improvement
%
% Author: Xiongtao Ruan (07/23/2021)
%
% xruan (07/27/2021): if resample not empty, indicate resample factor in
% the zarr folder
% xruan (10/13/2021): add support for stitching with reference for decon data
% xruan (12/20/2021): add support for mip stitching
% xruan (02/17/2023): simplify code and remove unused code. 

nF = numel(tileFullpaths);

% convert tif to zarr files (first assume the files exist)
inputFullpaths = cell(nF, 1);
zarrFullpaths = cell(nF, 1);
fsnames = cell(nF, 1);
suffix_str = 'z';
if zarrFile
    ext = '.zarr';
else
    ext = '.tif';
end
for i = 1 : nF
    tileFullpath = tileFullpaths{i};
    [dataPath, fsname] = fileparts(tileFullpath);
    dataPath = strip(dataPath, 'right', '/');
    if ~isempty(ProcessedDirstr)
        tilePath = sprintf('%s/%s', dataPath, ProcessedDirstr);
    else
        tilePath = dataPath;
    end

    fsnames{i} = fsname;
    
    if processTiles 
        if ~isempty(resample) && any(resample ~= 1)
            % complete resample to 3d
            rs = [ones(1, 4 - numel(resample)) * resample(1), resample(2 : end)];    
            zarrPathstr = sprintf('zarr_%d_%d_%d', rs(1), rs(2), rs(3));
        else
            zarrPathstr = 'zarr';
            if zarrFile
                zarrPathstr = 'zarr_processed';
            end
        end
    else
        zarrPathstr = '';
    end
    
    if any(stitchMIP)
        inputFullpaths{i} = sprintf('%s/MIPs/%s_MIP_%s%s', tilePath, fsname, suffix_str, ext);
        zarrFullpaths{i} = sprintf('%s/MIPs/%s/%s_MIP_%s.zarr', tilePath, zarrPathstr, fsname, suffix_str); 
    else
        inputFullpaths{i} = sprintf('%s/%s%s', tilePath, fsname, ext);
        zarrFullpaths{i} = sprintf('%s/%s/%s.zarr', tilePath, zarrPathstr, fsname);
    end
end


end


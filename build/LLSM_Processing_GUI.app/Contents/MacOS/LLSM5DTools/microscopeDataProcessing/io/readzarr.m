function [data, bim] = readzarr(filepath, options)
% wrapper for zarr reader
% bbox provide the region bounding box [ymin, xmin, zmin, ymax, xmax, zmax]
% 
% Author: Xiongtao Ruan (01/25/2022)
% 
% xruan (02/01/2022): add support for parallel read zarr


arguments
    filepath char 
    options.bbox (1, :) {mustBeNumeric} = []
    options.sparseData (1, :) {mustBeNumericOrLogical} = true
end

bbox = options.bbox;
sparseData = options.sparseData;

try 
    if isempty(bbox)
        data = parallelReadZarr(filepath);
    else
        bbox = bbox(:)';
        data = parallelReadZarr(filepath, 'bbox', bbox, 'sparse', sparseData); 
    end
    
    if nargout == 2
        bim = blockedImage(filepath, "Adapter", CZarrAdapter);
    end
catch ME
    disp(ME);
    if ~exist(filepath, 'dir')
        error('zarr file %s does not exist!', filepath);
    end
    disp('Use the alternative zarr reader (ZarrAdapter)...');   
    
    bim = blockedImage(filepath, "Adapter", ZarrAdapter);    
    if isempty(bbox)
        data = bim.Adapter.getIORegion([1, 1, 1], bim.Size);    
    else
        data = bim.Adapter.getIORegion(bbox(1 : 3), bbox(4 : 6));
    end
end

end

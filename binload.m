function [ d, h ] = binload(filename, range)
    %BINLOAD Loads data from a DataAcquisition-generated file in a range
    %   binload(filename, range) - Load range=[start,end] of points, 0-based
    %   binload(filename, 'info') - Load header data only
    
    d = [];
    h = [];

    % open the file and read header
    fid = fopen(filename,'r');
    if fid == -1
        error(['Could not open ' filename]);
    end
    
    % get total length of file
    d = dir(filename);
    fileSize = d.bytes;
    
    % header always the same
    h.numChan = 3;
    fstart = 0;
%     h.numTotal = double(fileSize - fstart)/2;
    h.numTotal = double(fileSize - fstart)/8; % for doubles it's 8
    h.numPts = double(h.numTotal/h.numChan);
    h.scaleFactors = [1,1];
    h.chNames = {'Measured Current','Applied Voltage'};
    
    % load data, or just return header?
    if nargin > 1 && strcmp(range,'info')
        fclose(fid);
        return;
    end
    
    % find the right place to seek, and do so
    if nargin<2
        range = [0 h.numPts];
    end

    % go to start
    fseek(fid, fstart+range(1)*8*h.numChan, 'bof'); % double needs an 8 here
    % how many points and array size
    npts = range(2) - range(1);
    sz = [h.numChan, npts];
    % now read
%     d16 = fread(fid, sz, '*int16');
    d = fread(fid, sz, 'double')';
    d = d(:,2:end);

    % all done
    fclose(fid);
end


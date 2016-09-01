function [ d, h ] = dbfload(filename, range)
    %DBFLOAD Loads data from a DataAcquisition-generated file in a range
    %   dbfload(filename, range) - Load range=[start,end] of points, 0-based
    %   dbfload(filename, 'info') - Load header data only
    
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
    
    % now read number of header points, and the header
    nh = uint64(fread(fid,1,'*uint32'));
    hh = fread(fid,nh,'*uint8');
    h = getArrayFromByteStream(hh);
    
    fstart = 4+nh;
    bytesize = 2; % int16
    
    % also, how many points and channels?
    h.numChan = numel(h.chNames);
    % this is the total number of points
    h.numTotal = double(fileSize - fstart)/bytesize;
    % this is the number per each channel
    h.numPts = double(h.numTotal/h.numChan);
    
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
    fseek(fid, fstart+range(1)*bytesize*h.numChan, 'bof'); % double needs an 8 here
    % how many points and array size
    npts = range(2) - range(1);
    sz = [h.numChan, npts];
    % now read
    d16 = double(fread(fid, sz, '*int16')');
    d = d16./repmat(h.data_compression_scaling,size(d16,1),1);
    
    d(:,1) = d(:,1)/1000; % PoreView works in nA

    % all done
    fclose(fid);
end


function plot_noise(sigdata, trange)
%PLOT_NOISE Makes or adds to existing noise plot
%   plot_noise(sigdata, trange)
%   Takes a SignalData object and a time range as input, uses the same
%       algorithm as ClampFit (I think).

    % do same thing as ClampFit does - average spectral segs
    % ClampFit does 2*65536 pts per seg (2^17)
    % get start and end index
    irange = floor(trange/sigdata.si);
    
    fftsize = min(diff(irange),2*65536);

    % only process real signals
    dfft = zeros(fftsize,sigdata.nsigs);
    % number of frames
    nframes = 0;
    
    wh = waitbar(0,'Calculating power spectrum...','Name','PoreView');
    
    for ind=irange(1):fftsize:irange(2)
        % get only the real signals
        d = sigdata.get(ind:min(irange(2),ind+fftsize-1),1+(1:sigdata.nsigs));
        % quit if we don't have enough points
        if size(d,1) < fftsize
            break
        end
        % calculate power spectrum
        df = sigdata.si*abs(fft(d)).^2/fftsize;
        % and add to fft accum.
        dfft = dfft + df;
        nframes = nframes + 1;
        waitbar((ind-irange(1))/(irange(2)-irange(1)));
    end
    
    close(wh);
    %temp = input('Temperature in degrees C: '); % in degrees C
    temp = 22;

    % do the averaging
    dfft = dfft / nframes;
    
    % dave's factor of 2
    dfft = 2*dfft;
    
    % and calculate the frequency range
    f = 1/sigdata.si*(0:fftsize-1)/fftsize;
    
    % range of f to plot, only do half (Nyquist and all)
    imax = floor(size(dfft,1)/2);

    hf = findobj('Name','Noise Power Spectrum');
    if isempty(hf)
        % make a new plot figure, leave menu bar
        hf = figure('Name','Noise Power Spectrum','NumberTitle','off');
        
        % and make axes
        ax = axes('Parent',hf,'XScale','log','YScale','log',...
            'XLimMode','manual','YLimMode','auto','NextPlot','add',...
            'TickDir','out');
        
        % scale x axis
        set(ax,'XLim',[1 f(imax)]);
        set(gca,'FontSize',12)
        set(gca,'LooseInset',[0 0 0 0]) % the all-important elimination of whitespace!
        set(gca,'OuterPosition',[0 0 0.99 1]) % fit everything in there
        set(gcf,'Position',[100 500 750 500]) % size the figure
        % grid
        grid on
        grid minor
        box on
        % labels
        title('Noise Power Spectrum');
        ylabel('Current Noise (nA^2/Hz)')
        xlabel('Frequency (Hz)')
    end

    % bring figure to front
    figure(hf);
    % and plot
    V = mean(sigdata.get(trange(1)/sigdata.si:(trange(1)/sigdata.si+1000),3));
    I = mean(sigdata.get(trange(1)/sigdata.si:(trange(1)/sigdata.si+1000),2))*1000;
    if abs(V)<4
        conductance = input('Conductance (nS): ');
    else
        conductance = I/V; % in nS
        %display(['Conductance = ' num2str(conductance,3) 'nS'])
    end

    R = 1/(conductance*1e-9);
    k = 1.38 * 10^-23; % Boltzmann constant
    T = temp + 273.15; % absolute temperature in Kelvin
    Rf = 500e6; % feedback resistor in Axopatch with beta = 1 in whole cell mode
    Cin = 4e-12; % headstage input capacitance is about 4pF (Sakmann and Neher say 15pF, p.112)
    V_headstage = 3e-9; % input voltage noise on headstage op-amp = 3nV/sqrt(Hz)
    Ra = 3e7; % access resistance = rho/4*a (J.E. Hall, 1975), rho = 0.0895ohm*m for 1M KCl (http://www.sigmaaldrich.com/catalog/product/fluka/60131?lang=en&region=US), a = 1nm
    Cm = 0.45e-12; % typical membrane capacitance 0.2pF
    loss_tangent = 1; % Dave ref to http://pubs.acs.org/doi/pdf/10.1021/jp0680138
    johnson = 4*k*T * ( 1/(R+2*Ra) + 1/Rf ) * 10^18;
    
    plot(f(1:imax)',dfft(1:imax,1));
    hold on
    
    % also plot a mean smoothed version
    x = f(2:imax);
    y = dfft(2:imax,1);
    xx = logspace(log10(min(x)),log10(5e4),1000)';
    subs = arrayfun(@(a) find(x(a)<=xx,1,'first'), 1:numel(x));
    yy = accumarray(subs',y',[],@median);
    xx = xx(yy~=0);
    yy = yy(yy~=0);
    plot(xx,yy)

end


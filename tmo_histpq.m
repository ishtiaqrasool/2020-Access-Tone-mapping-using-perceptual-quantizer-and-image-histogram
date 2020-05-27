%--------------------------------------------------
function [ldr] = tmo_histpq(hdr, nBins, k, s)
%--------------------------------------------------
% The code implements the TMO proposed in 
% Khan, Ishtiaq Rasool, Wajid Aziz, and Seong-O. Shim. 
% "Tone-Mapping Using Perceptual-Quantizer and Image Histogram." 
% IEEE Access 8 (2020): 31350-31358.  

%% Input parameters
% nBins is the number of histogram bins. Default is nBins=256.
% k is the parameter for truncation of bin counts. Default is k=5.
% s controls saturation. Default is s=1/1.5. Try s=1 and s=1/2.2 as well.

% Check input parameters
if ~exist('n', 'var'), nBins = 256; end
if ~exist('p', 'var'), k = 5; end
if ~exist('s', 'var'), s = 1/1.5; end

%% apply PQ transformation
hdrY = lum(hdr);
lum_pq = PQ_EOTF(hdrY);
hdr_pq = PQ_EOTF(hdr);

%% Design TMO based on histogram of PQ transformed luminance
[counts, bins] = hist(lum_pq(:), nBins);

% include minimum and maximum values of luminance to the bin edges, to
% ensure that all luminance values are in one of the bins.
bins = [min(hdrY(:)), bins];
bins(end) = max(hdrY(:));

% Truncate bin counts that are beyond k*(mean values of pixels per bin)
% This step is needed to control typical problem of excessive contrast
% enhancement in histogram based TMOs.
counts = process_histogram(counts, nBins, k); 

%% Tone-mapping curve
% cumulative histogram
cum_counts = [0; counts'];
cum_counts = cumsum(cum_counts);

% LUT of [HDR, LDR] pairs. x and y are the vectors of mapping HDR and LDR
% key points.
x = double(bins);
y = double(cum_counts) / max(cum_counts);

%% Tone-map using interpolation and the LUT [x, y].
ldrY = interp1(x, y, lum_pq, 'linear', 'extrap');
ldr = (hdr_pq ./ repmat(lum_pq, [1,1,3])) .^ s .* repmat(ldrY, [1,1,3]);

end

%%
function counts = process_histogram(counts, n, p) 
counts(counts>(p*sum(counts)/n))=p*sum(counts)/n;
end

%%
function Y = lum(img)
Y = 0.2126 * img(:,:,1) + 0.7152 * img(:,:,2) + 0.0722 * img(:,:,3);
end

%%
function V = PQ_EOTF(L)
L = L/10000;
V = ((107+2413*L.^(1305/8192))./(128+2392*L.^(1305/8192))).^(2523/32);
end
clc; clear; close all;

%% Code parameters
numFrames = 1e3;                                                            % Number of frames to simulate
A = 2^5;                                                                    % Message length in bits, including CRC, K > 30
E = 128;                                                                    % Rate matched output length, E <= 8192
N = E;
L = 8;                                                                      % List length, a power of two, [1 2 4 8]
linkDir = 'DL';                                                             % Link direction: downlink ('DL') OR uplink ('UL')
ber = comm.ErrorRate;
if strcmpi(linkDir,'DL')
    % Downlink scenario (K >= 36, including CRC bits)
    crcLen = 24;      % Number of CRC bits for DL, Section 5.1, [6]
    poly = '24C';     % CRC polynomial
    nPC = 0;          % Number of parity check bits, Section 5.3.1.2, [6]
    nMax = 9;         % Maximum value of n, for 2^n, Section 7.3.3, [6]
    iIL = true;       % Interleave input, Section 5.3.1.1, [6]
    iBIL = false;     % Interleave coded bits, Section 5.4.1.3, [6]
    K = A+24;
else
    % Uplink scenario (K > 30, including CRC bits)
    crcLen = 11;
    poly = '11';
    nPC = 0;
    nMax = 10;
    iIL = false;
    iBIL = true;
    K = A+11;
end
R = K/E;                                                                    % Effective code rate
%% Loop over for different SNR values
snr = -5:1:5;
for k = 1:1:length(snr)
    EbNo = snr(k);
    bps = 2;                                                                % bits per symbol, 1 for BPSK, 2 for QPSK
    EsNo = EbNo + 10*log10(bps);
    snrdB = EsNo + 10*log10(R);                                             % in dB
    noiseVar = 1./(10.^(snrdB/10));
    chan = comm.AWGNChannel('NoiseMethod','Variance','Variance',noiseVar);  % Channel
    numferr = 0;
    for i = 1:numFrames
        msg = randi([0 1], K-crcLen,1);                                     % Generate a random message
        msgcrc = nrCRCEncode(msg,poly);                                     % Attach CRC
        encOut = nrPolarEncode(msgcrc,E,nMax,iIL);                          % Polar encode
        N = length(encOut);
        
        modIn = nrRateMatchPolar(encOut,K,E,iBIL);                          % Rate match
        modIn_polar = PolarCoding(A,E,msg,linkDir);                         % From the Coded Function PolarCoding
        
        modOut = nrSymbolModulate(modIn,'QPSK');                            % Modulate
        modOut_polar = nrSymbolModulate(modIn_polar','QPSK');               % Modulate
        
        rSig = chan(modOut);                                                % Add White Gaussian noise
        rSig_polar =chan(modOut_polar);
        
        rxLLR = nrSymbolDemodulate(rSig,'QPSK',noiseVar);                   % Soft demodulate
        rxLLR_polar = nrSymbolDemodulate(rSig_polar,'QPSK', noiseVar);
        
        decIn = nrRateRecoverPolar(rxLLR,K,N,iBIL);                         % Rate recover
        decIn_polar = nrRateRecoverPolar(rxLLR_polar, K, N, iBIL);
        
        decBits = nrPolarDecode(decIn,K,E,L,nMax,iIL,crcLen);               % Polar decode
        decBits_polar = nrPolarDecode(decIn_polar,K,E,L,nMax,iIL,crcLen);
        
        errStats = ber(double(decBits(1:K-crcLen)), msg);                   % Compare msg and decoded bits
        errStats_polar = ber(double(decBits_polar(1:K-crcLen)), msg);       % Compare msg and decoded bits
        
        numferr = numferr + any(decBits(1:K-crcLen)~=msg);
        numferr_polar = numferr + any(decBits_polar(1:K-crcLen)~=msg);
    end
    Block_error_rate(k) = numferr/numFrames;
    Block_error_rate_polar(k) = numferr_polar/numFrames;
    
    Bit_error_rate(k) = errStats(1);     
    Bit_error_rate_polar(k) = errStats_polar(1);
end

figure(1); clf;
subplot(1,2,1)
fig = semilogy(snr, Bit_error_rate,'-.rd', snr, Bit_error_rate_polar, ':ks');
set(fig, 'Linewidth',2)
legend('Matlab Built-In','Our Coded Results', 'Location','NorthEast', 'FontSize',14)
xlabel('SNR,  E_b/N_0 [dB]', 'Fontsize', 16)
ylabel('BER', 'FontSize',16)
str = sprintf('BER vs SNR in Polar Code (%s-Link)',linkDir);
title(str, 'FontSize',16) 

subplot(1,2,2)
fig1 = semilogy(snr, Block_error_rate,'-.rd', snr, Block_error_rate_polar, ':ks');
set(fig1, 'Linewidth',2)
legend('Matlab Built-In','Our Coded Results', 'Location','NorthEast', 'FontSize',14)
xlabel('SNR, E_b/N_0 [dB]', 'Fontsize', 16)
ylabel('BLER', 'FontSize',16)
str0 = sprintf('BLER vs SNR in Polar Code (%s-Link)',linkDir);
title(str0, 'FontSize',16) 
% saveas(gcf,'polar_coding_ul.pdf')
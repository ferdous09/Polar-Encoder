clc; clear; close all;

% Perform polar encoding of a random message of length K. The rate-matched output is of length E
N = 1e3;                                            % No of blocks; should select at least 1e5;
K = 64;                                             % message of length K
E = 128;                                            % rate-matched output length E; block length
R = K/E;                                            % Effective code rate

snr = -5:5; 
BER = zeros(length(snr),1);
BER_uncod = zeros(length(snr),1);
for k = 1:length(snr)
    ber_snr = zeros(N,1);
    ber_snr_uncod = zeros(N,1);
    for kk = 1:N
        msg = randi([0 1],K, 1);                    % Generated N blocks of random message
        enc = nrPolarEncode(msg, E);                % Encoding the K message bits into E output bits
        
        %Modulate the polar encoded data using BSPK modulation, add WGN, and demodulate.
        nVar = 1.2;                                 % variance of the bpskDemod and channel
        bpskMod = comm.BPSKModulator;
        bpskDemod = comm.BPSKDemodulator('DecisionMethod',... 
            'Approximate log-likelihood ratio','Variance',nVar); 
        errorRate = comm.ErrorRate;
        mod = bpskMod(enc);                         % BPSK modulation of the encoded bits
        mod_uncod = bpskMod(msg);                   % BPSK modulation of the uncoded bits
        rSig = awgn(mod, snr(k));                   % Received Signal (coded) at the receiver 
        rSig_uncod = awgn(mod_uncod, snr(k));       % Received Signal (uncoded) at the receiver 
        rxLLR = bpskDemod(rSig);                    % Demodulated Rx Signal (Coded)
        rxLLR_uncod = bpskDemod(rSig_uncod);        % Demodulated Rx Signal (Uncoded)
       
        %Perform polar decoding using successive-cancellation list decoder of length L.
        L = 8;
        rxBits = nrPolarDecode(rxLLR,K,E,L);        % Decoding of the Demodulated Rx Singnal
        
        %Determine the number of bit errors.
        error_St = errorRate(msg, rxBits);          % BER calcualtion for this block
        ber_snr(kk) = error_St(1);
        errorStats = errorRate(msg, rxLLR_uncod);   % BER calcualtion for this block
        ber_snr_uncod(kk) = errorStats(1);
    end
    BER(k) = sum(ber_snr)/N;                        % Average BER (Coded)
    BER_uncod(k) = sum(ber_snr_uncod)/N;            % Average BER (Uncoded)
%     snr_coded(k) = snr(k) - 10*log10(K/E);
end

figure(1); clf;
fig = semilogy(snr, BER,'-dk', snr, BER_uncod, '-sb');
set(fig, 'Linewidth',2)
legend('Polar Coded - BPSK','Uncoded - BPSK','Location','SouthEast', 'FontSize',14)
xlabel('SNR, E_b/N_0 [dB]', 'Fontsize', 16)
ylabel('BER', 'FontSize',16)
title('Polar Code: BER vs SNR', 'FontSize',16) 


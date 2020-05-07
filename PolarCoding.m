function bo_interleaved_code = PolarCoding(A, E, bi, linkDir, iBIL)

    %% Step 1: Get the Reliability Sequence
    reliability_sequence = xlsread('Reliability_Sequence');  % Extracted from TS 38.212 Table 5.3.1.2-1
    Q = reliability_sequence';

    %% Step 2: Define the Parameters
%     A = 2^5;                                                    % Actual message size
%     bi = randi([0 1],A,1);                                      % Generating Random message
%     linkDir = 'DL';                                             % Specify Link Direction
    if strcmpi(linkDir,'DL')                                    % Downlink scenario (K >= 36, including CRC bits)
        crcLen = 24;                                            % Number of CRC bits for DL, Section 5.1, [6]
        poly = '24C';                                           % CRC polynomial
%         iBIL = true;                                           % Interleave coded bits, Section 5.4.1.3, [6]
        K = A+24;
    else                                                        % Uplink scenario (K > 30, including CRC bits)
        crcLen = 11;
        poly = '11';
%         iBIL = true;                                           % Interleave coded bits, Section 5.4.1.3, [6]
        K = A+11;
    end

    %% Step 3: Perform CRC Encoding
    bi_crc_encoded = nrCRCEncode(bi, poly);                     % Perform CRC Encoding based on Link Direction
    if length(bi_crc_encoded) ~= K
        error('Error in CRC Encoding')
%     else
%         fprintf('CRC Encoding is Done :) \n')
    end

    %% Step 4: Generate the Kernel 
%     E = 128;                                                    % Block length
    N = E;
    Q_K = Q(1:N);                                               % Trancated reliability sequence for message length K
    G2 = [1 0; 1 1];                                            % define the kernels
    n = log2(N);                                                % n for the Knoncker product for the Kernel
    G2n = G2;                                                   % initial G2n Kernel
    for k = 1:n-1
        G2n = kron(G2n, G2);                                    % Update G2n
    end

    %% Step 5: Insert the CRC Encoded Message Bits into the Last N-K positions following the Reliability Sequence
    Q_K_frozen = Q_K(1:N-K);
    Q_K_msg = Q_K(N-K+1:end);
    bo_int = zeros(1, N);                                           % Initialize the encoded output as all zero
    bo_int(N-K+1:end) = bi_crc_encoded;                             % Inserting message into the last K positions 
    bo = mod(bo_int*G2n, 2);
    bo = bo';

    %% Step 6: Perform Rate Matching in Polar Coding
    bo_interleaved_code = Rate_Matching(N, E, bo, iBIL);

end

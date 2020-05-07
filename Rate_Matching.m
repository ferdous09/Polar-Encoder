function bo_interleaved_code = Rate_Matching(N, E, bo, iBIL)
% This function performs Rate Matching of Polar code Following TS 38.212, Section: 5.4.1

% Step 1: Section 5.4.1.1 Sub-block interleaving
    Sub_blk_int_pattern = [0 1 2 4 3 5 6 7 8 16 9 17 10 18 11 19 12 20 ... 
                  13 21 14 22 15 23 24 25 26 28 27 29 30 31];           % Extracted from TS 38.212 Table 5.4.1.1-1

    for kaka = 0:1:N-1 
        temp = floor((32*kaka)/N);
        temp1(kaka+1) = Sub_blk_int_pattern(temp+1)*(N/32) + mod(kaka, N/32);
        bo_sub_blk_interleaving(kaka+1) = bo(temp1(kaka+1) +1);
    end

% Step 2: Section 5.4.1.2 Bit Selection
    if (E >= N)                                                         % Perform Repetition
        bo_bit_selection = bo_sub_blk_interleaving(mod (0:1:E-1, N)+1);
    elseif ((K/E) <= (7/16))                                            % Perform Puncturing
        bo_bit_selection = bo_sub_blk_interleaving(N-E+1:1:N);
    else                                                                % Perform Shortening
        bo_bit_selection = bo_sub_blk_interleaving(1:E);
    end


% Step 3: Section 5.4.1.3 Interleaving of coded Bits
    if(iBIL == 1)                                                      
%         error('No Interleaving ');                                    % Interleaving Flag is False
        syms T
        equation = T*(T+1) >= E;
        sl = double(solve(equation, T));
        t = ceil(max(sl));
        k = 0;
        for ii = 0:t-1
            for jj= 0:t-1-ii
                if k < E
                    v(ii,jj) = bo_bit_selection(k);
                else
                    v(ii,jj) = 0;
                end
                k=k+1;
            end
        end
        k = 0;
        for jj = 0:t-1
            for ii =0:t-1-jj
                if v(ii,jj) ~= 0
                    f(k) = v(ii,jj);
                    k=k+1;
                end
            end
        end
        bo_interleaved_code = f;
        
        
    else
        bo_interleaved_code = bo_bit_selection;                         % No Interleaving of coded bits are performed
    end
end

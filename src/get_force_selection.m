function seq = get_force_selection(seq_num)
% You can use this function to force selection of a specified sequence
if seq_num == 16
    % 16 extractive distillation sequences for 5 comp. without merging col
    seq0 = [1 2 3 4 0;
        1 2 5 6 0;
        1 10 11 12 0;
        1 10 13 14 0;
        1 7 9 8 0;
        32 33 34 35 0;
        32 33 36 37 0;
        32 42 43 44 45;
        32 42 43 46 47;
        32 42 48 49 50;
        32 38 41 39 40;
        22 31 23 24 25;
        22 31 23 26 27;
        22 31 28 29 30;
        15 16 17 18 19;
        15 16 17 20 21];
elseif seq_num == 28
    % 28 aniline extractive sequences for 5 comp. without merging col
    seq0 = [1 2 3 4 5;
        1 2 3 6 7;
        1 2 11 12 13;
        1 2 11 14 15;
        1 2 8 9 10;
        1 28 29 30 31;
        1 28 29 32 33;
        1 28 37 38 39;
        1 28 37 40 41;
        1 28 34 35 36;
        1 22 23 24 27;
        1 22 25 26 27;
        1 16 17 18 19;
        1 16 17 20 21;
        59 60 61 62 63;
        59 60 61 64 65;
        59 60 69 70 71;
        59 60 69 72 73;
        59 60 66 67 68;
        59 78 79 80 81;
        59 78 79 82 83;
        59 78 84 85 86;
        59 74 75 76 77;
        49 58 50 51 52;
        49 58 50 53 54;
        49 58 55 56 57;
        42 43 44 45 46;
        42 43 44 47 48];
end
for i = 1:size(seq0,1)
    seq{i} = seq0(i,seq0(i,:) > 0);
end
end
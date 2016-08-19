%function [I, Q] = PRNgen(signalNo)
signalNo=1;
    % Define intermediate codes (g1 is U, g2 is V)
    A = zeros(1, 10230);
    B = zeros(1, 10230);
    I_B = zeros(1, 10230);
    Q_B = zeros(1, 10230);
    
    % Define XB Advance values for I and Q (one for each of the 37 signal
    % numbers)
    BShift_I = [266, 365, 804, 1138, 1509, 1559, 1756, 2084, 2170, 2303, 2527, 2687, 2930, 3471, 3940, 4132, 4332, 4924, 5343, 5443, 5641, 5816, 5898, 5918, 5955, 6243, 6345, 6477, 6518, 6875, 7168, 7187, 7329, 7577, 7720, 7777, 8057];
    BShift_Q = [1701, 323, 5292, 2020, 5429, 7136, 1041, 5947, 4315, 148, 535, 1939, 5206, 5910, 3595, 5135, 6082, 6990, 3546, 1523, 4548, 4484, 1893, 3961, 7106, 5299, 4660, 276, 4389, 3783, 1591, 1601, 749, 1387, 1661, 3210, 708];
    
    % Set initial values for A and B
    A(1:13) = -1;
    B(1:13) = -1;
    % NOTE: Actual I and Q are made up of 1s and 0s. But that messes with
    % the calculations, so in this code 1 = 0 and -1 = 1 and converted at
    % the very end
    
    % Generate A (A is the same for both I and Q)
    for i = 14:10230
        A(i) = A(i - 13) * A(i - 12) * A(i - 10) * A(i - 9);
    end
    
    % Generate generic B (for finding initial conditions for Q_B and I_B)
     for i = 14:10230 
        B(i) = B(i - 1) * B(i - 2) * B(i - 6) * B(i - 7) * B(i - 8) * B(i - 10) * B(i - 11) * B(i - 13);
     end
     
    % Set initial values for I_B and Q_B, based on their BShift and A
    I_B(1:13) = B((BShift_Q(signalNo) + 13):(BShift_Q(signalNo) + 25));
    
    % Generate I_B
%     for i = 14:10230
%         I_B(i) = I_B(i - 13) * I_B(i - 12) * I_B(i - 8) * I_B(i - 7) * I_B(i - 6) * I_B(i - 4) * I_B(i - 3) * I_B(i - 1);
%     end
    
    % Generate Q_B
%     for i = 14:10230
%         I_B(i) = I_B(i - 13) * I_B(i - 12) * I_B(i - 8) * I_B(i - 7) * I_B(i - 6) * I_B(i - 4) * I_B(i - 3) * I_B(i - 1);
%     end
    
    I_B = I_B * -0.5 + 0.5;
    
    I_B(1:13)
%end
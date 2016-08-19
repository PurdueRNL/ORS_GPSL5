function [CAcode] = caGen(SignalNo)
    % Calculate GPS satellite CA code for use in determining circular
    % correlation.
    % SignalNo: Assigned number of satellite
    % CAcode: CA code corresponding to given PRN 

    % Initialize vectors (for speed)
    g1 = zeros(1, 1023);
    g2 = zeros(1, 1023);
    
    % G2 shifts
    SVG2 = [5, 6, 7, 8, 17, 18, 139, 140, 141, 251, 252, 254, 255, 256, 257, 258, 469, 470, 471, 472, 473, 474, 509, 512, 513, 514, 515, 516, 859, 860, 861, 862 , 145, 175, 52, 21, 237, 235, 886, 657, 634, 762, 355, 1012, 176, 603, 130, 359, 595, 68, 386];
    
    % Assign G2 shift based on SignalNo
    G2shift = SVG2(SignalNo);
    
    % Generate G1 code
    % Set initial conditions to all ones (in this script, -1=1)
    g1(1:10) = -1 * ones(1, 10);
    
    % Run LSFR to generate remaining G1 code
    for i = 11:1023
       g1(i) = g1(i - 3) * g1(i - 10); 
    end
    
    % Generate G2 code
    % Set initial conditions to all ones
    g2(1:10) = -1 * ones(1, 10);
    
    % Run LSFR to generate remaining G2 code
    for i = 11:1023
       g2(i) = g2(i - 10) * g2(i - 9) * g2(i - 8) * g2(i - 6) * g2(i - 3) * g2(i - 2); 
    end
    
    % Shift G2 code
    g2 = [g2((1024 - G2shift):1023), g2(1:(1023 - G2shift))];
    
    % Calculate final CA code
    CAcode = (g1 .* g2) * (-0.5) + 0.5;
end
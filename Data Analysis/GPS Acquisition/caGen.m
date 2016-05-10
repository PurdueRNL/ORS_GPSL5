function CA_Code = caGen(PRN)
sv = [ 5, 6, 7, 8, 17, 18, 139, 140, 141, 251, 252, 254, 255, 256, 257, 258, 469, 470, 471, 472, 473, 474, 509, 512, 513, 514, 515, 516, 859, 860, 861, 862 , 145, 175, 52, 21, 237, 235, 886, 657, 634, 762, 355, 1012, 176, 603, 130, 359, 595, 68, 386]; % shift of g2
g2s = sv(PRN);
%--- Generate G1 code
g1 = zeros(1, 1023);
g1(1:10)=-1*ones(1,10);
for i=1:1023-10
g1(i+10) = g1(i+7)*g1(i);
end %Generate G1 signal chips
%--- Generate G2 code
g2 = zeros(1, 1023);
g2(1:10)=-1*ones(1,10);
for i=1:1023-10
g2(i+10)= g2(i)*g2(i+1)*g2(i+2)*g2(i+4)*g2(i+7)*g2(i+8);
end %Generate G2 signal chips
g2 = [g2(1023-g2s+1:1023), g2(1:1023-g2s)]; %Shift G2 code
CA_Code = (g1 .* g2)*(-0.5)+0.5;
end
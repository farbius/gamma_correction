%% gamma correction algorithm
% A Rostov 14/05/2018
% a.rostov@riftek.com
%%
clc
clear all

fileID = -1;
errmsg = '';
while fileID < 0 
   disp(errmsg);
   filename = input('Open file: ', 's');
   [fileID,errmsg] = fopen(filename);
   I = imread(filename);
end
[Nx, Ny, Nz] = size(I)

gamma = 2.1;

display('Writing data for RTL model...');
fidR = fopen('Rdata.txt', 'w');
fidG = fopen('Gdata.txt', 'w');
fidB = fopen('Bdata.txt', 'w');

for i = 1 : Nx
    for j = 1 : Ny
      fprintf(fidR, '%x\n', I(i, j, 1));
      fprintf(fidG, '%x\n', I(i, j, 2));
      fprintf(fidB, '%x\n', I(i, j, 3));
    end
end
fclose(fidR);
fclose(fidG);
fclose(fidB);

packet_data = zeros(1,256);

for i = 1 : 255
    packet_data(i) = floor((((i-1)/255)^(gamma))*255);
end

packet_data = uint8(packet_data);

fid = fopen('InputData.txt', 'w');
for i = 1 : 256
    fprintf(fid, '%x\n', packet_data(i));  
end
fclose(fid);

%%
fid = fopen('parameters.vh', 'w');
fprintf(fid,'parameter Nrows   = %d ;\n', Ny);
fprintf(fid,'parameter Ncol    = %d ;\n', Nx);
fclose(fid);

%%
display('Please, start RTL model');
prompt = 'Press Enter when RTL modeling is done \n';
x = input(prompt);

% read processing data
fidR = fopen(fullfile([pwd '\gamma_correction.sim\sim_1\behav\xsim'],'Rs_out.txt'), 'r');
fidG = fopen(fullfile([pwd '\gamma_correction.sim\sim_1\behav\xsim'],'Gs_out.txt'), 'r');
fidB = fopen(fullfile([pwd '\gamma_correction.sim\sim_1\behav\xsim'],'Bs_out.txt'), 'r');
R = zeros(1, Nx*Ny);
G = zeros(1, Nx*Ny);
B = zeros(1, Nx*Ny);
  R = fscanf(fidR,'%d');  
  G = fscanf(fidG,'%d');  
  B = fscanf(fidB,'%d');  
fclose(fidR);
fclose(fidG);
fclose(fidB);

Iprocess = zeros(Nx, Ny, 3);
n = 1;
for i = 1 : Nx
    for j = 1 : Ny 
       Iprocess(i, j, 1) = R(n); 
       Iprocess(i, j, 2) = G(n); 
       Iprocess(i, j, 3) = B(n); 
       n = n + 1;
 end
end
Iprocess = uint8(Iprocess);

%%

Inew = zeros(Nx, Ny, Nz);  
Inew(:,:,1) = (double(I(:,:,1))./255).^gamma;
Inew(:,:,2) = (double(I(:,:,2))./255).^gamma;
Inew(:,:,3) = (double(I(:,:,3))./255).^gamma;

Inew(:,:,1) = floor(Inew(:,:,1).*255);
Inew(:,:,2) = floor(Inew(:,:,2).*255);
Inew(:,:,3) = floor(Inew(:,:,3).*255);
Inew = uint8(Inew);


figure(1)
imshow(I);
title('Исходное изображение')

figure(2)
imshow(Inew);
title('Работа алгоритма в Matlab')

figure(3)
imshow(Iprocess);
title('Работа алгоритма в RTL модели')
display('processing done!');



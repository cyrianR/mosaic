% Calcul d'une mosaique d'image à partir de N images
% dans le repère de l'image 1

function [Imos] = mosaiqueN(images, TailleFenetre, NbPoints, k, seuil)

N = size(images,2);
[nblI1, nbcI1, ~] = size(images{1});

homographies = zeros(N-1, 3, 3);
xmin = 1;
ymin = 1;
xmax = nbcI1;
ymax = nblI1;

% Calculer les homographies des images par rapport à I1 dans l'ordre
% et les dimensions de la mosaique
for i=1:N-1

    Imi = rgb2gray(images{i});
    Imiplus1 = rgb2gray(images{i+1});

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Detection des points d'interet avec Harris %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [XY_i,~] = harris(Imi,TailleFenetre,NbPoints,k);
    [XY_iplus1,~] = harris(Imiplus1,TailleFenetre,NbPoints,k);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Appariement des points d'interet %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    contrainte = "all"; % choisir une contrainte : "aucune", "seuil", "symetrie" ou "all"
    affichage = false;
    [XY_Ci,XY_Ciplus1] = apparier_POI(Imi,XY_i,Imiplus1,XY_iplus1,TailleFenetre,seuil,contrainte,affichage);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Estimation (et verification) de l'homographie %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    H = homographie(XY_Ci,XY_Ciplus1);
    
    if i == 1
        homographies(i,:,:) = H;
    else
        prevH = squeeze(homographies(i-1,:,:));
        homographies(i,:,:) = H*prevH;
    end

    [nblI_iplus1, nbcI_iplus1] = size(Imiplus1);

    % On calcule l'homographie inverse, normalisee, 
    % pour nous permettre d'effectuer la transformation de Iiplus1 vers I1. 
    Hinv = inv(squeeze(homographies(i,:,:)));
    Hinv = Hinv./Hinv(3,3);

    % Calcul des quatre coins dans l'image i+1. 
    % les coins de l'image i+1 sont ranges en ligne selon : 
    % haut_gauche, haut_droit, bas_droit, bas gauche. 
    % Lignes et colonnes sont inversees.  
    xy_coinsI2_R2 = [1 1; nbcI_iplus1 1; nbcI_iplus1 nblI_iplus1; 1 nblI_iplus1];

    % Application de l'homographie Hinv sur ces coins. 
    % Calcul des images des coins dans I1. 
    xy_coinsI2_R1 = appliquerHomographie(Hinv,xy_coinsI2_R2);

    % Determination des dimensions de l'image mosaique, 
    % les xmin ymin xmax ymax, ou :
    %  - xmin represente la plus petite abscisse parmi les abscisses des images 
    %    des coins de Iiplus1 projetes dans I1 et les coins dans I1, 
    %  - etc
    % Lignes et colonnes sont inversees. 
    xmin=min([xy_coinsI2_R1(:,1)' xmin]);
    ymin=min([xy_coinsI2_R1(:,2)' ymin]);
    xmax=max([xy_coinsI2_R1(:,1)' xmax]);
    ymax=max([xy_coinsI2_R1(:,2)' ymax]);

end

% On arrondit de maniere a etre certain d'avoir les coordonnees initiales
% bien comprises dans l'image. 
xmin=floor(xmin);
ymin=floor(ymin);
xmax=ceil(xmax);
ymax=ceil(ymax);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONTRUCTION DE LA MOSAIQUE %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calcul de la taille de la mosaique. 
% Lignes et colonnes sont inversees. 
nblImos=ymax-ymin+1;
nbcImos=xmax-xmin+1;

Imos=zeros(nblImos,nbcImos,3);

% Calcul de l'origine de l'image I1 dans le repere de la mosaique Imos. 
O1x_Rmos = 1-(xmin-1);
O1y_Rmos = 1-(ymin-1);

% Copie de l'image I1. 
% Lignes et colonnes sont inversees. 
Imos(O1y_Rmos:O1y_Rmos+nblI1-1, O1x_Rmos:O1x_Rmos+nbcI1-1, :) = images{1};

% Copie des autres images transformees par leurs homographies respectives
% par rapport à I1.
for x=1:nbcImos,
  for y=1:nblImos,
    % Calcul des coordonnees dans I1 connaissant les coordonnees du point origine de I1 dans Imos. 
    y_R1=y-O1y_Rmos;
    x_R1=x-O1x_Rmos;

    y_Rimoins1=y_R1;
    x_Rimoins1=x_R1;

    for i=2:N
        [nblIimoins1, nbcIimoins1, ~] = size(images{i-1});
        [nblIi, nbcIi, ~] = size(images{i});

        % Dans le repere attache a l'image I1, 
        % nous estimons les coordonnees du point image de (y_R1,x_R1)
        % par l'homographie homographies(i) : (xy_Ri). 
        Hi = squeeze(homographies(i-1,:,:));
        xy_Ri = appliquerHomographie(Hi,[x_R1 y_R1]);
    
        % Il existe plusieurs strategies, mais, ici, 
        % pour estimer les coordonnees (entieres) , 
        % on choisit : sans interpolation, le plus proche voisin. 
        x_Ri=round(xy_Ri(1)); 
        y_Ri=round(xy_Ri(2));
    
        % On verifie que xy_Ri appartient bien a l'image Ii 
        % avant d'affecter cette valeur a Imos
        % Lignes et colonnes sont inversees. 
        if(x_Ri>=1 & x_Ri<=nbcIi & y_Ri>=1 & y_Ri<=nblIi)
            % Si on est aussi dans l'image Iimoins1, moyenne pondérée
            if (x_Rimoins1>=1 & x_Rimoins1<=nbcIimoins1 & y_Rimoins1>=1 & y_Rimoins1<=nblIimoins1)
                d1 = nbcIimoins1 - x_Rimoins1;
                d2 = y_Ri;
                p1 = d1/(d1+d2);
                p2 = d2/(d1+d2);
                Imos(y,x,:)=p1.*images{i-1}(y_Rimoins1,x_Rimoins1,:) + ...
                    p2.*images{i}(y_Ri,x_Ri,:);
            else
                Imos(y,x,:)=images{i}(y_Ri,x_Ri,:);
            end
        end 

        y_Rimoins1 = y_Ri;
        x_Rimoins1 = x_Ri;

    end
  end
end

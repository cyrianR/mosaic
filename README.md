# Mosaïque d'images

## 1. Travail à rendre

- `harris.m` : détection des points d'intérêt par la méthode de Harris.
- `voisinage.m` : extraction du voisinage local d'un point.
- `apparier_Points.m` : calcul d'une matrice de corrélation entre points d'intérêt.
- `apparier_POI.m` : sélection des correspondances fiables entre deux images.
- `homographie.m` : estimation de la matrice d'homographie.
- `mosaique.m` : création d'une mosaïque à partir de deux images.
- `mosaiquebis.m` : version alternative de mosaïque.
- `mosaiquecoul.m` : mosaïque couleur.
- `mosaiqueN.m` : mosaïque obtenue à partir de N images.
- `TP_mosaique.m` : script principal qui exécute tout le pipeline.
- `Images` : un dossier contenant toutes les images obtenues

## 2. Etapes du traitement

1. Lecture des images.
2. Détection des points d'intérêt par la méthode de Harris.
3. Calcul du voisinage local autour de chaque point.
4. Appariement des points entre deux images.
5. Vérification des correspondances avec un seuil et/ou une contrainte de symétrie.
6. Estimation de l'homographie.
7. Projection d'une image dans le repère d'une autre.
8. Superposition des images pour former la mosaïque.

## 3. Détail du code

### 3.1 Détection de points d'intérêt : `harris.m`

-> repérer des zones locales très contrastées ie des points que l'on pourra trouver dans plusieurs images.

- Ix = dérivée de l'image selon x
- Iy = dérivée selon y
- A = Ix² lissé par filtre de lissage gaussien de taille TailleFenetre avec conv2
- B = Iy² lissé par filtre de lissage gaussien de taille TailleFenetre avec conv2
- C = Ix·Iy lissé par filtre de lissage gaussien de taille TailleFenetre avec conv2
- réponse Harris : R = det(M) - k·trace(M)² avec M = [[A, C], [C, B]].

Ensuite, on garde les pixels qui sont des maxima locaux dans une fenêtre donnée, puis on sélectionne les `NbPoints` plus fortes réponses.

Paramètres :

- `I` : Image
- `TailleFenetre` : taille du voisinage utilisé pour le calcul,
- `NbPoints` : nombre de points d'intérêt à conserver,
- `k` : coefficient de la méthode Harris, conséillé entre 0.04 et 0.06

Sortie :

- `XY` : coordonnées (x, y) des points détectés,
- `Res` : image de réponse Harris.

### 3.2 Voisinage local : `voisinage.m`

-> comparer le voisinage autour des points de harris.

On découpe une fenêtre centrée sur chaque point qu'on vectorise. On compare ainsi les points et leurs voisinage pour avoir de meilleures corresspondances.

Paramètres :

- `I` : Image
- `xyPt` : matrice de taille NbPoints×2 contenant les coordonnées des points à apparier ie 1 point par ligne
- `TailleFenetre` : taille du voisinage utilisé pour le calcul,

Sortie :

- `voisins` : matrice de taille NbPoints x TailleFenetre^2
      - avec sur chaque ligne, le voisinage d'un point

### 3.3 Appariement des points : `apparier_Points.m`

-> construire une matrice de similarité entre les points d'intérêt de deux images. Pour chaque point de l'image 1 et chaque point de l'image 2, on compare leurs voisinages et on calcule un score de corrélation.

Paramètres :

- `I1` : Image 1
- `Ptint1` : Points à apparier de I1
- `I2` : Image 2
- `Ptint2` : Points à apparier de I2
- `K` : taille de la fenêtre de corrélation

Sortie :

- `C` : Score de corrélation entre tous les points à apparier de I1 et ceux de I2 de taille nbPtInt1 x nbPtInt2

### 3.4 Vérification des correspondances : `apparier_POI.m`

-> sélectionner les correspondances les plus fiables entre les points des deux images.

La fonction calcule d'abord les scores de corrélation entre les voisinages, puis cherche pour chaque point le meilleur appariement. Elle peut appliquer différentes contraintes :

- `"aucune"` : on garde le meilleur appariement,
- `"seuil"` : on garde les appariements dont le score est supérieur ou égal au seuil,
- `"symetrie"` : on garde les appariements qui sont les meilleurs dans les deux sens,
- `"all"` : on applique à la fois le seuil et la contrainte de symétrie.

Cette étape permet d'éliminer des correspondances fausses avant le calcul de l'homographie.

Paramètres :

- `Im1` : Image 1
- `XY_1` : points d'intérêt de l'image 1
- `Im2` : Image 2
- `XY_2` : points d'intérêt de l'image 2
- `TailleFenetre` : taille de la fenêtre utilisée pour calculer la corrélation
- `seuil` : score minimal accepté pour la contrainte `"seuil"` ou `"all"`
- `contrainte` : méthode de vérification (`"aucune"`, `"seuil"`, `"symetrie"` ou `"all"`)
- `affichage` : indique si les appariements doivent être affichés

Sortie :

- `XY_C1` : coordonnées des points appariés dans l'image 1
- `XY_C2` : coordonnées correspondantes dans l'image 2

### 3.5 Estimation de l'homographie : `homographie.m`

-> calculer la transformation entre deux images à partir de leurs points appariés.

On obtiens une matrice `3×3` qui permet de projeter les points d'une image dans l'autre.

Il faut au moins 4 paires de points pour estimer une homographie.

Paramètres :

- `XY_C1` : coordonnées des points de l'image 1
- `XY_C2` : coordonnées des points homologues de l'image 2

Sortie :

- `H` : matrice d'homographie estimée

### 3.6 Application de l'homographie : `appliquerHomographie.m`

-> projeter un ou plusieurs points dans un autre repère à l'aide d'une homographie.

Les coordonnées des points sont transformées en coordonnées homogènes, multipliées par la matrice `H`, puis ramenées à deux coordonnées.

Paramètres :

- `H` : matrice d'homographie de taille `3×3`
- `xy1` : coordonnées des points à transformer, un point par ligne

Sortie :

- `xy2` : coordonnées des points après transformation

## 4. Construction de la mosaïque

### 4.1 Mosaïque à deux images : `mosaique.m`

-> assembler deux images en niveaux de gris en utilisant leur homographie.

Paramètres :

- `I1` : Image de référence
- `I2` : Image à projeter dans le repère de `I1`
- `H` : homographie entre les deux images

Sortie :

- `Imos` : mosaïque des deux images

### 4.2 Autre méthode de reconstruction : `mosaiquebis.m`

-> construire une mosaïque en niveaux de gris avec une fusion pondérée dans la zone de recouvrement.

Cette fonction reprend le principe de `mosaique.m`, mais calcule une moyenne pondérée des pixels lorsque les deux images se recouvrent.

Paramètres :

- `I1` : Image de référence
- `I2` : Image à projeter dans le repère de `I1`
- `H` : homographie entre les deux images

Sortie :

- `Imos` : mosaïque des deux images

### 4.3 Mosaïque couleur : `mosaiquecoul.m`

-> construire une mosaïque à partir de deux images couleur.

Le principe est le même que pour `mosaique.m`. La fonction traite les trois canaux de couleur et réalise une fusion pondérée dans la zone de recouvrement.

Paramètres :

- `I1` : Image couleur de référence
- `I2` : Image couleur à projeter dans le repère de `I1`
- `H` : homographie entre les deux images

Sortie :

- `Imos` : mosaïque couleur des deux images

### 4.4 Mosaïque à N images : `mosaiqueN.m`

-> construire une mosaïque couleur à partir de plusieurs images.

La fonction détecte et apparie les points entre chaque paire d'images successives, estime les homographies, puis les compose pour projeter les images dans le repère de la première.

Paramètres :

- `images` : cellules contenant les images couleur dans leur ordre d'assemblage
- `TailleFenetre` : taille de la fenêtre utilisée pour détecter et apparier les points
- `NbPoints` : nombre de points d'intérêt à conserver par image
- `k` : coefficient de la méthode de Harris
- `seuil` : seuil de corrélation pour filtrer les appariements

Sortie :

- `Imos` : mosaïque couleur construite à partir des images

## 5. Script principal : `TP_mosaique.m`

-> exécuter les différentes étapes du traitement et afficher les résultats.

Le script lit les images, fixe les paramètres, détecte et apparie les points, estime l'homographie, puis construit les mosaïques.

Paramètres réglés dans le script :

- `TailleFenetre` : taille de la fenêtre de voisinage et de corrélation
- `NbPoints` : nombre de points d'intérêt conservés
- `k` : coefficient de Harris
- `seuil` : seuil de corrélation des appariements
- `contrainte` : "aucune", "seuil", "symetrie" ou "all"
- `affichage` : true ou false pour afficher ou non l'appariement

| Paramètre | Valeur | Correspondances | Mosaïque |
|---|---|---|---|
| TailleFenetre | 9 | 18 | fausse |
| TailleFenetre | 15 | 6 | correcte |
| TailleFenetre | 21 | 8 | fausse |
| NbPoints | 50 | 5 | correcte |
| NbPoints | 100 | 6 | correcte |
| NbPoints | 200 | 14 | fausse |
| k | 0.04 | 5 | correcte |
| k | 0.05 | 6 | correcte |
| k | 0.06 | 4 | correcte (limite) |
| seuil | 0.7 | 17 | correcte |
| seuil | 0.8 | 13 | correcte |
| seuil | 0.9 | 6 | correcte |
| contrainte | "aucune" | 100 | fausse |
| contrainte | "seuil" | 7 | fausse |
| contrainte | "symetrie" | 30 | fausse |
| contrainte | "all" | 6 | correcte |

### 6.1 Taille de la fenêtre
Seule la taille 15 donne une mosaïque correcte. Avec 9, le voisinage est trop petit pour être
discriminant : on obtient 18 correspondances, mais beaucoup sont fausses. Avec 21, le voisinage
contient trop de contenu et la corrélation perd en précision. Le nombre de correspondances ne
garantit donc pas la qualité du résultat : un seul faux appariement suffit à fausser l'homographie,
car elle est estimée par moindres carrés. Ce paramètre règle à la fois Harris et la corrélation,
donc les deux effets sont mêlés.


### 6.2 Nombre de points
50 et 100 points donnent une mosaïque correcte : 5 paires justes suffisent. Avec 200 points, on
obtient 14 correspondances mais la mosaïque est fausse : les points ajoutés ont une réponse de
Harris faible, sont difficiles à apparier, et le seuil de 0.9 laisse passer des faux. Ajouter des
points n'améliore donc pas forcément le résultat. 100 est un bon compromis.

### 6.3 Coefficient de Harris
Pour k = 0.04, 0.05 et 0.06, les résultats sont proches (5, 6 et 4 correspondances) et les mosaïques
sont toutes correctes : dans la plage conseillée, k a peu d'influence. À 0.06, on tombe à 4 paires,
le minimum pour une homographie, ce qui rend le résultat fragile. On garde 0.05.

### 6.4 Seuil et contrainte
Les trois seuils (0.7, 0.8, 0.9) donnent une mosaïque correcte. Plus le seuil est bas, plus on
garde de correspondances (17, 13, 6), ce qui stabilise l'homographie, mais un seuil trop bas risque
de laisser passer de faux appariements. 0.8 est un bon compromis.

Pour les contraintes, seule `"all"` donne une mosaïque correcte. Sans vérification, `"aucune"` garde
les 100 points, y compris les faux, car chaque point a forcément un meilleur voisin. Le seuil seul
(7 paires) et la symétrie seule (30 paires) laissent encore passer des faux appariements. Le seuil
élimine les paires peu corrélées, la symétrie les paires non réciproques : les deux filtres sont
complémentaires.

### 6.5 Bilan
Le réglage retenu est `TailleFenetre = 15`, `NbPoints = 100`,
`k = 0.05`, `seuil = 0.8` et `contrainte = "all"`. Les paramètres les plus sensibles sont la taille
de la fenêtre et la contrainte d'appariement.

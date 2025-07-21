{ Auteur : Gr�gory BERSEGEAY (http://www.gbesoft.fr)
  Impl�mentation de l'algorithme A* (https://fr.wikipedia.org/wiki/Algorithme_A*)
}
unit uGBEPathFinder;

interface

uses System.SysUtils, System.Types, System.UITypes, System.Classes, System.Generics.Collections;

Type
  TGBENoeud = record
  public
    coutDeplacement, heuristique, estimationCout : integer;
    position, parent : TPoint;
  end;

  TGBEPathFinderMode = (deplacementsMinimum, coutMinimum);
  TGBEPathFinder = class
    fNoeudDepart, fNoeudArrivee : TGBENoeud;
    listeNoeudsPossibles : TDictionary<TPoint, TGBENoeud>;
    listeNoeudsVoisins : TDictionary<TPoint, TGBENoeud>;
    flGrille, fhGrille, fCoutDeplacementCote, fCoutDeplacementDiagonal : integer;
    fAutoriserDeplacementDiagonal, fQuePremiereEtape : boolean;
    fMode : TGBEPathFinderMode;

    function calculerCoutArrivee(point : TPoint):integer;
    procedure optimiserChemin;
    function rechercheCoutTotalMin(liste: TDictionary<TPoint, TGBENoeud>):TGBENoeud;
    procedure listerVoisins(unNoeud: TGBENoeud);

  public
    listeChemin : TDictionary<TPoint, TGBENoeud>;
    listeNoeudsObstacles : TDictionary<TPoint, TGBENoeud>;
    listeOptimisee : TList<TGBENoeud>;

    constructor Create; virtual;
    destructor Destroy; override;
    function RechercherChemin:boolean;

    property NoeudDepart : TGBENoeud read fNoeudDepart write fNoeudDepart;
    property NoeudArrivee: TGBENoeud read fNoeudArrivee write fNoeudArrivee;
    property LargeurGrille : integer read flGrille write flGrille;
    property HauteurGrille : integer read fhGrille write fhGrille;
    property CoutDeplacementCote : integer read fCoutDeplacementCote write fCoutDeplacementCote;
    property CoutDeplacementDiagonal : integer read fCoutDeplacementDiagonal write fCoutDeplacementDiagonal;
    property AutoriserDeplacementDiagonal : boolean read fAutoriserDeplacementDiagonal write fAutoriserDeplacementDiagonal;
    property QuePremiereEtape : boolean read fQuePremiereEtape write fQuePremiereEtape;
    property Mode : TGBEPathFinderMode read fMode write fMode;
  end;

implementation

{ TGBEPathFinder }

constructor TGBEPathFinder.Create;
begin
  largeurGrille := 12;
  hauteurGrille := 10;
  CoutDeplacementCote := 10;
  CoutDeplacementDiagonal := 15;
  AutoriserDeplacementDiagonal := true;
  QuePremiereEtape := false;
  Mode := TGBEPathFinderMode.deplacementsMinimum;
  listeNoeudsPossibles := TDictionary<TPoint, TGBENoeud>.create;
  listeChemin := TDictionary<TPoint, TGBENoeud>.create;
  listeNoeudsObstacles := TDictionary<TPoint, TGBENoeud>.create;
  listeNoeudsVoisins := TDictionary<TPoint, TGBENoeud>.create;
  listeOptimisee := TList<TGBENoeud>.create;
end;

destructor TGBEPathFinder.Destroy;
begin
  FreeAndNil(listeNoeudsPossibles);
  FreeAndNil(listeChemin);
  FreeAndNil(listeNoeudsObstacles);
  FreeAndNil(listeNoeudsVoisins);
  FreeAndNil(listeOptimisee);
  inherited;
end;

// Permet de calculer le cout d'un point donn� jusqu'� l'arriv�e
function TGBEPathFinder.calculerCoutArrivee(point : TPoint):integer;
begin
  var absX := abs(point.X - noeudArrivee.position.X);
  var absY := abs(point.Y - noeudArrivee.position.Y);
  var valeurDiagonale, valeurCote : integer;
  if absX > absY then begin
    valeurDiagonale := absY * coutDeplacementDiagonal;
    valeurCote := (absX - absY) * coutDeplacementCote;
  end else begin
    valeurDiagonale := absX * coutDeplacementDiagonal;
    valeurCote := (absY - absX) * coutDeplacementCote;
  end;
  result := valeurDiagonale + valeurCote;
end;

// Algorithme A* : 1�re �tape
// On explore toutes les pistes jusqu'� trouver le noeud d'arriv�e
function TGBEPathFinder.RechercherChemin:boolean;
begin
  result := false; // initialisation du retour � false (indiquant qu'aucun chemin n'a �t� trouv�)
  listeChemin.Clear;
  listeNoeudsVoisins.Clear;
  listeNoeudsPossibles.Clear;
  listeNoeudsPossibles.Add(NoeudDepart.position,NoeudDepart);  // au d�but, on se place sur le noeud de d�part, c'est le seul noeud possible

  while listeNoeudsPossibles.Count > 0 do begin  // Tant que la liste des noeuds possibles n'est pas vide
    var unNoeud := rechercheCoutTotalMin(listeNoeudsPossibles); // recherche du noeud possible ayant le cout minimum
    listeNoeudsPossibles.Remove(unNoeud.position);  // on enl�ve le noeud trouv� de la liste des noeuds possibles
    listeChemin.Add(unNoeud.position, unNoeud);  // on le rajoute � la liste des noeuds parcourus pour trouver le chemin

    if unNoeud.position = noeudArrivee.position then begin  // si le noeud trouv� est le noeud d'arriv�e (test sur la position)
      noeudArrivee := unNoeud; // on reprend les informations du noeud trouv� pour compl�ter les informations du noeud d'arriv�e (entre autre la position de son parent)
      listeNoeudsPossibles.Clear;
      result := true; // On a trouv� un chemin
      break;          // on sort du while
    end;

    listerVoisins(unNoeud);  // On renseigne la liste des noeuds voisins du noeud trouv�

    for var unVoisin in listeNoeudsVoisins.Keys do begin  // Parcours des noeuds voisins
      if listeChemin.ContainsKey(unVoisin) then continue;   // Si le voisin est d�j� dans la liste des noeuds parcourus on passe � l'it�ration suivante

      if not(listeNoeudsPossibles.ContainsKey(unVoisin)) then // Si le voisin n'est pas d�j� dans la liste des noeuds possibles, on l'y rajoute
        listeNoeudsPossibles.Add(unVoisin, listeNoeudsVoisins.Items[unVoisin]);
    end;
  end;

  // 1ere �tape termin�e, si on a trouv� une solution et que l'on souhaite faire la 2nd �tape,
  // alors on passe � "l'optimisation"
  if result and not(QuePremiereEtape) then optimiserChemin;
end;

// 2�me partie : permet de tracer uniquement le chemin � partir des pistes explor�es � l'�tape 1
// On va parcourir la liste des noeuds explor�s � l'�tape 1 en partant du noeud d'arriv�e et en remontant
// jusqu'au noeud de d�part afin de ne dresser la liste que des noeuds n�cessaires � la constitution du chemin
procedure TGBEPathFinder.optimiserChemin;
begin
  var iNoeud := noeudArrivee; // on part du noeud d'arriv�e

  while iNoeud.position <> noeudDepart.position do begin  // Tant qu'on n'est pas sur le noeud de d�part
    listeOptimisee.Add(iNoeud); // on place le noued courant dans la liste temporaire
    listeChemin.TryGetValue(iNoeud.parent, iNoeud); // le nouveau noeud courant devient le noeud parent du noeud courant
  end;
  listeOptimisee.Add(noeudDepart); // On ajoute le noeud de d�part � la fin de la liste
  listeOptimisee.Reverse; // On inverse la liste (pour avoir les noeuds dans l'ordre noeud de d�part vers noeud d'arriv�e)

  listeChemin.Clear;
  for iNoeud in listeOptimisee do // On replace dans listeChemin la liste optimis�e trouv�e
    listeChemin.Add(iNoeud.position, iNoeud);
end;

// Permet de r�cup�rer le noeud le moins couteux d'une liste
function TGBEPathFinder.rechercheCoutTotalMin(liste: TDictionary<TPoint, TGBENoeud>):TGBENoeud;
begin
  if liste.Count > 0 then begin
    var tableau := liste.ToArray;   // Astuce pour r�cup�rer le premier �l�ment d'un TDictionary (pas de m�thode first sur le TDictionary)
    result := tableau[0].Value; // Astuce pour r�cup�rer le premier �l�ment d'un TDictionary
    for var iNoeud in liste.Keys do begin  // Parcours de la liste
      if liste.Items[iNoeud].estimationCout < result.estimationCout then begin
        result := liste.Items[iNoeud];
        continue;
      end;
      if liste.Items[iNoeud].estimationCout = result.estimationCout then begin
        case mode of
          deplacementsMinimum: begin
                                 if liste.Items[iNoeud].heuristique < result.heuristique then begin
                                   result := liste.Items[iNoeud];
                                   continue;
                                 end;
                                 if (liste.Items[iNoeud].heuristique = result.heuristique) and
                                    (liste.Items[iNoeud].coutDeplacement < result.coutDeplacement) then
                                      result := liste.Items[iNoeud];
                               end;
          coutMinimum: begin
                         if liste.Items[iNoeud].coutDeplacement < result.coutDeplacement then begin
                           result := liste.Items[iNoeud];
                           continue;
                         end;
                         if (liste.Items[iNoeud].coutDeplacement = result.coutDeplacement) and
                            (liste.Items[iNoeud].heuristique < result.heuristique) then
                              result := liste.Items[iNoeud];
                       end;
        end;
      end;
    end;
  end;
end;

{ Permet de lister les voisins d'un noeud donn� }
procedure TGBEPathFinder.listerVoisins(unNoeud: TGBENoeud);
begin
  listeNoeudsVoisins.Clear;

  // Parcours des 8 positions autour du noeud donn�
  for var x := -1 to 1 do begin
    for var y := -1 to 1 do begin
      if (x = 0) and (y = 0) then continue;
      if not(AutoriserDeplacementDiagonal) then begin // si les d�placements en diagonal ne sont pas autoris�s
        if (x = -1) and (y = -1) then continue;
        if (x = 1) and (y = -1) then continue;
        if (x = 1) and (y = 1) then continue;
        if (x = -1) and (y = 1) then continue;
      end;

      var unVoisin : TGBENoeud;
      unVoisin.position.x := unNoeud.position.X + x;
      unVoisin.position.y := unNoeud.position.Y + y;

      // Le voisin doit �tre dans la grille
      if (unVoisin.position.x >= 0) and (unVoisin.position.x < LargeurGrille) and
         (unVoisin.position.y >= 0) and (unVoisin.position.y < HauteurGrille) then begin
        if (unVoisin.position.x <> unNoeud.position.x) and (unVoisin.position.y <> unNoeud.position.y) then
           unVoisin.coutDeplacement := coutDeplacementDiagonal
        else unVoisin.coutDeplacement := coutDeplacementCote;
        unVoisin.parent := unNoeud.position;

        // Si le voisin n'est pas dans la liste des noeuds obstacles, on peut le rajouter � la liste des noeuds voisins
        if (not(listeNoeudsObstacles.ContainsKey(unVoisin.position))) then begin
          unVoisin.heuristique := calculerCoutArrivee(unVoisin.position); // On calcule ses couts
          unVoisin.estimationCout := unVoisin.coutDeplacement + unVoisin.heuristique;
          listeNoeudsVoisins.Add(unVoisin.position, unVoisin); // On ajoute le noeud � la liste des voisins
        end;
      end;
    end;
  end;
end;

end.

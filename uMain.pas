unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Layouts, FMX.Viewport3D,
  FMX.StdCtrls, FMX.Objects, uLabyrinthe, System.Math.Vectors, FMX.Controls3D,
  FMX.Objects3D, FMX.MaterialSources, FMX.Ani, FMX.Types3D, uGBEPathFinder,
  uConsts, FMX.Controls.Presentation;

type
  TPlayerDirection = (left, right, up, down, none);
  TfrmMain = class(TForm)
    layIHM: TLayout;
    rIHM: TRectangle;
    pGround: TPlane;
    dmyLabyrinthe: TDummy;
    vp3D: TViewport3D;
    lmsGround: TLightMaterialSource;
    Light: TLight;
    lmsWalls: TLightMaterialSource;
    timerCPU: TTimer;
    dmyWalls: TDummy;
    lmsPlayer: TLightMaterialSource;
    arrivee: TCube;
    lmsFinish: TLightMaterialSource;
    lmsCPUPlayer: TLightMaterialSource;
    layIHMInfos: TLayout;
    layCPU: TLayout;
    lblCPU: TLabel;
    lblCPUScore: TLabel;
    layPlayer: TLayout;
    lblPlayer: TLabel;
    lblPlayerScore: TLabel;
    btnQuit: TButton;
    aniRotation: TFloatAnimation;
    player: TCylinder;
    playerCPU: TCylinder;
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure timerCPUTimer(Sender: TObject);
    procedure btnQuitClick(Sender: TObject);
    procedure aniRotationFinish(Sender: TObject);
  private
    procedure creerMurs(posX, posY: integer);
    procedure PlacerJoueurs;
    procedure goLeft;
    procedure goRight;
    procedure goUp;
    procedure goDown;
    procedure gererTouches;
    procedure placerSortie;
    procedure genererPartie;
    procedure deplacerPlayerCPU;
    procedure initialiserPathFinding;
    procedure creerListeObstacles;
    procedure terminerPartie(playerWin: boolean);
    procedure afficherScore;
    procedure initialiserNiveau;
    procedure viderNiveau;
    procedure genererNiveau;
    { Déclarations privées }
  public
    { Déclarations publiques }
    niveau : TLabyrinthe;
    direction : TPlayerDirection;
    noeudDepart, noeudArrivee : TGBENoeud;
    PathFinder : TGBEPathFinder;
    iEtapeCPU, cpuScore, playerScore : integer;
    activerTouches, playerFirst: boolean;
  end;

var
  frmMain: TfrmMain;

implementation
{$R *.fmx}

procedure TfrmMain.genererPartie;
begin
  initialiserNiveau;

  for var i := 0 to niveau.tailleX -1 do
    for var j := 0 to niveau.tailleY -1 do
      if niveau.matrice[i,j] = -1 then creerMurs(i, j); // Générer un mur

  placerJoueurs;
  placerSortie;
  initialiserPathFinding;
  iEtapeCPU := 0;
end;

procedure TFrmMain.initialiserNiveau;
begin
  viderNiveau;
  genererNiveau;
end;

procedure TfrmMain.viderNiveau;
begin
  player.parent := vp3D;
  playerCPU.parent := vp3D;
  arrivee.parent := vp3D;
  dmyWalls.DeleteChildren;
  player.parent := dmyWalls;
  playerCPU.parent := dmyWalls;
  arrivee.parent := dmyWalls;
  if assigned(niveau) then niveau.Destroy;
end;

procedure TfrmMain.genererNiveau;
begin
  randomize;
  niveau := TLabyrinthe.Create(TAILLE_X, TAILLE_Y);
  niveau.niveauOuverture := random(3)+1;
  niveau.genererLabyrinthe;
  pGround.Width := niveau.tailleX;
  pGround.Height := niveau.tailleY;
  dmyWalls.position.x := -pGround.Width * 0.5;
  dmyWalls.position.y := -pGround.height * 0.5;
end;

procedure TfrmMain.placerSortie;
begin
  randomize;
  var rand := random(90);
  var arriveePlacee := false;
  var indice := 0;
  for var i := 1 to niveau.tailleX -2 do begin
    for var j := 1 to 5 do begin
       if niveau.matrice[i,j] = 0 then begin
         inc(indice);
         if indice = rand then begin
           arrivee.position.x := i + 0.5;
           arrivee.position.y := j + 0.5;
           arriveePlacee := true;
           break;
         end;
       end;
    end;
    if arriveePlacee then break;
  end;
end;

procedure TfrmMain.initialiserPathFinding;
begin
  noeudDepart.position.x := Trunc(playerCPU.Position.x);
  noeudDepart.position.y := Trunc(playerCPU.Position.y);
  noeudArrivee.position.x := Trunc(arrivee.position.x);
  noeudArrivee.position.y := Trunc(arrivee.position.y);
  PathFinder.LargeurGrille := niveau.tailleX;
  PathFinder.HauteurGrille := niveau.tailleY;
  PathFinder.NoeudDepart := noeudDepart;
  PathFinder.NoeudArrivee := noeudArrivee;
  PathFinder.AutoriserDeplacementDiagonal := true;
  PathFinder.Mode := TGBEPathFinderMode.coutMinimum;
  creerListeObstacles;
  PathFinder.RechercherChemin;
end;

procedure TfrmMain.aniRotationFinish(Sender: TObject);
begin
  placerJoueurs;
  activerTouches := true;
end;

procedure TfrmMain.btnQuitClick(Sender: TObject);
begin
  close;
end;

procedure TfrmMain.creerListeObstacles;
begin
  PathFinder.listeNoeudsObstacles.Clear;
  PathFinder.listeOptimisee.Clear;
  var noeudObstacle : TGBENoeud;
  for var i := 0 to niveau.tailleX -1 do
    for var j := 0 to niveau.tailleY -1 do
       if niveau.matrice[i,j] = -1 then begin
         noeudObstacle.position.x := i;
         noeudObstacle.position.y := j;
         PathFinder.listeNoeudsObstacles.Add(noeudObstacle.position, noeudObstacle);
       end;
end;

procedure TfrmMain.timerCPUTimer(Sender: TObject);
begin
  if playerFirst then deplacerPlayerCPU; // Le CPU démarre après que l'humain est appuyé sur une flèche
end;

procedure TfrmMain.deplacerPlayerCPU;
begin
  if iEtapeCPU <= PathFinder.listeOptimisee.count-1 then begin
    TAnimator.AnimateFloat(playerCPU,'Position.x',PathFinder.listeOptimisee[iEtapeCPU].position.x +0.5,0.1);
    TAnimator.AnimateFloat(playerCPU,'Position.y',PathFinder.listeOptimisee[iEtapeCPU].position.y +0.5,0.1);
    inc(iEtapeCPU);
  end else TerminerPartie(false);
end;

procedure TfrmMain.PlacerJoueurs;
begin
  player.position.x := niveau.tailleX -2 + 0.5;
  player.position.y := niveau.tailleY -2 + 0.5;
  playerCPU.Position.x := 1.5;
  playerCPU.position.y := niveau.tailleY -2 + 0.5;
end;

procedure TfrmMain.goLeft;
begin
  if niveau.matrice[Trunc(player.position.X)-1, Trunc(player.position.Y)] = 0 then
     player.position.X := player.position.X-1;
end;

procedure TfrmMain.goRight;
begin
  if niveau.matrice[Trunc(player.position.X)+1, Trunc(player.position.Y)] = 0 then
     player.position.X := player.position.X+1;
end;

procedure TfrmMain.goUp;
begin
  if niveau.matrice[Trunc(player.position.X), Trunc(player.position.Y)-1] = 0 then
     player.position.Y := player.position.Y-1;
end;

procedure TfrmMain.goDown;
begin
  if niveau.matrice[Trunc(player.position.X), Trunc(player.position.Y)+1] = 0 then
    player.position.Y := player.position.Y+1;
end;

procedure TfrmMain.creerMurs(posX, posY : integer);
begin
  var unCube := TCube.Create(nil);
  unCube.Parent := dmyWalls;
  unCube.Name := 'cube' + pGround.ChildrenCount.ToString;
  unCube.Position.Y := 0;
  unCube.Width := 1;
  unCube.Height := 1;
  unCube.Depth := 1;
  unCube.Position.X := posX + 0.5;
  unCube.Position.Y := posY + 0.5;
  unCube.Position.Z := - 0.5;
  unCube.HitTest := false;
  unCube.TwoSide := true;
  unCube.MaterialSource := lmsWalls;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  PathFinder := TGBEPathFinder.Create;
  cpuScore := 0;
  playerScore := 0;
  timerCPU.Interval := 500;
  activerTouches := true;
  playerFirst := false;
  afficherScore;
  genererPartie;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(PathFinder);
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if not(activerTouches) then exit;

  direction := TPlayerDirection.none;
  if key = vkLeft then direction := TPlayerDirection.left;
  if key = vkRight then direction := TPlayerDirection.right;
  if key = vkUp then direction := TPlayerDirection.up;
  if key = vkDown then direction := TPlayerDirection.down;
  if direction = TPlayerDirection.none then exit;
  playerFirst := true;
  gererTouches;
  timerCPU.enabled := true;
end;

procedure TfrmMain.gererTouches;
begin
  case direction of
    TPlayerDirection.left: goLeft;
    TPlayerDirection.right: goRight;
    TPlayerDirection.up: goUp;
    TPlayerDirection.down: goDown;
  end;

  if (player.Position.x = arrivee.position.x) and (player.Position.y = arrivee.position.y) then TerminerPartie(true);
end;

procedure TfrmMain.terminerPartie(playerWin: boolean);
begin
  playerFirst := false;
  timerCPU.enabled := false;
  activerTouches := false;
  direction := TPlayerDirection.none;
  if playerWin then begin
    inc(playerScore);
    if timerCPU.interval > 150 then timerCPU.Interval := timerCPU.Interval - 25;
  end else inc(cpuScore);
  afficherScore;
  aniRotation.start;
  genererPartie;
end;

procedure TfrmMain.afficherScore;
begin
  lblCPUScore.text := cpuScore.ToString;
  lblPlayerScore.text := playerScore.ToString;
end;

end.

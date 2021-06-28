{ Main "playing game" state, where most of the game logic takes place.

  Feel free to use this code as a starting point for your own projects.
  (This code is in public domain, unlike most other CGE code which
  is covered by the LGPL license variant, see the COPYING.txt file.) }
unit GameStatePlay;

interface

uses Classes,
  CastleUIState, CastleComponentSerialize, CastleUIControls, CastleControls,
  CastleKeysMouse, CastleViewport, CastleScene, CastleVectors, CastleCameras,
  CastleTransform,
  GameEnemy;

type
  { Main "playing game" state, where most of the game logic takes place. }
  TStatePlay = class(TUIState)
  private
    { Components designed using CGE editor, loaded from gamestateplay.castle-user-interface. }
    LabelFps: TCastleLabel;
    MainViewport: TCastleViewport;
    WalkNavigation: TCastleWalkNavigation;
    ButtonShadowImplementation: TCastleButton;
    ButtonRenderVersion: TCastleButton;
    ButtonDepthOrOffset: TCastleButton;
    ButtonDepthVersion: TCastleButton;
    ButtonIncUpdateFactor: TCastleButton;
    ButtonDecUpdateFactor: TCastleButton;

    { Enemies behaviors }
    Enemies: TEnemyList;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Stop; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: Boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
    procedure ButtonShadowImplementationClick(Sender: TObject);
    procedure ButtonRenderVersionClick(Sender: TObject);
    procedure ButtonDepthOrOffsetClick(Sender: TObject);
    procedure ButtonDepthVersionClick(Sender: TObject);
    procedure ButtonIncUpdateFactorClick(Sender: TObject);
    procedure ButtonDecUpdateFactorClick(Sender: TObject);
    procedure UpdateButtons;
  end;

var
  StatePlay: TStatePlay;

implementation

uses SysUtils, Math,
  CastleSoundEngine, CastleLog, CastleStringUtils, CastleFilesUtils,
  GameStateMenu, CastleInternalGLShadowVolumes;

{ TStatePlay ----------------------------------------------------------------- }

constructor TStatePlay.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gamestateplay.castle-user-interface';
end;

procedure TStatePlay.Start;
var
  SoldierScene: TCastleScene;
  Enemy: TEnemy;
  I: Integer;
begin
  inherited;

  { Find components, by name, that we need to access from code }
  LabelFps := DesignedComponent('LabelFps') as TCastleLabel;
  MainViewport := DesignedComponent('MainViewport') as TCastleViewport;
  WalkNavigation := DesignedComponent('WalkNavigation') as TCastleWalkNavigation;

  ButtonShadowImplementation := DesignedComponent('ButtonShadowImplementation') as TCastleButton;
  ButtonShadowImplementation.OnClick := @ButtonShadowImplementationClick;

  ButtonRenderVersion := DesignedComponent('ButtonRenderVersion') as TCastleButton;
  ButtonRenderVersion.OnClick := @ButtonRenderVersionClick;

  ButtonDepthOrOffset := DesignedComponent('ButtonDepthOrOffset') as TCastleButton;
  ButtonDepthOrOffset.OnClick := @ButtonDepthOrOffsetClick;

  ButtonDepthVersion := DesignedComponent('ButtonDepthVersion') as TCastleButton;
  ButtonDepthVersion.OnClick := @ButtonDepthVersionClick;

  ButtonIncUpdateFactor := DesignedComponent('ButtonIncUpdateFactor') as TCastleButton;
  ButtonDecUpdateFactor := DesignedComponent('ButtonDecUpdateFactor') as TCastleButton;
  ButtonIncUpdateFactor.OnClick := @ButtonIncUpdateFactorClick;
  ButtonDecUpdateFactor.OnClick := @ButtonDecUpdateFactorClick;

  UpdateButtons;

  {$ifdef OpenGLES}
    ButtonRenderVersion.Enabled := false;
    ButtonShadowImplementation.Enabled := false;
  {$endif}

  { Create TEnemy instances, add them to Enemies list }
  Enemies := TEnemyList.Create(true);
  for I := 1 to 4 do
  begin
    SoldierScene := DesignedComponent('SceneSoldier' + IntToStr(I)) as TCastleScene;
    { Below using nil as Owner of TEnemy, as the Enemies list already "owns"
      instances of this class, i.e. it will free them. }
    Enemy := TEnemy.Create(nil);
    SoldierScene.AddBehavior(Enemy);
    Enemies.Add(Enemy);
  end;
end;

procedure TStatePlay.Stop;
begin
  FreeAndNil(Enemies);
  inherited;
end;

procedure TStatePlay.Update(const SecondsPassed: Single; var HandleInput: Boolean);
begin
  inherited;
  { This virtual method is executed every frame.}
  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;
end;

function TStatePlay.Press(const Event: TInputPressRelease): Boolean;
var
  HitEnemy: TEnemy;
begin
  Result := inherited;
  if Result then Exit; // allow the ancestor to handle keys

  { This virtual method is executed when user presses
    a key, a mouse button, or touches a touch-screen.

    Note that each UI control has also events like OnPress and OnClick.
    These events can be used to handle the "press", if it should do something
    specific when used in that UI control.
    The TStatePlay.Press method should be used to handle keys
    not handled in children controls.
  }

  if Event.IsMouseButton(buttonLeft) then
  begin
    //SoundEngine.Sound(SoundEngine.SoundFromName('shoot_sound'));

    { We clicked on enemy if
      - TransformUnderMouse indicates we hit something
      - It has a behavior of TEnemy. }
    if (MainViewport.TransformUnderMouse <> nil) and
       (MainViewport.TransformUnderMouse.FindBehavior(TEnemy) <> nil) then
    begin
      HitEnemy := MainViewport.TransformUnderMouse.FindBehavior(TEnemy) as TEnemy;
      HitEnemy.Hurt;
    end;

    Exit(true);
  end;

  if Event.IsKey(CtrlM) then
  begin
    WalkNavigation.MouseLook := not WalkNavigation.MouseLook;
    Exit(true);
  end;

  if Event.IsKey(keyF5) then
  begin
    Container.SaveScreenToDefaultFile;
    Exit(true);
  end;

  if Event.IsKey(keyEscape) then
  begin
    TUIState.Current := StateMenu;
    Exit(true);
  end;
end;

procedure TStatePlay.ButtonShadowImplementationClick(Sender: TObject);
begin
  InternalUseOldShadowVolumes := not InternalUseOldShadowVolumes;
  UpdateButtons;
end;

procedure TStatePlay.ButtonRenderVersionClick(Sender: TObject);
begin
  InternalShadowVolumesOldRender := not InternalShadowVolumesOldRender;
  UpdateButtons;
end;

procedure TStatePlay.ButtonDepthOrOffsetClick(Sender: TObject);
begin
  InternalShadowVolumesUseDepth := not InternalShadowVolumesUseDepth;
  UpdateButtons;
end;

procedure TStatePlay.ButtonDepthVersionClick(Sender: TObject);
begin
  InternalShadowVolumesUseDepthV2 := not InternalShadowVolumesUseDepthV2;
  UpdateButtons;
end;

procedure TStatePlay.UpdateButtons;
begin
  if InternalUseOldShadowVolumes then
    ButtonShadowImplementation.Caption := 'Current: Old implementation'
  else
    ButtonShadowImplementation.Caption := 'Current: New implementation';

  if InternalShadowVolumesOldRender then
    ButtonRenderVersion.Caption := 'Current: Old render() with pop/push'
  else
    ButtonRenderVersion.Caption := 'Current: New render() without pop/push';

  if InternalShadowVolumesUseDepth then
    ButtonDepthOrOffset.Caption := 'Current: Depth'
  else
    ButtonDepthOrOffset.Caption := 'Current: Polygon offset';

  if InternalShadowVolumesUseDepthV2 then
    ButtonDepthVersion.Caption := 'Depth V2'
  else
    ButtonDepthVersion.Caption := 'Depth V1';

  ButtonIncUpdateFactor.Caption := 'Inc upd factor (' +
    IntToStr(MainViewport.InternalShadowVolumeUpdateFactor) + ')';

  ButtonDecUpdateFactor.Caption := 'Dec upd factor (' +
    IntToStr(MainViewport.InternalShadowVolumeUpdateFactor) + ')';
end;

procedure TStatePlay.ButtonIncUpdateFactorClick(Sender: TObject);
begin
  Inc(MainViewport.InternalShadowVolumeUpdateFactor);
  UpdateButtons;
end;

procedure TStatePlay.ButtonDecUpdateFactorClick(Sender: TObject);
begin
  if MainViewport.InternalShadowVolumeUpdateFactor > 0 then
    Dec(MainViewport.InternalShadowVolumeUpdateFactor);
  UpdateButtons;
end;


end.

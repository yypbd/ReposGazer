unit Form.ReposGazerMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, Menus, ActnList;

type
  { TFormMain }
  TFormMain = class(TForm)
    ActionViewRemote: TAction;
    ActionViewBranch: TAction;
    ActionViewStatus: TAction;
    ActionViewGitignore: TAction;
    ActionViewBasic: TAction;
    ActionFileOpenRepos: TAction;
    ActionFileRefresh: TAction;
    ActionEditCopyLocalPath: TAction;
    ActionEditOpenLocalPath: TAction;
    ActionEditCopyRemotePath: TAction;
    ActionEditOpenRemotePath: TAction;
    ActionFileExit: TAction;
    ActionListMain: TActionList;
    ButtonGitignoreReload: TButton;
    ButtonGitignoreSave: TButton;
    ButtonShowGithubGitignore: TButton;
    CoolBarMain: TCoolBar;
    ImageListMain: TImageList;
    LabelStatusRootPath: TLabel;
    ListViewRepo: TListView;
    MainMenuMain: TMainMenu;
    MemoBasicInfo: TMemo;
    MemoStatus: TMemo;
    MemoRemote: TMemo;
    MemoBranch: TMemo;
    MemoGitignore: TMemo;
    MenuItemPopupOpenRemotePath: TMenuItem;
    MenuItemAbout: TMenuItem;
    MenuItemFileOpenRepos: TMenuItem;
    MenuItemFileRefresh: TMenuItem;
    MenuItemEditOpenLocalPath: TMenuItem;
    MenuItemViewBasic: TMenuItem;
    MenuItemViewRemote: TMenuItem;
    MenuItemViewBranch: TMenuItem;
    MenuItemViewStatus: TMenuItem;
    MenuItemViewGitignore: TMenuItem;
    MenuItemEditCopyLocalPath: TMenuItem;
    MenuItemEditCopyRemotePath: TMenuItem;
    PanelStatusPath: TPanel;
    SeparatorEdit1: TMenuItem;
    MenuItemEditOpenRemotePath: TMenuItem;
    MenuItemView: TMenuItem;
    MenuItemFileExit: TMenuItem;
    MenuItemFile: TMenuItem;
    MenuItemEdit: TMenuItem;
    MenuItemSep01: TMenuItem;
    MenuItemPopupCopyRemotePath: TMenuItem;
    MenuItemPopupCopyLocalPath: TMenuItem;
    MenuItemPopupOpenLocalPath: TMenuItem;
    PageControlInfo: TPageControl;
    PanelGitignoreButtons: TPanel;
    PanelStatus: TPanel;
    PanelStatusProgress: TPanel;
    PopupMenuEdit: TPopupMenu;
    ProgressBar: TProgressBar;
    SeparatorFile1: TMenuItem;
    SplitterMain: TSplitter;
    TabSheetBasic: TTabSheet;
    TabSheetRemote: TTabSheet;
    TabSheetBranch: TTabSheet;
    TabSheetStatus: TTabSheet;
    TabSheetGitignore: TTabSheet;
    ToolBarMenu: TToolBar;
    ToolButtonViewBasic: TToolButton;
    ToolButtonViewRemote: TToolButton;
    ToolButtonViewBranch: TToolButton;
    ToolButtonViewStatus: TToolButton;
    ToolButtonViewGitignore: TToolButton;
    ToolButtonSep03: TToolButton;
    ToolButtonFileOpenRepos: TToolButton;
    ToolButtonFileRefresh: TToolButton;
    ToolButtonEditOpenRemotePath: TToolButton;
    ToolButtonSep01: TToolButton;
    ToolButtonEditCopyLocalPath: TToolButton;
    ToolButtonEditOpenLocalPath: TToolButton;
    ToolButtonEditCopyRemotePath: TToolButton;
    ToolButtonSep02: TToolButton;
    procedure ActionEditCopyLocalPathExecute(Sender: TObject);
    procedure ActionEditCopyRemotePathExecute(Sender: TObject);
    procedure ActionEditOpenLocalPathExecute(Sender: TObject);
    procedure ActionEditOpenRemotePathExecute(Sender: TObject);
    procedure ActionFileExitExecute(Sender: TObject);
    procedure ActionFileOpenReposExecute(Sender: TObject);
    procedure ActionFileRefreshExecute(Sender: TObject);
    procedure ActionListMainUpdate(AAction: TBasicAction; var Handled: Boolean);
    procedure ActionViewBasicExecute(Sender: TObject);
    procedure ActionViewBranchExecute(Sender: TObject);
    procedure ActionViewGitignoreExecute(Sender: TObject);
    procedure ActionViewRemoteExecute(Sender: TObject);
    procedure ActionViewStatusExecute(Sender: TObject);
    procedure ButtonGitignoreReloadClick(Sender: TObject);
    procedure ButtonGitignoreSaveClick(Sender: TObject);
    procedure ButtonShowGithubGitignoreClick(Sender: TObject);
    procedure ListViewRepoColumnClick(Sender: TObject; Column: TListColumn);
    procedure ListViewRepoCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure ListViewRepoSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure PopupMenuEditPopup(Sender: TObject);
  private
    FColumnToSort: Integer;

    procedure SearchGitRepoRecursive(const APath: string);
    procedure AddGitRepoToListView(const APath: string);
    procedure RefreshRepoInfos;
    procedure RefreshSelectedRepoInfos;
    procedure RefreshRepoInfo(AListItem: TListItem);

    procedure ShowInfo(Item: TListItem);
    procedure ShowBasicInfo(Item: TListItem);
    procedure ShowRemoteInfo(Item: TListItem);
    procedure ShowBranchInfo(Item: TListItem);
    procedure ShowStatusInfo(Item: TListItem);
    procedure ShowGitignoreInfo(Item: TListItem);
  protected
    procedure DoCreate; override;
    procedure DoDestroy; override;
  public

  end;

var
  FormMain: TFormMain;

implementation

uses
  Clipbrd, lclintf,
  Util.Common, Util.Git;

{$R *.lfm}

{ TFormMain }

procedure TFormMain.ButtonGitignoreReloadClick(Sender: TObject);
begin
  if ListViewRepo.Selected = nil then
    Exit;

  ShowGitignoreInfo(ListViewRepo.Selected);
end;

procedure TFormMain.ActionFileOpenReposExecute(Sender: TObject);
var
  Directory: string;
begin
  if SelectDirectory('', '', Directory, False) then
  begin
    ListViewRepo.Items.Clear;
    LabelStatusRootPath.Caption := 'Root Path : ' + Directory;

    SearchGitRepoRecursive(Directory);

    RefreshRepoInfos;
  end;
end;

procedure TFormMain.ActionFileExitExecute(Sender: TObject);
begin
  if MessageDlg(Application.Title, 'Exit?', mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes then
  begin
    Application.Terminate;
  end;
end;

procedure TFormMain.ActionEditCopyLocalPathExecute(Sender: TObject);
begin
  Clipboard.AsText := ListViewRepo.Selected.SubItems[0];
end;

procedure TFormMain.ActionEditCopyRemotePathExecute(Sender: TObject);
begin
  Clipboard.AsText := ListViewRepo.Selected.SubItems[1];
end;

procedure TFormMain.ActionEditOpenLocalPathExecute(Sender: TObject);
begin
  OpenDocument(ListViewRepo.Selected.SubItems[0]);
end;

procedure TFormMain.ActionEditOpenRemotePathExecute(Sender: TObject);
var
  Url: string;
begin
  Url := ListViewRepo.Selected.SubItems[1];

  OpenURL(Url);
end;

procedure TFormMain.ActionFileRefreshExecute(Sender: TObject);
begin
  RefreshSelectedRepoInfos;
end;

procedure TFormMain.ActionListMainUpdate(AAction: TBasicAction;
  var Handled: Boolean);
begin
  if ListViewRepo.Selected = nil then
  begin
    ActionFileRefresh.Enabled := False;

    ActionEditCopyLocalPath.Enabled := False;
    ActionEditOpenLocalPath.Enabled := False;
    ActionEditCopyRemotePath.Enabled := False;
    ActionEditOpenRemotePath.Enabled := False;
  end
  else
  begin
    ActionFileRefresh.Enabled := True;

    ActionEditCopyLocalPath.Enabled := ListViewRepo.Selected.SubItems[0] <> '';
    ActionEditOpenLocalPath.Enabled := ListViewRepo.Selected.SubItems[0] <> '';
    ActionEditCopyRemotePath.Enabled := ListViewRepo.Selected.SubItems[1] <> '';
    ActionEditOpenRemotePath.Enabled := (ListViewRepo.Selected.SubItems[1] <> '') and (LowerCase(Copy(ListViewRepo.Selected.SubItems[1], 1, 4)) = 'http');
  end;
end;

procedure TFormMain.ActionViewBasicExecute(Sender: TObject);
begin
  PageControlInfo.PageIndex := 0;

  ActionViewBasic.Checked := True;
end;

procedure TFormMain.ActionViewBranchExecute(Sender: TObject);
begin
  PageControlInfo.PageIndex := 2;

  ActionViewBranch.Checked := True;
end;

procedure TFormMain.ActionViewGitignoreExecute(Sender: TObject);
begin
  PageControlInfo.PageIndex := 4;

  ActionViewGitignore.Checked := True;
end;

procedure TFormMain.ActionViewRemoteExecute(Sender: TObject);
begin
  PageControlInfo.PageIndex := 1;

  ActionViewRemote.Checked := True;
end;

procedure TFormMain.ActionViewStatusExecute(Sender: TObject);
begin
  PageControlInfo.PageIndex := 3;

  ActionViewStatus.Checked := True;
end;

procedure TFormMain.ButtonGitignoreSaveClick(Sender: TObject);
var
  FileName: string;
begin
  if ListViewRepo.Selected = nil then
    Exit;

  FileName := ListViewRepo.Selected.SubItems[0] + PathDelim + '.gitignore';

  if FileExists(FileName) then
  begin
    if MessageDlg('Save .gitignore', 'Overwrite .gitignore?', mtConfirmation, [mbYes, mbNo], 0, mbYes) <> mrYes then
    begin
      Exit;
    end;
  end;

  MemoGitignore.Lines.SaveToFile(FileName);
end;

procedure TFormMain.ButtonShowGithubGitignoreClick(Sender: TObject);
var
  Url: string;
begin
  Url := 'https://github.com/github/gitignore';
  OpenURL(Url);
end;

procedure TFormMain.ListViewRepoColumnClick(Sender: TObject; Column: TListColumn
  );
begin
  FColumnToSort := Column.Index;
end;

procedure TFormMain.ListViewRepoCompare(Sender: TObject; Item1,
  Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  case FColumnToSort of
    0:  Compare := CompareText(Item1.Caption, Item2.Caption);
    else Compare := CompareText(Item1.SubItems[FColumnToSort - 1], Item2.SubItems[FColumnToSort - 1]);
  end;

  if ListViewRepo.SortDirection = sdDescending then
  begin
    Compare := Compare * -1;
  end;
end;

procedure TFormMain.ListViewRepoSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if Selected and (Item <> nil) then
  begin
    ShowInfo(Item);
    ButtonGitignoreReload.Enabled := True;
    ButtonGitignoreSave.Enabled := True;
  end
  else
  begin
    ShowInfo(nil);
    ButtonGitignoreReload.Enabled := False;
    ButtonGitignoreSave.Enabled := False;
  end;
end;

procedure TFormMain.PopupMenuEditPopup(Sender: TObject);
begin
  MenuItemPopupCopyLocalPath.Enabled := False;
  MenuItemPopupOpenLocalPath.Enabled := False;
  MenuItemPopupCopyRemotePath.Enabled := False;

  if ListViewRepo.Selected = nil then
    Exit;

  if ListViewRepo.Selected.SubItems[0] <> '' then
    MenuItemPopupCopyLocalPath.Enabled := True;

  MenuItemPopupOpenLocalPath.Enabled := ListViewRepo.Selected.SubItems[1] <> '';
  MenuItemPopupCopyRemotePath.Enabled := (ListViewRepo.Selected.SubItems[1] <> '') and (LowerCase(Copy(ListViewRepo.Selected.SubItems[1], 1, 4)) = 'http');
end;

procedure TFormMain.SearchGitRepoRecursive(const APath: string);
var
  FileList: TStringList;
  I: Integer;
begin
  FileList := FindAllDirectories(APath, False);

  try
    if FileList.Count = 0 then
      Exit;

    if ExistsDotGit(FileList) then
    begin
      AddGitRepoToListView(APath);
    end
    else
    begin
      for I := 0 to FileList.Count - 1 do
      begin
        SearchGitRepoRecursive(FileList.Strings[I]);
      end;
    end;
  finally
    FileList.Free;;
  end;
end;

procedure TFormMain.AddGitRepoToListView(const APath: string);
var
  ListItem: TListItem;
  I: Integer;
begin
  ListItem := ListViewRepo.Items.Add;

  ListItem.Caption := ExtractFileName(APath);
  ListItem.SubItems.Add(APath);

  // Line Data
  // 1 ~ 10
  for I := 0 to 9 do
    ListItem.SubItems.Add('');

  // Hidden Data
  // 11 ~ 20
  for I := 0 to 9 do
    ListItem.SubItems.Add('');
end;

procedure TFormMain.RefreshRepoInfos;
var
  I: Integer;
begin
  Enabled := False;
  try
    ProgressBar.Position := 0;
    ProgressBar.Max := ListViewRepo.Items.Count;

    for I := 0 to ListViewRepo.Items.Count - 1 do
    begin
      RefreshRepoInfo(ListViewRepo.Items[I]);
      ProgressBar.Position := I + 1;
      Application.ProcessMessages;
    end;
  finally
    Enabled := True;
  end;
end;

procedure TFormMain.RefreshSelectedRepoInfos;
var
  I: Integer;
begin
  Enabled := False;
  try
    if ListViewRepo.SelCount > 0 then
    begin
      ProgressBar.Position := 0;
      ProgressBar.Max := ListViewRepo.SelCount;

      for I := 0 to ListViewRepo.Items.Count - 1 do
      begin
        if ListViewRepo.Items[I].Selected then
        begin
          RefreshRepoInfo(ListViewRepo.Items[I]);
          ProgressBar.Position := ProgressBar.Position + 1;
          Application.ProcessMessages;
        end;
      end;
    end;

  finally
    Enabled := True;
  end;
end;

procedure TFormMain.RefreshRepoInfo(AListItem: TListItem);
var
  Path: string;
  Output: string;
  Line: string;
  Line2: string;
begin
  Path := AListItem.SubItems[0];

  Output := RunGitRemote(Path);
  Line := ParseLnGitRemote(Output);
  AListItem.SubItems[1] := Line;
  AListItem.SubItems[11] := Output;

  Output := RunGitBranch(Path);
  Line := ParseLnGitBranch(Output);
  AListItem.SubItems[2] := Line;
  AListItem.SubItems[12] := Output;

  Output := RunGitStatus(Path);
  ParseLnGitStatus(Output, Line, Line2);
  AListItem.SubItems[3] := Line;
  AListItem.SubItems[4] := Line2;
  AListItem.SubItems[13] := Output;
end;

procedure TFormMain.ShowInfo(Item: TListItem);
begin
  ShowBasicInfo(Item);
  ShowRemoteInfo(Item);
  ShowBranchInfo(Item);
  ShowStatusInfo(Item);
  ShowGitignoreInfo(Item);
end;

procedure TFormMain.ShowBasicInfo(Item: TListItem);
begin
  MemoBasicInfo.Lines.Clear;
  if Item = nil then
    Exit;

  MemoBasicInfo.Lines.Add('== Path ==');
  MemoBasicInfo.Lines.Add(Item.SubItems[0]);
  MemoBasicInfo.Lines.Add('');
  MemoBasicInfo.Lines.Add('== Repo ==');
  MemoBasicInfo.Lines.Add(Item.SubItems[1]);
end;

procedure TFormMain.ShowRemoteInfo(Item: TListItem);
var
  Output: string;
begin
  MemoRemote.Lines.Clear;
  if Item = nil then
    Exit;

  Output := Item.SubItems[11];
  Output := StringReplace(Output, #10, LineEnding, [rfReplaceAll]);
  if Output <> '' then
  begin
    MemoRemote.Lines.Add('> git remote -v');
    MemoRemote.Lines.Add('---------------');
    MemoRemote.Lines.Add('');
    MemoRemote.Lines.Add(Output);
  end;
end;

procedure TFormMain.ShowBranchInfo(Item: TListItem);
var
  Output: string;
begin
  MemoBranch.Lines.Clear;
  if Item = nil then
    Exit;

  Output := Item.SubItems[12];
  Output := StringReplace(Output, #10, LineEnding, [rfReplaceAll]);
  if Output <> '' then
  begin
    MemoBranch.Lines.Add('> git branch -a');
    MemoBranch.Lines.Add('---------------');
    MemoBranch.Lines.Add('');
    MemoBranch.Lines.Add(Output);
  end;
end;

procedure TFormMain.ShowStatusInfo(Item: TListItem);
var
  Output: string;
begin
  MemoStatus.Lines.Clear;
  if Item = nil then
    Exit;

  Output := Item.SubItems[13];
  Output := StringReplace(Output, #10, LineEnding, [rfReplaceAll]);
  if Output <> '' then
  begin
    MemoStatus.Lines.Add('> git status -s');
    MemoStatus.Lines.Add('---------------');
    MemoStatus.Lines.Add('');
    MemoStatus.Lines.Add(Output);
  end;
end;

procedure TFormMain.ShowGitignoreInfo(Item: TListItem);
var
  FileName: string;
begin
  MemoGitignore.Lines.Clear;
  if Item = nil then
    Exit;

  FileName := Item.SubItems[0] + PathDelim + '.gitignore';
  if FileExists(FileName) then
  begin
    MemoGitignore.Lines.LoadFromFile(FileName);
  end;
end;

procedure TFormMain.DoCreate;
begin
  Caption := Application.Title + ' v' + GetVersion;
  DoubleBuffered := True;

  ActionViewBasic.Execute;
end;

procedure TFormMain.DoDestroy;
begin
end;

end.


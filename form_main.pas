unit form_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls;

type
  { TFormMain }
  TFormMain = class(TForm)
    ButtonReadProjects: TButton;
    ButtonRefresh: TButton;
    ListViewRepo: TListView;
    MemoBasicInfo: TMemo;
    MemoStatus: TMemo;
    MemoRemote: TMemo;
    MemoBranch: TMemo;
    PageControlInfo: TPageControl;
    PanelStatus: TPanel;
    PanelStatusProgress: TPanel;
    PanelTop: TPanel;
    ProgressBar: TProgressBar;
    SplitterMain: TSplitter;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    procedure ButtonReadProjectsClick(Sender: TObject);
    procedure ButtonRefreshClick(Sender: TObject);
    procedure ListViewRepoColumnClick(Sender: TObject; Column: TListColumn);
    procedure ListViewRepoCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure ListViewRepoSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
  private
    FColumnToSort: Integer;
    FAsc: Boolean;

    procedure SearchDirectory(const APath: string);
    procedure RefreshRepoInfos;
    procedure RefreshSelectedRepoInfos;
    procedure RefreshRepoInfo(AListItem: TListItem);

    procedure ShowInfo(Item: TListItem);
    procedure ShowBasicInfo(Item: TListItem);
    procedure ShowRemoteInfo(Item: TListItem);
    procedure ShowBranchInfo(Item: TListItem);
    procedure ShowStatusInfo(Item: TListItem);
  protected
    procedure DoCreate; override;
    procedure DoDestroy; override;
  public

  end;

var
  FormMain: TFormMain;

implementation

uses
  util_git;

{$R *.lfm}

{ TFormMain }

procedure TFormMain.ButtonReadProjectsClick(Sender: TObject);
var
  Directory: string;
begin
  if SelectDirectory('', '', Directory, False) then
  begin
    ListViewRepo.Items.Clear;

    SearchDirectory(Directory);

    RefreshRepoInfos;
  end;
end;

procedure TFormMain.ButtonRefreshClick(Sender: TObject);
begin
  RefreshSelectedRepoInfos;
end;

procedure TFormMain.ListViewRepoColumnClick(Sender: TObject; Column: TListColumn
  );
begin
  FColumnToSort := Column.Index;
  FAsc := not FAsc;
  (Sender as TListView).AlphaSort;
end;

procedure TFormMain.ListViewRepoCompare(Sender: TObject; Item1,
  Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  case FColumnToSort of
    0:  Compare := CompareText(Item1.Caption, Item2.Caption);
    else Compare := CompareText(Item1.SubItems[FColumnToSort - 1], Item2.SubItems[FColumnToSort - 1]);
  end;

  if FAsc then
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
  end;
end;

procedure TFormMain.SearchDirectory(const APath: string);
var
  FileList: TStringList;
  I: Integer;
  ListItem: TListItem;
begin
  FileList := FindAllDirectories(APath, False);

  try
    if FileList.Count = 0 then
      Exit;

    if ExistsDotGit(FileList) then
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
    end
    else
    begin
      for I := 0 to FileList.Count - 1 do
      begin
        SearchDirectory(FileList.Strings[I]);
      end;
    end;
  finally
    FileList.Free;;
  end;
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
end;

procedure TFormMain.ShowBasicInfo(Item: TListItem);
begin
  MemoBasicInfo.Lines.Clear;
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

procedure TFormMain.DoCreate;
begin
  Caption := Application.Title;
  DoubleBuffered := True;
  PageControlInfo.ActivePageIndex := 0;

  FAsc := False;
end;

procedure TFormMain.DoDestroy;
begin
end;

end.


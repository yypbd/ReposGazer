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
    MemoRemote: TMemo;
    MemoBranch: TMemo;
    PageControlInfo: TPageControl;
    PanelTop: TPanel;
    SplitterMain: TSplitter;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    procedure ButtonReadProjectsClick(Sender: TObject);
    procedure ButtonRefreshClick(Sender: TObject);
    procedure ListViewRepoSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
  private
    procedure SearchDirectory(const APath: string);
    procedure RefreshRepoInfos;
    procedure RefreshRepoInfo(AListItem: TListItem);
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
  RefreshRepoInfos;
end;

procedure TFormMain.ListViewRepoSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  Output: string;
begin
  if Selected and (Item <> nil) then
  begin
    MemoBasicInfo.Lines.Clear;
    MemoBasicInfo.Lines.Add('== Path ==');
    MemoBasicInfo.Lines.Add(Item.SubItems[0]);
    MemoBasicInfo.Lines.Add('');
    MemoBasicInfo.Lines.Add('== Repo ==');
    MemoBasicInfo.Lines.Add(Item.SubItems[1]);

    MemoRemote.Lines.Clear;
    Output := item.SubItems[11];
    Output := StringReplace(Output, #10, LineEnding, [rfReplaceAll]);
    if Output <> '' then
    begin
      MemoRemote.Lines.Add('> git remote -v');
      MemoRemote.Lines.Add('---------------');
      MemoRemote.Lines.Add('');
      MemoRemote.Lines.Add(Output);
    end;

    MemoBranch.Lines.Clear;
    Output := item.SubItems[12];
    Output := StringReplace(Output, #10, LineEnding, [rfReplaceAll]);
    if Output <> '' then
    begin
      MemoBranch.Lines.Add('> git branch -a');
      MemoBranch.Lines.Add('---------------');
      MemoBranch.Lines.Add('');
      MemoBranch.Lines.Add(Output);
    end;
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
  for I := 0 to ListViewRepo.Items.Count - 1 do
  begin
    RefreshRepoInfo( ListViewRepo.Items[I] );
  end;
end;

procedure TFormMain.RefreshRepoInfo(AListItem: TListItem);
var
  Path: string;
  Output: string;
  Line: string;
begin
  Path := AListItem.SubItems[0];

  Output := RunGitRemote(Path);
  Line := ParseLnGitRemote(Output);
  AListItem.SubItems[1] := Line;
  AListItem.SubItems[11] := Output;

  Output := RunGitBranch(Path);
  Line := ParseLnGitBranch(Output);
  AListItem.SubItems[2] := Line;;
  AListItem.SubItems[12] := Output;

end;

procedure TFormMain.DoCreate;
begin
  Caption := Application.Title;

  PageControlInfo.ActivePageIndex := 0;
end;

procedure TFormMain.DoDestroy;
begin
end;

end.


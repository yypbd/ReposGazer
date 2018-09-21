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
    ListViewRepo: TListView;
    MemoMessage: TMemo;
    PanelTop: TPanel;
    procedure ButtonReadProjectsClick(Sender: TObject);
    procedure ListViewRepoSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
  private
    procedure SearchDirectory(const APath: string);
    function ParseRemote(const AOutput: string): string;
    procedure FindGitRemote;
  protected
    procedure DoCreate; override;
    procedure DoDestroy; override;
  public

  end;

var
  FormMain: TFormMain;

implementation

uses
  process_addon, util_git;

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

    FindGitRemote;
  end;
end;

procedure TFormMain.ListViewRepoSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  Path: string;
  Output: string;
  Status: Integer;
begin
  if Selected and (Item <> nil) then
  begin
    MemoMessage.Lines.Clear;
    Path := Item.SubItems[0];

    if not DirectoryExists(Path) then Exit;

    RunCommandIndirCustom(Path, 'git', ['remote', '-v'], Output, Status);

    Output := StringReplace(Output, #10, LineEnding, [rfReplaceAll]);
    if Output <> '' then
    begin
      MemoMessage.Lines.Add('git remote -v');
      MemoMessage.Lines.Add('');
      MemoMessage.Lines.Add(Output);
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

function TFormMain.ParseRemote(const AOutput: string): string;
var
  Pos1, Pos2: Integer;
begin
  Result := '';

  if AOutput = '' then Exit;

  Pos1 := Pos(#9, AOutput);
  Pos2 := Pos(#10, AOutput);
  if (Pos1 > 0) and (Pos2 > 0) then
  begin
    Result := Copy(AOutput, Pos1 + 1, Pos2 - Pos1 - 1);
  end;
end;

procedure TFormMain.FindGitRemote;
var
  I: Integer;
  Path: string;
  Status: Integer;
  Output: string;
begin
  for I := 0 to ListViewRepo.Items.Count - 1 do
  begin
    Path := ListViewRepo.Items[I].SubItems[0];

    if not DirectoryExists(Path) then Exit;

    RunCommandIndirCustom(Path, 'git', ['remote', '-v'], Output, Status);
    // RunCommandIndir(Path, 'git', ['remote', '-v'], Output, Status);

    // Output := StringReplace(Output, #10, LineEnding, [rfReplaceAll]);
    Output := ParseRemote(Output);

    ListViewRepo.Items[I].SubItems.Add(Output);
  end;
end;

procedure TFormMain.DoCreate;
begin
  Caption := Application.Title;
end;

procedure TFormMain.DoDestroy;
begin
end;

end.


unit UnitFormMain;

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
    FFileList: TStringList;

    procedure OnDirectoryFound(FileIterator: TFileIterator);

    procedure SearchDirectory(const APath: string);
    function ExistsDotGitDirecotry: Boolean;
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
  ProcessCustom;

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

procedure TFormMain.OnDirectoryFound(FileIterator: TFileIterator);
begin
  if FileIterator.IsDirectory then
  begin
    FFileList.Add(FileIterator.FileName);
  end;
end;

procedure TFormMain.SearchDirectory(const APath: string);
var
  FileSearcher: TFileSearcher;
  I: Integer;
  FileList: TStringList;
  ListItem: TListItem;
begin
  FileSearcher := TFileSearcher.Create;
  try
    FileSearcher.OnDirectoryFound := @OnDirectoryFound;
    FileSearcher.DirectoryAttribute := faAnyFile;
    FileSearcher.Search(APath, '', False, False);
  finally
    FileSearcher.Free;
  end;

  if ExistsDotGitDirecotry then
  begin
    FFileList.Clear;

    ListItem := ListViewRepo.Items.Add;

    ListItem.Caption := ExtractFileName(APath);
    ListItem.SubItems.Add(APath);
  end
  else
  begin
    FileList := TStringList.Create;
    try
      FileList.Assign(FFileList);
      FFileList.Clear;
      for I := 0 to FileList.Count - 1 do
      begin
        SearchDirectory(FileList.Strings[I]);
      end;
    finally
      FileList.Free;
    end;
  end;
end;

function TFormMain.ExistsDotGitDirecotry: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FFileList.Count - 1 do
  begin
    if LowerCase(Copy(FFileList.Strings[I], Length(FFileList.Strings[I]) - 4, 5)) = PathDelim + '.git' then
    begin
      Result := True;
      Exit;
    end;
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

  FFileList := TStringList.Create;
end;

procedure TFormMain.DoDestroy;
begin
  FFileList.Free;
end;

end.


unit util_git;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

  function ExistsDotGit(AFileList: TStringList): Boolean;

  function RunGitRemote(const APath: string): string;
  function ParseLnGitRemote(const AOutput: string): string;

  function RunGitBranch(const APath: string): string;
  function ParseLnGitBranch(const AOutput: string): string;

implementation

uses
  process_addon;

function ExistsDotGit(AFileList: TStringList): Boolean;
const
  GIT_DIR = PathDelim + '.git';
var
  I: Integer;
  LastStr: string;
begin
  Result := False;
  for I := 0 to AFileList.Count - 1 do
  begin
    // LastStr := LowerCase(Copy(AFileList.Strings[I], Length(AFileList.Strings[I]) - Length(GIT_DIR) - 1, Length(GIT_DIR)));
    LastStr := LowerCase(RightStr(AFileList.Strings[I], Length(GIT_DIR)));
    if LastStr = GIT_DIR then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function RunGitRemote(const APath: string): string;
var
  Output: string;
  Status: Integer;
begin
  Result := '';

  if not DirectoryExists(APath) then
    Exit;

  // Output := StringReplace(Output, #10, LineEnding, [rfReplaceAll]);
  if RunCommandIndirCustom(APath, 'git', ['remote', '-v'], Output, Status) = 0 then
  begin
    Result := Output;
  end;
end;

function ParseLnGitRemote(const AOutput: string): string;
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

function RunGitBranch(const APath: string): string;
var
  Output: string;
  Status: Integer;
begin
  Result := '';

  if not DirectoryExists(APath) then
    Exit;

  if RunCommandIndirCustom(APath, 'git', ['branch', '-a'], Output, Status) = 0 then
  begin
    Result := Output;
  end;
end;

function ParseLnGitBranch(const AOutput: string): string;
const
  CURRENT_BRANCH = '* ';
var
  StringList: TStringList;
  I: Integer;
  Text: string;
begin
  Result := '';
  StringList := TStringList.Create;

  try
    StringList.StrictDelimiter := True;
    StringList.Delimiter := #10;
    StringList.DelimitedText := AOutput;

    for I := 0 to StringList.Count - 1 do
    begin
      Text := LeftStr(StringList.Strings[I], Length(CURRENT_BRANCH));
      if Text = CURRENT_BRANCH then
      begin
        Result := RightStr( StringList.Strings[I], Length(StringList.Strings[I]) - Length(CURRENT_BRANCH) );
        // Result := StringList.Strings[I];
        Exit;
      end;
    end;
  finally
    StringList.Free;
  end;
end;

end.


unit Util.Git;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

  function ExistsDotGit(AFileList: TStringList): Boolean;

  function RunGitRemote(const APath: string): string;
  function ParseLnGitRemote(const AOutput: string): string;

  function RunGitBranch(const APath: string): string;
  function ParseLnGitBranch(const AOutput: string): string;

  function RunGitStatus(const APath: string): string;
  procedure ParseLnGitStatus(const AOutput: string; var AIndex, AWorkTree: string);

implementation

uses
  Util.ProcessAddon;

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
  Pos2 := Pos(' ', AOutput);
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

function RunGitStatus(const APath: string): string;
var
  Output: string;
  Status: Integer;
begin
  Result := '';

  if not DirectoryExists(APath) then
    Exit;

  if RunCommandIndirCustom(APath, 'git', ['status', '-s'], Output, Status) = 0 then
  begin
    Result := Output;
  end;
end;

procedure ParseLnGitStatus(const AOutput: string; var AIndex, AWorkTree: string);
var
  StringList: TStringList;
  I: Integer;

  IndexChar, WorkTreeChar: Char;
  Index_M, Index_T, Index_A, Index_D, Index_R, Index_C: Integer;
  WorkTree_M, WorkTree_T, WorkTree_D, WorkTree_R, WorkTree_C: Integer;
  Untracked: Integer;
begin
  AIndex := '';
  AWorkTree := '';

  StringList := TStringList.Create;

  try
    StringList.StrictDelimiter := True;
    StringList.Delimiter := #10;
    StringList.DelimitedText := AOutput;

    Index_M := 0;
    Index_T := 0;
    Index_A := 0;
    Index_D := 0;
    Index_R := 0;
    Index_C := 0;

    WorkTree_M := 0;
    WorkTree_T := 0;
    WorkTree_D := 0;
    WorkTree_R := 0;
    WorkTree_C := 0;

    Untracked := 0;

    for I := 0 to StringList.Count - 1 do
    begin
      if Length(StringList.Strings[I]) > 3 then
      begin
        // Read status counts
        IndexChar := StringList.Strings[I][1];
        WorkTreeChar := StringList.Strings[I][2];

        if IndexChar = 'M' then
        begin
          Inc(Index_M);
        end
        else if IndexChar = 'T' then
        begin
          Inc(Index_T);
        end
        else if IndexChar = 'A' then
        begin
          Inc(Index_A);
        end
        else if IndexChar = 'D' then
        begin
          Inc(Index_D);
        end
        else if IndexChar = 'R' then
        begin
          Inc(Index_R);
        end
        else if IndexChar = 'C' then
        begin
          Inc(Index_C);
        end;

        if WorkTreeChar = 'M' then
        begin
          Inc(WorkTree_M);
        end
        else if WorkTreeChar = 'T' then
        begin
          Inc(WorkTree_T);
        end
        else if WorkTreeChar = 'D' then
        begin
          Inc(WorkTree_D);
        end
        else if WorkTreeChar = 'R' then
        begin
          Inc(WorkTree_R);
        end
        else if WorkTreeChar = 'C' then
        begin
          Inc(WorkTree_C);
        end;

        if (IndexChar = '?') and (WorkTreeChar = '?') then
        begin
          Inc(Untracked);
        end;
      end;
    end;

    if Index_M > 0 then
    begin
      AIndex := AIndex + 'M:' + IntToStr(Index_M) + ' ';
    end;
    if Index_T > 0 then
    begin
      AIndex := AIndex + 'T:' + IntToStr(Index_T) + ' ';
    end;
    if Index_A > 0 then
    begin
      AIndex := AIndex + 'A:' + IntToStr(Index_A) + ' ';
    end;
    if Index_R > 0 then
    begin
      AIndex := AIndex + 'R:' + IntToStr(Index_R) + ' ';
    end;
    if Index_D > 0 then
    begin
      AIndex := AIndex + 'D:' + IntToStr(Index_D) + ' ';
    end;
    if Index_C > 0 then
    begin
      AIndex := AIndex + 'C:' + IntToStr(Index_C) + ' ';
    end;

    if WorkTree_M > 0 then
    begin
      AWorkTree := AWorkTree + 'M:' + IntToStr(WorkTree_M) + ' ';
    end;
    if WorkTree_T > 0 then
    begin
      AWorkTree := AWorkTree + 'T:' + IntToStr(WorkTree_T) + ' ';
    end;
    if WorkTree_D > 0 then
    begin
      AWorkTree := AWorkTree + 'D:' + IntToStr(WorkTree_D) + ' ';
    end;
    if WorkTree_R > 0 then
    begin
      AWorkTree := AWorkTree + 'R:' + IntToStr(WorkTree_R) + ' ';
    end;
    if WorkTree_C > 0 then
    begin
      AWorkTree := AWorkTree + 'C:' + IntToStr(WorkTree_C) + ' ';
    end;

    if Untracked > 0 then
    begin
      AWorkTree := AWorkTree + '?:' + IntToStr(Untracked) + ' ';
    end;

    AIndex := Trim(AIndex);
    AWorkTree := Trim(AWorkTree);
  finally
    StringList.Free;
  end;
end;

end.


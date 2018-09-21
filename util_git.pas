unit util_git;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

  function ExistsDotGit(AFileList: TStringList): Boolean;

implementation


function ExistsDotGit(AFileList: TStringList): Boolean;
var
  I: Integer;
  LastStr: string;
begin
  Result := False;
  for I := 0 to AFileList.Count - 1 do
  begin
    LastStr := LowerCase(Copy(AFileList.Strings[I], Length(AFileList.Strings[I]) - 4, 5));
    if LastStr = PathDelim + '.git' then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

end.


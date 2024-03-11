unit Util.Common;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

  function GetVersion: string;

implementation

uses
  FileInfo;

function GetVersion: string;
var
  Info: TFileVersionInfo;
begin
  Info := TFileVersionInfo.Create(nil);

  try
    Info.ReadFileInfo;
    Result := Info.VersionStrings.Values['FileVersion'];
  finally
    Info.Free;
  end;
end;

end.


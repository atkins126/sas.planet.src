{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2011, SAS.Planet development team.                      *}
{* This program is free software: you can redistribute it and/or modify       *}
{* it under the terms of the GNU General Public License as published by       *}
{* the Free Software Foundation, either version 3 of the License, or          *}
{* (at your option) any later version.                                        *}
{*                                                                            *}
{* This program is distributed in the hope that it will be useful,            *}
{* but WITHOUT ANY WARRANTY; without even the implied warranty of             *}
{* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *}
{* GNU General Public License for more details.                               *}
{*                                                                            *}
{* You should have received a copy of the GNU General Public License          *}
{* along with this program.  If not, see <http://www.gnu.org/licenses/>.      *}
{*                                                                            *}
{* http://sasgis.ru                                                           *}
{* az@sasgis.ru                                                               *}
{******************************************************************************}

unit u_GeoCoderByNavitel;

interface

uses
  Classes,
  forms,
  u_GeoTostr,
  XMLIntf,
  msxmldom,
  XMLDoc,
  i_CoordConverter,
  u_GeoCoderBasic;

type
  TGeoCoderByNavitel = class(TGeoCoderBasic)
  protected
    function PrepareURL(ASearch: WideString): string; override;
    function ParseStringToPlacemarksList(AStr: string; ASearch: WideString): IInterfaceList; override;
  public
  end;

implementation

uses
  SysUtils,
  StrUtils,
  t_GeoTypes,
  i_GeoCoder,
  u_ResStrings,
  dialogs,
  u_GeoCodePlacemark,
//
  ALHTTPCommon,
  ALHttpClient,
  ALWinInetHttpClient,
  i_InetConfig,
  i_ProxySettings,
  u_GlobalState,
  RegExpr;

{ TGeoCoderByNavitel }

function DoHttpRequest(const ARequestUrl, ARequestHeader, APostData: string; out AResponseHeader, AResponseData: string): Cardinal;
var
  VHttpClient: TALWinInetHTTPClient;
  VHttpResponseHeader: TALHTTPResponseHeader;
  VHttpResponseBody: TMemoryStream;
  VHttpPostData: TMemoryStream;
  VInetConfig: IInetConfigStatic;
  VProxyConfig: IProxyConfigStatic;
  VTmp:TStringList;
begin
  try
    VHttpClient := TALWinInetHTTPClient.Create(nil);
    try
      VHttpResponseHeader := TALHTTPResponseHeader.Create;
      try
        // config
        VInetConfig := GState.InetConfig.GetStatic;
        VHttpClient.RequestHeader.RawHeaderText := ARequestHeader;
        VHttpClient.RequestHeader.Accept := '*/*';
        VHttpClient.ConnectTimeout := VInetConfig.TimeOut;
        VHttpClient.SendTimeout := VInetConfig.TimeOut;
        VHttpClient.ReceiveTimeout := VInetConfig.TimeOut;
        VHttpClient.InternetOptions := [  wHttpIo_No_cache_write,
                                          wHttpIo_Pragma_nocache,
                                          wHttpIo_No_cookies,
                                          wHttpIo_Ignore_cert_cn_invalid,
                                          wHttpIo_Ignore_cert_date_invalid
                                       ];
        VProxyConfig := VInetConfig.ProxyConfigStatic;
        if Assigned(VProxyConfig) then begin
          if VProxyConfig.UseIESettings then begin
            VHttpClient.AccessType := wHttpAt_Preconfig
          end else if VProxyConfig.UseProxy then begin
            VHttpClient.AccessType := wHttpAt_Proxy;
            VHttpClient.ProxyParams.ProxyServer :=
              Copy(VProxyConfig.Host, 0, Pos(':', VProxyConfig.Host) - 1);
            VHttpClient.ProxyParams.ProxyPort :=
              StrToInt(Copy(VProxyConfig.Host, Pos(':', VProxyConfig.Host) + 1));
            if VProxyConfig.UseLogin then begin
              VHttpClient.ProxyParams.ProxyUserName := VProxyConfig.Login;
              VHttpClient.ProxyParams.ProxyPassword := VProxyConfig.Password;
            end;
          end else begin
            VHttpClient.AccessType := wHttpAt_Direct;
          end;
        end;
        // request
        VHttpResponseBody := TMemoryStream.Create;
        try
          VTmp := TStringList.Create;
          try
            if APostData <> '' then begin
              VHttpPostData := TMemoryStream.Create;
              try
                VHttpPostData.Position := 0;
                VTmp.Text := APostData;
                VTmp.SaveToStream(VHttpPostData);
                VHttpClient.Post(ARequestUrl, VHttpPostData, VHttpResponseBody, VHttpResponseHeader);
              finally
                VHttpPostData.Free;
              end;
            end else begin
              VHttpClient.Get(ARequestUrl, VHttpResponseBody, VHttpResponseHeader);
            end;
            Result := StrToIntDef(VHttpResponseHeader.StatusCode, 0);
            AResponseHeader := VHttpResponseHeader.RawHeaderText;
            if VHttpResponseBody.Size > 0 then begin
              VHttpResponseBody.Position := 0;
              VTmp.Clear;
              VTmp.LoadFromStream(VHttpResponseBody);
              AResponseData := VTmp.Text;
            end;
          finally
            VTmp.Free;
          end;
        finally
          VHttpResponseBody.Free;
        end;
      finally
        VHttpResponseHeader.Free;
      end;
    finally
      VHttpClient.Free;
    end;
  except
    on E: EALHTTPClientException do begin
      Result := E.StatusCode;
      AResponseHeader := '';
      AResponseData := E.Message;
    end;
    on E: EOSError do begin
      Result := E.ErrorCode;
      AResponseHeader := '';
      AResponseData := E.Message;
    end;
  end;
end;

function NavitelType(t : integer) : string;
begin
case t of
  1: Result := '';
  2: Result := '��. ';
  3: Result := '������ ';
  5: Result := '���. ';
  6: Result := '��-� ';
  7: Result := '��-�� ';
  8: Result := '����� ';
  9: Result := '���������� ';
  10: Result := '���������� ';
  11: Result := '���������� ';
  13: Result := '���������� ';
  18: Result := '���������� ';
  20: Result := '������ ';
  24: Result := '����� ';
  27: Result := '���������� ';
  30: Result := '�. ';
  31: Result := '�. ';
  32: Result := '�. ';
  33: Result := '�. ';
  34: Result := '�-� ';
  35: Result := '�.�. ';
  36: Result := '';
  37: Result := '������� ';
  38: Result := '�. ';
  39: Result := '�.�. ';
  40: Result := '���. ';
  41: Result := '�. ';
  42: Result := '�/� ';
  43: Result := '';
  44: Result := '�. ';
  45: Result := '';
  46: Result := '��� ';
  47: Result := '�. ';
  48: Result := '�. ';
  49: Result := '�. ';
  50: Result := '';
  51: Result := '�/� ';
  52: Result := '�.�. ';
  53: Result := '�.�. ';
  54: Result := '�. ';
  55: Result := '�. ';
  56: Result := '�. ';
  57: Result := '�.�. ';
  60: Result := '�. ';
  81: Result := '��. ';
  80: Result := '��. ';
  82: Result := '��. ';
  86: Result := '��. ';
  88: Result := '��. ';
  29: Result := '��. ';
  15: Result := '��-�� ';
  84: Result := '��-�� ';
  85: Result := '��-�� ';
  12: Result := '��-� ';
  87: Result := '��-� ';
  83: Result := '���������� ';
  58: Result := '����. ';
  59: Result := '���. ';
  61: Result := '���. ';
  62: Result := '�.�. ';
  63: Result := '�. ';
  64: Result := '';
  65: Result := '�. ';
  66: Result := '���� ';
  67: Result := '����. ';
  68: Result := '�. ';
  69: Result := '�.�. ';
  70: Result := '';
  71: Result := '�. ';
  72: Result := '�. ';
  73: Result := '';
  74: Result := '';
  75: Result := '�.�. ';
  76: Result := '�. ';
  77: Result := '�.�. ';
  78: Result := '�.���. ';
  79: Result := '�/� ';
  89: Result := '���������� ������� ';
  90: Result := '��������� �������� ';
  91: Result := '��������� ������� ';
  92: Result := '��������� ����������� ';
  93: Result := '������� ����� ';
  94: Result := '��������������� ������� ��� ��������� ';
  95: Result := '��������������� ������ ';
  96: Result := '������� ������������� ������ ';
  97: Result := '��������� ��������� ';
  98: Result := '���� ';
  99: Result := '�������� ';
  100: Result := '������ ������ ';
  101: Result := '������������ ���� ';
  102: Result := '������������ ���� ';
  103: Result := '�������������� ���� ';
  104: Result := '������ ';
  105: Result := '�������� ';
  106: Result := '������ ';
  107: Result := '�������� ';
  108: Result := '���� ��� ';
  109: Result := '�/� ������� �� ���������� ';
  110: Result := '����� ';
  111: Result := '���� ';
  112: Result := '���������� ';
  113: Result := '����-������ ';
  114: Result := '�/� ������� ��� ��������� ';
  115: Result := '���������� ���������� ';
  116: Result := '������� ����� ';
  117: Result := '���������������� ������� ';
  118: Result := '������ ������� ��������� ';
  119: Result := '����������� ������� ��������� ';
  120: Result := '�������� ';
  121: Result := '�������������� ';
  122: Result := '����: Result := ����� ';
  123: Result := '���������: Result := ��������� ';
  124: Result := '���������� ';
  125: Result := '������ ';
  126: Result := '������ ������� ������� ';
  127: Result := '������ ����������� ';
  128: Result := '������ ������ ';
  129: Result := '������ ����� ';
  130: Result := '������ ������ ';
  131: Result := '����������� ������� ';
  132: Result := '�������� ';
  187: Result := '����� ';
  133: Result := '��������� �������� ';
  135: Result := '���������� ������ ';
  137: Result := '���������� ';
  139: Result := '���������: Result := �/� ����� ';
  141: Result := '��������-���� ';
  143: Result := '������� ������� ';
  145: Result := '������� ������� ����� ';
  134: Result := '��������� ������������ ';
  136: Result := '�������� ';
  138: Result := '������������ ';
  140: Result := '���������� ����� ������� Wi-Fi ';
  142: Result := '����� ';
  144: Result := '������������ ������� ';
  146: Result := '������� ������� ������� ';
  147: Result := '������� ��������� ������� ';
  148: Result := '���������� � ������������� ������ ';
  149: Result := '��������� ������� ';
  150: Result := '������� �������� ';
  151: Result := '��������� ������� ';
  152: Result := '��������� ������� ';
  153: Result := '���������� ';
  154: Result := '������������ ';
  155: Result := '������������ ������� ';
  156: Result := '���� ';
  157: Result := '�������� � ��������������� ';
  158: Result := '����������� ������� ';
  159: Result := '�������� (������������ �����) ';
  160: Result := '�������� (��������� �����) ';
  161: Result := '�������� (������) ';
  162: Result := '�������� (��������� �����) ';
  163: Result := '�������� (����������: Result := �����: Result := ��������) ';
  164: Result := '�������� (����������������� �����) ';
  165: Result := '�������� �������� ������� ';
  166: Result := '�������� (����������� �����) ';
  167: Result := '�������� (������������ �����) ';
  168: Result := '�������� ';
  169: Result := '�������� (������������) ';
  170: Result := '�������� (�����) ';
  171: Result := '������� (������������ �������) ';
  172: Result := '���� ';
  173: Result := '�������� (����������� �����) ';
  174: Result := '�������� (�������� �����) ';
  175: Result := '�������� (���������� ��������� �����) ';
  176: Result := '����������� ������� �������� ';
  177: Result := '��������� ';
  178: Result := '����� ��� ������ ';
  179: Result := '����� � ��������� ';
  180: Result := '������� ';
  181: Result := '��������� �����: Result := ��� ������ ';
  182: Result := '������ ��������: Result := ������ ';
  183: Result := '���� ';
  184: Result := '����� ';
  185: Result := '���������� ';
  186: Result := '��������������������� ';
  188: Result := '����/��� ';
  190: Result := '������� ';
  192: Result := '���������� ��� ';
  194: Result := '��������������� ��������� ';
  196: Result := '���/������ ���� ';
  198: Result := '������ ';
  200: Result := '������ �����/������ ';
  202: Result := '����� ';
  189: Result := '�������/�������� ';
  191: Result := '��� ';
  193: Result := '����/������/�������� ';
  195: Result := '����� ';
  197: Result := '��������� ';
  199: Result := '�����-���� ';
  201: Result := '�������-����� ';
  203: Result := '������� ';
  204: Result := '��������/������-����� ';
  205: Result := '���������� �������� ';
  206: Result := '�������� ������ ';
  207: Result := '��������� ';
  208: Result := '����������������� ������� ';
  209: Result := '�������� ����� ';
  210: Result := '�������� ����� ';
  211: Result := '������ ';
  212: Result := '������ ������������� ������ ';
  213: Result := '������ ';
  214: Result := '������ ��� ���� � ���� ';
  215: Result := '������ ';
  216: Result := '������������������ ������� ';
  217: Result := '����������/�� ';
  218: Result := '������ ';
  219: Result := '��� ';
  220: Result := '������ ����������� ';
  221: Result := '���������� ';
  222: Result := '���������� ';
  223: Result := '�������� ��������� ';
  224: Result := '���� ';
  225: Result := '����������� ';
  226: Result := '�������/��������� ��������� ���������� ';
  227: Result := '������ �����: Result := �������: Result := ��� ';
  228: Result := '��������� ������: Result := ��������� ';
  229: Result := '����������� ';
  230: Result := '���� ������: Result := ���������� ��� �������� ';
  231: Result := '�������� ';
  232: Result := '��������� ';
  233: Result := '����� ����� Garmin ';
  234: Result := '������ ���� (���������: Result := ���������) ';
  235: Result := '������-������ ';
  236: Result := '����� ����� ';
  237: Result := '���� ������� ';
  238: Result := '����� ';
  239: Result := '������������ ������ ';
  240: Result := '������� ���������� ';
  241: Result := '��������� ������������� ���������� ';
  242: Result := '��������������� ��� ���������� ������ ';
  243: Result := '��������� ������� ';
  244: Result := '�������� ';
  245: Result := '����� ';
  246: Result := '��� ';
  247: Result := '��������� ��� ���������� ������������ ����������� ';
  248: Result := '����������� ����� ';
  249: Result := '��������������� ���������� ';
  251: Result := '�����-���� ';
  253: Result := '�������: Result := ��������� ';
  255: Result := '��� ';
  257: Result := '��� ';
  259: Result := '������� ';
  261: Result := '����� ��� ������� ';
  263: Result := '���������� ';
  265: Result := '������ ';
  267: Result := '�������� ���� ';
  269: Result := '�������� ��� ';
  250: Result := '�������� ����� ';
  252: Result := '����� ��� ������� ';
  254: Result := '�������� ��� ��� ';
  256: Result := '�������� ';
  258: Result := '�������� ������ ';
  260: Result := '���� ';
  262: Result := '�������� ';
  264: Result := '����������� ';
  266: Result := '��� ';
  268: Result := '������� ';
  270: Result := '������ ���� ';
  271: Result := '����� ��� ������� ';
  272: Result := '�����: Result := ������� ';
  273: Result := '��������� ���� ';
  274: Result := '������� ���� ';
  275: Result := '������������ ������ ';
  276: Result := '�������� ';
  277: Result := '������� �������� ';
  278: Result := '������� �������� ';
  279: Result := '����� �������� ';
  280: Result := '����������� �������� ';
  281: Result := '�������� ';
  282: Result := '������������ ����� ';
  283: Result := '������� ';
  284: Result := '����� ��� �������� ';
  285: Result := '������� ���� (������ �������) ';
  286: Result := '������� ���� (������� �����������) ';
  287: Result := '���������������� ';
  288: Result := '��� ';
  289: Result := '������� ������� ';
  290: Result := '������� ������ ';
  291: Result := '������������� ���������� ';
  292: Result := '���� ';
  293: Result := '������ ';
  294: Result := '�������� ';
  295: Result := '����/������/�������� ';
  296: Result := '������������ ������ ';
  297: Result := '�����������: Result := ���������: Result := ������� ';
  298: Result := '������� ';
  299: Result := '�������� ';
  300: Result := '�������: Result := ���������� ';
  301: Result := '��������� ';
  302: Result := '������� ������ ';
  303: Result := '�����: Result := ������ ';
  304: Result := '������������� ����� ';
  305: Result := '���� ';
  306: Result := '����� ';
  307: Result := '����� ';
  308: Result := '�����: Result := ����� ';
  309: Result := '������ ����� ';
  310: Result := '������/��������� ������� ';
  311: Result := '�������� ����: Result := ������: Result := ������� ';
  312: Result := '����������� ����� ';
  313: Result := '���������� ';
  314: Result := '������ ����������� ';
  315: Result := '������: Result := �������� ����� ';
  316: Result := '�������� ������ ';
  317: Result := '����� ';
  318: Result := '�������� ���� ';
  319: Result := '������������� ����� ';
  320: Result := '������ ';
  321: Result := '����� ';
  322: Result := '������� ';
  323: Result := '������ ';
  324: Result := '������ ';
  325: Result := '������ ';
  326: Result := '������ ';
  327: Result := '����� ';
  328: Result := '������ ';
  329: Result := '������������� ';
  330: Result := '���� ';
  331: Result := '������ ';
  332: Result := '����� ';
  333: Result := '������ ';
  334: Result := '��������� �������� ������ ';
  335: Result := '���� ';
  336: Result := '�����: Result := ������� ';
  337: Result := '��������� ';
  338: Result := '����� ';
  339: Result := '������: Result := ����� ';
  340: Result := '��� ';
  341: Result := '���� ';
  342: Result := '������ ';
  343: Result := '����� ';
  344: Result := '��� ';
  345: Result := '������: Result := �������� ';
  346: Result := '����� ������ ';
  347: Result := '�������� ';
  348: Result := '���� ';
  349: Result := '�����: Result := ������� ';
  350: Result := '������� ';
  351: Result := '����� ';
  352: Result := '���������� ';
  353: Result := '������ ';
  354: Result := '����� ';
  355: Result := '����� ';
  356: Result := '������� ����� ��� ���� ';
  357: Result := '������ ';
  358: Result := '��� ';
  359: Result := '���� ';
  360: Result := '�������� ����� ';
  361: Result := '��������� ';
  362: Result := '�������� ';
  363: Result := '������� ���� (������� �����������) ';
  364: Result := '������� ���� (������ �������) ';
  365: Result := '������� ���� (����� ����) ';
  366: Result := '������������ ���� ����� ';
  367: Result := '������������ ���� ������� ';
  368: Result := '������������ ���� ������ ';
  369: Result := '������������ ���� ������ ';
  370: Result := '������������ ���� ������ ';
  371: Result := '������������ ���� �������� ';
  372: Result := '������������ ���� ������������ ';
  373: Result := '���������� ���� ';
  374: Result := '���������� ���� ����� ';
  375: Result := '���������� ���� ������� ';
  376: Result := '���������� ���� ������ ';
  377: Result := '���������� ���� ������ ';
  378: Result := '���������� ���� ��������� ';
  380: Result := '���������� ���� ����� ';
  379: Result := '���������� ���� ���������� ';
  381: Result := '���������� ���� ������������ ';
  382: Result := '������� ���� ';
  383: Result := '����������� ';
  384: Result := '������ ';
  385: Result := '�������� ';
  386: Result := '����� ��� �������� ';
  387: Result := '�������� ';
  388: Result := '���������� ������������ ��� �������� ';
  389: Result := '�������� ';
  390: Result := '������������ ���� ';
  391: Result := '����������: Result := ���������� ';
  392: Result := '�������-���������� ������ ';
  393: Result := '������: Result := ������������� ���������� ';
  394: Result := '������������ ���� ';
  395: Result := '������������ ���� ';
  396: Result := '������������ ���� ';
  397: Result := '��������� ���� ';
  398: Result := '���� ��� ������ ';
  399: Result := '���������� �������� ';
  400: Result := '�������� ';
  401: Result := '��������������� ���� ';
  402: Result := '��������������� ���� ';
  403: Result := '��������������� ���� ';
  404: Result := '���������� ����� ';
  405: Result := '����� ';
  406: Result := '������ ';
  407: Result := '���������� ';
  408: Result := '��������� ������� ';
  409: Result := '�������� ��������� ';
  410: Result := '�������� ������������� ';
  411: Result := '�������� ������������� ����������� ';
  412: Result := '����� ';
  413: Result := '���������� ';
  414: Result := '����� ';
  415: Result := '������� ';
  416: Result := '������� ';
  417: Result := '��������������� ����� ';
  418: Result := '��������������� ������� ';
  419: Result := '��������������� ��������� ';
  420: Result := '��������������� ���� ';
  421: Result := '������� ';
  422: Result := '������ ';
  423: Result := '���������� ';
  424: Result := '�������� ��������� ';
  425: Result := '������ ';
  426: Result := '���������� '
  else  Result := '';
 end;
end;

function RegExprReplaceMatchSubStr(const AStr, AMatchExpr, AReplace: string): string;
var
  VRegExpr: TRegExpr;
begin
    VRegExpr  := TRegExpr.Create;
  try
    VRegExpr.Expression := AMatchExpr;
    if VRegExpr.Exec(AStr) then
      Result := VRegExpr.Replace(AStr, AReplace, True)
    else
      Result := AStr;
  finally
    FreeAndNil(VRegExpr);
  end;
end;

function TGeoCoderByNavitel.ParseStringToPlacemarksList(
  AStr: string; ASearch: WideString): IInterfaceList;
var
  slat, slon, sname, sdesc, sfulldesc, Navitel_id, Navitel_type, place_id: string;
  i, j , ii , jj : integer;
  VPoint: TDoublePoint;
  VPlace: IGeoCodePlacemark;
  VList: IInterfaceList;
  VFormatSettings: TFormatSettings;

  vCurPos: integer;
  vCurChar: string;
  vBrLevel: integer;
  VBuffer: string;
  vErrCode: cardinal;
begin
  sfulldesc:='';
  sdesc:='';
  vBrLevel := 1;
  if AStr = '' then begin
    raise EParserError.Create(SAS_ERR_EmptyServerResponse);
  end;

  AStr := ReplaceStr(AStr,#$0A,'');
  VFormatSettings.DecimalSeparator := '.';
  VList := TInterfaceList.Create;

  vCurPos:=1;
  while (vCurPos<length(AStr)) do begin
   inc (vCurPos);
   vCurChar:=copy(AStr,vCurPos,1);
   VBuffer:=VBuffer+vCurChar;

   if vCurChar='[' then inc(vBrLevel);
   if vCurChar=']' then begin
    dec(vBrLevel);
    if vBrLevel=1 then  begin
    //[848692, ["Москва"], 72, 857666, null],
    //[817088, ["Новая Москва"], 32, null, ["Шкотовский р-н", "Приморский край", "Россия"]],
     sdesc:='';
     sname:='';
     sfulldesc:='';
     i := PosEx('[', vBuffer, 1);
     j := PosEx(',', vBuffer, 1);
     navitel_id := Copy(vBuffer, i + 1, j - (i + 1));

     j:=1;
     i := PosEx('[', vBuffer, 1);
     if i>0  then begin
       j := PosEx(',', vBuffer, i + 1);
       sfulldesc := 'http://maps.navitel.su/webmaps/searchTwoStepInfo?id='+(Copy(vBuffer, i + 1, j - (i + 1)));
       vErrCode := DoHttpRequest(sfulldesc, '' ,'',sname,sdesc);
       if vErrCode <> 200 then exit;
        ii := 1;
       jj := PosEx(',', sdesc, ii + 1 );
       slon := Copy(sdesc, ii + 1, jj - (ii + 1));
       ii := jj;
       jj := PosEx(',', sdesc, ii + 1 );
       slat := Copy(sdesc, ii + 1, jj - (ii + 1));
       sfulldesc :='';
     end;
     i:=j+1;
     j := PosEx(']', vBuffer, i);
     sname := Utf8ToAnsi(Copy(vBuffer, i + 3, j - (i + 4)));
     j := PosEx(',', vBuffer, j+1);
     i := j+1;
     j := PosEx(',', vBuffer, j+1);
     Navitel_type := Copy(vBuffer, i + 1, j - (i + 1));
     Sname := NavitelType(StrToInt(Navitel_type )) + sname;
     i := j+1;
     j := PosEx(',', vBuffer, i+1);
     place_id := Copy(vBuffer, i + 1, j - (i + 1));
     if place_id<>'null' then begin
      //http://maps.navitel.su/webmaps/searchById?id=812207
      vErrCode := DoHttpRequest('http://maps.navitel.su/webmaps/searchById?id='+(place_id), '' ,'',Navitel_type,sdesc);
      sdesc := RegExprReplaceMatchSubStr(sdesc,'[0-9]','');
      sdesc := ReplaceStr(sdesc,#$0A,'');
      sdesc := ReplaceStr(sdesc,#$0D,'');
      sdesc := ReplaceStr(sdesc,'[','');
      sdesc := ReplaceStr(sdesc,']','');
      sdesc := ReplaceStr(sdesc,'null','');
      sdesc := ReplaceStr(sdesc,', ','');
      sdesc := ReplaceStr(sdesc,'""','","');
      sdesc := Utf8ToAnsi(sdesc);
      if vErrCode <> 200 then exit;
     end else begin
       i := PosEx('[', vBuffer, j+1);
       if i>j+1 then begin
        j := PosEx(']', vBuffer, i);
        sdesc := Utf8ToAnsi(Copy(vBuffer, i + 1, j - (i + 1)));
       end;
     end;

     try
       VPoint.Y := StrToFloat(slat, VFormatSettings);
       VPoint.X := StrToFloat(slon, VFormatSettings);
     except
       raise EParserError.CreateFmt(SAS_ERR_CoordParseError, [slat, slon]);
     end;
     VPlace := TGeoCodePlacemark.Create(VPoint, sname, sdesc, sfulldesc, 4);
     VList.Add(VPlace);

    vBuffer:='';
    end;
   end;
  end;

  Result := VList;
end;

function TGeoCoderByNavitel.PrepareURL(ASearch: WideString): string;
var
  VSearch: String;
  VConverter: ICoordConverter;
  VZoom: Byte;
  VMapRect: TDoubleRect;
  VLonLatRect: TDoubleRect;
begin

  VSearch := ASearch;
  VConverter:=FLocalConverter.GetGeoConverter;
  VZoom := FLocalConverter.GetZoom;
  VMapRect := FLocalConverter.GetRectInMapPixelFloat;
  VConverter.CheckPixelRectFloat(VMapRect, VZoom);
  VLonLatRect := VConverter.PixelRectFloat2LonLatRect(VMapRect, VZoom);

  //http://maps.navitel.su/webmaps/searchTwoStep?s=%D0%BD%D0%BE%D0%B2%D0%BE%D1%82%D0%B8%D1%82%D0%B0%D1%80%D0%BE%D0%B2%D1%81%D0%BA%D0%B0%D1%8F&lon=38.9739197086479&lat=45.2394838066316&z=11
  //http://maps.navitel.su/webmaps/searchTwoStepInfo?id=842798

  //http://maps.navitel.su/webmaps/searchTwoStep?s=%D0%BC%D0%BE%D1%81%D0%BA%D0%B2%D0%B0&lon=37.6&lat=55.8&z=6
  //http://maps.navitel.su/webmaps/searchTwoStepInfo?id=848692
  Result := 'http://maps.navitel.su/webmaps/searchTwoStep?s='+URLEncode(AnsiToUtf8(VSearch))+
  '&lon='+R2StrPoint(FLocalConverter.GetCenterLonLat.x)+'&lat='+R2StrPoint(FLocalConverter.GetCenterLonLat.y)+
  '&z='+inttostr(VZoom);
end;

end.


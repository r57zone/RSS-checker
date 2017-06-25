unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, XMLDoc, XMLIntf, WinInet, ShellAPI, ExtCtrls, IniFiles,
  Menus;

type
  TMain = class(TForm)
    Timer: TTimer;
    PopupMenu: TPopupMenu;
    AboutBtn: TMenuItem;
    N2: TMenuItem;
    ExitBtn: TMenuItem;
    N1: TMenuItem;
    N3: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TimerTimer(Sender: TObject);
    procedure ExitBtnClick(Sender: TObject);
    procedure AboutBtnClick(Sender: TObject);
    procedure N1Click(Sender: TObject);
  private
    procedure CheckNew;
    procedure CheckNotified;
    procedure DefaultHandler(var Message); override;
    { Private declarations }
  public
    { Public declarations }
  protected
    procedure IconMouse(var Msg:TMessage); message WM_USER+1;
  end;

var
  Main: TMain;
  Doc: IXMLDocument;
  FeedsNode: IXMLNode;
  Notified: TStringList;
  WM_TaskBarCreated: Cardinal;
  NotificationApp: string;

implementation

{$R *.dfm}

function CheckUrl(Url: string): boolean;
var
  hSession, hFile, hRequest: hInternet;
  dwIndex, dwCodeLen: dword;
  dwCode: array [1..20] of char;
  res: PChar;
begin
  Result:=false;
  hSession:=InternetOpen('Mozilla/4.0 (MSIE 6.0; Windows NT 5.1)', INTERNET_OPEN_TYPE_PRECONFIG, nil,nil,0);
  if Assigned(hSession) then begin
    if Copy(UpperCase(Url),1,8)='HTTPS://' then
      hFile:=InternetOpenURL(hSession, PChar(Url), nil, 0, INTERNET_FLAG_SECURE, 0)
    else
      hFile:=InternetOpenURL(hSession, PChar(Url) , nil, 0, INTERNET_FLAG_RELOAD, 0);
    dwIndex:=0;
    dwCodeLen:=10;
    HttpQueryInfo(hFile, HTTP_QUERY_STATUS_CODE, @dwCode, dwCodeLen, dwIndex);
    res:=PChar(@dwCode);
    Result:=(res='200') or (res='302');
    if Assigned(hFile) then InternetCloseHandle(hFile);
    InternetCloseHandle(hSession);
  end;
end;

function GetUrl(Url: string): string;
var
  hSession, hConnect, hRequest: hInternet;
  FHost, FScript, SRequest, Uri: string;
  Ansi: PAnsiChar;
  Buff: array [0..1023] of Char;
  BytesRead: Cardinal;
  Res, Len: DWORD;
  https: boolean;
const
  Header='Content-Type: application/x-www-form-urlencoded' + #13#10;
begin
  https:=false;
  if Copy(UpperCase(Url),1,8)='HTTPS://' then https:=true;
  Result:='';

  if Copy(UpperCase(Url),1,7)='HTTP://' then Delete(Url, 1, 7);
  if Copy(UpperCase(Url),1,8)='HTTPS://' then Delete(Url, 1, 8);

  Uri:=Url;
  Uri:=Copy(Uri,1,Pos('/', Uri)-1);
  FHost:=Uri;
  FScript:=Url;
  Delete(FScript, 1, Pos(FHost, FScript) + Length(FHost));

  hSession:=InternetOpen('Mozilla/4.0 (MSIE 6.0; Windows NT 5.1)', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if not Assigned(hSession) then Exit;
  try
    if https then hConnect:=InternetConnect(hSession, PChar(FHost), INTERNET_DEFAULT_HTTPS_PORT, nil,'HTTP/1.0', INTERNET_SERVICE_HTTP, 0, 0) else
      hConnect:=InternetConnect(hSession, PChar(FHost), INTERNET_DEFAULT_HTTP_PORT, nil,'HTTP/1.0', INTERNET_SERVICE_HTTP, 0, 0);
    if not Assigned(hConnect) then Exit;
    try
      Ansi:='text/*';
      if https then
        hRequest:=HttpOpenRequest(hConnect, 'GET', PChar(FScript), 'HTTP/1.1',nil, @Ansi, INTERNET_FLAG_SECURE, 0)
      else
        hRequest:=HttpOpenRequest(hConnect, 'GET', PChar(FScript), 'HTTP/1.1',nil, @Ansi, INTERNET_FLAG_RELOAD, 0);
      if not Assigned(hConnect) then Exit;
        try
          if not (HttpAddRequestHeaders(hRequest, Header, Length(Header),HTTP_ADDREQ_FLAG_REPLACE or HTTP_ADDREQ_FLAG_ADD or HTTP_ADDREQ_FLAG_COALESCE_WITH_COMMA)) then Exit;
          Len:=0;
          Res:=0;
          SRequest:=' ';
          HttpQueryInfo(hRequest, HTTP_QUERY_RAW_HEADERS_CRLF or HTTP_QUERY_FLAG_REQUEST_HEADERS, @SRequest[1], Len, Res);
          if Len>0 then begin
            SetLength(SRequest, Len);
            HttpQueryInfo(hRequest, HTTP_QUERY_RAW_HEADERS_CRLF or
            HTTP_QUERY_FLAG_REQUEST_HEADERS, @SRequest[1], Len, Res);
          end;
          if not (HttpSendRequest(hRequest, nil, 0, nil, 0)) then Exit;
          FillChar(Buff, SizeOf(Buff), 0);
          repeat
            Application.ProcessMessages;
            Result:=Result+Buff;
            FillChar(Buff, SizeOf(Buff), 0);
            InternetReadFile(hRequest, @Buff, SizeOf(Buff), BytesRead);
          until BytesRead=0;
        finally
          InternetCloseHandle(hRequest);
        end;
    finally
      InternetCloseHandle(hConnect);
    end;
  finally
    InternetCloseHandle(hSession);
  end;
end;

procedure Tray(n:integer); //1 - добавить, 2 - удалить, 3 -  заменить
var
  nim: TNotifyIconData;
begin
  with nim do begin
    cbSize:=SizeOf(nim);
    wnd:=Main.Handle;
    uId:=1;
    uFlags:=nif_icon or nif_message or nif_tip;
    hIcon:=Application.Icon.Handle;
    uCallBackMessage:=WM_User+1;
    StrCopy(szTip, PChar(Application.Title));
  end;
  case n of
    1: Shell_NotifyIcon(nim_add,@nim);
    2: Shell_NotifyIcon(nim_delete,@nim);
    3: Shell_NotifyIcon(nim_modify,@nim);
  end;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
begin
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'Setup.ini');
  Timer.Interval:=Ini.ReadInteger('Main', 'CheckInterval', 20) * 60000; //Минуты
  NotificationApp:=Ini.ReadString('Main', 'NotificationApp', '');
  if not FileExists(NotificationApp) then ShowMessage('Ошибка, программа уведомлений не найдена.');
  Ini.Free;
  Application.Title:=Caption;
  WM_TaskBarCreated:=RegisterWindowMessage('TaskbarCreated');
  Tray(1);
  Notified:=TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0))+'Notified.txt') then
    Notified.LoadFromFile(ExtractFilePath(ParamStr(0))+'Notified.txt');
  Doc:=LoadXMLDocument(ExtractFilePath(ParamStr(0)) + 'rss.xml');
  FeedsNode:=Doc.DocumentElement.ChildNodes.Findnode('feeds');
end;

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Tray(2);
  Notified.Free;
end;

procedure TMain.CheckNew;
var
  RssNode: IXMLNode; i, j, n, h: integer; XMLCode, IgnoreFilters: TStringList; FoundFilter: boolean;
  FeedName, FeedItem, NotificationValue, NotificationColor, NotificationBigIcon, NotificationSmallIcon: string;
begin
  XMLCode:=TStringList.Create;
  IgnoreFilters:=TStringList.Create;

  //Список RSS
  for i:=0 to FeedsNode.ChildNodes.Count - 1 do begin
    RssNode:=FeedsNode.ChildNodes.Get(i);

    //XML получение разметки
    XMLCode.Text:=GetUrl(FeedsNode.ChildNodes[i].Attributes['url']);

    //Пропуск, если ничего не удалось получить
    if XMLCode.Count = 0 then Continue;

    //Проверка на названия
    for j:=0 to XMLCode.Count - 1 do

      //Проверяем только названия
      if Pos('<title>', XMLCode.Strings[j]) > 0 then begin
        //Оставляем только название
        XMLCode.Strings[j]:=StringReplace(XMLCode.Strings[j], '<title>', '', [rfIgnoreCase]);
        XMLCode.Strings[j]:=StringReplace(XMLCode.Strings[j], '</title>', '', [rfIgnoreCase]);
        XMLCode.Strings[j]:=Trim(XMLCode.Strings[j]);

        //Список имен в RSS
        for n:=0 to RSSNode.ChildNodes.Count - 1 do

          //Проверка на совпадение именами в базе "rss.xml" (для уведомлений) и
          //проверка на уже уведомленные имена "notified.txt"
          if (Pos(AnsiUpperCase(RSSNode.ChildNodes.Get(n).Attributes['search']), AnsiUpperCase(XMLCode.Strings[j])) > 0) and (Pos(XMLCode.Strings[j], Notified.Text) = 0) then begin

            //Фильтры игнорирования
            FoundFilter:=false;
            if RSSNode.ChildNodes.Get(n).HasAttribute('ignore') then begin
              IgnoreFilters.Text:=RSSNode.ChildNodes.Get(n).Attributes['ignore'];
              IgnoreFilters.Text:=StringReplace(IgnoreFilters.Text, ';', #13#10, [rfReplaceAll]);
              //ShowMessage(IgnoreFilters.Text);
              for h:=0 to IgnoreFilters.Count - 1 do
                if Trim(IgnoreFilters.Strings[h]) <> '' then
                  if Pos(IgnoreFilters.Strings[h], XMLCode.Strings[j]) > 0 then FoundFilter:=true;
            end;

            //Если фильтров нет (ignore)
            if FoundFilter = false then begin
              Notified.Add(XMLCode.Strings[j]);

              FeedName:=FeedsNode.ChildNodes[i].Attributes['name'];
              FeedItem:=RSSNode.ChildNodes.Get(n).NodeValue;
              NotificationValue:=FeedsNode.ChildNodes[i].Attributes['notification'];
              NotificationColor:=FeedsNode.ChildNodes[i].Attributes['color'];
              NotificationBigIcon:=FeedsNode.ChildNodes[i].Attributes['big-icon'];
              NotificationSmallIcon:=FeedsNode.ChildNodes[i].Attributes['small-icon'];

              WinExec(PChar(NotificationApp + ' "' + FeedName +
                '" "' + NotificationValue + '" "' + FeedItem + '" "' + NotificationBigIcon + '" "' +
                NotificationSmallIcon + '" ' + NotificationColor + ''), SW_ShowNormal);

              //Сохраняем показанные уведомления, чтобы больше не показывать их
              Notified.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Notified.txt');

            end;

          end; //Проверка на совпадение имени

      end; //Только названия

  end; //RSS

  IgnoreFilters.Free;
  XMLCode.Free;
end;

procedure TMain.CheckNotified;
var
  RssNode: IXMLNode; i, c: integer; XMLCode: TStringList;
  FeedUrl: String;
begin
  XMLCode:=TStringList.Create;

  //Список RSS
  for i:=0 to FeedsNode.ChildNodes.Count - 1 do begin
    RssNode:=FeedsNode.ChildNodes.Get(i);

    FeedUrl:=FeedsNode.ChildNodes[i].Attributes['url'];
    //XML получение разметки
    if CheckUrl(FeedsNode.ChildNodes[i].Attributes['url'])=false then
      Application.MessageBox(PChar('Не удалось получить RSS ленту - ' + FeedUrl), PChar(Caption), 0);

    //Создание общего списка для проверки
    XMLCode.Text:=XMLCode.Text + GetUrl(FeedsNode.ChildNodes[i].Attributes['url']);

    //Для тех, кто не соблюдает стандарт
    XMLCode.Text:=StringReplace(XMLCode.Text, '<title>', '', [rfReplaceAll]);
    XMLCode.Text:=StringReplace(XMLCode.Text, '</title>', '', [rfReplaceAll]);
  end;

  //Удаление устаревших ссылок
  c:=0;
  for i:=Notified.Count - 1 downto 0 do
    if (Pos(Notified.Strings[i], XMLCode.Text) = 0) or (Trim(Notified.Strings[i]) = '') then begin
      Notified.Delete(i);
      Inc(c);
    end;

  Notified.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Notified.txt');
  Application.MessageBox(Pchar('Готово. Удалено ссылок: ' + IntToStr(c)), PChar(Caption), 0);

  XMLCode.Free;
end;

procedure TMain.IconMouse(var Msg: TMessage);
begin
  case Msg.LParam of
    WM_RButtonDown:
        PopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end;
end;

procedure TMain.DefaultHandler(var Message);
begin
  if TMessage(Message).Msg = WM_TASKBARCREATED then Tray(1);
  inherited;
end;

procedure TMain.TimerTimer(Sender: TObject);
begin
  CheckNew;
end;

procedure TMain.ExitBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TMain.AboutBtnClick(Sender: TObject);
begin
  Application.MessageBox('RSS checker 0.4' + #13#10
  + 'Последнее обновление: 28.05.2017' + #13#10
  + 'http://r57zone.github.io' + #13#10 + 'r57zone@gmail.com','О программе...',0);
end;

procedure TMain.N1Click(Sender: TObject);
begin
  case MessageBox(Handle,'Удалить старые ссылки? Улучшит работу программы.', PChar(Caption), 35) of
          6: CheckNotified;
        end;
end;

end.

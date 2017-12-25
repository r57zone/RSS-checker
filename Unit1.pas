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
    CloseBtn: TMenuItem;
    RemLinksBtn: TMenuItem;
    LineItem: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TimerTimer(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure AboutBtnClick(Sender: TObject);
    procedure RemLinksBtnClick(Sender: TObject);
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
  NotificationApp, LangFile: string;

  //Перевод / Translate
  ID_NOTIFICATION_APP_ERROR, ID_FAILED_GET_RSS, ID_REMOVING_LINKS_QUESTION, ID_REMOVED_LINKS_DESC: string;
  ID_LAST_UPDATE, ID_ABOUT_TITLE: string;

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
    if Copy(LowerCase(Url), 1, 8) = 'https://' then
      hFile:=InternetOpenURL(hSession, PChar(Url), nil, 0, INTERNET_FLAG_SECURE, 0)
    else
      hFile:=InternetOpenURL(hSession, PChar(Url) , nil, 0, INTERNET_FLAG_RELOAD, 0);
    dwIndex:=0;
    dwCodeLen:=10;
    HttpQueryInfo(hFile, HTTP_QUERY_STATUS_CODE, @dwCode, dwCodeLen, dwIndex);
    res:=PChar(@dwCode);
    Result:=(res='200') or (res='302');
    if Assigned(hFile) then
      InternetCloseHandle(hFile);
    InternetCloseHandle(hSession);
  end;
end;

function HTTPGet(Url: string): string;
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
  if Copy(LowerCase(Url),1,8) = 'https://' then https:=true;
  Result:='';

  if Copy(LowerCase(Url), 1, 7) = 'http://' then Delete(Url, 1, 7);
  if Copy(LowerCase(Url), 1, 8) = 'https://' then Delete(Url, 1, 8);

  Uri:=Url;
  Uri:=Copy(Uri, 1, Pos('/', Uri) - 1);
  FHost:=Uri;
  FScript:=Url;
  Delete(FScript, 1, Pos(FHost, FScript) + Length(FHost));

  hSession:=InternetOpen('Mozilla/4.0 (MSIE 6.0; Windows NT 5.1)', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if not Assigned(hSession) then exit;
  try
    if https then hConnect:=InternetConnect(hSession, PChar(FHost), INTERNET_DEFAULT_HTTPS_PORT, nil,'HTTP/1.0', INTERNET_SERVICE_HTTP, 0, 0) else
      hConnect:=InternetConnect(hSession, PChar(FHost), INTERNET_DEFAULT_HTTP_PORT, nil, 'HTTP/1.0', INTERNET_SERVICE_HTTP, 0, 0);
    if not Assigned(hConnect) then exit;
    try
      Ansi:='text/*';
      if https then
        hRequest:=HttpOpenRequest(hConnect, 'GET', PChar(FScript), 'HTTP/1.1', nil, @Ansi, INTERNET_FLAG_SECURE, 0)
      else
        hRequest:=HttpOpenRequest(hConnect, 'GET', PChar(FScript), 'HTTP/1.1', nil, @Ansi, INTERNET_FLAG_RELOAD, 0);
      if not Assigned(hConnect) then Exit;
        try
          if not (HttpAddRequestHeaders(hRequest, Header, Length(Header), HTTP_ADDREQ_FLAG_REPLACE or HTTP_ADDREQ_FLAG_ADD or HTTP_ADDREQ_FLAG_COALESCE_WITH_COMMA)) then
            exit;
          Len:=0;
          Res:=0;
          SRequest:=' ';
          HttpQueryInfo(hRequest, HTTP_QUERY_RAW_HEADERS_CRLF or HTTP_QUERY_FLAG_REQUEST_HEADERS, @SRequest[1], Len, Res);
          if Len > 0 then begin
            SetLength(SRequest, Len);
            HttpQueryInfo(hRequest, HTTP_QUERY_RAW_HEADERS_CRLF or HTTP_QUERY_FLAG_REQUEST_HEADERS, @SRequest[1], Len, Res);
          end;
          if not (HttpSendRequest(hRequest, nil, 0, nil, 0)) then
            exit;
          FillChar(Buff, SizeOf(Buff), 0);
          repeat
            Application.ProcessMessages;
            Result:=Result + Buff;
            FillChar(Buff, SizeOf(Buff), 0);
            InternetReadFile(hRequest, @Buff, SizeOf(Buff), BytesRead);
          until BytesRead = 0;
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

procedure Tray(n: integer); //1 - добавить, 2 - удалить, 3 -  заменить
var
  nim: TNotifyIconData;
begin
  with nim do begin
    cbSize:=SizeOf(nim);
    wnd:=Main.Handle;
    uId:=1;
    uFlags:=nif_icon or nif_message or nif_tip;
    hIcon:=Application.Icon.Handle;
    uCallBackMessage:=WM_User + 1;
    StrCopy(szTip, PChar(Application.Title));
  end;
  case n of
    1: Shell_NotifyIcon(nim_add, @nim);
    2: Shell_NotifyIcon(nim_delete, @nim);
    3: Shell_NotifyIcon(nim_modify, @nim);
  end;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
begin
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Setup.ini');
  Timer.Interval:=Ini.ReadInteger('Main', 'CheckInterval', 20) * 60000; //Минуты
  NotificationApp:=Ini.ReadString('Main', 'NotificationApp', '');
  LangFile:=Ini.ReadString('Main', 'Language', 'English');
  Ini.Free;

  //Перевод / Translate
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Languages\' + LangFile + '.ini');
  ID_NOTIFICATION_APP_ERROR:=Ini.ReadString('Main', 'ID_NOTIFICATION_APP_ERROR', '');
  ID_FAILED_GET_RSS:=Ini.ReadString('Main', 'ID_FAILED_GET_RSS', '');
  ID_REMOVING_LINKS_QUESTION:=Ini.ReadString('Main', 'ID_REMOVING_LINKS_QUESTION', '');
  ID_REMOVED_LINKS_DESC:=Ini.ReadString('Main', 'ID_REMOVED_LINKS_DESC', '');
  ID_LAST_UPDATE:=Ini.ReadString('Main', 'ID_LAST_UPDATE', '');
  ID_ABOUT_TITLE:=Ini.ReadString('Main', 'ID_ABOUT_TITLE', '');
  RemLinksBtn.Caption:=Ini.ReadString('Main', 'ID_REMOVING_LINKS', '');
  AboutBtn.Caption:=Ini.ReadString('Main', 'ID_ABOUT', '');
  CloseBtn.Caption:=Ini.ReadString('Main', 'ID_EXIT', '');
  Ini.Free;

  if not FileExists(NotificationApp) then
    Application.MessageBox(PChar(ID_NOTIFICATION_APP_ERROR), PChar(Caption), MB_ICONWARNING);

  Application.Title:=Caption;
  WM_TaskBarCreated:=RegisterWindowMessage('TaskbarCreated');
  Tray(1);
  Notified:=TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0))+'Notified.txt') then
    Notified.LoadFromFile(ExtractFilePath(ParamStr(0))+'Notified.txt');
  Doc:=LoadXMLDocument(ExtractFilePath(ParamStr(0)) + 'RSS.xml');
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

  //Список RSS / RSS list
  for i:=0 to FeedsNode.ChildNodes.Count - 1 do begin
    RssNode:=FeedsNode.ChildNodes.Get(i);

    //Получение XML  / Get XML
    XMLCode.Text:=HTTPGet(FeedsNode.ChildNodes[i].Attributes['url']);

    //Пропуск, если ничего не удалось получить / Skip, if nothing is possible to get
    if XMLCode.Count = 0 then
      Continue;

    //Проверка на названия / Checking for names
    for j:=0 to XMLCode.Count - 1 do

      //Проверяем только названия
      if Pos('<title>', XMLCode.Strings[j]) > 0 then begin

        //Оставляем только название / Get only the name
        XMLCode.Strings[j]:=Trim(Copy(XMLCode.Strings[j], Pos('<title>', AnsiLowerCase(XMLCode.Strings[j])) + 7, Pos('</title>', AnsiLowerCase(XMLCode.Strings[j])) - Pos('<title>', AnsiLowerCase(XMLCode.Strings[j])) - 7));

        //Список имен в RSS /List of name in RSS
        for n:=0 to RSSNode.ChildNodes.Count - 1 do

          //Проверка на совпадение именами в базе "RSS.xml" (для уведомлений) и / Check for matches of names in "RSS.xml" (for notification) and
          //проверка на уже уведомленные "notified.txt" / Check for already notified "notified.txt"
          if (Pos(AnsiLowerCase(RSSNode.ChildNodes.Get(n).Attributes['search']), AnsiLowerCase(XMLCode.Strings[j])) > 0) and (Pos(XMLCode.Strings[j], Notified.Text) = 0) then begin

            //Фильтры игнорирования / Ignore filters
            FoundFilter:=false;
            if RSSNode.ChildNodes.Get(n).HasAttribute('ignore') then begin
              IgnoreFilters.Text:=RSSNode.ChildNodes.Get(n).Attributes['ignore'];
              IgnoreFilters.Text:=StringReplace(IgnoreFilters.Text, ';', #13#10, [rfReplaceAll]);

              for h:=0 to IgnoreFilters.Count - 1 do
                if Trim(IgnoreFilters.Strings[h]) <> '' then
                  if Pos(IgnoreFilters.Strings[h], XMLCode.Strings[j]) > 0 then FoundFilter:=true;
            end;

            //Если фильтров нет (ignore) / If filter not found
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

              //Сохраняем показанные уведомления, чтобы больше не показывать их / Saved notifications for don't show again
              Notified.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Notified.txt');

            end;

          end; //Проверка на совпадение имени / Check for matches of names

      end; //Только названия / Only names

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

  //Список RSS / RSS list
  for i:=0 to FeedsNode.ChildNodes.Count - 1 do begin
    RssNode:=FeedsNode.ChildNodes.Get(i);

    FeedUrl:=FeedsNode.ChildNodes[i].Attributes['url'];
    //Получение XML / Get XML
    if CheckUrl(FeedsNode.ChildNodes[i].Attributes['url'])=false then
      Application.MessageBox(PChar(ID_FAILED_GET_RSS + ' ' + FeedUrl), PChar(Caption), MB_ICONWARNING);

    //Создание общего списка для проверки ссылок / Creating a common list for checking links
    XMLCode.Text:=XMLCode.Text + HTTPGet(FeedsNode.ChildNodes[i].Attributes['url']);
  end;

  //Удаление устаревших ссылок / Removing outdated links
  c:=0;
  for i:=Notified.Count - 1 downto 0 do
    if (Pos(Notified.Strings[i], XMLCode.Text) = 0) or (Trim(Notified.Strings[i]) = '') then begin
      Notified.Delete(i);
      Inc(c);
    end;

  Notified.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Notified.txt');
  Application.MessageBox(Pchar(ID_REMOVED_LINKS_DESC + ' ' + IntToStr(c)), PChar(Caption), MB_ICONINFORMATION);

  XMLCode.Free;
end;

procedure TMain.IconMouse(var Msg: TMessage);
begin
  case Msg.LParam of
    WM_LButtonDown: begin
      PostMessage(Handle, WM_LBUTTONDOWN, MK_LBUTTON, 0);
      PostMessage(Handle, WM_LBUTTONUP, MK_LBUTTON, 0);
    end;
    WM_RButtonDown:
      PopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end;
end;

procedure TMain.DefaultHandler(var Message);
begin
  if TMessage(Message).Msg = WM_TASKBARCREATED then
    Tray(1);
  inherited;
end;

procedure TMain.TimerTimer(Sender: TObject);
begin
  CheckNew;
end;

procedure TMain.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TMain.AboutBtnClick(Sender: TObject);
begin
  Application.MessageBox(PChar('RSS checker 0.5' + #13#10
  + ID_LAST_UPDATE + ' 25.12.2017' + #13#10
  + 'http://r57zone.github.io' + #13#10 + 'r57zone@gmail.com'), PChar(ID_ABOUT_TITLE), 0);
end;

procedure TMain.RemLinksBtnClick(Sender: TObject);
begin
  case MessageBox(Handle, PChar(ID_REMOVING_LINKS_QUESTION), PChar(Caption), MB_YESNO + MB_ICONQUESTION) of
    6: CheckNotified;
  end;
end;

end.

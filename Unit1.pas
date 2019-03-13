unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, XMLDoc, XMLIntf, ShellAPI, ExtCtrls, IniFiles,
  Menus, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  IdIOHandler, IdIOHandlerSocket, IdSSLOpenSSL, RegExpr, Registry;

type
  TMain = class(TForm)
    Timer: TTimer;
    PopupMenu: TPopupMenu;
    AboutBtn: TMenuItem;
    CloseBtn: TMenuItem;
    RemLinksBtn: TMenuItem;
    LineItem: TMenuItem;
    IdHTTP: TIdHTTP;
    IdSSLIOHandlerSocket: TIdSSLIOHandlerSocket;
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
    procedure IconMouse(var Msg:TMessage); message WM_USER + 1;
  end;

var
  Main: TMain;
  Doc: IXMLDocument;
  FeedsNode: IXMLNode;
  Notified: TStringList;
  RegExp, SubRegExp: TRegExpr;
  WM_TaskBarCreated: Cardinal;
  NotificationApp, LangFile: string;

  DownloadPath: string;

  DownloaderPath: string;

  //Перевод / Translate
  ID_NOTIFICATION_APP_ERROR, ID_FAILED_GET_RSS, ID_REMOVING_LINKS_QUESTION, ID_REMOVED_LINKS_DESC: string;
  ID_LAST_UPDATE, ID_ABOUT_TITLE: string;

implementation

{$R *.dfm}

function DownloadTorrent(URL, Cookie, Path: string; out DownloadedFileName: string): boolean;
const
  DefExt = '.torrent';
var
  FS: TFileStream; FileExistsCounter: integer;
begin
  FileExistsCounter:=1;
  while True do
    if FileExists(Path + IntToStr(FileExistsCounter) + DefExt) then
      Inc(FileExistsCounter)
    else
      break;

  DownloadedFileName:=IntToStr(FileExistsCounter) + DefExt;
  FS:=TFileStream.Create(Path + DownloadedFileName, fmCreate);
  try
    Main.IdHTTP.Request.CustomHeaders.Text:= 'COOKIE:' + Cookie;
    Main.IdHTTP.Get(URL, FS);
    Result:=true;
  except
    Result:=false;
  end;
  FS.Free;
end;

function HTTPGet(URL, Cookie: string): string;
begin
  Main.IdHTTP.Request.CustomHeaders.Text:='COOKIE:' + Cookie;
  try
    Result:=Main.IdHTTP.Get(URL);
  except
    Result:='';
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

function GetNotificationAppPath: string;
var
  Reg: TRegistry;
begin
  Reg:=TRegistry.Create;
  Reg.RootKey:=HKEY_CURRENT_USER;
  if Reg.OpenKey('\Software\r57zone\Notification', false) then begin
      Result:=Reg.ReadString('Path');
    Reg.CloseKey;
  end;
  Reg.Free;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
begin
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Setup.ini');
  Timer.Interval:=Ini.ReadInteger('Main', 'CheckInterval', 20) * 60000; //Минуты
  NotificationApp:=GetNotificationAppPath;
  LangFile:=Ini.ReadString('Main', 'Language', 'English');
  DownloadPath:=Ini.ReadString('Main', 'DownloadPath', '');
  if Trim(DownloadPath) = '' then begin
    if not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Downloads') then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Downloads');
    DownloadPath:=ExtractFilePath(ParamStr(0)) + 'Downloads\';
  end;
  DownloaderPath:=Ini.ReadString('Main', 'DownloaderPath', '');
  Ini.Free;

  //Перевод / Translate
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Languages\' + LangFile + '.ini');
  ID_NOTIFICATION_APP_ERROR:=Ini.ReadString('Main', 'ID_NOTIFICATION_APP_ERROR', '');
  ID_FAILED_GET_RSS:=StringReplace(Ini.ReadString('Main', 'ID_FAILED_GET_RSS', ''), '\n', #13#10, [rfReplaceAll]);
  ID_REMOVING_LINKS_QUESTION:=Ini.ReadString('Main', 'ID_REMOVING_LINKS_QUESTION', '');
  ID_REMOVED_LINKS_DESC:=Ini.ReadString('Main', 'ID_REMOVED_LINKS_DESC', '');
  ID_LAST_UPDATE:=Ini.ReadString('Main', 'ID_LAST_UPDATE', '');
  ID_ABOUT_TITLE:=Ini.ReadString('Main', 'ID_ABOUT_TITLE', '');
  RemLinksBtn.Caption:=Ini.ReadString('Main', 'ID_REMOVING_LINKS', '');
  AboutBtn.Caption:=Ini.ReadString('Main', 'ID_ABOUT', '');
  CloseBtn.Caption:=Ini.ReadString('Main', 'ID_EXIT', '');
  Ini.Free;

  if not FileExists(NotificationApp) then begin
    Application.MessageBox(PChar(ID_NOTIFICATION_APP_ERROR), PChar(Caption), MB_ICONWARNING);
    Exit;
  end;

  Application.Title:=Caption;
  WM_TaskBarCreated:=RegisterWindowMessage('TaskbarCreated');
  Tray(1);
  Notified:=TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0))+'Notified.txt') then
    Notified.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'Notified.txt');
  Doc:=LoadXMLDocument(ExtractFilePath(ParamStr(0)) + 'RSS.xml');
  FeedsNode:=Doc.DocumentElement.ChildNodes.Findnode('feeds');

  RegExp:=TRegExpr.Create;
  SubRegExp:=TRegExpr.Create;
  RegExp.ModifierG:=false; //Не жадный режим / None greedy mode
  SubRegExp.ModifierG:=false;
end;

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Tray(2);
  SubRegExp.Free;
  RegExp.Free;
  Notified.Free;
end;

procedure TMain.CheckNew;
var
  RssNode: IXMLNode; i, j, n: integer; IgnoreFilters: TStringList; FoundFilter: boolean;
  Source, FeedName, FeedItem, ItemTitle, ItemLink, NotificationValue, NotificationColor, NotificationBigIcon, NotificationSmallIcon, DownloadedFile: string;
begin
  IgnoreFilters:=TStringList.Create;

  //Список RSS / RSS list
  for i:=0 to FeedsNode.ChildNodes.Count - 1 do begin
    RssNode:=FeedsNode.ChildNodes.Get(i);

    //Получение XML  / Get XML
    Source:=HTTPGet(FeedsNode.ChildNodes[i].Attributes['url'], FeedsNode.ChildNodes[i].Attributes['cookie']);

    //Пропуск, если ничего не удалось получить / Skip, if nothing is possible to get
    if Source = '' then
      Continue;

    RegExp.Expression:='(?i)<item>(.*)</item>';

    try
      if RegExp.Exec(Source) then
        repeat

          //Item title
          SubRegExp.Expression:='(?i)<title>(.*)</title>';
          if SubRegExp.Exec(RegExp.Match[1]) then ItemTitle:=SubRegExp.Match[1];

          //Item link
          SubRegExp.Expression:='(?i)<link>(.*)</link>';
          if SubRegExp.Exec(RegExp.Match[1]) then ItemLink:=SubRegExp.Match[1];

          //Item link, костыль для newstudio
          SubRegExp.Expression:='(?i)<enclosure*.url="(.*)"';
          if SubRegExp.Exec(RegExp.Match[1]) then ItemLink:=SubRegExp.Match[1];

          //Список имен в RSS / List of name in RSS
          for j:=0 to RSSNode.ChildNodes.Count - 1 do

            //Проверка на совпадение именами в базе "RSS.xml" (для уведомлений) и / Check for matches of names in "RSS.xml" (for notification) and
            //проверка на уже уведомленные "notified.txt" / Check for already notified "notified.txt"
            if (Pos(AnsiLowerCase(RSSNode.ChildNodes.Get(j).Attributes['search']), AnsiLowerCase(ItemTitle)) > 0) and (Pos(ItemTitle, Notified.Text) = 0) then begin

              //Фильтры игнорирования / Ignore filters
              FoundFilter:=false;
              if RSSNode.ChildNodes.Get(j).HasAttribute('ignore') then begin
                IgnoreFilters.Text:=RSSNode.ChildNodes.Get(j).Attributes['ignore'];
                IgnoreFilters.Text:=StringReplace(IgnoreFilters.Text, ';', #13#10, [rfReplaceAll]);

                for n:=0 to IgnoreFilters.Count - 1 do
                  if Trim(IgnoreFilters.Strings[n]) <> '' then
                    if Pos(AnsiLowerCase(IgnoreFilters.Strings[n]), AnsiLowerCase(ItemTitle)) > 0 then FoundFilter:=true;
              end;

              //Если фильтров нет (ignore) / If filter not found
              if FoundFilter = false then begin
                Notified.Add(ItemTitle);

                FeedName:=FeedsNode.ChildNodes[i].Attributes['name'];
                FeedItem:=RSSNode.ChildNodes.Get(j).NodeValue;
                NotificationValue:=FeedsNode.ChildNodes[i].Attributes['notification'];
                NotificationColor:=FeedsNode.ChildNodes[i].Attributes['color'];
                NotificationBigIcon:=FeedsNode.ChildNodes[i].Attributes['big-icon'];
                NotificationSmallIcon:=FeedsNode.ChildNodes[i].Attributes['small-icon'];

                if NotificationApp <> '' then
                  WinExec(PChar(NotificationApp + ' -t "' + FeedName +
                    '" -d "' + NotificationValue + '\n' + FeedItem + '" -b "' + NotificationBigIcon + '" -s "' +
                    NotificationSmallIcon + '" -c ' + NotificationColor), SW_SHOWNORMAL);

                if AnsiLowerCase(FeedsNode.ChildNodes[i].Attributes['download']) = 'true' then begin
                  DownloadTorrent(ItemLink, FeedsNode.ChildNodes[i].Attributes['cookie'], DownloadPath, DownloadedFile);
                  if DownloaderPath <> '' then WinExec(PChar(Format(DownloaderPath, [DownloadPath + DownloadedFile])), SW_SHOWNORMAL);
                end;

                //Сохраняем показанные уведомления, чтобы больше не показывать их / Saved notifications for don't show again
                Notified.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Notified.txt');

              end;

            end; //Проверка на совпадение имени / Check for matches of names


        until not RegExp.ExecNext;
    except
    end;

  end; //RSS

  IgnoreFilters.Free;
end;

procedure TMain.CheckNotified;
var
  RssNode: IXMLNode; i, c: integer;
  Source: string;
  FailedGetRSS: boolean;
begin
  FailedGetRSS:=false;
  //Список RSS / RSS list
  for i:=0 to FeedsNode.ChildNodes.Count - 1 do begin
    RssNode:=FeedsNode.ChildNodes.Get(i);

    //Создание общего списка для проверки ссылок / Creating a common list for checking links
    Source:=Source + HTTPGet(FeedsNode.ChildNodes[i].Attributes['url'], '');
    //Получение XML / Get XML
    if Source = '' then begin
      Application.MessageBox(PChar(Format(ID_FAILED_GET_RSS, [FeedsNode.ChildNodes[i].Attributes['url']])), PChar(Caption), MB_ICONWARNING);
      FailedGetRSS:=true;
    end;
  end;

  if FailedGetRSS = false then begin
    //Удаление устаревших ссылок / Removing outdated links
    c:=0;
    for i:=Notified.Count - 1 downto 0 do
      if (Pos(Notified.Strings[i], Source) = 0) or (Trim(Notified.Strings[i]) = '') then begin
        Notified.Delete(i);
        Inc(c);
      end;

    Notified.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Notified.txt');
    Application.MessageBox(Pchar(ID_REMOVED_LINKS_DESC + ' ' + IntToStr(c)), PChar(Caption), MB_ICONINFORMATION);
  end;
end;

procedure TMain.IconMouse(var Msg: TMessage);
begin
  case Msg.LParam of
    WM_LBUTTONDOWN: begin
      PostMessage(Handle, WM_LBUTTONDOWN, MK_LBUTTON, 0);
      PostMessage(Handle, WM_LBUTTONUP, MK_LBUTTON, 0);
    end;
    WM_RBUTTONDOWN:
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
  Application.MessageBox(PChar('RSS checker 0.6' + #13#10
  + ID_LAST_UPDATE + ' 27.02.2018' + #13#10
  + 'http://r57zone.github.io' + #13#10
  + 'r57zone@gmail.com'), PChar(ID_ABOUT_TITLE), 0);
end;

procedure TMain.RemLinksBtnClick(Sender: TObject);
begin
  case MessageBox(Handle, PChar(ID_REMOVING_LINKS_QUESTION), PChar(Caption), MB_YESNO + MB_ICONQUESTION) of
    6: CheckNotified;
  end;
end;

end.

object Main: TMain
  Left = 192
  Top = 124
  BorderStyle = bsSingle
  Caption = 'RSS '#1089'hecker'
  ClientHeight = 193
  ClientWidth = 312
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Timer: TTimer
    OnTimer = TimerTimer
    Left = 8
    Top = 8
  end
  object PopupMenu: TPopupMenu
    Left = 40
    Top = 8
    object RemLinksBtn: TMenuItem
      Caption = #1054#1095#1080#1089#1090#1080#1090#1100
      OnClick = RemLinksBtnClick
    end
    object LineItem: TMenuItem
      Caption = '-'
    end
    object AboutBtn: TMenuItem
      Caption = #1054' '#1087#1088#1086#1075#1088#1072#1084#1084#1077'...'
      OnClick = AboutBtnClick
    end
    object CloseBtn: TMenuItem
      Caption = #1042#1099#1093#1086#1076
      OnClick = CloseBtnClick
    end
  end
  object IdHTTP: TIdHTTP
    IOHandler = IdSSLIOHandlerSocket
    MaxLineAction = maException
    ReadTimeout = 0
    AllowCookies = True
    HandleRedirects = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = 0
    Request.ContentRangeStart = 0
    Request.ContentType = 'text/html'
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/4.0 (MSIE 6.0; Windows NT 5.1)'
    HTTPOptions = [hoForceEncodeParams]
    Left = 72
    Top = 8
  end
  object IdSSLIOHandlerSocket: TIdSSLIOHandlerSocket
    SSLOptions.Method = sslvTLSv1
    SSLOptions.Mode = sslmUnassigned
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    Left = 104
    Top = 8
  end
end

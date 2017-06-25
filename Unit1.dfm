object Main: TMain
  Left = 192
  Top = 124
  BorderStyle = bsSingle
  Caption = 'RSS checker'
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
    object N1: TMenuItem
      Caption = #1054#1095#1080#1089#1090#1080#1090#1100
      OnClick = N1Click
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object AboutBtn: TMenuItem
      Caption = #1054' '#1087#1088#1086#1075#1088#1072#1084#1084#1077'...'
      OnClick = AboutBtnClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object ExitBtn: TMenuItem
      Caption = #1042#1099#1093#1086#1076
      OnClick = ExitBtnClick
    end
  end
end

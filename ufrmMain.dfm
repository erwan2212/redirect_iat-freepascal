object Form1: TForm1
  Left = 521
  Height = 298
  Top = 125
  Width = 524
  Caption = 'frmMain'
  ClientHeight = 298
  ClientWidth = 524
  Color = clBtnFace
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'MS Sans Serif'
  LCLVersion = '1.8.2.0'
  object Button1: TButton
    Left = 52
    Height = 20
    Top = 33
    Width = 61
    Caption = 'intercept'
    OnClick = Button1Click
    TabOrder = 0
  end
  object Button2: TButton
    Left = 52
    Height = 20
    Top = 65
    Width = 61
    Caption = 'test msgbox'
    OnClick = Button2Click
    TabOrder = 1
  end
  object Button3: TButton
    Left = 52
    Height = 20
    Top = 98
    Width = 61
    Caption = 'free'
    OnClick = Button3Click
    TabOrder = 2
  end
  object ListBox1: TListBox
    Left = 137
    Height = 234
    Top = 7
    Width = 267
    ItemHeight = 0
    TabOrder = 3
  end
end

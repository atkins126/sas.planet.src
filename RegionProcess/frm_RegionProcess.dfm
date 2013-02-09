object frmRegionProcess: TfrmRegionProcess
  Left = 234
  Top = 298
  Caption = 'Selection Manager'
  ClientHeight = 323
  ClientWidth = 572
  Color = clBtnFace
  Constraints.MinHeight = 343
  Constraints.MinWidth = 580
  ParentFont = True
  OldCreateOrder = False
  PopupMode = pmExplicit
  Position = poMainFormCenter
  ShowHint = True
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 572
    Height = 286
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    TabWidth = 92
    object TabSheet1: TTabSheet
      Caption = 'Download'
    end
    object TabSheet2: TTabSheet
      Tag = 1
      Caption = 'Stitch'
      ImageIndex = 1
    end
    object TabSheet3: TTabSheet
      Tag = 2
      Caption = 'Generate'
      ImageIndex = 2
    end
    object TabSheet4: TTabSheet
      Tag = 3
      Caption = 'Delete'
      ImageIndex = 3
    end
    object TabSheet5: TTabSheet
      Tag = 4
      Caption = 'Export'
      ImageIndex = 4
    end
    object TabSheet6: TTabSheet
      Tag = 5
      Caption = 'Copy'
      ImageIndex = 5
    end
  end
  object pnlBottomButtons: TPanel
    Left = 0
    Top = 286
    Width = 572
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    BorderWidth = 3
    TabOrder = 1
    object SpeedButton1: TSpeedButton
      AlignWithMargins = True
      Left = 379
      Top = 6
      Width = 25
      Height = 25
      Hint = 'Save selection info to file'
      Align = alRight
      Flat = True
      Glyph.Data = {
        46030000424D460300000000000036000000280000000E0000000E0000000100
        20000000000010030000000000000000000000000000000000008D6637818D66
        37FF8D6637FFD8D8B7FFD8D8B7FFD8D8B7FFD8D8B7FFD8D8B7FFD8D8B7FFD8D8
        B7FF8D6637FF8D6637FF8D6637FF8D6637FF8E6738FFB78448FFA67841FFECEC
        D0FFA67841FFA67841FFECECD0FFECECD0FFECECD0FFECECD0FFA67841FFA678
        41FFC2945BFF8E6738FF906839FFBD894AFFA67841FFEFEFD9FFBD894AFFA678
        41FFEFEFD9FFEFEFD9FFEFEFD9FFEFEFD9FFA67841FFA67841FFC2945BFF9068
        39FF926A39FFBF8A4BFFA67841FFF1F1E0FFBF8A4BFFA67841FFF1F1E0FFF1F1
        E0FFF1F1E0FFF1F1E0FFA67841FFA67841FFC2945BFF926A39FF946B3AFFC18C
        4CFFA67841FFF3F3E5FFF3F3E5FFF3F3E5FFF3F3E5FFF3F3E5FFF3F3E5FFF3F3
        E5FFA67841FFA67841FFC2945BFF946B3AFF976D3BFFC48E4DFFC48E4DFFA678
        41FFA67841FFA67841FFA67841FFA67841FFA67841FFC2945BFFC2945BFFC294
        5BFFC48E4DFF976D3BFF996F3CFFC7904EFFC7904EFFC7904EFFC7904EFFC790
        4EFFC7904EFFC7904EFFC7904EFFC7904EFFC7904EFFC7904EFFC7904EFF996F
        3CFF9C713DFFC9924FFFFEEBDEFFFEEBDEFFFEEBDEFFFEEBDEFFFEEBDEFFFEEB
        DEFFFEEBDEFFFEEBDEFFFEEBDEFFFEEBDEFFC9924FFF9C713DFF9E733EFFCC94
        51FFC0E4E8FFC0E4E8FFC0E4E8FFC0E4E8FFC0E4E8FFC0E4E8FFC0E4E8FFC0E4
        E8FFC0E4E8FFC0E4E8FFCC9451FF9E733EFFA17540FFD09652FFFFEDE2FFFFED
        E2FFFFEDE2FFFFEDE2FFFFEDE2FFFFEDE2FFFFEDE2FFFFEDE2FFFFEDE2FFFFED
        E2FFD09652FFA17540FFA67942FFD69B55FFBEE5E9FFBEE5E9FFBEE5E9FFBEE5
        E9FFBEE5E9FFBEE5E9FFBEE5E9FFBEE5E9FFBEE5E9FFBEE5E9FFD69B55FFA679
        42FFAC7D44FFDCA057FFFFF0E6FFFFF0E6FFFFF0E6FFFFF0E6FFFFF0E6FFFFF0
        E6FFFFF0E6FFFFF0E6FFFFF0E6FFFFF0E6FFDCA057FFAC7D44FFB18146FFE1A3
        59FF07C8F8FF07C8F8FF07C8F8FF07C8F8FF07C8F8FF07C8F8FF07C8F8FF07C8
        F8FF07C8F8FF07C8F8FFE1A359FFB18146FFB68448FFB68448FF0FA5ECFF0FA5
        ECFF0FA5ECFF0FA5ECFF0FA5ECFF0FA5ECFF0FA5ECFF0FA5ECFF0FA5ECFF0FA5
        ECFFB68448FFB68448FF}
      Layout = blGlyphTop
      Margin = 5
      ParentShowHint = False
      ShowHint = True
      OnClick = SpeedButton1Click
    end
    object SpeedButton_fit: TSpeedButton
      AlignWithMargins = True
      Left = 348
      Top = 6
      Width = 25
      Height = 25
      Hint = 'Fit to Screen'
      Align = alRight
      Flat = True
      Glyph.Data = {
        06030000424D060300000000000036000000280000000F0000000F0000000100
        180000000000D002000000000000000000000000000000000000FFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF88B2
        CB337CA9AFD2E8000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFF88B2CB4386AF8EC1E3367CA8000000FFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8BB4CD4386AF8EC1
        E34989B293B8D0000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFF92B8D04486B08EC1E34989B293B8D0FFFFFF000000FFFFFFFFFFFF
        FFFFFFBDBEBE828584606462828584BDBEBEFFFFFF2E77A482B7D94889B291B7
        CFFFFFFFFFFFFF000000FFFFFFFFFFFF8082818A8D8CDBD9D6EFEAE5D9D7D28A
        8B898082817A99AB3178A693B8D0FFFFFFFFFFFFFFFFFF000000FFFFFF808281
        BCBEBCF7F0EAEFE0D2F0E1D3F4E8DEF8F2EDBAB8B5808280FFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFF000000BDBEBE8A8D8CF8F2EBBE753CBE753CEFDECFBE753CBE
        753CF9F3EE8A8B89BDBEBEFFFFFFFFFFFFFFFFFFFFFFFF000000828584DCDCDA
        ECD9C6BE753CEBD8C5EEDFD0F0E2D4BE753CF6EDE5D9D6D2828482FFFFFFFFFF
        FFFFFFFFFFFFFF000000606462F1EEEAE8D1BBE8D4C2EBDACAEEE0D3EFE3D8F2
        E5D9F5EAE0F1EDE9616462FFFFFFFFFFFFFFFFFFFFFFFF000000828483DCDBD9
        ECDAC9BE753CEBE0D4EEE5DCEEE7E0BE753CF7EEE6DAD8D4818381FFFFFFFFFF
        FFFFFFFFFFFFFF000000BCBDBC8D908EF6EEE6CF9F72CF9F72EEE7E0BE753CBE
        753CF9F4EF8B8C8ABBBCBCFFFFFFFFFFFFFFFFFFFFFFFF000000FFFFFF7D817F
        C0C0BEF6EDE4F1E2D5F1E3D7F5EAE1F9F3EEBDBCB87D807EFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFF000000FFFFFFFFFFFF7E81808E918FDDD9D5F1ECE6DDD9D48E
        8F8B7E817EFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000FFFFFFFFFFFF
        FFFFFFB9BABA828584606462828584B9BABAFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFF000000}
      Layout = blGlyphTop
      Margin = 5
      ParentShowHint = False
      ShowHint = True
      OnClick = SpeedButton_fitClick
    end
    object SpeedButton_mkMark: TSpeedButton
      AlignWithMargins = True
      Left = 317
      Top = 6
      Width = 25
      Height = 25
      Hint = 'Add Placemark'
      Align = alRight
      Flat = True
      Glyph.Data = {
        26040000424D2604000000000000360000002800000012000000120000000100
        180000000000F0030000120B0000120B00000000000000000000FFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFC5C5C5C5C5C5FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC5
        C5C5C5C5C5FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA3A3A3A3A3A3FFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF787879787879FFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFF787879787879FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDADADA69
        696A6A6A6ACFCFCFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF6F6F6A0A0A18080818F8F8F929292
        F3F3F3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFD2D2D26B6B6CC4C4C5CECECF6A6A6BCBCBCBFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFE3E3
        E3808081969697F0F0F1F3F3F39E9D9E7C7C7CE1E1E1FFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFECECEC8F8F8F848485E2E2E3FD
        FDFEFEFEFEE5E5E58686878C8C8CEBEBEBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        0000FFFFFFFFFFFFFFFFFFB0B0B0737374DADADAFCFCFCFDFDFEFDFDFEFDFDFD
        DCDCDD757576ACACACFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFF
        ECECEC777777B5B5B5F8F8F8FDFDFEFDFDFEFDFDFEFDFDFEF8F8F9B8B8B97474
        74EBEBEBFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFE9E9E9727272BFBF
        C0FAFAFAFDFDFEFDFDFEFDFDFEFDFDFEFAFAFAC2C2C2707070E8E8E8FFFFFFFF
        FFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFA3A3A37C7C7DE1E1E2FDFDFDFD
        FDFEFDFDFEFDFDFDE3E3E37F7F809F9F9FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        0000FFFFFFFFFFFFFFFFFFE5E5E57F7F7F8E8E8FDDDDDEF6F6F6F6F6F6DEDEDF
        9090907C7C7CE2E2E2FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFF
        FFFFFFFFFFFFDDDDDD858585717171A2A2A3A3A3A4717171818181DADADAFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFEBEBEBBCBCBC8D8D8D8B8B8BB9B9B9EAEAEAFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFF0000}
      Layout = blGlyphTop
      Margin = 5
      ParentShowHint = False
      ShowHint = True
      OnClick = SpeedButton_mkMarkClick
    end
    object Button1: TButton
      AlignWithMargins = True
      Left = 410
      Top = 6
      Width = 75
      Height = 25
      Align = alRight
      Caption = 'Start'
      Default = True
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button3: TButton
      AlignWithMargins = True
      Left = 491
      Top = 6
      Width = 75
      Height = 25
      Align = alRight
      Cancel = True
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = Button3Click
    end
    object CBCloseWithStart: TCheckBox
      AlignWithMargins = True
      Left = 6
      Top = 6
      Width = 305
      Height = 25
      Align = alClient
      Caption = 'Close this window after start'
      Checked = True
      State = cbChecked
      TabOrder = 2
    end
  end
  object SaveSelDialog: TSaveDialog
    DefaultExt = '*.hlg'
    Filter = 'Selections|*.hlg'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 32
    Top = 48
  end
end
VERSION 5.00
Begin VB.Form frmConfigure 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Configure Fury�"
   ClientHeight    =   2250
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   4680
   ControlBox      =   0   'False
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   Icon            =   "frmConfigure.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   150
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   312
   StartUpPosition =   2  'CenterScreen
   Begin VB.CommandButton cmdCancel 
      Cancel          =   -1  'True
      Caption         =   "Cancel"
      BeginProperty Font 
         Name            =   "Tahoma"
         Size            =   9
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   405
      Left            =   3450
      TabIndex        =   12
      Top             =   1815
      Width           =   1200
   End
   Begin VB.CommandButton cmdOK 
      Caption         =   "OK"
      Default         =   -1  'True
      BeginProperty Font 
         Name            =   "Tahoma"
         Size            =   9
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   405
      Left            =   30
      TabIndex        =   4
      Top             =   1815
      Width           =   1200
   End
   Begin VB.Frame fraSound 
      Caption         =   "Sound"
      Height          =   270
      Left            =   30
      TabIndex        =   3
      Top             =   1515
      Width           =   4620
      Begin VB.CheckBox chkEnableSound 
         Alignment       =   1  'Right Justify
         Caption         =   "Enable"
         Height          =   195
         Left            =   3765
         TabIndex        =   11
         Top             =   0
         Value           =   1  'Checked
         Width           =   780
      End
   End
   Begin VB.Frame fraGraphics 
      Caption         =   "Graphics"
      Height          =   1485
      Left            =   30
      TabIndex        =   0
      Top             =   0
      Width           =   4620
      Begin VB.CheckBox chkDirectRender 
         Height          =   195
         Left            =   4320
         TabIndex        =   13
         Top             =   1185
         Width           =   195
      End
      Begin VB.CheckBox chkVSync 
         Height          =   195
         Left            =   1470
         TabIndex        =   9
         Top             =   1185
         Width           =   195
      End
      Begin VB.ComboBox cmbBitDepth 
         Height          =   315
         ItemData        =   "frmConfigure.frx":708A
         Left            =   3255
         List            =   "frmConfigure.frx":709A
         Style           =   2  'Dropdown List
         TabIndex        =   8
         Top             =   735
         Width           =   1260
      End
      Begin VB.ComboBox cmbScreenSize 
         Height          =   315
         ItemData        =   "frmConfigure.frx":70C3
         Left            =   1470
         List            =   "frmConfigure.frx":70EB
         Style           =   2  'Dropdown List
         TabIndex        =   6
         Top             =   735
         Width           =   1755
      End
      Begin VB.Frame Frame1 
         BeginProperty Font 
            Name            =   "Small Fonts"
            Size            =   2.25
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   90
         Left            =   90
         TabIndex        =   5
         Top             =   600
         Width           =   4440
      End
      Begin VB.ComboBox cmbGraphicsPlugin 
         Height          =   315
         ItemData        =   "frmConfigure.frx":7164
         Left            =   1470
         List            =   "frmConfigure.frx":716E
         Style           =   2  'Dropdown List
         TabIndex        =   2
         Top             =   255
         Width           =   3045
      End
      Begin VB.Label lblDirectRender 
         Alignment       =   1  'Right Justify
         AutoSize        =   -1  'True
         Caption         =   "Direct Render (faster but buggy):"
         Height          =   195
         Left            =   1860
         TabIndex        =   14
         Top             =   1170
         Width           =   2430
      End
      Begin VB.Label lblVSync 
         Alignment       =   1  'Right Justify
         AutoSize        =   -1  'True
         Caption         =   "Vertical Sync:"
         Height          =   195
         Left            =   465
         TabIndex        =   10
         Top             =   1170
         Width           =   975
      End
      Begin VB.Label lblScreenMode 
         Alignment       =   1  'Right Justify
         AutoSize        =   -1  'True
         Caption         =   "Screen Mode:"
         Height          =   195
         Left            =   450
         TabIndex        =   7
         Top             =   795
         Width           =   990
      End
      Begin VB.Label lblOutputPlugin 
         Alignment       =   1  'Right Justify
         AutoSize        =   -1  'True
         Caption         =   "Output Plugin:"
         Height          =   195
         Left            =   405
         TabIndex        =   1
         Top             =   315
         Width           =   1035
      End
   End
End
Attribute VB_Name = "frmConfigure"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'
'    Engine (Fury� Game Creation System Runtime Engine)
'    Copyright (C) 2003 Kevin Gadd
'
'    This library is free software; you can redistribute it and/or
'    modify it under the terms of the GNU Lesser General Public
'    License as published by the Free Software Foundation; either
'    version 2.1 of the License, or (at your option) any later version.
'
'    This library is distributed in the hope that it will be useful,
'    but WITHOUT ANY WARRANTY; without even the implied warranty of
'    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
'    Lesser General Public License for more details.
'
'    You should have received a copy of the GNU Lesser General Public
'    License along with this library; if not, write to the Free Software
'    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
'

Public Cancelled As Boolean

Sub LoadSettings()
On Error Resume Next
    With m_Engine
        If m_booIDE Then
            cmbGraphicsPlugin.ListIndex = 0
        Else
            Select Case LCase(Trim(m_Engine.OutputPlugin))
            Case "ddraw", "directdraw"
                cmbGraphicsPlugin.ListIndex = 1
            Case Else
                cmbGraphicsPlugin.ListIndex = 0
            End Select
        End If
        cmbScreenSize.Text = CStr(.ScreenWidth) + "x" + CStr(.ScreenHeight)
        If Err.Number <> 0 Then
            cmbScreenSize.AddItem CStr(.ScreenWidth) + "x" + CStr(.ScreenHeight)
            cmbScreenSize.Text = CStr(.ScreenWidth) + "x" + CStr(.ScreenHeight)
            Err.Clear
        End If
        If .Fullscreen = False Then
            cmbScreenSize.Text = "Windowed"
        End If
        Err.Clear
        Select Case .BitDepth
        Case 16
            cmbBitDepth.ListIndex = 1
        Case 24
            cmbBitDepth.ListIndex = 2
        Case 32
            cmbBitDepth.ListIndex = 3
        Case Else
            cmbBitDepth.ListIndex = 0
        End Select
        chkVSync.Value = Abs(CInt(.VSync))
        chkDirectRender.Value = Abs(CInt(.DirectRender))
        chkEnableSound.Value = Abs(CInt(Not CBool(.DisableSound)))
    End With
End Sub

Sub SaveSettings()
On Error Resume Next
    With m_Engine
        If cmbGraphicsPlugin.ListIndex = 1 Then
            .OutputPlugin = "DirectDraw"
        Else
            .OutputPlugin = "GDI"
        End If
        If cmbScreenSize.ListIndex = 0 Then
            .Fullscreen = False
            .ScreenWidth = .ScreenWidth
            .ScreenHeight = .ScreenHeight
        ElseIf cmbScreenSize.ListIndex = 1 Then
        Else
            .Fullscreen = True
            .ScreenWidth = CLng(Left(cmbScreenSize.Text, InStr(cmbScreenSize.Text, "x") - 1))
            .ScreenHeight = CLng(Mid(cmbScreenSize.Text, InStr(cmbScreenSize.Text, "x") + 1))
        End If
        Select Case cmbBitDepth.ListIndex
        Case 1
            .BitDepth = 16
        Case 2
            .BitDepth = 24
        Case 3
            .BitDepth = 32
        Case Else
            .BitDepth = -1
        End Select
        .DisableSound = Not CBool(chkEnableSound.Value)
        .VSync = CBool(chkVSync.Value)
        .DirectRender = CBool(chkDirectRender.Value)
    End With
End Sub

Private Sub cmbGraphicsPlugin_Change()
    If cmbGraphicsPlugin.ListIndex = 0 Then
        cmbScreenSize.Enabled = False
        cmbBitDepth.Enabled = False
        chkVSync.Enabled = False
        lblVSync.Enabled = False
        lblScreenMode.Enabled = False
    Else
        cmbScreenSize.Enabled = True
        cmbBitDepth.Enabled = True
        chkVSync.Enabled = True
        lblVSync.Enabled = True
        lblScreenMode.Enabled = True
    End If
End Sub

Private Sub cmbGraphicsPlugin_Click()
    cmbGraphicsPlugin_Change
End Sub

Private Sub cmdCancel_Click()
On Error Resume Next
    Cancelled = True
    Me.Hide
End Sub

Private Sub cmdOK_Click()
    SaveSettings
    Me.Hide
End Sub

Private Sub Form_Load()
    LoadSettings
End Sub

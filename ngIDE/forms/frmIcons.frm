VERSION 5.00
Object = "{396F7AC0-A0DD-11D3-93EC-00C0DFE7442A}#1.0#0"; "vbalIml6.ocx"
Begin VB.Form frmIcons 
   BorderStyle     =   4  'Fixed ToolWindow
   Caption         =   "Icon Container Form"
   ClientHeight    =   540
   ClientLeft      =   45
   ClientTop       =   300
   ClientWidth     =   1620
   ControlBox      =   0   'False
   Icon            =   "frmIcons.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   540
   ScaleWidth      =   1620
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   Visible         =   0   'False
   Begin vbalIml6.vbalImageList ilIcons 
      Left            =   0
      Top             =   0
      _ExtentX        =   953
      _ExtentY        =   953
      ColourDepth     =   8
      Size            =   50512
      Images          =   "frmIcons.frx":000C
      Version         =   131072
      KeyCount        =   44
      Keys            =   $"frmIcons.frx":C57C
   End
   Begin vbalIml6.vbalImageList ilWindowIcons 
      Left            =   540
      Top             =   0
      _ExtentX        =   953
      _ExtentY        =   953
      ColourDepth     =   8
   End
   Begin vbalIml6.vbalImageList ilPluginIcons 
      Left            =   1080
      Top             =   0
      _ExtentX        =   953
      _ExtentY        =   953
      ColourDepth     =   8
   End
End
Attribute VB_Name = "frmIcons"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'
'    ngIDE (Fury� Game Creation System Next-Generation Editor)
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

Option Explicit


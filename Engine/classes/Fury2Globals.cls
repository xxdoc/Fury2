VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Fury2Globals"
Attribute VB_GlobalNameSpace = True
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Attribute VB_Description = "Fury� Global Functions/Values/Etc"
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Attribute VB_Ext_KEY = "Member0" ,"Fury2Engine"
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

Public Enum Fury2ScreenScaleModes
    SSM_Fast = 0
    SSM_Bilinear = 1
    SSM_2xSaI = 2
    SSM_HQnX = 3
End Enum

Public Enum Fury2WindowSkinSections
    WS_TopLeft = 0
    WS_Top = 1
    WS_TopRight = 2
    WS_Right = 3
    WS_BottomRight = 4
    WS_Bottom = 5
    WS_BottomLeft = 6
    WS_Left = 7
    WS_Middle = 8
End Enum

Public Enum Fury2CollisionTypes
    CT_None = 0
    CT_Tile = 1
    CT_Line = 2
    CT_Rectangle = 3
End Enum

Public Enum Fury2EngineModes
    EM_Normal = 0
    EM_Library = 1
End Enum

Public Enum Fury2ControllerStyles
    CS_Normal = 0
    CS_ResidentEvil = 1
    CS_Platformer = 2
    CS_HorizontalShooter = 3
    CS_VerticalShooter = 4
End Enum

Public Enum Fury2TransitionTypes
    TR_None = 0
    TR_Fade = 1
    TR_Crossfade = 2
    TR_SmoothFadeLeft = 3
    TR_SmoothFadeRight = 4
    TR_SmoothFadeUp = 5
    TR_SmoothFadeDown = 6
    TR_SlideLeft = 7
    TR_SlideRight = 8
    TR_SlideUp = 9
    TR_SlideDown = 10
    TR_CircleIn = 11
End Enum

Public Enum Fury2SpriteEffects
    F2SB_Matte
    F2SB_Alpha
    F2SB_Additive
    F2SB_Subtractive
    F2SB_Gamma
    F2SB_Screen
    F2SB_Multiply
    F2SB_Lightmap
    F2SB_Merge
End Enum

Public Enum Fury2SpriteClasses
    F2SC_Null = -1
    F2SC_Normal = 0
    F2SC_PartyMember = 1
    F2SC_NPC = 2
    F2SC_Monster = 3
    F2SC_Object = 4
    F2SC_Projectile = 5
    F2SC_Effect = 6
    F2SC_Item = 7
    F2SC_Sign = 8
    F2SC_Door = 9
    F2SC_Doodad = 10
End Enum

Public Enum Fury2SpriteTypes
    F2ST_Entity = 0
    F2ST_Object = 1
    F2ST_Projectile = 2
    F2ST_Effect = 3
    F2ST_Ghost = 4
End Enum

Public Enum Fury2BehaviorTypes
    F2BH_None
    F2BH_Script
    F2BH_Fade
    F2BH_Translate
End Enum

Public Enum Fury2LoopModes
    F2LM_OneShot
    F2LM_Restart
    F2LM_PingPong
End Enum

Public Enum Fury2TimerEventTypes
    F2TE_Normal
    F2TE_Exact
End Enum

Public Function Engine() As Fury2Engine
Attribute Engine.VB_Description = "Returns the current Fury� Engine object."
    Set Engine = m_Engine
End Function

Sub Fury2Initialize(Optional Editor As Boolean = False)
Attribute Fury2Initialize.VB_Description = "Initializes the engine library."
On Error Resume Next
    F2Init
    Randomize Timer
    m_booEditor = Editor
    SetProfilerCallbacks AddressOf ProfileClear, AddressOf ProfilePrint, AddressOf ProfileQuery
    Set m_Engine = New Fury2Engine
End Sub

Sub Fury2Terminate()
Attribute Fury2Terminate.VB_Description = "Unloads the library from memory."
    If InIDE Then Else TerminateProcess GetCurrentProcess, 0
End Sub

Public Property Get Fury2Engine() As Fury2Engine
On Error Resume Next
    Set Fury2Engine = m_Engine
End Property

Sub Fury2Hook(Obj As Object)
Attribute Fury2Hook.VB_Description = "Sets the object that will recieve notification of engine events."
On Error Resume Next
    m_Engine.HookEvents Obj
End Sub

Function Fury2Load(Optional Parameters As String = "", Optional Mode As Fury2EngineModes = EM_Normal, Optional Notify As Object = Nothing, Optional Window As Long = 0) As Fury2Engine
On Error Resume Next
    Set m_Notify = Notify
    Select Case Mode
    Case EM_Library
        Fury2Initialize True
        m_booEditor = True
        m_Engine.HideLog = True
        mdlFury2.Main Parameters
    Case Else
        Fury2Initialize False
        #If DebugFeatures = 1 Then
            frmLog.Show
        #End If
        mdlFury2.Main Parameters
    End Select
    Err.Clear
    Set Fury2Load = m_Engine
End Function

Sub Fury2Shutdown()
Attribute Fury2Shutdown.VB_Description = "Shuts down the engine library."
On Error Resume Next
    DoEvents
    DoEvents
    DoEvents
    m_Engine.iTerminate
    Set m_Engine = Nothing
    F2Shutdown
End Sub

Public Function SaveToFile(ByRef Obj As Object, ByRef File As Object) As Boolean
On Error Resume Next
Dim m_vfFile As VirtualFile
    If Obj Is Nothing Then Exit Function
    Err.Clear
    If TypeOf File Is Fury2File Then
        Set m_vfFile = New VirtualFile
    ElseIf TypeOf File Is VirtualFile Then
        Set m_vfFile = File
    End If
    m_vfFile.Save g_strHeader
    m_vfFile.Save Obj
    If TypeOf File Is Fury2File Then
        If Err = 0 Then File.Save m_vfFile
    End If
    Set m_vfFile = Nothing
    If Err.Number <> 0 Then Exit Function
    SaveToFile = True
End Function

Public Function LoadFromFile(ByRef Obj As Object, ByRef File As Object) As Boolean
On Error Resume Next
Dim m_vfFile As VirtualFile
    If Obj Is Nothing Then Exit Function
    Err.Clear
    If TypeOf File Is Fury2File Then
        Set m_vfFile = File.Load
    ElseIf TypeOf File Is VirtualFile Then
        Set m_vfFile = File
    End If
    If ValidateFileHeader(m_vfFile) Then
        m_vfFile.Load Obj
    Else
        Exit Function
    End If
    Set m_vfFile = Nothing
    If Err.Number <> 0 Then Exit Function
    LoadFromFile = True
End Function

Public Function SaveToFileWithRevisions(ByRef Obj As Fury2TrackedObject, ByRef File As Object) As Boolean
On Error Resume Next
Dim m_vfFile As VirtualFile
    If Obj Is Nothing Then Exit Function
    Err.Clear
    If TypeOf File Is Fury2File Then
        Set m_vfFile = New VirtualFile
    ElseIf TypeOf File Is VirtualFile Then
        Set m_vfFile = File
    End If
    m_vfFile.Save g_strHeader
    m_vfFile.Save Obj
    m_vfFile.Save Obj.Revision
    If TypeOf File Is Fury2File Then
        If Err = 0 Then File.Save m_vfFile
    End If
    Set m_vfFile = Nothing
    If Err.Number <> 0 Then Exit Function
    SaveToFileWithRevisions = True
End Function

Public Function LoadFromFileWithRevisions(ByRef Obj As Fury2TrackedObject, ByRef File As Object) As Boolean
On Error Resume Next
Dim m_vfFile As VirtualFile
    If Obj Is Nothing Then Exit Function
    Err.Clear
    If TypeOf File Is Fury2File Then
        Set m_vfFile = File.Load
    ElseIf TypeOf File Is VirtualFile Then
        Set m_vfFile = File
    End If
    If ValidateFileHeader(m_vfFile) Then
        m_vfFile.Load Obj
        m_vfFile.Load Obj.Revision
    Else
        Exit Function
    End If
    Set m_vfFile = Nothing
    If Err.Number <> 0 Then Exit Function
    LoadFromFileWithRevisions = True
End Function

Public Function GetEngineVersion() As String
Attribute GetEngineVersion.VB_Description = "Returns the version of the library."
On Error Resume Next
    GetEngineVersion = "Fury� " + Choose(App.Major + 1, "Alpha", "Beta", "Prototype") + " RC" + CStr(App.Minor) + " Build " + CStr(App.Revision)
End Function

Function ToBoolean(Value) As Boolean
On Error Resume Next
    Err.Clear
    ToBoolean = CBool(Value)
    If VarType(Value) = vbObject Then
        If Err = 0 Then Exit Function
        Err.Clear
        ToBoolean = Value.ToBoolean
        If Err = 0 Then Exit Function
        Err.Clear
        ToBoolean = Value.Class_ToBoolean
        If Err = 0 Then Exit Function
        Err.Clear
        ToBoolean = Value.ToNumber
        If Err = 0 Then Exit Function
        Err.Clear
        ToBoolean = Value.Class_ToNumber
        If Err = 0 Then Exit Function
        Err.Clear
        ToBoolean = Value.ToInteger
        If Err = 0 Then Exit Function
        Err.Clear
        ToBoolean = Value.Class_ToInteger
        If Err = 0 Then Exit Function
        Err.Raise 10241, "ToBoolean()", "Unable to convert object to boolean"
    End If
End Function

Function ToInteger(Value) As Long
On Error Resume Next
    If (VarType(Value) = vbLong) Then
        ToInteger = Value
        Exit Function
    ElseIf (VarType(Value) = vbSingle) Then
        ToInteger = Value
        Exit Function
    ElseIf (VarType(Value) = vbDouble) Then
        ToInteger = Value
        Exit Function
    End If
    Err.Clear
    ToInteger = CLng(Value)
    If VarType(Value) = vbObject Then
        If Err = 0 Then Exit Function
        Err.Clear
        ToInteger = Value.ToInteger
        If Err = 0 Then Exit Function
        Err.Clear
        ToInteger = Value.Class_ToInteger
        If Err = 0 Then Exit Function
        Err.Clear
        ToInteger = Value.ToNumber
        If Err = 0 Then Exit Function
        Err.Clear
        ToInteger = Value.Class_ToNumber
        If Err = 0 Then Exit Function
        Err.Clear
        ToInteger = Value.ToBoolean
        If Err = 0 Then Exit Function
        Err.Clear
        ToInteger = Value.Class_ToBoolean
        If Err = 0 Then Exit Function
        Err.Raise 10241, "ToInteger()", "Unable to convert object to integer"
    End If
End Function

Function ToNumber(Value) As Double
On Error Resume Next
    If (VarType(Value) = vbDouble) Then
        ToNumber = Value
        Exit Function
    ElseIf (VarType(Value) = vbSingle) Then
        ToNumber = Value
        Exit Function
    ElseIf (VarType(Value) = vbLong) Then
        ToNumber = Value
        Exit Function
    End If
    ToNumber = CDbl(Value)
    If VarType(Value) = vbObject Then
        If Err = 0 Then Exit Function
        Err.Clear
        ToNumber = Value.ToNumber
        If Err = 0 Then Exit Function
        Err.Clear
        ToNumber = Value.Class_ToNumber
        If Err = 0 Then Exit Function
        Err.Clear
        ToNumber = Value.ToInteger
        If Err = 0 Then Exit Function
        Err.Clear
        ToNumber = Value.Class_ToInteger
        If Err = 0 Then Exit Function
        Err.Clear
        ToNumber = Value.ToBoolean
        If Err = 0 Then Exit Function
        Err.Clear
        ToNumber = Value.Class_ToBoolean
        If Err = 0 Then Exit Function
        Err.Raise 10241, "ToNumber()", "Unable to convert object to number"
    End If
End Function

Function ToString(Value, Optional QuoteStrings As Boolean = False) As String
On Error Resume Next
Dim l_vtType As VariantTypeConstants
    l_vtType = VarType(Value)
    If l_vtType = vbEmpty Then
        ToString = "{Empty}"
    ElseIf l_vtType = vbNull Then
        ToString = "{Null}"
    ElseIf (l_vtType And vbArray) = vbArray Then
        If UBound(Value) > 64 Then
            ToString = "{Array}"
        Else
            If QuoteStrings Then
                ToString = "{" + JoinX(Value, ", ", QuoteStrings) + "}"
            Else
                ToString = JoinX(Value, , QuoteStrings)
            End If
        End If
    ElseIf (l_vtType = vbSingle) Or (l_vtType = vbDouble) Then
        ToString = Format(Value, "##############0.0##############")
    ElseIf l_vtType = vbString Then
        If QuoteStrings Then
            ToString = """" + Value + """"
        Else
            ToString = Value
        End If
    ElseIf l_vtType = vbObject Then
        If Value Is Nothing Then
            ToString = "{Nothing}"
        Else
            Err.Clear
            ToString = "{Object}"
            ToString = IIf(QuoteStrings, """", "") & CStr(Value.ToString()) & IIf(QuoteStrings, """", "")
            If Err = 0 Then Exit Function
            Err.Clear
            ToString = IIf(QuoteStrings, """", "") & CStr(Value.Class_ToString()) & IIf(QuoteStrings, """", "")
            If Err = 0 Then Exit Function
            Err.Clear
            ToString = CStr(ToNumber(Value))
            If Err = 0 Then Exit Function
            Err.Clear
            ToString = "{Object: " + TypeName(Value) + "}"
        End If
    ElseIf l_vtType = vbUserDefinedType Then
        ToString = "{UDT}"
    Else
        ToString = "{Unknown}"
        Err.Clear
        ToString = CStr(Value)
        If Err <> 0 Then ToString = "{Unknown}"
    End If
End Function

Function JoinX(Arr As Variant, Optional ByVal Delimiter As String = " ", Optional ByVal QuoteStrings As Boolean = False) As String
On Error Resume Next
Dim m_lngLB As Long, m_lngUB As Long, m_lngCount As Long
Dim m_lngItems As Long
    JoinX = ""
    Err.Clear
    If (VarType(Arr) And vbArray) <> vbArray Then Exit Function
    m_lngLB = LBound(Arr)
    m_lngUB = UBound(Arr)
    m_lngCount = (m_lngUB - m_lngLB) + 1
    If Err <> 0 Or m_lngUB < 0 Then Exit Function
    For m_lngItems = m_lngLB To m_lngUB
        JoinX = JoinX + ToString(Arr(m_lngItems), True)
        If m_lngItems < m_lngUB Then
            JoinX = JoinX + Delimiter
        End If
    Next m_lngItems
    Err.Clear
End Function

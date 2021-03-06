VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Fury2Filesystem"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Attribute VB_Description = "A virtual filesystem."
'
'    libFilesystem (Fury� Virtual Filesystem Library)
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
Option Compare Text

Private m_strRoot As String
Private m_strCurrentFolder As String
Private m_colDeletionQueue As Collection
Private m_colFolderDeletionQueue As Collection

Private m_colModules As Fury2Collection

Private m_modRoot As Fury2DiskFolder

Public FileHook As Object
Public OutputHook As Object
Public OverwriteReadOnlyFiles As Boolean

Public Function MountDiskFolder(ByRef Path As String, Optional ByRef MountPoint As String = "/") As Fury2DiskFolder
On Error Resume Next
Dim l_dfModule As Fury2DiskFolder
Dim l_modModule As Fury2FSModule
    Set l_dfModule = New Fury2DiskFolder
    l_dfModule.SetFilesystem Me
    l_dfModule.SetPath Path
    Set l_modModule = l_dfModule
    l_modModule.MountPoint = MountPoint
    Set MountDiskFolder = l_modModule
    LoadModule l_modModule
End Function

Public Property Get Modules() As Fury2Collection
On Error Resume Next
    Set Modules = m_colModules
End Property

Public Sub LoadModule(ByVal Module As Fury2FSModule)
On Error Resume Next
    If m_colModules.Find(Module) Then
    Else
        m_colModules.Add Module
    End If
End Sub

Public Sub UnloadModule(ByVal Module As Fury2FSModule)
On Error Resume Next
    m_colModules.RemoveObject Module
End Sub

Friend Sub LogMessage(Message As String)
On Error Resume Next
    Debug.Print Message
    OutputHook.TextOut Message
End Sub

Friend Sub LogError(Error As String)
On Error Resume Next
    Debug.Print Error
    OutputHook.DebugOut Error
End Sub

Public Function AutoSelectExtension(ByVal Filename As String, Optional ByVal Extensions As String = "*") As String
On Error Resume Next
Dim l_varExtensions As Variant, l_lngExtensions As Long
    Filename = Replace(Filename, "\", "/")
    If FileExists(Filename) Then
        AutoSelectExtension = Filename
        Exit Function
    End If
    l_varExtensions = Split(Extensions, ";")
    For l_lngExtensions = LBound(l_varExtensions) To UBound(l_varExtensions)
        If FileExists(Filename + "." + l_varExtensions(l_lngExtensions)) Then
            AutoSelectExtension = Filename + "." + l_varExtensions(l_lngExtensions)
            Exit Function
        End If
    Next l_lngExtensions
    AutoSelectExtension = Filename
End Function

Public Function PathMatch(ByVal Match As String, ByVal Pattern As String, Optional ByVal Recursive As Boolean = False)
Attribute PathMatch.VB_Description = "Returns True if Match matches Pattern, or if Match is a subfolder of Pattern and Recursive is True."
On Error Resume Next
    ' Clean up the inputs
    Match = Replace(Match, "\", "/")
    If Trim(Match) = "" Then Match = "/"
    If Left(Match, 1) <> "/" Then Match = "/" + Match
    If Right(Match, 1) <> "/" Then Match = Match + "/"
    If Left(Pattern, 1) <> "/" Then Pattern = "/" + Pattern
    If (Right(Pattern, 1) <> "/") And (Right(Pattern, 1) <> "*") Then Pattern = Pattern + "/"
    If Recursive Then
        ' If recursive, only compare the beginning
        If InStr(Match, "/") <> InStrRev(Match, "/") Then
            PathMatch = Left(Match, InStr(2, Match, "/") - 1) Like Pattern
        Else
            PathMatch = Match Like Pattern
        End If
    Else
        ' Otherwise compare the whole strings
        PathMatch = (Match Like Pattern) And (UBound(Split(Match, "/")) <= UBound(Split(Pattern, "/")))
    End If
End Function

Public Function GetFullPath(ByVal Filename As String) As String
Attribute GetFullPath.VB_Description = "Returns the path part of a filename, or the current search folder if no path is specified in the filename."
On Error Resume Next
Dim l_lngPosition As Long
    l_lngPosition = InStrRev(Filename, "/")
    If l_lngPosition Then
        ' If the filename contains a path, return it
        GetFullPath = Left(Filename, l_lngPosition)
        If Left(GetFullPath, 1) = "/" Then
        Else
            GetFullPath = CurrentFolder + GetFullPath
        End If
    Else
        ' Otherwise just return the current folder
        GetFullPath = CurrentFolder
    End If
End Function

Public Function GetPath(ByVal Filename As String) As String
Attribute GetPath.VB_Description = "Returns the path part of a filename."
On Error Resume Next
Dim l_lngPosition As Long
    l_lngPosition = InStrRev(Filename, "/")
    If l_lngPosition Then
        ' If the filename contains a path, return it
        GetPath = Left(Filename, l_lngPosition)
    Else
        ' Otherwise just return /
        GetPath = "/"
    End If
End Function

Public Function GetTitle(ByVal Filename As String) As String
Attribute GetTitle.VB_Description = "Returns the title part of a filename."
On Error Resume Next
Dim l_lngPosition As Long
    l_lngPosition = InStrRev(Filename, "/")
    If l_lngPosition Then
        GetTitle = Mid(Filename, l_lngPosition + 1)
    Else
        GetTitle = Filename
    End If
End Function

Public Function GetExtension(ByVal Filename As String) As String
On Error Resume Next
Dim l_lngPosition As Long
    l_lngPosition = InStrRev(Filename, ".")
    If l_lngPosition Then
        GetExtension = Mid(Filename, l_lngPosition + 1)
    Else
        GetExtension = ""
    End If
End Function

Public Function RealFileExists(ByVal Filename As String) As Boolean
Attribute RealFileExists.VB_Description = "Returns True if the specified file exists on the hard disk."
Attribute RealFileExists.VB_MemberFlags = "40"
On Error Resume Next
Dim l_strLocalPath As String, l_lngLength As Long
    l_strLocalPath = Replace(Replace(m_strRoot + Filename, "/", "\"), "\\", "\")
    RealFileExists = False
    RealFileExists = Trim(Dir(l_strLocalPath)) <> ""
    Err.Clear
End Function

Public Function FileExists(ByVal Filename As String) As Boolean
Attribute FileExists.VB_Description = "Returns True if the specified file exists."
On Error Resume Next
Dim l_strFilename As String
Dim l_strPath As String
Dim l_modModule As Fury2FSModule
    If InStr(Filename, "\") Then
        OutputHook.DebugOut "Malformed filename used: " & Filename
    End If
    
    Filename = Replace(Filename, "\", "/")
        
    If Left(Filename, 1) <> "/" Then Filename = CurrentFolder + Filename
        
    If Not (FileHook Is Nothing) Then FileHook.Invoke CStr(Filename)
    
    For Each l_modModule In m_colModules
        If l_modModule.Enabled Then
            If InStr(Filename, l_modModule.MountPoint) Then
                If l_modModule.FileExists(ReplaceFirst(Filename, l_modModule.MountPoint, "/")) Then
                    FileExists = True
                    Exit For
                End If
            End If
        End If
    Next l_modModule
End Function

Public Function FolderExists(ByVal Path As String) As Boolean
Attribute FolderExists.VB_Description = "Returns True if the specified folder exists."
On Error Resume Next
Dim l_strFilename As String
Dim l_strPath As String
Dim l_modModule As Fury2FSModule
    
    Path = Replace(Path, "\", "/")
    
    If Trim(Path) = "" Then Path = CurrentFolder
    Path = LCase(Trim(Path))
    If Left(Path, 1) <> "/" Then Path = CurrentFolder + Path
    If Right(Path, 1) <> "/" Then Path = Path + "/"
    
    For Each l_modModule In m_colModules
        If l_modModule.Enabled Then
            If InStr(Path, l_modModule.MountPoint) Then
                If l_modModule.FolderExists(ReplaceFirst(Path, l_modModule.MountPoint, "/")) Then
                    FolderExists = True
                    Exit For
                End If
            End If
        End If
    Next l_modModule
    
End Function

Public Function TranslateFilename(ByVal Filename As String) As String
Attribute TranslateFilename.VB_Description = "Converts a Local (filesystem) filename to a Real (hard disk) filename."
Attribute TranslateFilename.VB_MemberFlags = "40"
On Error Resume Next
    Filename = Trim(Filename)
    If Left(Filename, 1) = "/" Then ' Virtual path
        TranslateFilename = TranslateFilename(m_strRoot + Mid(Filename, 2))
    ElseIf InStr(Filename, ":") Then ' Real path
        TranslateFilename = Replace(Filename, "/", "\")
    Else ' Local path
        TranslateFilename = TranslateFilename(CurrentFolder + Filename)
    End If
End Function
'
'Public Function LoadPackage(ByVal Filename) As Fury2Package2
'On Error Resume Next
'#If SawZIP = 1 Then
'If EnablePackages Then
'Dim l_pkgPackage As Fury2Package2
'    Set l_pkgPackage = Package(Filename)
'    If l_pkgPackage Is Nothing Then
'        Err.Clear
'        Set l_pkgPackage = New Fury2Package2
'        l_pkgPackage.SetFilesystem Me
'        l_pkgPackage.OpenPackage CStr(Filename)
'        If Err <> 0 Then
'            LogError "Unable to load package " + Filename + "."
'        Else
'            If Left(Filename, 1) = "_" Then
'                ' Add at the end. Used for 'last-chance' packages
'                m_colPackages.Add l_pkgPackage, LCase(Trim(Filename))
'                m_lngLastPackages = m_lngLastPackages + 1
'            ElseIf InStr(Filename, "_") Then
'                ' Replace with sorted insertion, based on version suffix
'                m_colPackages.Add l_pkgPackage, LCase(Trim(Filename))
'                m_lngPatchPackages = m_lngPatchPackages + 1
'            Else
'                m_colPackages.Add l_pkgPackage, LCase(Trim(Filename))
'                m_lngPackages = m_lngPackages + 1
'            End If
'        End If
'    End If
'    Set LoadPackage = l_pkgPackage
'End If
'#End If
'End Function

Public Function EnumFiles(Optional ByVal Path = "", Optional ByVal Filter = "*.*", Optional ByVal Recursive = False) As Fury2Files
Attribute EnumFiles.VB_Description = "Returns a Fury2Files object containing all the files that match the specified requirements."
On Error Resume Next
Dim l_modModule As Fury2FSModule
Dim l_feFiles() As FileEnumerationEntry
Dim l_lngFileCount As Long
Dim l_lngBufferSize As Long
Dim l_lngIndex As Long
Dim l_flsFiles As Fury2Files

    ' Allocate a file buffer with 16 entries (enough for most searches and fast to allocate)
    ReDim l_feFiles(0 To 15)
    l_lngFileCount = 0

    ' Fix up the path
    Path = Replace(Path, "\", "/")
    If Trim(Path) = "" Then Path = CurrentFolder
    Path = LCase(Trim(Path))
    If Left(Path, 1) <> "/" Then Path = CurrentFolder + Path
    If Right(Path, 1) <> "/" Then Path = Path + "/"

    ' Fix up the filter
    If Trim(Filter) = "" Then Filter = "*.*"
    
    For Each l_modModule In m_colModules
        If l_modModule.Enabled Then
            If StartsWith(CStr(Path), l_modModule.MountPoint) Then
                l_modModule.EnumFiles ReplaceFirst(CStr(Path), l_modModule.MountPoint, "/"), CStr(Path), l_lngFileCount, Filter, Recursive, l_feFiles
            End If
        End If
    Next l_modModule
    
    Set l_flsFiles = New Fury2Files

    ' If there were any files retrieved
    If l_lngFileCount > 0 Then
        ' Resize the files buffer to its actual number of used entries
        ReDim Preserve l_feFiles(0 To l_lngFileCount - 1)
        ' Give a copy of the files buffer to the class
        l_flsFiles.SetData l_feFiles, Me
        ' Erase our copy
        Erase l_feFiles
    End If

    Set EnumFiles = l_flsFiles
End Function

Public Function EnumFolders(Optional ByVal Filter = "*", Optional ByVal Recursive = False) As Fury2Folders
Attribute EnumFolders.VB_Description = "Returns a Fury2Folders object containing all the folders that match the specified requirements."
On Error Resume Next
Dim l_modModule As Fury2FSModule
Dim l_feFolders() As FolderEnumerationEntry
Dim l_lngFolderCount As Long
Dim l_lngBufferSize As Long
Dim l_strPath As String
Dim l_lngFolders As Long
Dim l_fdsFolders As Fury2Folders
    
    ' Allocate a folder buffer with 16 entries (enough for most searches and fast to allocate)
    ReDim l_feFolders(0 To 15)
    l_lngBufferSize = 16
    l_lngFolderCount = 0

    ' Fix up the filter
    Filter = Replace(Filter, "\", "/")
    If Trim(Filter) = "" Then Filter = "*"
    If Left(Filter, 1) <> "/" Then
        Filter = CurrentFolder & Filter
    End If
    
    For Each l_modModule In m_colModules
        If l_modModule.Enabled Then
            If StartsWith(CStr(Filter), l_modModule.MountPoint) Then
                l_modModule.EnumFolders ReplaceFirst(CStr(Filter), l_modModule.MountPoint, "/"), GetPath(CStr(Filter)), l_lngFolderCount, Recursive, l_feFolders
            End If
        End If
    Next l_modModule
    
    Set l_fdsFolders = New Fury2Folders

    ' If there were any folders retrieved
    If l_lngFolderCount > 0 Then
        ' Resize the folders buffer to its actual number of used entries
        ReDim Preserve l_feFolders(0 To l_lngFolderCount - 1)
        ' Give a copy of the folders buffer to the class
        l_fdsFolders.SetData l_feFolders, Me
        ' Erase our copy
        Erase l_feFolders
    End If

    Set EnumFolders = l_fdsFolders

End Function


Public Property Get Root() As String
Attribute Root.VB_Description = "The root folder used by the filesystem on the local machine."
Attribute Root.VB_MemberFlags = "40"
On Error Resume Next
    Root = m_strRoot
End Property

Public Property Let Root(NewRoot As String)
On Error Resume Next
    m_strRoot = NewRoot
    If Right(m_strRoot, 1) <> "\" Then m_strRoot = m_strRoot + "\"
    If Not (m_modRoot) Is Nothing Then m_modRoot.SetPath m_strRoot
    CurrentFolder = "/"
End Property

Public Property Get CurrentFolder() As String
Attribute CurrentFolder.VB_Description = "The current default search folder for the filesystem."
On Error Resume Next
    CurrentFolder = m_strCurrentFolder
End Property

Public Property Let CurrentFolder(NewFolder As String)
On Error Resume Next
    m_strCurrentFolder = NewFolder
End Property

' Recursive, like cd or chdir
Public Sub ChangeFolder(ByVal NewDir As String)
Attribute ChangeFolder.VB_Description = "Changes the current default search folder of the filesystem. (Like chdir/cd.)"
On Error Resume Next
Dim l_lngPos As Long
Dim l_strPiece As String
    If Left(NewDir, 1) = "/" Then
        CurrentFolder = NewDir + IIf(Right(NewDir, 1) = "/", "", "/")
        Exit Sub
    End If
    Do
        l_lngPos = InStr(NewDir, "/")
        If l_lngPos = 0 Then
            l_strPiece = NewDir
            NewDir = ""
        Else
            l_strPiece = Left(NewDir, l_lngPos - 1)
            NewDir = Mid(NewDir, l_lngPos + 1)
        End If
        Select Case l_strPiece
        Case ".."
            If InStr(CurrentFolder, "/") = InStrRev(CurrentFolder, "/") Then
            Else
                CurrentFolder = Left(CurrentFolder, InStrRev(CurrentFolder, "/") - 1)
                CurrentFolder = Left(CurrentFolder, InStrRev(CurrentFolder, "/"))
            End If
        Case "."
        Case Else
            If FolderExists(CurrentFolder + l_strPiece + "/") Then
                CurrentFolder = CurrentFolder + l_strPiece + "/"
            Else
                LogError "Folder " + CurrentFolder + l_strPiece + "/" + " does not exist."
            End If
        End Select
        If l_lngPos = 0 Then Exit Do
    Loop
End Sub

Public Property Get FolderCount() As Long
On Error Resume Next
Dim l_modModule As Fury2FSModule
Dim l_lngCount As Long
    For Each l_modModule In m_colModules
        If l_modModule.Enabled Then l_lngCount = l_lngCount + l_modModule.FolderCount
    Next l_modModule
    FolderCount = l_lngCount
End Property

Public Property Get FileCount() As Long
Attribute FileCount.VB_Description = "Returns the number of files currently available in the filesystem."
On Error Resume Next
Dim l_modModule As Fury2FSModule
Dim l_lngCount As Long
    For Each l_modModule In m_colModules
        If l_modModule.Enabled Then l_lngCount = l_lngCount + l_modModule.FileCount
    Next l_modModule
    FileCount = l_lngCount
End Property

Public Function CreateFile(ByVal Filename As String) As Fury2File
On Error Resume Next
Dim l_modModule As Fury2FSModule
Dim l_filFile As Fury2File
Dim l_feFile As FileEnumerationEntry
    Set l_filFile = File(Filename)
    If l_filFile Is Nothing Then
        If Left(Filename, 1) <> "/" Then Filename = CurrentFolder + Filename
        For Each l_modModule In m_colModules
            If l_modModule.Enabled Then
                If StartsWith(CStr(Filename), l_modModule.MountPoint) Then
                    Set l_feFile.Parent = l_modModule
                    l_feFile.Filename = ReplaceFirst(Filename, l_modModule.MountPoint, "/")
                    Set l_filFile = New Fury2File
                    l_filFile.SetData l_feFile, Me
                    CreateEmptyFile l_filFile.GetRealFilename
                    Set l_filFile = File(Filename)
                    Exit For
                End If
            End If
        Next l_modModule
    End If
    Set CreateFile = l_filFile
End Function

Public Property Get File(ByVal Index) As Fury2File
Attribute File.VB_Description = "Returns a Fury2File object for the requested file. (You can pass either a string or a number into this property.)"
Attribute File.VB_UserMemId = 0
Attribute File.VB_MemberFlags = "200"
On Error Resume Next
Dim l_modModule As Fury2FSModule
Dim l_lngIndex As Long
Dim l_lngCount As Long, l_lngModuleCount As Long
Dim l_filFile As Fury2File
Dim l_feFile As FileEnumerationEntry
    If VarType(Index) = vbString Then
        If InStr(Index, "\") Then
            OutputHook.DebugOut "Malformed filename used: " & Index
        End If
        If Left(Index, 1) <> "/" Then Index = CurrentFolder + Index
        For Each l_modModule In m_colModules
            If l_modModule.Enabled Then
                If StartsWith(CStr(Index), l_modModule.MountPoint) Then
                    If l_modModule.FileExists(ReplaceFirst(CStr(Index), l_modModule.MountPoint, "/")) Then
                        l_feFile = l_modModule.NamedFile(ReplaceFirst(CStr(Index), l_modModule.MountPoint, "/"))
                        If l_feFile.Filename = vbNullString Then Exit Property
                        Set l_filFile = New Fury2File
                        l_filFile.SetData l_feFile, Me
                        Set File = l_filFile
                        Exit For
                    End If
                End If
            End If
        Next l_modModule
    Else
        l_lngIndex = Index - 1
        For Each l_modModule In m_colModules
            If l_modModule.Enabled Then
                l_lngModuleCount = l_modModule.FileCount
                If (l_lngIndex >= l_lngCount) And (l_lngIndex < l_lngCount + l_lngModuleCount) Then
                    l_feFile = l_modModule.File(l_lngIndex - l_lngCount)
                    If l_feFile.Filename = vbNullString Then Exit Property
                    Set l_filFile = New Fury2File
                    l_filFile.SetData l_feFile, Me
                    Set File = l_filFile
                    Exit For
                End If
                l_lngCount = l_lngCount + l_lngModuleCount
            End If
        Next l_modModule
    End If
End Property

Public Property Get Folder(ByVal Index) As Fury2Folder
On Error Resume Next
Dim l_modModule As Fury2FSModule
Dim l_lngIndex As Long
Dim l_lngCount As Long, l_lngModuleCount As Long
Dim l_fldFolder As Fury2Folder
Dim l_feFolder As FolderEnumerationEntry
    If VarType(Index) = vbString Then
        If Left(Index, 1) <> "/" Then Index = CurrentFolder + Index
        If Right(Index, 1) <> "/" Then Index = Index + "/"
        For Each l_modModule In m_colModules
            If l_modModule.Enabled Then
                If StartsWith(CStr(Index), l_modModule.MountPoint) Then
                    If l_modModule.FolderExists(ReplaceFirst(CStr(Index), l_modModule.MountPoint, "/")) Then
                        l_feFolder = l_modModule.NamedFolder(ReplaceFirst(CStr(Index), l_modModule.MountPoint, "/"))
                        If l_feFolder.Path = vbNullString Then Exit Property
                        Set l_fldFolder = New Fury2Folder
                        l_fldFolder.SetData l_feFolder
                        Set Folder = l_fldFolder
                        Exit For
                    End If
                End If
            End If
        Next l_modModule
    Else
        l_lngIndex = Index - 1
        For Each l_modModule In m_colModules
            If l_modModule.Enabled Then
                l_lngModuleCount = l_modModule.FolderCount
                If (l_lngIndex >= l_lngCount) And (l_lngIndex < l_lngCount + l_lngModuleCount) Then
                    l_feFolder = l_modModule.Folder(l_lngIndex - l_lngCount)
                    If l_feFolder.Path = vbNullString Then Exit Property
                    Set l_fldFolder = New Fury2Folder
                    l_fldFolder.SetData l_feFolder
                    Set Folder = l_fldFolder
                    Exit For
                End If
                l_lngCount = l_lngCount + l_lngModuleCount
            End If
        Next l_modModule
    End If
End Property

' Internal functions

Public Function GetFile(Filename As String) As String
Attribute GetFile.VB_Description = "Returns the local path of a file if it is already extracted."
Attribute GetFile.VB_MemberFlags = "40"
On Error Resume Next
Dim l_strLocalPath As String, l_lngLength As Long
    If InStr(Filename, "\") Then
        OutputHook.DebugOut "Malformed filename used: " & Filename
    End If
    l_strLocalPath = Replace(Replace(m_strRoot + Filename, "/", "\"), "\\", "\")
    l_lngLength = -1
    Err.Clear
    l_lngLength = FileLen(l_strLocalPath)
    If l_lngLength >= 0 Then
        GetFile = l_strLocalPath
    Else
        GetFile = ""
    End If
End Function

Public Function ExtractFile(Filename As String) As String
Attribute ExtractFile.VB_Description = "Extracts a file and returns its local path."
#If SawZIP = 1 Then
If EnablePackages Then
On Error Resume Next
Dim l_strFilename As String
Dim l_strPath As String
Dim l_flsFiles As Fury2Files
Dim l_pkgPackage As Fury2Package2
Dim l_filFile As SAWZIPLib.File
Dim l_strLocalPath As String, l_lngLength As Long

    ' Check if it's already extracted
    ExtractFile = GetFile(Filename)
    If ExtractFile <> "" Then Exit Function
    Filename = GetFullPath(Filename) + GetTitle(Filename)

    ' Enumerate all loaded packages
    For Each l_pkgPackage In m_colPackages
        With l_pkgPackage.Archive
            ' Enumerate all files in the package
            For Each l_filFile In .Files
                With l_filFile

                    ' Get the name and properly format it
                    l_strFilename = l_pkgPackage.MountPoint + Replace(.Name, "\", "/")
                    If l_strFilename = Filename Then
                        ' Extract and return local path
                        CreateFolderTree Replace(Replace(m_strRoot + CurrentFolder + l_pkgPackage.MountPoint, "/", "\"), "\\", "\")
                        ExtractFile = .Extract(Replace(Replace(m_strRoot + CurrentFolder + l_pkgPackage.MountPoint, "/", "\"), "\\", "\"))
                        QueueFoldersForDeletion GetFullPath(l_pkgPackage.MountPoint + Replace(.Name, "\", "/"))
                        Exit Function
                    End If

                End With
            Next l_filFile
        End With
    Next l_pkgPackage

    ExtractFile = ""
    LogError "File " + Filename + " does not exist."
End If
#End If
End Function

Friend Sub CreateEmptyFile(Filename As String)
On Error Resume Next
Dim l_lngHandle As Long

    l_lngHandle = FreeFile
    
    Open Filename For Binary As #l_lngHandle
    Close #l_lngHandle
End Sub

Friend Function ReadFile(Filename As String) As String
Attribute ReadFile.VB_Description = "Returns the contents of a file as a String, or vbNullString if it does not exist."
On Error Resume Next

    If Len(Filename) > 0 Then
        ReadFile = ReadTextFile(Filename)
        If Err = 0 Then Exit Function
    End If
    
    ReadFile = vbNullString
    LogError "File " + Filename + " does not exist."
End Function

Friend Sub WriteFile(Filename As String, Text As String)
On Error Resume Next
Dim l_lngHandle As Long
    WriteTextFile Filename, Text
End Sub

Public Sub CreateFolderTree(ByVal Path As String)
On Error Resume Next
Dim l_varFolders As Variant
Dim l_lngFolders As Long
Dim l_strPath As String
    Path = Replace(Path, "/", "\")
    l_varFolders = Split(Path, "\")
    l_strPath = ""
    For l_lngFolders = LBound(l_varFolders) To UBound(l_varFolders)
        If LCase(Trim(Dir(l_strPath + l_varFolders(l_lngFolders), vbDirectory))) = LCase(Trim(l_varFolders(l_lngFolders))) Then
            ' folder exists
            l_strPath = Replace(l_strPath & l_varFolders(l_lngFolders) & "\", "\\", "\")
        Else
            MkDir l_strPath & l_varFolders(l_lngFolders) & "\"
            l_strPath = Replace(l_strPath & l_varFolders(l_lngFolders) & "\", "\\", "\")
        End If
    Next l_lngFolders
End Sub

Friend Sub QueueFolderForDeletion(ByVal Path As String)
On Error Resume Next
Dim l_varFolders As Variant
Dim l_lngFolders As Long
Dim l_strPath As String
    l_varFolders = Split(Path, "/")
    If m_colFolderDeletionQueue.Count > 0 Then
        m_colFolderDeletionQueue.Add CStr(Path), , 1
    Else
        m_colFolderDeletionQueue.Add CStr(Path)
    End If
    For l_lngFolders = LBound(l_varFolders) To UBound(l_varFolders)
        l_strPath = Replace(l_strPath & l_varFolders(l_lngFolders) & IIf(l_lngFolders < UBound(l_varFolders), "/", ""), "\\", "\")
        If Trim(l_strPath) <> "/" Then
            If m_colFolderDeletionQueue.Count > 0 Then
                m_colFolderDeletionQueue.Add l_strPath, , 1
            Else
                m_colFolderDeletionQueue.Add l_strPath
            End If
        End If
    Next l_lngFolders
End Sub

Friend Sub QueueForDeletion(ByVal Filename As String)
Attribute QueueForDeletion.VB_Description = "Queues a file up to be deleted when the Filesystem is destroyed. (Used when a File owns a file but cannot delete it because it is in use)."
On Error Resume Next
    m_colDeletionQueue.Add CStr(Filename)
    Err.Clear
End Sub

Public Sub Cleanup()
On Error Resume Next
Dim l_lngIndex As Long
#If SawZIP = 1 Then
    ' Unload all packages
    Do While m_colPackages.Count > 0
        m_colPackages(1).CloseArchive
        m_colPackages.Remove 1
    Loop
    ' Unload all modules
    Do While m_colModules.Count > 0
        m_colModules.Remove 1
    Loop
    
#End If
    ' Process the deletion queue
    l_lngIndex = 1
    Do While m_colDeletionQueue.Count > (l_lngIndex - 1)
        Err.Clear
        Kill m_colDeletionQueue(l_lngIndex)
        If Err = 0 Then
            m_colDeletionQueue.Remove l_lngIndex
        Else
            l_lngIndex = l_lngIndex + 1
        End If
    Loop
    l_lngIndex = 1
    Do While m_colFolderDeletionQueue.Count > (l_lngIndex - 1)
        RmDir Replace(Root + Replace(m_colFolderDeletionQueue(l_lngIndex), "/", "\"), "\\", "\")
        If Err = 0 Then
            m_colFolderDeletionQueue.Remove l_lngIndex
        Else
            l_lngIndex = l_lngIndex + 1
        End If
        DoEvents
    Loop
    Err.Clear
End Sub

Private Sub Class_Initialize()
On Error Resume Next
    m_strRoot = App.Path
    m_strCurrentFolder = "/"
    If Right(m_strRoot, 1) <> "\" Then m_strRoot = m_strRoot + "\"
    Set m_colDeletionQueue = New Collection
    Set m_colFolderDeletionQueue = New Collection
    Set m_colModules = New Fury2Collection
    Set m_modRoot = MountDiskFolder(App.Path)
    OverwriteReadOnlyFiles = True
End Sub

Private Sub Class_Terminate()
On Error Resume Next
    Cleanup
End Sub

VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "ImageFile"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit
Implements iPlugin
Implements iFileTypePlugin
Private m_objEditor As Object

Private Sub iPlugin_ShowConfiguration()
End Sub

Private Property Get iPlugin_CanConfigure() As Boolean
End Property

Private Sub iFileTypePlugin_FixUpSaveFilename(ByRef Filename As String)
    If Len(Trim(GetExtension(Filename))) > 0 Then
    Else
        Filename = Filename + ".png"
    End If
End Sub

Private Function iFileTypePlugin_CanOpenFile(Filename As String) As Boolean
On Error Resume Next
    If InStr(libGraphics.SupportedGraphicsFormats & ";", ("*." & LCase(Trim(GetExtension(Filename))) & ";")) Then
        iFileTypePlugin_CanOpenFile = True
    End If
End Function

Private Function iFileTypePlugin_CreateNew() As iDocument
On Error Resume Next
Dim l_frmNew As New frmImage
    l_frmNew.SetFilename ""
    Set iFileTypePlugin_CreateNew = l_frmNew
    Set iFileTypePlugin_CreateNew.Plugin = Me
End Function

Private Property Get iFileTypePlugin_FileTypeName() As String
On Error Resume Next
    iFileTypePlugin_FileTypeName = "Image"
End Property

Private Function iFileTypePlugin_LoadFromFile(File As libGraphics.VirtualFile) As iDocument
On Error Resume Next
End Function

Private Function iFileTypePlugin_LoadFromFilename(Filename As String) As iDocument
On Error Resume Next
Dim l_frmNew As New frmImage
    l_frmNew.SetFilename Filename
    l_frmNew.SetImage F2LoadImage(Filename)
    Set iFileTypePlugin_LoadFromFilename = l_frmNew
    Set iFileTypePlugin_LoadFromFilename.Plugin = Me
End Function

Private Property Get iFileTypePlugin_ShowInNewMenu() As Boolean
On Error Resume Next
    iFileTypePlugin_ShowInNewMenu = False
End Property

Private Sub iPlugin_Activate()
End Sub

Private Property Set iPlugin_Editor(RHS As Object)
    Set m_objEditor = RHS
End Property

Private Property Get iPlugin_Icon() As stdole.Picture
    Set iPlugin_Icon = LoadResPicture("IMAGE", vbResIcon)
End Property

Private Sub iPlugin_Initialize()
End Sub

Private Property Get iPlugin_PluginDescription() As String
On Error Resume Next
    iPlugin_PluginDescription = "Enables viewing of image formats supported by the engine."
End Property

Private Property Get iPlugin_PluginName() As String
On Error Resume Next
    iPlugin_PluginName = "Image Viewer Plugin"
End Property

Private Property Get iPlugin_PluginPath() As String
On Error Resume Next
    iPlugin_PluginPath = App.Path & IIf(Right(App.Path, 1) = "\", "ng.dll", "\ng.dll")
End Property

Private Property Get iPlugin_ShowInPluginMenu() As Boolean
    iPlugin_ShowInPluginMenu = False
End Property

Private Sub iPlugin_Shutdown()
End Sub

Private Property Get iFileTypePlugin_FilterString() As String
On Error Resume Next
    iFileTypePlugin_FilterString = "Images|" & libGraphics.SupportedGraphicsFormats
End Property

VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "VirtualFile"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'
'   Fury2 Virtual File Class
'

Implements IVirtualFileSaveable

Private Declare Sub memcpyvb Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal Length As Long)

Private m_booWriteMode As Boolean
Private m_bytData() As Byte
Private m_lngCursorPos As Long
Private m_colSegEnds As New Collection
Private m_colSegStarts As New Collection
Private m_colSegLengths As New Collection
Private m_lngBookmark As Long
Private m_lngSegmentCount As Long
Private m_booBigEndian As Boolean

Public Property Get Pointer() As Long
On Error Resume Next
    Pointer = VarPtr(m_bytData(LBound(m_bytData)))
End Property

Private Sub ReverseRead(ByVal Address As Long, ByVal DestPtr As Long, ByVal Length As Long)
On Error Resume Next
Dim m_lngIdx As Long
    For m_lngIdx = Length - 1 To 0 Step -1
        memcpyvb ByVal DestPtr + ((Length - 1) - m_lngIdx), ByVal VarPtr(m_bytData(Address - 1)) + (m_lngIdx), 1
    Next m_lngIdx
End Sub

Public Property Get BigEndian() As Boolean
    BigEndian = m_booBigEndian
End Property

Public Property Let BigEndian(ByVal NewValue As Boolean)
    m_booBigEndian = NewValue
End Property

Public Property Get Data() As Byte()
On Error Resume Next
    Data = m_bytData
End Property

Public Property Let Data(NewData() As Byte)
On Error Resume Next
    m_bytData = NewData
End Property

'Public Sub Intersperse(Value As Byte, Step As Long)
'On Error Resume Next
'    If (Step < 0) Then Exit Sub
'    If (Value < 0) Or (Value > 255) Then Exit Sub
'    SoftFX.IntersperseData VarPtr(m_bytData(m_lngCursorPos - 1)), Value, Step, ((UBound(m_bytData) + 1) - (m_lngCursorPos - 1)) \ (Step + 1)
'End Sub
'
'Public Sub Pad(DataBytes As Long, NullBytes As Long)
'On Error Resume Next
'Dim m_bytOld() As Byte
'Dim m_lngBytes As Long
'Dim m_lngDest As Long
'    m_bytOld = m_bytData
'    ReDim m_bytData(((UBound(m_bytData) + 1) \ DataBytes) * (DataBytes + NullBytes))
'    SoftFX.PadData VarPtr(m_bytData(m_lngCursorPos - 1)), VarPtr(m_bytOld(m_lngCursorPos - 1)), DataBytes, NullBytes, ((UBound(m_bytOld) + 1) - (m_lngCursorPos - 1)) \ DataBytes
'End Sub
'
'Public Sub UnPad(DataBytes As Long, NullBytes As Long)
'On Error Resume Next
'Dim m_bytOld() As Byte
'Dim m_lngBytes As Long
'Dim m_lngDest As Long
'    m_bytOld = m_bytData
'    ReDim m_bytData(((UBound(m_bytData) + 1) \ (DataBytes + NullBytes)) * (DataBytes))
'    SoftFX.UnPadData VarPtr(m_bytData(m_lngCursorPos - 1)), VarPtr(m_bytOld(m_lngCursorPos - 1)), DataBytes, NullBytes, ((UBound(m_bytOld) + 1) - (m_lngCursorPos - 1)) \ (DataBytes + NullBytes)
'End Sub

Public Property Get SegmentLength() As Long
On Error Resume Next
    If m_lngSegmentCount > 0 Then
        SegmentLength = m_colSegLengths(m_lngSegmentCount)
    End If
End Property

Public Property Get SegmentLeft() As Long
On Error Resume Next
    If m_lngSegmentCount <= 0 Then Exit Function
    SegmentLeft = ((m_colSegStarts(m_lngSegmentCount) + (m_colSegLengths(m_lngSegmentCount) + 4))) - m_lngCursorPos
End Property

Public Property Get Length() As Long
On Error Resume Next
    Length = UBound(m_bytData) + 1
End Property

Public Property Let Length(ByVal NewLength As Long)
On Error Resume Next
    ReDim Preserve m_bytData(0 To NewLength - 1)
End Property

Public Property Get CursorPos() As Long
On Error Resume Next
    CursorPos = m_lngCursorPos
End Property

Public Property Let CursorPos(ByVal NewCursorPos As Long)
On Error Resume Next
    m_lngCursorPos = NewCursorPos
End Property

Private Sub IncSegLength(Amount As Long)
On Error Resume Next
Dim m_lngSegs As Long
Dim m_lngLength As Long
    If m_lngSegmentCount = 0 Then Exit Sub
    For m_lngSegs = 1 To m_lngSegmentCount
        m_lngLength = m_colSegLengths(m_lngSegs)
        m_colSegLengths.Remove m_lngSegs
        m_lngLength = m_lngLength + Amount
        Err.Clear
        m_colSegLengths.Add m_lngLength, , m_lngSegs
        If Err <> 0 Then m_colSegLengths.Add m_lngLength
    Next m_lngSegs
End Sub

Public Function EOF() As Boolean
On Error Resume Next
    If (m_lngCursorPos > (UBound(m_bytData) + 1)) Then
        EOF = True
    End If
End Function

Public Function EOS() As Boolean
On Error Resume Next
    If m_lngSegmentCount <= 0 Then Exit Function
    If (m_lngCursorPos >= ((m_colSegStarts(m_lngSegmentCount) + (m_colSegLengths(m_lngSegmentCount) + 4)))) Then
        EOS = True
    End If
End Function

Public Sub Destroy()
On Error Resume Next
    m_lngSegmentCount = 0
    Set m_colSegLengths = New Collection
    Set m_colSegStarts = New Collection
    Erase m_bytData
    m_lngCursorPos = 1
    m_lngBookmark = 1
End Sub

Public Sub LoadFile(ByVal Filename As String)
On Error Resume Next
Dim m_lngFileHandle As Long
Dim m_lngLoadSegment As Long
Dim m_booCancel As Boolean
Dim m_lngLength As Long
    m_lngLength = -1
    m_lngLength = FileLen(Filename)
    If m_lngLength < 0 Then
        Err.Raise 10244, "VirtualFile.LoadFile", "File does not exist"
        Exit Sub
    End If
    m_lngFileHandle = FreeFile
    m_lngSegmentCount = 0
    Set m_colSegLengths = New Collection
    Set m_colSegStarts = New Collection
    Erase m_bytData
    m_lngCursorPos = 1
    m_lngBookmark = 1
    If m_lngLength = 0 Then
        ReDim m_bytData(0 To 0)
        Exit Sub
    End If
    Open Filename For Binary Access Read As #m_lngFileHandle
        ReDim m_bytData(0 To m_lngLength - 1)
        Get #m_lngFileHandle, 1, m_bytData
    Close #m_lngFileHandle
    m_lngCursorPos = 1
    m_lngBookmark = 1
    Err.Clear
End Sub

Public Sub LoadFromString(ByRef Data As String)
On Error Resume Next
Dim m_booCancel As Boolean
    m_lngSegmentCount = 0
    Set m_colSegLengths = New Collection
    Set m_colSegStarts = New Collection
    Erase m_bytData
    m_lngCursorPos = 1
    m_lngBookmark = 1
    m_bytData = Data
    Err.Clear
End Sub

Public Function SaveToString() As String
On Error Resume Next
    SaveToString = m_bytData
End Function

Public Sub LoadFileCompressed(ByVal Filename As String)
On Error Resume Next
Dim m_lngFileHandle As Long
Dim m_lngSourceLength As Long
Dim m_lngDestLength As Long
Dim m_bytCompressed() As Byte
Dim m_booCancel As Boolean
    If Trim(Dir(Filename)) = "" Then
        Err.Raise 10244, "VirtualFile.LoadFile", "File does not exist"
        Exit Sub
    End If
    m_lngFileHandle = FreeFile
    Erase m_bytData
    m_lngCursorPos = 1
    m_lngBookmark = 1
    Open Filename For Binary Access Read As #m_lngFileHandle
        Get #m_lngFileHandle, , m_lngDestLength
        Get #m_lngFileHandle, , m_lngSourceLength
        ReDim m_bytCompressed(0 To m_lngSourceLength - 1)
        Get #m_lngFileHandle, 1, m_bytCompressed()
        m_bytData() = zlibDecompressBytes(m_bytCompressed, m_lngDestLength)
    Close #m_lngFileHandle
    m_lngCursorPos = 1
    m_lngBookmark = 1
    Err.Clear
End Sub

Public Sub SaveFileCompressed(ByVal Filename As String)
On Error Resume Next
Dim m_lngFileHandle As Long
Dim m_lngSourceLength As Long
Dim m_lngDestLength As Long
Dim m_bytCompressed() As Byte
    Kill Filename
    m_lngFileHandle = FreeFile
    Open Filename For Binary Access Write As #m_lngFileHandle
        m_bytCompressed = zlibCompressBytes(m_bytData)
        m_lngSourceLength = UBound(m_bytCompressed) + 1
        m_lngDestLength = UBound(m_bytData) + 1
        Put #m_lngFileHandle, , m_lngDestLength
        Put #m_lngFileHandle, , m_lngSourceLength
        Put #m_lngFileHandle, , m_bytCompressed()
    Close #m_lngFileHandle
    Err.Clear
End Sub

Public Sub SaveFile(ByVal Filename As String)
On Error Resume Next
Dim m_lngFileHandle As Long
    Kill Filename
    m_lngFileHandle = FreeFile
    Open Filename For Binary Access Write As #m_lngFileHandle
        Put #m_lngFileHandle, 1, m_bytData
    Close #m_lngFileHandle
    Err.Clear
End Sub

Private Sub EnsureLength(Length As Long)
On Error Resume Next
    If UBound(m_bytData) = -1 Then
        ReDim m_bytData(0 To Length - 2)
    Else
        If UBound(m_bytData) > Length Then
        Else
            ReDim Preserve m_bytData(0 To Length - 2)
        End If
    End If
End Sub

Public Sub RawSave(ByVal DataPointer As Long, ByVal Length As Long)
On Error Resume Next
    If DataPointer < 16 Then Exit Sub
    EnsureLength m_lngCursorPos + Length
    memcpyvb m_bytData(m_lngCursorPos - 1), ByVal DataPointer, Length
    m_lngCursorPos = m_lngCursorPos + Length
    IncSegLength Length
End Sub

Public Function LoadBytes(ByVal Length As Long) As Byte()
On Error Resume Next
Dim l_bytData() As Byte
    If (m_lngCursorPos + (Length - 1)) > (UBound(m_bytData) + 1) Then Exit Function
    ReDim l_bytData(0 To Length - 1)
    memcpyvb ByVal VarPtr(l_bytData(0)), m_bytData(m_lngCursorPos - 1), Length
    LoadBytes = l_bytData
    m_lngCursorPos = m_lngCursorPos + Length
End Function

Public Sub RawLoad(ByVal DataPointer As Long, ByVal Length As Long)
On Error Resume Next
    If DataPointer < 16 Then Exit Sub
    If ((m_lngCursorPos + (Length - 1)) > (UBound(m_bytData) + 1)) Or EOS Then
        SoftFX.FillMemoryByte DataPointer, 0, Length
    Else
        memcpyvb ByVal DataPointer, m_bytData(m_lngCursorPos - 1), Length
        m_lngCursorPos = m_lngCursorPos + Length
    End If
End Sub

Public Sub RawSaveCompressed(ByVal DataPointer As Long, ByVal Length As Long)
On Error Resume Next
Dim m_bytTemp() As Byte, m_lngLength As Long
    m_bytTemp = zlibCompressBytesP(DataPointer, Length)
    m_lngLength = (UBound(m_bytTemp) - LBound(m_bytTemp)) + 1
    Save m_lngLength
    EnsureLength m_lngCursorPos + m_lngLength
    memcpyvb m_bytData(m_lngCursorPos - 1), m_bytTemp(LBound(m_bytTemp)), m_lngLength
    m_lngCursorPos = m_lngCursorPos + m_lngLength
    IncSegLength m_lngLength
End Sub

Public Sub RawLoadCompressed(ByVal DataPointer As Long, ByVal Length As Long)
On Error Resume Next
Dim m_bytTemp() As Byte, m_lngLength As Long
    Load m_lngLength
    If (m_lngCursorPos + (m_lngLength - 1)) > (UBound(m_bytData) + 1) Then Exit Sub
    m_bytTemp = zlibDecompressBytesP(VarPtr(m_bytData(m_lngCursorPos - 1)), m_lngLength, Length)
    memcpyvb ByVal DataPointer, m_bytTemp(LBound(m_bytTemp)), Length
    m_lngCursorPos = m_lngCursorPos + m_lngLength
End Sub

Public Sub Save(ByRef Data)
On Error Resume Next
Dim m_bytValue As Byte
Dim m_intValue As Integer
Dim m_lngValue As Long
Dim m_strValue As String
Dim m_sngValue As Single
Dim m_dblValue As Double
Dim m_curValue As Currency
Dim m_lngItems As Long
Dim m_lngNewLength As Long
Dim m_objData As IVirtualFileSaveable
Dim m_colData As IVirtualFileCollection
    If VarType(Data) = vbObject Then
        If Data Is Nothing Then
            WriteSegment_Begin
            WriteSegment_End
            Exit Sub
        End If
    End If
    Select Case VarType(Data)
    Case vbObject
        If TypeOf Data Is IVirtualFileCollection Then
            Set m_colData = Data
            WriteSegment_Begin
            m_colData.SaveHeader Me
            Save CLng(m_colData.Count)
            If m_colData.Count > 0 Then
                For m_lngItems = 1 To m_colData.Count
                    Save m_colData.GetItem(m_lngItems)
                Next m_lngItems
            End If
            WriteSegment_End
        ElseIf TypeOf Data Is IVirtualFileSaveable Then
            Set m_objData = Data
            m_objData.Serialize Me
        Else
            Err.Clear
            On Error Resume Next
            Data.Class_Save Me
            Data.Object_Save Me
            If Err <> 0 Then
                Err.Raise 10243, "VirtualFile.Save", "Object does not support VirtualFile serialization"
                On Error Resume Next
            End If
        End If
    Case Is >= vbArray
        Err.Clear
        ReDim Preserve Data(LBound(Data) To UBound(Data))
        If Err <> 0 Then
        Else
            m_lngValue = (UBound(Data) - LBound(Data)) + 1
            EnsureLength m_lngCursorPos + 4
            memcpyvb m_bytData(m_lngCursorPos - 1), m_lngValue, 4
            m_lngCursorPos = m_lngCursorPos + 4
            IncSegLength 4
        End If
        Err.Clear
        m_lngLength = -1
        m_lngLength = UBound(Data)
        If (m_lngLength >= 0) And (Err = 0) Then
            For m_lngItems = LBound(Data) To UBound(Data)
                Save Data(m_lngItems)
            Next m_lngItems
        End If
    Case vbBoolean
        m_intValue = Data
        EnsureLength m_lngCursorPos + 2
        memcpyvb m_bytData(m_lngCursorPos - 1), m_intValue, 2
        m_lngCursorPos = m_lngCursorPos + 2
        IncSegLength 2
    Case vbByte
        m_bytValue = Data
        EnsureLength m_lngCursorPos + 1
        memcpyvb m_bytData(m_lngCursorPos - 1), m_bytValue, 1
        m_lngCursorPos = m_lngCursorPos + 1
        IncSegLength 1
    Case vbInteger
        m_intValue = Data
        EnsureLength m_lngCursorPos + 2
        memcpyvb m_bytData(m_lngCursorPos - 1), m_intValue, 2
        m_lngCursorPos = m_lngCursorPos + 2
        IncSegLength 2
    Case vbLong
        m_lngValue = Data
        EnsureLength m_lngCursorPos + 4
        memcpyvb m_bytData(m_lngCursorPos - 1), m_lngValue, 4
        m_lngCursorPos = m_lngCursorPos + 4
        IncSegLength 4
    Case vbSingle
        m_sngValue = Data
        EnsureLength m_lngCursorPos + 4
        memcpyvb m_bytData(m_lngCursorPos - 1), m_sngValue, 4
        m_lngCursorPos = m_lngCursorPos + 4
        IncSegLength 4
    Case vbDouble
        m_dblValue = Data
        EnsureLength m_lngCursorPos + 8
        memcpyvb m_bytData(m_lngCursorPos - 1), m_dblValue, 8
        m_lngCursorPos = m_lngCursorPos + 8
        IncSegLength 8
    Case vbCurrency
        m_curValue = Data
        EnsureLength m_lngCursorPos + 8
        memcpyvb m_bytData(m_lngCursorPos - 1), m_curValue, 8
        m_lngCursorPos = m_lngCursorPos + 8
        IncSegLength 8
    Case vbString
        m_strValue = Data
        m_lngValue = Len(m_strValue)
        EnsureLength m_lngCursorPos + (4) + (Len(m_strValue) * 2)
        memcpyvb m_bytData(m_lngCursorPos - 1), m_lngValue, 4
        m_lngCursorPos = m_lngCursorPos + (4)
        IncSegLength 4
        memcpyvb m_bytData(m_lngCursorPos - 1), ByVal StrPtr(m_strValue), Len(m_strValue) * 2
        m_lngCursorPos = m_lngCursorPos + (Len(m_strValue) * 2)
        IncSegLength Len(m_strValue) * 2
    Case Else
        If IsEmpty(Data) Then
        Else
            Err.Raise 10241, "VirtualFile.Save", "Data type not supported"
            Exit Sub
            ' Unsupported data type
        End If
    End Select
    Err.Clear
End Sub

Public Sub SaveCString(ByRef Data As String)
On Error Resume Next
Dim m_bytText() As Byte
    Err.Clear
    If (VarType(Data) And vbString) = vbString Then
        m_bytText = StrConv(Data + Chr(0), vbFromUnicode)
    Else
        m_bytText = Data
    End If
    If Err <> 0 Then Exit Sub
    EnsureLength m_lngCursorPos + UBound(m_bytText) + 1
    memcpyvb m_bytData(m_lngCursorPos - 1), m_bytText(0), UBound(m_bytText) + 1
    m_lngCursorPos = m_lngCursorPos + UBound(m_bytText) + 1
    IncSegLength UBound(m_bytText) + 1
End Sub

Public Sub LoadCString(ByRef Data As String)
On Error Resume Next
Dim m_lngIndex As Long
Dim m_bytText() As Byte
    m_lngIndex = m_lngCursorPos - 1
    Do
        m_lngIndex = m_lngIndex + 1
        If m_bytData(m_lngIndex) = 0 Then
            ReDim m_bytText(0 To m_lngIndex - (m_lngCursorPos))
            memcpyvb m_bytText(0), m_bytData(m_lngCursorPos - 1), UBound(m_bytText) + 1
            Data = StrConv(m_bytText, vbUnicode)
            m_lngCursorPos = m_lngIndex + 2
            Exit Do
        End If
    Loop
End Sub

Public Sub LoadGeneric(ByRef Data, ByVal VarType)
On Error Resume Next
    ' Fills the data type so that the proper type is loaded. Used for VBscript.
    Select Case VarType
    Case vbString, "string", "String"
        Data = CStr(Data)
    Case vbLong, "long", "Long"
        Data = CLng(Data)
    Case vbInteger, "integer", "Integer"
        Data = CInt(Data)
    Case vbSingle, "single", "Single", "number", "Number"
        Data = CSng(Data)
    Case vbDouble, "double", "Double"
        Data = CDbl(Data)
    Case vbDate, "date", "Date"
        Data = CDate(Data)
    Case vbBoolean, "boolean", "Boolean", "bool", "Bool"
        Data = CDate(Data)
    Case Else
    End Select
    Load Data
End Sub

Public Sub Load(ByRef Data)
On Error Resume Next
Dim m_bytValue As Byte
Dim m_intValue As Integer
Dim m_lngValue As Long
Dim m_strValue As String, m_lngLength As Long
Dim m_sngValue As Single
Dim m_dblValue As Double
Dim m_curValue As Currency
Dim m_lngItems As Long
Dim m_lngNewLength As Long
Dim m_lngCount As Long
Dim m_objData As IVirtualFileSaveable
Dim m_objLoad As Object
Dim m_colData As IVirtualFileCollection
    If VarPtr(Data) = 0 Then Exit Sub
    If VarType(Data) = vbObject Then
        If Data Is Nothing Then
            ReadSegment_Begin
            ReadSegment_End
            Exit Sub
        End If
    End If
    m_lngValue = -1
    m_lngValue = UBound(m_bytData)
    If m_lngValue = -1 Then Exit Sub
    Err.Clear
    If ((m_lngSegmentCount > 0) And (EOS = True)) Or (EOF = True) Then
        Select Case VarType(Data)
        Case vbBoolean
            Data = CBool(False)
        Case vbByte
            Data = CByte(0)
        Case vbInteger
            Data = CInt(0)
        Case vbLong
            Data = CLng(0)
        Case vbSingle
            Data = CSng(0)
        Case vbDouble
            Data = CDbl(0)
        Case vbCurrency
            If (m_lngCursorPos + 7) > (UBound(m_bytData) + 1) Then Data = 0: Exit Sub
            memcpyvb m_curValue, m_bytData(m_lngCursorPos - 1), 8
            m_lngCursorPos = m_lngCursorPos + 8
            Data = CCur(0)
        Case vbString
            Data = CStr("")
        Case Else
        End Select
        If (m_lngSegmentCount > 0) And (EOS = True) Then
            Err.Raise 10242, "VirtualFile.Load", "Read beyond end of segment attempted" + vbCrLf + "Call ReadSegment_Cancel to avoid this error"
        Else
            Err.Raise 10245, "VirtualFile.Load", "Read beyond end of file attempted" + vbCrLf + "File is too short"
        End If
        Exit Sub
    End If
    Select Case VarType(Data)
    Case vbObject
        If TypeOf Data Is IVirtualFileCollection Then
            Set m_colData = Data
            m_colData.Reset
            ReadSegment_Begin
            m_colData.LoadHeader Me
            Load m_lngCount
            If m_lngCount > 0 Then
                For m_lngItems = 1 To m_lngCount
                    Set m_objLoad = m_colData.CreateNew
                    Load m_objLoad
                    m_colData.AddItem m_objLoad
                Next m_lngItems
            End If
            ReadSegment_End
        ElseIf TypeOf Data Is IVirtualFileSaveable Then
            Set m_objData = Data
            m_objData.Deserialize Me
        Else
            Err.Clear
            On Error Resume Next
            Data.Class_Load Me
            Data.Object_Load Me
            If Err <> 0 Then
                Err.Raise 10243, "VirtualFile.Load", "Object does not support VirtualFile serialization"
                Exit Sub
            End If
        End If
    Case Is >= vbArray
        Err.Clear
        m_lngLength = -1
        m_lngLength = UBound(Data)
        If m_lngLength = -1 Then
            If (m_lngCursorPos + 3) > (UBound(m_bytData) + 1) Then Exit Sub
            memcpyvb m_lngLength, m_bytData(m_lngCursorPos - 1), 4
            m_lngCursorPos = m_lngCursorPos + 4
            If m_lngLength > 0 Then ReDim Data(0 To m_lngLength - 1)
        End If
        Err.Clear
        m_lngLength = -1
        m_lngLength = UBound(Data)
        If (m_lngLength >= 0) And (Err = 0) Then
            For m_lngItems = LBound(Data) To UBound(Data)
                Load Data(m_lngItems)
            Next m_lngItems
        End If
    Case vbBoolean
        If (m_lngCursorPos + 1) > (UBound(m_bytData) + 1) Then Data = 0: Exit Sub
        If m_booBigEndian Then
            ReverseRead m_lngCursorPos, VarPtr(m_intValue), 2
        Else
            memcpyvb m_intValue, m_bytData(m_lngCursorPos - 1), 2
        End If
        m_lngCursorPos = m_lngCursorPos + 2
        Data = CBool(m_intValue)
    Case vbByte
        If (m_lngCursorPos) > (UBound(m_bytData) + 1) Then Data = 0: Exit Sub
        memcpyvb m_bytValue, m_bytData(m_lngCursorPos - 1), 1
        m_lngCursorPos = m_lngCursorPos + 1
        Data = CByte(m_bytValue)
    Case vbInteger
        If (m_lngCursorPos + 1) > (UBound(m_bytData) + 1) Then Data = 0: Exit Sub
        If m_booBigEndian Then
            ReverseRead m_lngCursorPos, VarPtr(m_intValue), 2
        Else
            memcpyvb m_intValue, m_bytData(m_lngCursorPos - 1), 2
        End If
        m_lngCursorPos = m_lngCursorPos + 2
        Data = CInt(m_intValue)
    Case vbLong
        If (m_lngCursorPos + 3) > (UBound(m_bytData) + 1) Then Data = 0: Exit Sub
        If m_booBigEndian Then
            ReverseRead m_lngCursorPos, VarPtr(m_lngValue), 4
        Else
            memcpyvb m_lngValue, m_bytData(m_lngCursorPos - 1), 4
        End If
        m_lngCursorPos = m_lngCursorPos + 4
        Data = CLng(m_lngValue)
    Case vbSingle
        If (m_lngCursorPos + 3) > (UBound(m_bytData) + 1) Then Data = 0: Exit Sub
        memcpyvb m_sngValue, m_bytData(m_lngCursorPos - 1), 4
        m_lngCursorPos = m_lngCursorPos + 4
        Data = CSng(m_sngValue)
    Case vbDouble
        If (m_lngCursorPos + 7) > (UBound(m_bytData) + 1) Then Data = 0: Exit Sub
        memcpyvb m_dblValue, m_bytData(m_lngCursorPos - 1), 8
        m_lngCursorPos = m_lngCursorPos + 8
        Data = CDbl(m_dblValue)
    Case vbCurrency
        If (m_lngCursorPos + 7) > (UBound(m_bytData) + 1) Then Data = 0: Exit Sub
        memcpyvb m_curValue, m_bytData(m_lngCursorPos - 1), 8
        m_lngCursorPos = m_lngCursorPos + 8
        Data = CCur(m_curValue)
    Case vbString
        If (m_lngCursorPos + 3) > (UBound(m_bytData) + 1) Then Data = "": Exit Sub
        memcpyvb m_lngLength, m_bytData(m_lngCursorPos - 1), 4
        m_lngCursorPos = m_lngCursorPos + 4
        If (m_lngSegmentCount > 0) And (EOS = True) Then
            Data = CStr("")
            Err.Raise 10242, "VirtualFile.Load", "Read beyond end of segment attempted" + vbCrLf + "Call ReadSegment_Cancel to avoid this error"
            Exit Sub
        End If
        m_strValue = Space(m_lngLength)
        If (m_lngCursorPos + ((m_lngLength * 2) - 2)) > UBound(m_bytData) Then Data = "": Exit Sub
        If StrPtr(m_strValue) > 0 Then
            memcpyvb ByVal StrPtr(m_strValue), m_bytData(m_lngCursorPos - 1), m_lngLength * 2
            m_lngCursorPos = m_lngCursorPos + (m_lngLength * 2)
            Data = m_strValue
        End If
    Case Else
        If IsEmpty(Data) Then
        Else
            Err.Raise 10241, "VirtualFile.Load", "Data type not supported"
            ' Unsupported data type
        End If
    End Select
    Err.Clear
End Sub

Public Function ReadString(Optional ByVal EndOfString As String = vbCrLf) As String
On Error Resume Next
Dim m_lngChars As Long
Dim m_booEnded As Boolean
Dim m_strFind As String
Dim m_bytText() As Byte
    m_strFind = EndOfString
    m_lngChars = m_lngCursorPos
    Do Until m_booEnded
        If m_lngChars > (UBound(m_bytData) + 1) Then m_booEnded = True: Exit Do
        If InStr(m_bytText, m_strFind) Then m_booEnded = True: Exit Do
        ReDim m_bytText(0 To (m_lngChars - (m_lngCursorPos)) - 1)
        memcpyvb m_bytText(0), m_bytData(m_lngCursorPos - 1), m_lngChars - m_lngCursorPos
        m_lngChars = m_lngChars + 1
    Loop
    ReadString = m_bytText
End Function

Public Function ReadStringUnicode(Optional ByVal EndOfString As String = vbCrLf) As String
On Error Resume Next
Dim m_lngChars As Long
Dim m_strText As String
Dim m_booEnded As Boolean
    m_lngChars = m_lngCursorPos
    Do Until m_booEnded
        If m_lngChars > (UBound(m_bytData) + 1) Then m_booEnded = True: Exit Do
        If InStr(m_strText, EndOfString) Then m_booEnded = True: Exit Do
        m_strText = Space(((m_lngChars - m_lngCursorPos) \ 2) + 1)
        memcpyvb ByVal StrPtr(m_strText), m_bytData(m_lngCursorPos - 1), m_lngChars - m_lngCursorPos
        m_lngChars = m_lngChars + 1
    Loop
    ReadStringUnicode = m_strText
End Function

Sub WriteData(ByRef Data() As Byte)
On Error Resume Next
Dim l_lngLength As Long
    Err.Clear
    l_lngLength = (UBound(Data) - LBound(Data)) + 1
    If l_lngLength < 1 Or Err <> 0 Then Exit Sub
    EnsureLength m_lngCursorPos + l_lngLength
    memcpyvb m_bytData(m_lngCursorPos - 1), Data(LBound(Data)), l_lngLength
    m_lngCursorPos = m_lngCursorPos + l_lngLength
End Sub

Sub WriteString(ByRef Text As String)
On Error Resume Next
Dim m_bytText() As Byte
    EnsureLength m_lngCursorPos + Len(Text)
    m_bytText = StrConv(Text, vbFromUnicode)
    memcpyvb m_bytData(m_lngCursorPos - 1), m_bytText(0), Len(Text)
    m_lngCursorPos = m_lngCursorPos + Len(Text)
End Sub

Sub WriteStringUnicode(ByRef Text As String)
On Error Resume Next
    EnsureLength m_lngCursorPos + (Len(Text) * 2)
    memcpyvb m_bytData(m_lngCursorPos - 1), ByVal StrPtr(Text), Len(Text) * 2
    m_lngCursorPos = m_lngCursorPos + (Len(Text) * 2)
End Sub

Public Sub MoveCursor(ByVal Location As Long)
On Error Resume Next
    m_lngCursorPos = Location
    If m_lngCursorPos < 1 Then m_lngCursorPos = 1
    If m_lngCursorPos > Length Then m_lngCursorPos = Length
End Sub

Public Sub SetBookmark()
On Error Resume Next
    m_lngBookmark = m_lngCursorPos
End Sub

Public Sub ReturnToBookmark()
On Error Resume Next
    m_lngCursorPos = m_lngBookmark
End Sub

Public Sub WriteSegment_Begin()
On Error Resume Next
    m_colSegStarts.Add m_lngCursorPos
    m_lngCursorPos = m_lngCursorPos + 4
    m_colSegLengths.Add 0
    m_lngSegmentCount = m_lngSegmentCount + 1
    m_booWriteMode = True
End Sub

Public Sub WriteSegment_End()
On Error Resume Next
Dim m_lngEnd As Long
    m_lngEnd = m_lngCursorPos
    m_lngCursorPos = m_colSegStarts(m_lngSegmentCount)
    Save CLng(m_colSegLengths(m_lngSegmentCount))
    m_lngCursorPos = m_lngEnd
    m_colSegLengths.Remove m_lngSegmentCount
    m_colSegStarts.Remove m_lngSegmentCount
    m_lngSegmentCount = m_lngSegmentCount - 1
End Sub

Public Sub ReadSegment_Begin()
On Error Resume Next
Dim m_lngLength As Long
    If m_lngSegmentCount > 0 And EOS = True Then
        m_colSegStarts.Add m_lngCursorPos
        m_colSegLengths.Add 0
        m_lngSegmentCount = m_lngSegmentCount + 1
        Err.Raise 10242, "VirtualFile.Load", "Read beyond end of segment attempted" + vbCrLf + "Call ReadSegment_Cancel to avoid this error"
        Exit Sub
    End If
    m_colSegStarts.Add m_lngCursorPos
    Load m_lngLength
    m_colSegLengths.Add m_lngLength
    m_lngSegmentCount = m_lngSegmentCount + 1
    m_booWriteMode = False
End Sub

Public Sub ReadSegment_End()
On Error Resume Next
    m_lngCursorPos = m_colSegStarts(m_lngSegmentCount) + m_colSegLengths(m_lngSegmentCount) + 4
    m_colSegLengths.Remove m_lngSegmentCount
    m_colSegStarts.Remove m_lngSegmentCount
    m_lngSegmentCount = m_lngSegmentCount - 1
End Sub

Public Sub ReadSegment_Cancel()
On Error Resume Next
    m_colSegLengths.Remove m_lngSegmentCount
    m_colSegStarts.Remove m_lngSegmentCount
    m_lngSegmentCount = m_lngSegmentCount - 1
End Sub

Public Sub WriteSegment_Cancel()
On Error Resume Next
    m_colSegLengths.Remove m_lngSegmentCount
    m_colSegStarts.Remove m_lngSegmentCount
    m_lngSegmentCount = m_lngSegmentCount - 1
End Sub

Public Sub Skip(Length As Long)
On Error Resume Next
    m_lngCursorPos = m_lngCursorPos + Length
    If m_booWriteMode Then IncSegLength Length
End Sub

Private Sub Class_Initialize()
    Erase m_bytData()
    m_lngCursorPos = 1
    m_lngBookmark = 1
End Sub

Public Function Class_ToString() As String
    Class_ToString = "File (" & Length & " bytes long)"
End Function

Private Sub IVirtualFileSaveable_Deserialize(File As VirtualFile)
On Error Resume Next
Dim m_booCancel As Boolean
Dim m_lngLength As Long
    With File
        .ReadSegment_Begin
            m_lngLength = -1
            .Load m_lngLength
            If m_lngLength < 0 Then
                .ReadSegment_End
                Exit Sub
            End If
            m_lngSegmentCount = 0
            Set m_colSegLengths = New Collection
            Set m_colSegStarts = New Collection
            Erase m_bytData
            m_lngCursorPos = 1
            m_lngBookmark = 1
            If m_lngLength = 0 Then
                ReDim m_bytData(0 To 0)
                .ReadSegment_End
                Exit Sub
            End If
            ReDim m_bytData(0 To m_lngLength - 1)
            .RawLoad VarPtr(m_bytData(0)), m_lngLength
            Err.Clear
        .ReadSegment_End
    End With
End Sub

Private Sub IVirtualFileSaveable_Serialize(File As VirtualFile)
    With File
        .WriteSegment_Begin
            .Save Length
            .RawSave ByVal VarPtr(m_bytData(0)), Length
        .WriteSegment_End
    End With
End Sub
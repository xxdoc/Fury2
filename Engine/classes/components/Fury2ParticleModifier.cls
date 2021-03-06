VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Fury2ParticleModifier"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit
Private m_modModifier As ParticleModifier

Private Sub Class_Initialize()
On Error Resume Next
    m_modModifier.RequireType = -1
    m_modModifier.ExcludeType = -1
    m_modModifier.Area.x1 = -99999
    m_modModifier.Area.y1 = -99999
    m_modModifier.Area.x2 = 99999
    m_modModifier.Area.y2 = 99999
    m_modModifier.Mass = 1#
    m_modModifier.Range = 100
End Sub

Friend Sub AddTo(ByVal Engine As Long)
On Error Resume Next
    AddParticleModifier Engine, m_modModifier
End Sub

Friend Sub RemoveFrom(ByVal Engine As Long)
On Error Resume Next
    RemoveParticleModifier Engine, m_modModifier
End Sub

Public Property Get Handle() As Long
On Error Resume Next
    Handle = VarPtr(m_modModifier)
End Property

Public Property Get LVDecay() As Single
Attribute LVDecay.VB_Description = "The amount of life velocity decay to apply to affected particles."
On Error Resume Next
    LVDecay = m_modModifier.LVDecay
End Property

Public Property Let LVDecay(ByVal NewValue As Single)
On Error Resume Next
    m_modModifier.LVDecay = NewValue
End Property

Public Property Get AVDecay() As Single
Attribute AVDecay.VB_Description = "The amount of alpha velocity decay to apply to affected particles."
On Error Resume Next
    AVDecay = m_modModifier.AVDecay
End Property

Public Property Let AVDecay(ByVal NewValue As Single)
On Error Resume Next
    m_modModifier.AVDecay = NewValue
End Property

Public Property Get XVDecay() As Single
Attribute XVDecay.VB_Description = "The amount of X velocity decay to apply to affected particles."
On Error Resume Next
    XVDecay = m_modModifier.XVDecay
End Property

Public Property Let XVDecay(ByVal NewValue As Single)
On Error Resume Next
    m_modModifier.XVDecay = NewValue
End Property

Public Property Get YVDecay() As Single
Attribute YVDecay.VB_Description = "The amount of Y velocity decay to apply to affected particles."
On Error Resume Next
    YVDecay = m_modModifier.YVDecay
End Property

Public Property Let YVDecay(ByVal NewValue As Single)
On Error Resume Next
    m_modModifier.YVDecay = NewValue
End Property

Public Property Get LVDecayMode() As ParticleDecayModes
Attribute LVDecayMode.VB_Description = "The type of decay to apply to life velocity."
On Error Resume Next
    LVDecayMode = m_modModifier.LVDecayMode
End Property

Public Property Let LVDecayMode(ByVal NewValue As ParticleDecayModes)
On Error Resume Next
    m_modModifier.LVDecayMode = NewValue
End Property

Public Property Get AVDecayMode() As ParticleDecayModes
Attribute AVDecayMode.VB_Description = "The type of decay to apply to alpha velocity."
On Error Resume Next
    AVDecayMode = m_modModifier.AVDecayMode
End Property

Public Property Let AVDecayMode(ByVal NewValue As ParticleDecayModes)
On Error Resume Next
    m_modModifier.AVDecayMode = NewValue
End Property

Public Property Get XVDecayMode() As ParticleDecayModes
Attribute XVDecayMode.VB_Description = "The type of decay to apply to X velocity."
On Error Resume Next
    XVDecayMode = m_modModifier.XVDecayMode
End Property

Public Property Let XVDecayMode(ByVal NewValue As ParticleDecayModes)
On Error Resume Next
    m_modModifier.XVDecayMode = NewValue
End Property

Public Property Get YVDecayMode() As ParticleDecayModes
Attribute YVDecayMode.VB_Description = "The type of decay to apply to Y velocity."
On Error Resume Next
    YVDecayMode = m_modModifier.YVDecayMode
End Property

Public Property Let YVDecayMode(ByVal NewValue As ParticleDecayModes)
On Error Resume Next
    m_modModifier.YVDecayMode = NewValue
End Property

Public Property Get X() As Single
Attribute X.VB_Description = "The X coordinate of the center of the modifier."
On Error Resume Next
    X = m_modModifier.X
End Property

Public Property Let X(ByVal NewValue As Single)
On Error Resume Next
    m_modModifier.X = NewValue
End Property

Public Property Get Y() As Single
Attribute Y.VB_Description = "The Y coordinate of the center of the modifier."
On Error Resume Next
    Y = m_modModifier.Y
End Property

Public Property Let Y(ByVal NewValue As Single)
On Error Resume Next
    m_modModifier.Y = NewValue
End Property

Public Property Get Range() As Single
Attribute Range.VB_Description = "The distance at which the modifier can operate."
On Error Resume Next
    Range = m_modModifier.Range
End Property

Public Property Let Range(ByVal NewValue As Single)
On Error Resume Next
    m_modModifier.Range = NewValue
End Property

Public Property Get RangeScale() As Single
Attribute RangeScale.VB_Description = "The amount to scale the strength of the modifier by."
On Error Resume Next
    RangeScale = m_modModifier.RangeScale
End Property

Public Property Let RangeScale(ByVal NewValue As Single)
On Error Resume Next
    m_modModifier.RangeScale = NewValue
End Property

Public Property Get Attraction() As Single
Attribute Attraction.VB_Description = "The amount of gravitational attraction to apply to particles."
On Error Resume Next
    Attraction = m_modModifier.Attraction
End Property

Public Property Let Attraction(ByVal NewValue As Single)
On Error Resume Next
    m_modModifier.Attraction = NewValue
End Property

Public Property Get Mass() As Single
Attribute Mass.VB_Description = "The mass of the modifier (used for gravitational attraction)"
On Error Resume Next
    Mass = m_modModifier.Mass
End Property

Public Property Let Mass(ByVal NewValue As Single)
On Error Resume Next
    m_modModifier.Mass = NewValue
End Property

Public Property Get ExcludeType() As Long
Attribute ExcludeType.VB_Description = "Excludes particles of a given type."
On Error Resume Next
    ExcludeType = m_modModifier.ExcludeType
End Property

Public Property Let ExcludeType(ByVal NewValue As Long)
On Error Resume Next
    m_modModifier.ExcludeType = NewValue
End Property

Public Property Get RequireType() As Long
Attribute RequireType.VB_Description = "Requires that particles be of a given type."
On Error Resume Next
    RequireType = m_modModifier.RequireType
End Property

Public Property Let RequireType(ByVal NewValue As Long)
On Error Resume Next
    m_modModifier.RequireType = NewValue
End Property



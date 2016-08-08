Option Explicit

Sub AddTOCSlide()
' Add a blank slide at the beginning of the presentation
' to hold the TOC contents

    Dim aSlideTitles() As String
    Dim oSl As Slide
    Dim oSh As Shape
    Dim x As Long
    Dim oRng As TextRange
    
    With ActivePresentation
        ' Collect the slide titles
        ReDim aSlideTitles(1 To .Slides.Count - 1)
        For x = 2 To .Slides.Count - 1
            aSlideTitles(x) = GetSlideTitle(.Slides(x))
        Next
    End With
    
    ' we'll arbitrarily add a paragraph to slide 1 with links to other slides
    ' copy the paragraph to any other slide you like
    With ActivePresentation.Slides(1)
        Set oSh = .Shapes.AddTextbox(msoTextOrientationHorizontal, _
            0, 0, _
            ActivePresentation.PageSetup.SlideWidth, _
            ActivePresentation.PageSetup.SlideHeight)
        With oSh.TextFrame.TextRange
            For x = 1 To UBound(aSlideTitles)
                Set oRng = .Characters.InsertAfter(aSlideTitles(x) & vbCrLf)
                With oRng.ActionSettings(ppMouseClick)
                    .Hyperlink.SubAddress = ActivePresentation.Slides(x).SlideID _
                        & "," & ActivePresentation.Slides(x).SlideIndex _
                        & "," & aSlideTitles(x)
                End With
            Next
        End With
    End With

End Sub

Function GetSlideTitle(oSl As Slide) As String

    Dim oSh As Shape
    Dim sTemp As String
    
    For Each oSh In oSl.Shapes
        If oSh.Type = msoPlaceholder Then
            If oSh.PlaceholderFormat.Type = ppPlaceholderCenterTitle _
                Or oSh.PlaceholderFormat.Type = ppPlaceholderTitle Then
                    sTemp = oSh.TextFrame.TextRange.Text
                    Exit For
            End If
        End If
    Next
    
    ' no title?  Assign a default title:
    If Len(sTemp) = 0 Then
        sTemp = "Slide " & CStr(oSl.SlideIndex)
    End If
    
    GetSlideTitle = sTemp
    
End Function


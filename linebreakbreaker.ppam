' put this file in C:\Program Files (x86)\Microsoft Office\Templates\1033\.... to prevent office from blocking this macro

Sub SayHello(ByVal control As IRibbonControl)
    Set m = ActivePresentation
    Set mySlide = ActivePresentation.Slides(ActiveWindow.Selection.SlideRange.SlideNumber)
    mySlide.Shapes.PasteSpecial (ppPasteText)
    
    Set myShape = mySlide.Shapes(mySlide.Shapes.Count)
    
    Dim myText As String
    myText = myShape.TextFrame.TextRange.Text
    'MsgBox myText
    myShape.Delete
    
    mySlide.Shapes(2).TextFrame.TextRange.Text = mySlide.Shapes(2).TextFrame.TextRange.Text & Chr(13) & Replace(myText, Chr(13), " ")

End Sub

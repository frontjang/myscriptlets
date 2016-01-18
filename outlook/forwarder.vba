Sub ChangeSubjectForward(Item As Outlook.MailItem)

'Item.Subject = Item.Subject
'Item.Save

Set myForward = Item.Forward
myForward.Recipients.Add "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
myForward.DeleteAfterSubmit = True
myForward.Subject = Item.Subject
myForward.Send

Item.Delete

Set outApp = CreateObject("outlook.application")
Set deleteItem = outApp.Session.GetItemFromID(Item.EntryID)
deleteItem.Delete

End Sub




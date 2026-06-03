// FC_JSONValidateDetail.4dm
// Form controller for JSONValidateDetail dialog
// Opens showing the validated JSON alongside its schema

property schemaLabel : Text
property schemaContent : Text
property jsonContent : Text

Class constructor($schemaName : Text; $schemaFile : 4D.File; $validatedJson : Object)
	This.schemaLabel:=$schemaName
	This.jsonContent:=JSON Stringify($validatedJson; *)
	If ($schemaFile#Null) && ($schemaFile.exists)
		var $raw : Text:=$schemaFile.getText()
		var $parsed : Object:=JSON Parse($raw)
		If ($parsed#Null)
			This.schemaContent:=JSON Stringify($parsed; *)
		Else 
			This.schemaContent:=$raw
		End if 
	Else 
		This.schemaContent:="(schema file not found)"
	End if 

//MARK: - Form event handler
Function formEventHandler($formEventCode : Integer)
	Case of 
		: ($formEventCode=On Load)
			OBJECT SET TITLE(*; "text_schema_label"; This.schemaLabel)
		: ($formEventCode=On Clicked)
			// handled by object methods
	End case 

Function btnCloseEventHandler($formEventCode : Integer)
	Case of 
		: ($formEventCode=On Clicked)
			CANCEL
	End case 

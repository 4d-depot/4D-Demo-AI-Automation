// AIWorkerContext.4dm
// Session singleton stores pending AI data per form window, keyed by window ID.
// Shared across all processes in the same session (form process + workers).
// Data is stored as JSON text because session singletons are shared objects
// and cannot hold regular (non-shared) objects/collections directly.

property _actionsJson : Object
property _linesJson : Object
property _contractRefs : Object

session singleton Class constructor()
	This._actionsJson:=New shared object()
	This._linesJson:=New shared object()
	This._contractRefs:=New shared object()

Function storeAction($windowID : Integer; $action : Object)
	Use (This._actionsJson)
		This._actionsJson[String($windowID)]:=JSON Stringify($action)
	End use 

Function getAction($windowID : Integer) : Object
	var $json : Text:=This._actionsJson[String($windowID)]
	return ($json#Null) && ($json#"") ? JSON Parse($json) : Null

Function storeExistingLines($windowID : Integer; $lines : Collection)
	Use (This._linesJson)
		This._linesJson[String($windowID)]:=JSON Stringify($lines)
	End use 

Function getExistingLines($windowID : Integer) : Collection
	var $json : Text:=This._linesJson[String($windowID)]
	return ($json#Null) && ($json#"") ? JSON Parse($json) : []

Function clearAction($windowID : Integer)
	Use (This._actionsJson)
		OB REMOVE(This._actionsJson; String($windowID))
	End use 
	Use (This._linesJson)
		OB REMOVE(This._linesJson; String($windowID))
	End use 

Function storeContractRef($windowID : Integer; $contractRef : Text)
	Use (This._contractRefs)
		This._contractRefs[String($windowID)]:=$contractRef
	End use 

Function getContractRef($windowID : Integer) : Text
	return String(This._contractRefs[String($windowID)])
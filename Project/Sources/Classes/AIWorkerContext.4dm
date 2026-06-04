// AIWorkerContext.4dm
// Process singleton — stores the pending AI action per form window, keyed by window ID.
// Eliminates JSON round-trip serialization of action objects through worker processes.
// Only accessed from the form process (write before CALL WORKER, read in CALL FORM callback).

singleton Class constructor()
	This.pendingActions := {}

Function storeAction($windowID : Integer; $action : Object)
	This.pendingActions[String($windowID)] := $action

Function getAction($windowID : Integer) : Object
	return This.pendingActions[String($windowID)]

Function clearAction($windowID : Integer)
	OB REMOVE(This.pendingActions; String($windowID))

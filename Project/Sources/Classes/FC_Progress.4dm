// FC_Progress.4dm
// Progress form controller — displays a spinner during worker processing
// Usage : var $p := cs.FC_Progress.new("Message…"; Formula(...))
//         DIALOG("Progress"; $p)

property message : Text
property detail : Text
property task : 4D.Function
property _spinnerIndex : Integer
property _frames : Collection

Class constructor($message : Text; $task : 4D.Function)
	This.message:=$message
	This.detail:=""
	This.task:=$task
	This._spinnerIndex:=0
	This._frames:=["⠋"; "⠙"; "⠹"; "⠸"; "⠼"; "⠴"; "⠦"; "⠧"; "⠇"; "⠏"]

//MARK: - Form event handler
Function formEventHandler($formEventCode : Integer)
	Case of 
		: ($formEventCode=On Load)
			This._onLoad()
		: ($formEventCode=On Timer)
			This._onTimer()
	End case 

//MARK: - Private
Function _onLoad()
	OBJECT SET TITLE(*; "text_message"; This.message)
	OBJECT SET TITLE(*; "text_spinner"; This._frames[0])
	SET TIMER(6)  // ~100ms → smooth spinner
	// Lancer le traitement dans un worker
	CALL WORKER("_progressWorker"; This.task; Current form window)

Function _onTimer()
	This._spinnerIndex:=(This._spinnerIndex+1)%(This._frames.length)
	OBJECT SET TITLE(*; "text_spinner"; This._frames[This._spinnerIndex])
	If (This.detail#"")
		OBJECT SET TITLE(*; "text_detail"; This.detail)
	End if 

// Called by the worker via CALL FORM when processing is complete
Function _onDone()
	SET TIMER(0)
	CANCEL

// FC_EmailDetail.4dm
// Scénario 1 (devis) et Scénario 3 (modification) — analyse IA + panneau d'actions

property email : cs.EmailEntity
property aiActions : Collection
property aiResult : Object
property running : Boolean
property _catalog : Collection

Class constructor($email : cs.EmailEntity)
	This.email:=$email
	This.aiActions:=[]
	This.aiResult:=Null
	This.running:=False
	This._catalog:=Null

//MARK: - Form & form objects event handlers
Function formEventHandler($formEventCode : Integer)
	Case of 
		: ($formEventCode=On Load)
			This._onLoad()
	End case 

Function btnBackEventHandler($formEventCode : Integer)
	Case of 
		: ($formEventCode=On Clicked)
			CANCEL
	End case 

Function btnAiAnalyzeEventHandler($formEventCode : Integer)
	Case of 
		: ($formEventCode=On Clicked)
			This._runAnalysis()
	End case 

Function btnAiAction1EventHandler($formEventCode : Integer)
	Case of 
		: ($formEventCode=On Clicked)
			This._executeAction(0)
	End case 

Function btnAiAction2EventHandler($formEventCode : Integer)
	Case of 
		: ($formEventCode=On Clicked)
			This._executeAction(1)
	End case 

Function btnAiAction3EventHandler($formEventCode : Integer)
	Case of 
		: ($formEventCode=On Clicked)
			This._executeAction(2)
	End case 

Function btnAiAction4EventHandler($formEventCode : Integer)
	Case of 
		: ($formEventCode=On Clicked)
			This._executeAction(3)
	End case 

//MARK: - Private
Function _onLoad()
	var $m : cs.EmailEntity:=This.email
	OBJECT SET TITLE(*; "text_subject"; $m.subject)
	OBJECT SET TITLE(*; "text_from_val"; $m.sender)
	OBJECT SET TITLE(*; "text_email_val"; $m.senderEmail)
	OBJECT SET TITLE(*; "text_date_val"; String($m.receivedAt; "EEEE dd MMMM yyyy"))
	OBJECT SET TITLE(*; "text_type_badge"; cs.UIHelpers.me.typeBadgeFull($m.emailType))
	OBJECT SET TITLE(*; "text_ai_sub"; This._aiSubtitle($m.emailType))

	// Email body — input field, use OBJECT SET VALUE
	OBJECT SET VALUE("text_body"; $m.body)

	If ($m.linkedEventID#"")
		var $evt : cs.EventEntity:=ds.Event.get($m.linkedEventID)
		If ($evt#Null)
			OBJECT SET TITLE(*; "text_linked_event"; "Linked to: "+$evt.contractRef+" – "+$evt.venue.name+" – "+String($evt.eventDate; "dd/MM/yyyy"))
		End if 
	End if 

	This._resetAIPanel()

Function _runAnalysis()
	This.running:=True
	OBJECT SET TITLE(*; "btn_ai_analyze"; "⏳ Analyzing...")
	OBJECT SET TITLE(*; "text_ai_status"; "AI is reading the email...")
	This._resetActionButtons()

	var $advisor : cs.AIAdvisor:=cs.AIAdvisor.new()
	var $emailType : Text:=This.email.emailType
	var $self : Object:=This

	Case of 
		: ($emailType="quote")
			OBJECT SET TITLE(*; "text_ai_status"; "Extracting quote information...")
			var $catalog : Collection:=This._getCatalog()
			$advisor.analyzeQuoteEmailAsync(This.email; $catalog; Formula($self._onQuoteAnalysisDone($1)))

		: ($emailType="modification")
			OBJECT SET TITLE(*; "text_ai_status"; "Identifying related events...")
			var $analyzer : cs.EmailAnalyzer:=cs.EmailAnalyzer.me
			var $candidates : Collection:=$analyzer.buildCandidateCollection(This.email)
			var $lines : Collection:=[]
			If ($candidates.length>0)
				$lines:=$analyzer.buildEventLinesCollection($candidates[0].eventID)
			End if 
			OBJECT SET TITLE(*; "text_ai_status"; "Analyzing modification impacts...")
			$advisor.analyzeModificationEmailAsync(This.email; $candidates; $lines; Formula($self._onModificationAnalysisDone($1)))

		Else 
			OBJECT SET TITLE(*; "text_ai_status"; "ℹ Info email – no action required.")
			This.running:=False
			OBJECT SET TITLE(*; "btn_ai_analyze"; "⚡ Analyze with AI")
	End case 

// ─── Callbacks async ─────────────────────────────────────────────────────────
Function _onQuoteAnalysisDone($result : Object)
	If (Form=Null)
		return 
	End if 
	This.aiResult:=$result
	This._renderQuoteResult($result)
	This.running:=False
	OBJECT SET TITLE(*; "btn_ai_analyze"; "⚡ Analyze with AI")

Function _onModificationAnalysisDone($result : Object)
	If (Form=Null)
		return 
	End if 
	This.aiResult:=$result
	This._renderModificationResult($result)
	This.running:=False
	OBJECT SET TITLE(*; "btn_ai_analyze"; "⚡ Analyze with AI")

Function _renderQuoteResult($result : Object)
	If (Not($result.success))
		OBJECT SET TITLE(*; "text_ai_status"; "⚠ Analysis failed")
		OBJECT SET TITLE(*; "text_ai_context"; $result.validationError)
		return 
	End if 

	var $ex : Object:=$result.extraction
	var $summary : Text:="Event type: "+$ex.eventType

	If ($ex.eventDate#Null)
		$summary:=$summary+"\nDate: "+$ex.eventDate
	End if 
	If ($ex.guestCount#Null) && ($ex.guestCount>0)
		$summary:=$summary+"\nGuests: "+String($ex.guestCount)
	End if 
	If ($ex.venueCity#Null) && ($ex.venueCity#"")
		$summary:=$summary+"\nCity: "+$ex.venueCity
	End if 
	If (($ex.missingFields#Null) && ($ex.missingFields.length>0))
		$summary:=$summary+"\n⚠ Missing: "+$ex.missingFields.extract("field").join(", ")
	End if 

	OBJECT SET TITLE(*; "text_ai_status"; "✦ Quote extraction complete")
	OBJECT SET TITLE(*; "text_ai_context"; $summary)
	OBJECT SET TITLE(*; "text_ai_validation_badge"; "✓ JSON Validate: schema_quote_extraction OK")

	This.aiActions:=$result.actions
	This._renderActionButtons($result.actions)

Function _renderModificationResult($result : Object)
	If (Not($result.success))
		OBJECT SET TITLE(*; "text_ai_status"; "⚠ Analysis failed")
		OBJECT SET TITLE(*; "text_ai_context"; $result.validationError)
		return 
	End if 

	var $data : Object:=$result.impacts
	OBJECT SET TITLE(*; "text_ai_validation_badge"; "✓ JSON Validate: schema_modification_impacts OK")

	If ($result.ambiguous)
		OBJECT SET TITLE(*; "text_ai_status"; "⚠ Ambiguous – multiple events match")
		var $candText : Text:="Please select the correct event:\n"
		var $cand : Object
		For each ($cand; $data.candidateEvents)
			$candText:=$candText+"• "+$cand.contractRef+" – "+$cand.venueName+" ("+$cand.eventDate+")\n"
		End for each 
		OBJECT SET TITLE(*; "text_ai_context"; $candText)

		var $disambActions : Collection:=[]
		var $i : Integer
		var $c : Object
		var $maxDisamb : Integer:=$data.candidateEvents.length
		If ($maxDisamb>4)
			$maxDisamb:=4
		End if 
		For ($i; 0; $maxDisamb-1)
			$c:=$data.candidateEvents[$i]
			$disambActions.push({actionType: "resolve_ambiguity"; label: $c.contractRef+" – "+$c.venueName; params: {eventID: $c.eventID}})
		End for 
		This.aiActions:=$disambActions
		This._renderActionButtons($disambActions)
	Else 
		var $ctx : Text:=$data.modificationSummary
		If ($data.totalExtraCost#Null)
			$ctx:=$ctx+"\n\nTotal impact: "+String($data.totalExtraCost; "### ### ##0 €")
		End if 
		If ($data.requiresAvenant)
			$ctx:=$ctx+"\n⚠ Amendment required"
		End if 
		OBJECT SET TITLE(*; "text_ai_status"; "✦ "+String($data.impacts.length)+" impacts identified")
		OBJECT SET TITLE(*; "text_ai_context"; $ctx)

		// Utiliser les executionActions retournées par l'IA (avec hiddenPrompt)
		var $actions : Collection:=Choose(($data.executionActions#Null); $data.executionActions; [])
		If ($actions.length=0)
			// Fallback si pas d'executionActions
			If ($data.requiresAvenant)
				$actions.push({actionType: "send_avenant"; label: "📝 Send Amendment to Client"; description: $data.draftAvenantMessage; hiddenPrompt: ""})
			End if 
		End if 
		This.aiActions:=$actions
		This._renderActionButtons($actions)
	End if 

Function _renderActionButtons($actions : Collection)
	cs.UIHelpers.me.showActionButtons($actions)

Function _resetActionButtons()
	cs.UIHelpers.me.resetActionButtons()

Function _resetAIPanel()
	This._resetActionButtons()
	OBJECT SET TITLE(*; "text_ai_status"; "Click 'Analyze with AI' to start.")
	OBJECT SET TITLE(*; "text_ai_context"; "")

Function _executeAction($index : Integer)
	If ($index>=This.aiActions.length)
		return 
	End if 
	var $action : Object:=This.aiActions[$index]
	var $type : Text:=$action.actionType

	// Si l'action a un hiddenPrompt, utiliser le Temps 2 (tool calling)
	If (($action.hiddenPrompt#Null) && ($action.hiddenPrompt#""))
		This._executeWithToolCalling($action)
		return 
	End if 

	// Fallback pour les actions sans hiddenPrompt
	Case of 
		: ($type="draft_reply")
			var $draft : Text:=Choose(($action.description#Null); $action.description; "No draft available.")
			ALERT("📧 Draft reply:\n\n"+$draft)
		: ($type="resolve_ambiguity")
			ALERT("Action: "+$action.label)
		Else 
			ALERT("Action: "+$action.label)
	End case 

// ─── Temps 2 : Exécution avec tool calling + dialogue confirmation ───────────
Function _executeWithToolCalling($action : Object)
	OBJECT SET TITLE(*; "text_ai_status"; "⏳ Searching services...")

	// Construire le contexte pour l'exécution
	var $context : Object:={}
	If (This.aiResult#Null)
		If (This.aiResult.extraction#Null)
			var $ex : Object:=This.aiResult.extraction
			If ($ex.guestCount#Null)
				$context.guestCount:=$ex.guestCount
			End if 
			If ($ex.venueCity#Null)
				$context.venueName:=$ex.venueCity
			End if 
			If ($ex.eventDate#Null)
				$context.eventDate:=$ex.eventDate
			End if 
		End if 
		// Pour les modifications, récupérer l'eventID de l'impacts
		If (This.aiResult.impacts#Null)
			$context.eventID:=This.aiResult.impacts.eventID
			// Charger les lignes existantes
			If ($context.eventID#"")
				var $analyzer : cs.EmailAnalyzer:=cs.EmailAnalyzer.me
				$context.existingLines:=$analyzer.buildEventLinesCollection($context.eventID)
			End if 
		End if 
	End if 

	var $advisor : cs.AIAdvisor:=cs.AIAdvisor.new()
	var $self : Object:=This
	var $act : Object:=$action
	var $ctx : Object:=$context
	$advisor.executeActionAsync($action.hiddenPrompt; $context; Formula($self._onExecutionDone($1; $act; $ctx)))

Function _onExecutionDone($execResult : Object; $action : Object; $context : Object)
	If (Form=Null)
		return 
	End if 

	If (Not($execResult.success))
		OBJECT SET TITLE(*; "text_ai_status"; "❌ "+$execResult.error)
		return 
	End if 

	OBJECT SET TITLE(*; "text_ai_status"; "")

	// Calculer le total actuel de l'événement (si applicable)
	var $elService : cs.EventLineService:=cs.EventLineService.me
	var $currentTotal : Real:=$elService.calculateTotal($context.existingLines)

	// Ouvrir le dialogue de confirmation
	var $fc : cs.FC_ActionConfirm:=cs.FC_ActionConfirm.new( \
		$action.label; \
		$execResult.summary; \
		$execResult.proposedLines; \
		$currentTotal \
	)
	DIALOG("ActionConfirm"; $fc)

	If (Not($fc.confirmed))
		OBJECT SET TITLE(*; "text_ai_status"; "Action annulée.")
		return 
	End if 

	// Appliquer les modifications en base
	$elService.applyProposedChanges($context.eventID; $execResult.proposedLines)
	OBJECT SET TITLE(*; "text_ai_status"; "✅ Action appliquée avec succès.")

//MARK: - Helpers
Function _getCatalog() : Collection
	If (This._catalog=Null)
		var $services : cs.ServiceSelection:=ds.Service.query("available = :1"; True)
		This._catalog:=[]
		var $svc : cs.ServiceEntity
		For each ($svc; $services)
			This._catalog.push({category: $svc.category; label: $svc.label; unit: $svc.unit; unitPrice: $svc.unitPrice})
		End for each 
	End if 
	return This._catalog

Function _aiSubtitle($type : Text) : Text
	Case of 
		: ($type="quote")
			return "Extract quote data, flag missing fields"
		: ($type="modification")
			return "Identify event & calculate impacts"
		Else 
			return "Read and summarize"
	End case 

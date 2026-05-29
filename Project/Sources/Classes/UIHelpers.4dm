// UIHelpers.4dm
// Fonctions UI partagées entre les form controllers (boutons d'action IA)

singleton Class constructor()

// ─── Masquer les 4 boutons d'action IA ────────────────────────────────────────
Function resetActionButtons()
	var $btns : Collection:=["btn_ai_action1"; "btn_ai_action2"; "btn_ai_action3"; "btn_ai_action4"]
	var $btn : Text
	For each ($btn; $btns)
		OBJECT SET VISIBLE(*; $btn; False)
		OBJECT SET TITLE(*; $btn; "")
	End for each 
	OBJECT SET TITLE(*; "text_ai_validation_badge"; "")

// ─── Afficher les boutons d'action IA (max 4) ─────────────────────────────────
Function showActionButtons($actions : Collection)
	var $btnNames : Collection:=["btn_ai_action1"; "btn_ai_action2"; "btn_ai_action3"; "btn_ai_action4"]
	var $maxAct : Integer:=$actions.length
	If ($maxAct>4)
		$maxAct:=4
	End if 
	var $i : Integer
	var $action : Object
	var $bName : Text
	For ($i; 0; $maxAct-1)
		$action:=$actions[$i]
		$bName:=$btnNames[$i]
		OBJECT SET VISIBLE(*; $bName; True)
		OBJECT SET TITLE(*; $bName; $action.label)
	End for 

// ─── Badges de type email ─────────────────────────────────────────────────────
// Version courte (listes)
Function typeBadge($type : Text) : Text
	Case of 
		: ($type="quote")
			return "📋 Quote"
		: ($type="modification")
			return "✏ Modification"
		: ($type="info")
			return "ℹ Info"
		Else 
			return $type
	End case 

// Version longue (détail)
Function typeBadgeFull($type : Text) : Text
	Case of 
		: ($type="quote")
			return "📋 QUOTE REQUEST"
		: ($type="modification")
			return "✏ MODIFICATION"
		: ($type="info")
			return "ℹ INFO"
		Else 
			return $type
	End case 

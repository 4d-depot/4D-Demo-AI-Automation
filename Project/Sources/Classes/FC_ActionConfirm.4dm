// FC_ActionConfirm.4dm
// Classe formulaire pour le dialogue de confirmation d'actions IA
// Affiche les lignes de services proposées et permet de confirmer/annuler

property title : Text
property summary : Text
property lines : Collection
property currentTotal : Real
property confirmed : Boolean

property impactDisplay : Text
property newTotalDisplay : Text

Class constructor($title : Text; $summary : Text; $proposedLines : Collection; $currentTotal : Real)
	This.title:=$title
	This.summary:=$summary
	This.currentTotal:=$currentTotal
	This.confirmed:=False

	// Préparer les lignes pour le listbox avec colonnes calculées
	This.lines:=[]
	var $impact : Real:=0
	var $line : Object
	For each ($line; $proposedLines)
		var $lineTotal : Real:=$line.quantity*$line.unitPrice
		var $deltaIcon : Text
		Case of 
			: ($line.delta="add")
				$deltaIcon:="➕"
				$impact:=$impact+$lineTotal
			: ($line.delta="remove")
				$deltaIcon:="➖"
				$impact:=$impact-$lineTotal
				$lineTotal:=-$lineTotal
			: ($line.delta="update")
				$deltaIcon:="✏️"
				$impact:=$impact+$lineTotal
		End case 
		This.lines.push({ \
			serviceID: $line.serviceID; \
			label: $line.label; \
			category: $line.category; \
			quantity: $line.quantity; \
			unitPrice: $line.unitPrice; \
			delta: $line.delta; \
			deltaIcon: $deltaIcon; \
			unitPriceDisplay: String($line.unitPrice; "### ### ##0.00 €"); \
			lineTotalDisplay: String(Abs($lineTotal); "### ### ##0.00 €"); \
			lineTotal: $lineTotal \
		})
	End for each 

	var $prefix : Text:=Choose($impact>=0; "+"; "")
	This.impactDisplay:=$prefix+String($impact; "### ### ##0.00 €")
	This.newTotalDisplay:=String(This.currentTotal+$impact; "### ### ##0.00 €")

// ─── Event handlers ──────────────────────────────────────────────────────────
Function formEventHandler($event : Integer)
	Case of 
		: ($event=On Load)
			OBJECT SET TITLE(*; "text_title"; This.title)
			OBJECT SET TITLE(*; "text_summary"; This.summary)
			OBJECT SET TITLE(*; "text_impact_value"; This.impactDisplay)
			OBJECT SET TITLE(*; "text_newtotal_value"; This.newTotalDisplay)
	End case 

Function btnConfirmHandler($event : Integer)
	Case of 
		: ($event=On Clicked)
			This.confirmed:=True
			CANCEL
	End case 

Function btnCancelHandler($event : Integer)
	Case of 
		: ($event=On Clicked)
			This.confirmed:=False
			CANCEL
	End case 

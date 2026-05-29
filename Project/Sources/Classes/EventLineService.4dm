// EventLineService.4dm
// Service partagé pour manipuler les EventLines (ajout, suppression, mise à jour)

singleton Class constructor()

// ─── Applique des modifications proposées par l'IA sur les lignes d'un event ──
Function applyProposedChanges($eventID : Text; $proposedLines : Collection)
	If (($eventID=Null) || ($eventID=""))
		return 
	End if 
	If (($proposedLines=Null) || ($proposedLines.length=0))
		return 
	End if 

	var $line : Object
	For each ($line; $proposedLines)
		Case of 
			: ($line.delta="add")
				var $newLine : cs.EventLineEntity:=ds.EventLine.new()
				$newLine.eventID:=$eventID
				$newLine.serviceID:=$line.serviceID
				$newLine.quantity:=$line.quantity
				$newLine.unitPrice:=$line.unitPrice
				$newLine.save()
			: ($line.delta="remove")
				var $toRemove : cs.EventLineSelection:=ds.EventLine.query("eventID = :1 AND serviceID = :2"; $eventID; $line.serviceID)
				$toRemove.drop()
			: ($line.delta="update")
				var $toUpdate : cs.EventLineSelection:=ds.EventLine.query("eventID = :1 AND serviceID = :2"; $eventID; $line.serviceID)
				If ($toUpdate.length>0)
					var $existing : cs.EventLineEntity:=$toUpdate.first()
					$existing.quantity:=$line.quantity
					$existing.save()
				End if 
		End case 
	End for each 

// ─── Calcule le total d'une collection de lignes ──────────────────────────────
Function calculateTotal($lines : Collection) : Real
	var $total : Real:=0
	If ($lines=Null)
		return $total
	End if 
	var $line : Object
	For each ($line; $lines)
		$total:=$total+($line.quantity*$line.unitPrice)
	End for each 
	return $total

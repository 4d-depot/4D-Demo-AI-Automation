// EmailAnalyzer.4dm
// Routing d'emails : identifie le type et le contexte sans appel IA
// L'IA intervient seulement après la pré-qualification

singleton Class constructor()

// ─── Recherche des événements candidats pour une modification ─────────────────
// Cherche par email du sender, puis par date ou référence mentionnée dans le corps
Function _findCandidateEvents($email : cs.EmailEntity) : Collection
	var $candidates : Collection:=[]

	// 1) Chercher le client par email du sender
	var $clientEmail : Text:=$email.senderEmail
	var $client : cs.ClientEntity:=ds.Client.query("email = :1"; $clientEmail).first()
	If ($client=Null)
		return $candidates
	End if

	// 2) Récupérer ses événements futurs (status confirmed ou quote)
	var $today : Date:=Current date
	var $events : cs.EventSelection:=ds.Event.query(\
		"clientID = :1 AND eventDate >= :2 AND (status = :3 OR status = :4)"; \
		$client.ID; $today; "confirmed"; "quote"\
	).orderBy("eventDate ASC")

	// 3) Scorer chaque événement selon mentions dans le body
	var $body : Text:=Lowercase($email.body)
	var $subject : Text:=Lowercase($email.subject)

	var $evt : cs.EventEntity
	var $score : Integer
	var $ref : Text
	var $dateStr : Text
	var $venue : cs.VenueEntity
	var $venueName : Text
	var $venueCity : Text
	For each ($evt; $events)
		$score:=0
		$ref:=Lowercase($evt.contractRef)
		$dateStr:=String($evt.eventDate; "yyyy-MM-dd")

		// Mention de la référence
		If ((Position($ref; $body)>0) || (Position($ref; $subject)>0))
			$score:=$score+10
		End if

		// Mention de la date
		If (Position($dateStr; $body)>0)
			$score:=$score+5
		End if

		// Mention du nom du venue
		$venue:=$evt.venue
		If ($venue#Null)
			$venueName:=Lowercase($venue.name)
			$venueCity:=Lowercase($venue.city)
			If ((Position($venueCity; $body)>0) || (Position($venueCity; $subject)>0))
				$score:=$score+3
			End if
			If (Position($venueName; $body)>0)
				$score:=$score+4
			End if
		End if

		// Toujours inclure si score > 0, ou si < 3 événements futurs (petit portefeuille)
		If (($score>0) || ($events.length<=3))
			$candidates.push({eventID: $evt.ID; contractRef: $evt.contractRef; eventDate: String($evt.eventDate; "yyyy-MM-dd"); venueName: (Choose($venue#Null; $venue.name; "")); guestCount: $evt.guestCount; score: $score})
		End if
	End for each

	// Trier par score décroissant
	$candidates:=$candidates.orderBy("score desc")

	// Limiter à 4 candidats max
	If ($candidates.length>4)
		$candidates:=$candidates.slice(0; 4)
	End if

	return $candidates

// ─── Construit la collection candidats pour AIAdvisor ────────────────────────
Function buildCandidateCollection($email : cs.EmailEntity) : Collection
	return This._findCandidateEvents($email)

// ─── Charge les lignes d'un événement pour le prompt IA ──────────────────────
Function buildEventLinesCollection($eventID : Text) : Collection
	var $lines : Collection:=[]
	var $selection : cs.EventLineSelection:=ds.EventLine.query("eventID = :1"; $eventID)
	var $line : cs.EventLineEntity
	var $service : cs.ServiceEntity
	For each ($line; $selection)
		$service:=$line.service
		$lines.push({serviceID: $line.serviceID; serviceLabel: (Choose($service#Null; $service.label; "Inconnu")); quantity: $line.quantity; unitPrice: $line.unitPrice})
	End for each
	return $lines

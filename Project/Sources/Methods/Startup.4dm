//%attributes = {}
// Startup.4dm
// Startup method for the Event Pulse application
// Called automatically by the Database Method "On Startup"
// AI provider and models configured in AIProviders.json

// 1. Amorcer la base si vide
cs.DataSeeder.me.seedIfEmpty()

// 2. Ouvrir le hub principal
var $w : Integer:=Open form window("Home"; Plain form window; Horizontally centered; Vertically centered)
DIALOG("Home")
CLOSE WINDOW($w)

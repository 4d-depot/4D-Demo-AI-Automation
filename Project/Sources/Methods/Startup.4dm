//%attributes = {}
// Startup.4dm
// Méthode de démarrage de l'application Event Pulse
// Appelée automatiquement par la Database Method "On Startup"
// Provider et modèles IA configurés dans AIProviders.json

// 1. Amorcer la base si vide
cs.DataSeeder.me.seedIfEmpty()

// 2. Ouvrir le hub principal
var $w : Integer:=Open form window("Home"; Plain form window; Horizontally centered; Vertically centered)
DIALOG("Home")
CLOSE WINDOW($w)

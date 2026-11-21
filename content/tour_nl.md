<!--
Visite guidée. Une section = une étape, dans l'ordre du fichier.
  tab:    onglet à ouvrir (accueil, cours, decouverte, exercices, dashboard)
  target: sélecteur CSS de l'élément à entourer (facultatif -> bulle centrée)
  ##      titre de la bulle, le reste est du markdown
  {base}  nom de l'objet de la base choisie (ex. BDD_NAIS), {titre_base} son titre
  {liste_bases} la liste des bases disponibles, {nb_bases} leur nombre
Si la cible n'est pas visible à l'écran, la bulle s'affiche au centre.
-->


# 01-bienvenue
tab: accueil
## Welkom in het {titre_app}
Dit atelier helpt je om een databank te leren analyseren met R of Python.

Deze rondleiding stelt de interface voor in enkele stappen. Gebruik **Volgende**, de pijltjestoetsen, of **Esc** om te stoppen.

# 02-base
target: #base
## Kies je databank
Beschikbare databanken: {liste_bases}.

Je werkt nu op **{base}** ({titre_base}). Een andere databank kiezen werkt **alle** tabbladen bij.

# 03-dico
target: #btn_dico
## Het woordenboek van de variabelen
Deze knop toont op elk moment de lijst van de kolommen van de databank, hun betekenis en hun codes. Houd de reflex: een variabele raad je niet, je leest ze in de documentatie.

# 04-cours
tab: cours
target: #cours-lessons
## De cursus, les per les
De lessen gaan van de eerste commando's tot een **volledige casestudy**. Elke les is opgedeeld in kaarten.

# 05-carte
tab: cours
target: .lesson-card
## Eén kaart = één begrip
Elke kaart toont een uitleg, de **code**, het **resultaat** (echt berekend op de databank), en dan een commentaar. De oranje kaders wijzen op klassieke valkuilen.

Ga van de ene kaart naar de andere met de knoppen of de **pijltjestoetsen**.

# 06-essayer
tab: cours
target: #cours-try
## Aan de slag
Deze knop kopieert de code van de kaart naar het tabblad **Ontdekken**, waar je ze kunt aanpassen en opnieuw uitvoeren.

# 07-decouverte
tab: decouverte
target: #decouverte-pistes
## Het tabblad Ontdekken
Begeleide sporen, elk met een startcode en ideeën om uit te proberen. En een **vrije zandbak** voor je eigen proeven.

# 08-editeur
tab: decouverte
target: .editor-card
## De code-editor
Pas de code aan en klik dan op **Uitvoeren** of druk op **Ctrl + Enter**. De code wordt uitgevoerd in een beschermde ruimte: je kunt niets stukmaken, en de oorspronkelijke databank blijft intact.

# 09-objets
tab: decouverte
target: #decouverte-objets
## Je objecten
De objecten die je aanmaakt, verschijnen hier en blijven beschikbaar van de ene uitvoering tot de andere. **Nieuwe omgeving** begint opnieuw van nul.

# 10-exercices
tab: exercices
target: #exercices-liste
## De oefeningen
Een opbouw in vijf niveaus, van de eerste filters tot volledige verwerkingen. Geslaagde oefeningen worden aangevinkt en in je browser onthouden.

# 11-verifier
tab: exercices
target: #exercices-check
## Je antwoord controleren
**Controleren** vergelijkt het resultaat van je laatste coderegel met dat van de oplossing. De kolomnamen mogen verschillen: het zijn de waarden die tellen.

Een **hint** is beschikbaar, en de **oplossing met commentaar** wanneer je wilt.

# 12-dashboard
tab: dashboard
## Het dashboard
Tot slot een interactief dashboard. Elke grafiek heeft een knop **Code bekijken**: je vindt er de werkwoorden van de cursus terug.

Veel succes!

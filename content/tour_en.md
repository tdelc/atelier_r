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
## Welcome to the {titre_app}
This workshop helps you learn to analyse a dataset with R or Python.

This tour presents the interface in a few steps. Use **Next**, the arrow keys, or **Esc** to quit.

# 02-base
target: #base
## Choose your dataset
Available datasets: {liste_bases}.

You are currently working on **{base}** ({titre_base}). Changing the dataset updates **all** the tabs.

# 03-dico
target: #btn_dico
## The variable dictionary
At any time, this button shows the list of the dataset's columns, their meaning and their codes. Keep the habit: a variable is not guessed, it is read in the documentation.

# 04-cours
tab: cours
target: #cours-lessons
## The course, lesson by lesson
The lessons go from the first commands to a **complete case study**. Each one is split into cards.

# 05-carte
tab: cours
target: .lesson-card
## One card = one idea
Each card shows an explanation, the **code**, its **result** (really computed on the dataset), then a comment. The orange boxes point out classic pitfalls.

Move from one card to the next with the buttons or the **arrow keys**.

# 06-essayer
tab: cours
target: #cours-try
## Try it yourself
This button copies the card's code into the **Explore** tab, where you can modify and run it again.

# 07-decouverte
tab: decouverte
target: #decouverte-pistes
## The Explore tab
Guided tracks, each with starting code and ideas to try. And a **free sandbox** for your own experiments.

# 08-editeur
tab: decouverte
target: .editor-card
## The code editor
Edit the code, then click **Run** or press **Ctrl + Enter**. The code runs in a protected space: you cannot break anything, and the original dataset stays intact.

# 09-objets
tab: decouverte
target: #decouverte-objets
## Your objects
The objects you create appear here and remain available from one run to the next. **New environment** starts again from scratch.

# 10-exercices
tab: exercices
target: #exercices-liste
## The exercises
A progression in five levels, from the first filters to complete processing. Solved exercises are ticked and remembered in your browser.

# 11-verifier
tab: exercices
target: #exercices-check
## Check your answer
**Check** compares the result of your last line of code with that of the solution. Column names may differ: what counts are the values.

A **hint** is available, and the **commented solution** whenever you want.

# 12-dashboard
tab: dashboard
## The dashboard
Finally, an interactive dashboard. Each chart has a **See the code** button: you will find the verbs of the course there.

Good work!

# Exécuté en silence au début de chaque leçon, piste et exercice :
# les paquets sont importés et les tables sont prêtes, comme dans un script
# qui commencerait par ces lignes.
import pandas as pd
import numpy as np

communes = pd.read_parquet("donnees/communes_2026.parquet")
pop_sexe = pd.read_parquet("donnees/pop_sexe_2026.parquet")

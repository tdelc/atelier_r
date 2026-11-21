# Exécuté en silence au début de chaque leçon, piste et exercice :
# les paquets sont importés et la table est prête, comme dans un script
# qui commencerait par ces lignes.
import pandas as pd
import numpy as np

personnes = pd.read_parquet("donnees/personnes_2025.parquet")

# Exécuté en silence au début de chaque leçon, piste et exercice :
# les paquets sont importés et la table est prête, comme dans un script
# qui commencerait par ces lignes.
import pandas as pd
import numpy as np

entreprises = pd.read_parquet("donnees/entreprises_2025.parquet")

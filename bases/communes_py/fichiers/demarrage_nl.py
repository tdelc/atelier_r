# Wordt stil uitgevoerd aan het begin van elke les, elk spoor en elke oefening:
# de pakketten zijn geïmporteerd en de tabellen staan klaar, zoals in een
# script dat met deze regels zou beginnen.
import pandas as pd
import numpy as np

gemeenten = pd.read_parquet("gegevens/gemeenten_2026.parquet")
bevolking_geslacht = pd.read_parquet("gegevens/bevolking_geslacht_2026.parquet")

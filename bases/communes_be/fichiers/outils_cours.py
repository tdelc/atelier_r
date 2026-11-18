"""Fonctions fournies pour le cours (demi-journées 2 à 5).

charger_lignes(chemin)  lit un fichier CSV (;), Excel (deux lignes de titre)
                        ou TXT tabulé et renvoie une liste de dictionnaires ;
                        une valeur manquante vaut None.
harmoniser_code(code)   ' 62063 ' -> '62063' ; '1000' -> '01000'.
harmoniser_sexe(valeur) 'f', ' H ' -> 'F', 'H' ; sinon None.
"""

import math

import pandas as pd


def charger_lignes(chemin):
    """Lit un fichier de population et renvoie une liste de dictionnaires."""
    if chemin.endswith(".xlsx"):
        df = pd.read_excel(chemin, header=2, dtype={"code_ins": str})
    elif chemin.endswith(".txt"):
        df = pd.read_csv(chemin, sep="\t", dtype={"code_ins": str})
    else:
        df = pd.read_csv(chemin, sep=";", dtype={"code_ins": str})
    lignes = []
    for ligne in df.to_dict("records"):
        for cle, valeur in ligne.items():
            if isinstance(valeur, float) and math.isnan(valeur):
                ligne[cle] = None
            elif isinstance(valeur, float) and valeur.is_integer():
                ligne[cle] = int(valeur)
            elif hasattr(valeur, "item"):
                ligne[cle] = valeur.item()
        lignes.append(ligne)
    return lignes


def harmoniser_code(code, longueur=5):
    """' 62063 ' -> '62063' ; '1000' -> '01000'."""
    return str(code).strip().zfill(longueur)


def harmoniser_sexe(valeur):
    """Renvoie 'H' ou 'F', ou None si la valeur n'est pas reconnue."""
    if valeur is None:
        return None
    valeur = str(valeur).strip().upper()
    if valeur in ("H", "F"):
        return valeur
    return None

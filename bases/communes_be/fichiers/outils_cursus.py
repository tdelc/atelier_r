"""Hulpfuncties voor de cursus (halve dagen 2 tot 5).

laad_rijen(pad)              leest een CSV-bestand (;), een Excel-bestand (twee
                             titelregels) of een tab-gescheiden TXT-bestand en
                             geeft een lijst van woordenboeken terug; een
                             ontbrekende waarde wordt None.
harmoniseer_code(code)       ' 62063 ' -> '62063' ; '1000' -> '01000'.
harmoniseer_geslacht(waarde) 'v', ' M ' -> 'V', 'M' ; anders None.
"""

import math

import pandas as pd


def laad_rijen(pad):
    """Leest een bevolkingsbestand en geeft een lijst van woordenboeken terug."""
    if pad.endswith(".xlsx"):
        df = pd.read_excel(pad, header=2, dtype={"nis_code": str})
    elif pad.endswith(".txt"):
        df = pd.read_csv(pad, sep="\t", dtype={"nis_code": str})
    else:
        df = pd.read_csv(pad, sep=";", dtype={"nis_code": str})
    rijen = []
    for rij in df.to_dict("records"):
        for sleutel, waarde in rij.items():
            if isinstance(waarde, float) and math.isnan(waarde):
                rij[sleutel] = None
            elif isinstance(waarde, float) and waarde.is_integer():
                rij[sleutel] = int(waarde)
            elif hasattr(waarde, "item"):
                rij[sleutel] = waarde.item()
        rijen.append(rij)
    return rijen


def harmoniseer_code(code, lengte=5):
    """' 62063 ' -> '62063' ; '1000' -> '01000'."""
    return str(code).strip().zfill(lengte)


def harmoniseer_geslacht(waarde):
    """Geeft 'M' of 'V' terug, of None als de waarde niet herkend wordt."""
    if waarde is None:
        return None
    waarde = str(waarde).strip().upper()
    if waarde in ("M", "V"):
        return waarde
    return None

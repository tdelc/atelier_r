---
titre: Une analyse de A à Z
resume: Étude de cas complète - la pauvreté des enfants. Le rôle du type de ménage et du travail des parents ; un indicateur pondéré, sa précision, ses limites.
partie: Étude de cas
---

# La question

« Un enfant sur six vit sous le seuil de pauvreté. » Pourquoi ? Est-ce une question de région, de type de famille, de travail des parents ?

On découpe la question :

1. Quel est le risque de pauvreté des enfants (moins de 18 ans), par région ?
2. Selon le type de ménage ?
3. Selon le travail des adultes du ménage ?
4. Que peut-on conclure, et avec quelle **précision** ?

::: etape
**La démarche** : une question → les données utiles → un tableau pondéré → un graphique → une conclusion en une phrase, avec ses limites.
:::

::: piege
Rappel : ces personnes sont **fictives**. La démarche est la bonne ; les chiffres ne décrivent pas la Belgique.
:::

# Étape 1 : le seuil, et une fonction de taux pondéré

On écrit une fois le calcul du taux pondéré, pour le réutiliser à chaque étape :

```python
tri = personnes.sort_values("revenu_equivalent")
cumul = tri["poids"].cumsum()
seuil = 0.6 * tri.loc[cumul >= tri["poids"].sum() / 2, "revenu_equivalent"].iloc[0]
personnes["pauvres_pond"] = (personnes["revenu_equivalent"] < seuil) * personnes["poids"]

def taux_pauvrete(table, groupe):
    t = table.groupby(groupe, as_index=False).agg(repondants=("id_personne", "count"),
                                                  pauvres=("pauvres_pond", "sum"),
                                                  population=("poids", "sum"))
    t["taux"] = (t["pauvres"] / t["population"] * 100).round(1)
    return t.drop(columns="pauvres")

enfants = personnes.query("age < 18")
taux_pauvrete(enfants, "region")
```

::: usage
`def` crée une **fonction** : un calcul nommé, que l'on rappelle avec d'autres tables ou d'autres groupes. La leçon « Boucles et fonctions » y revient.
:::

**Lecture :** 28,3 % des enfants bruxellois, 20,0 % des enfants wallons et 12,6 % des enfants flamands vivent sous le seuil.

# Étape 2 : selon le type de ménage

```python
taux_pauvrete(enfants, "type_menage")
```

**Lecture :** dans une famille monoparentale, près de quatre enfants sur dix (39,1 %) sont sous le seuil ; dans un couple, environ un sur dix (11,1 %). Avec un seul revenu possible et les mêmes besoins, le parent seul est beaucoup plus exposé.

# Étape 3 : selon le travail des adultes

On reprend l'**intensité de travail** du ménage (leçon « Créer des variables ») :

```python
adulte = personnes["age"].between(18, 59) & (personnes["statut"] != "étudiant")
personnes["adulte"] = adulte
personnes["adulte_en_emploi"] = adulte & (personnes["statut"] == "en emploi")
personnes["nb_adultes"] = personnes.groupby("id_menage")["adulte"].transform("sum")
personnes["nb_en_emploi"] = personnes.groupby("id_menage")["adulte_en_emploi"].transform("sum")
personnes["intensite"] = np.select(
    [personnes["nb_adultes"] == 0, personnes["nb_en_emploi"] == 0,
     personnes["nb_en_emploi"] < personnes["nb_adultes"]],
    ["sans adulte d'âge actif", "personne ne travaille", "une partie travaille"],
    default="tous travaillent")

enfants = personnes.query("age < 18")
taux_pauvrete(enfants, "intensite")
```

**Lecture :** quand personne ne travaille dans le ménage, près de neuf enfants sur dix sont sous le seuil ; quand tous les adultes travaillent, 6,9 %. Le travail des parents sépare les situations bien plus que la région.

# Étape 4 : un graphique pour le montrer

```python
import seaborn as sns
import matplotlib.pyplot as plt

t = taux_pauvrete(enfants.query("intensite != \"sans adulte d'âge actif\""),
                  ["type_menage", "intensite"])
t = t.query("type_menage in ['couple avec enfants', 'famille monoparentale']")
sns.barplot(data=t, x="taux", y="intensite", hue="type_menage",
            order=["personne ne travaille", "une partie travaille", "tous travaillent"])
plt.title("Risque de pauvreté des enfants (données fictives)")
plt.xlabel("% des enfants sous le seuil")
plt.ylabel("Adultes du ménage en emploi")
```

# Étape 5 : la précision d'un taux

Un taux calculé sur quelques dizaines de répondants est fragile. Ordre de grandeur de la marge d'erreur à 95 % (en supposant un tirage aléatoire simple) :

```python
t = taux_pauvrete(enfants, "intensite")
p = t["taux"] / 100
t["marge"] = (1.96 * np.sqrt(p * (1 - p) / t["repondants"]) * 100).round(1)
t[["intensite", "repondants", "taux", "marge"]]
```

::: piege
Cette marge est **optimiste** : les enfants d'un même ménage se ressemblent (même revenu !), et le plan de sondage n'est pas aléatoire simple. Les vraies enquêtes publient des marges calculées avec leur plan de sondage. Retenez l'ordre de grandeur : sur quelques centaines de répondants, quelques points de pourcentage ; sur moins de 30, ne publiez pas. La ligne « sans adulte d'âge actif » ne repose que sur 9 enfants : sa marge nulle n'a aucun sens.
:::

# Conclusion, et ses limites

**Ce que les données montrent** : la pauvreté des enfants est d'abord liée au **travail des adultes** du ménage et au **type de ménage** ; les écarts entre régions reflètent en grande partie ces deux facteurs (plus de familles monoparentales et de ménages sans emploi à Bruxelles).

**Ce qu'elles ne montrent pas** :

- la **causalité** : un parent seul travaille moins souvent, parce qu'il est seul ; les deux facteurs se mêlent, et un tableau croisé ne les sépare pas ;
- la **privation réelle** : le seuil est relatif ; d'autres indicateurs (privation matérielle, coût du logement) complètent le tableau ;
- le **revenu exact** : dans les vraies enquêtes, le revenu vient de plus en plus des fichiers fiscaux et sociaux, couplés à l'enquête ; c'est l'objet de la partie suivante.

::: etape
**À retenir** : en statistique sociale, chaque taux se calcule avec les **poids**, se lit avec son **dénominateur**, et se publie avec sa **précision**.
:::

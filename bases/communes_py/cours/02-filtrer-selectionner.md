---
titre: Filtrer et sélectionner
resume: Garder certaines lignes avec query(), certaines colonnes avec [[...]] ; combiner les conditions.
partie: Les bases
---

# query() : garder les lignes qui respectent une condition

Quelles sont les communes de plus de 100 000 habitants ?

```python
communes.query("total > 100000")
```

::: usage
`.query("condition")` garde les lignes pour lesquelles la condition est **vraie**. La condition s'écrit entre guillemets, avec les noms des colonnes.
:::

::: sas
`WHERE total > 100000;`
:::

# Les opérateurs de comparaison

| Opérateur | Signification | Exemple |
|---|---|---|
| `==` | égal à | `province == 'Namur'` |
| `!=` | différent de | `region != 'Flandre'` |
| `>`, `>=` | supérieur (ou égal) | `total >= 50000` |
| `<`, `<=` | inférieur (ou égal) | `total < 1000` |

```python
communes.query("total < 2000")
```

**Lecture :** 4 communes comptent moins de 2 000 habitants. La plus petite de Belgique, Herstappe (Limbourg), en compte 78.

::: piege
**Égal s'écrit `==`** (deux signes). Un seul `=` sert à ranger un résultat sous un nom. En SAS, `=` sert aux deux : c'est l'erreur la plus fréquente au début.
:::

# Le texte s'écrit entre guillemets

Dans une condition sur une colonne de texte, la valeur s'écrit entre guillemets **simples**, puisque toute la condition est déjà entre guillemets doubles.

```python
communes.query("province == 'Luxembourg'")
```

::: piege
Les majuscules et les accents comptent : `'liège'` ou `'Liege'` ne trouvent rien. En cas de doute, regardez les valeurs exactes avec `communes["province"].unique()`.
:::

```python
communes["province"].unique()
```

# Plusieurs conditions : and, or

- `and` : les **deux** conditions sont vraies ;
- `or` : **au moins une** des conditions est vraie.

Les communes wallonnes de plus de 50 000 habitants :

```python
communes.query("region == 'Wallonie' and total > 50000")
```

Les communes de Namur **ou** de Luxembourg de moins de 3 000 habitants : les parenthèses décident de l'ordre.

```python
communes.query("(province == 'Namur' or province == 'Luxembourg') and total < 3000")
```

::: sas
`WHERE (province = 'Namur' or province = 'Luxembourg') and total < 3000;`
:::

# in : une liste de valeurs

Pour plusieurs valeurs d'une même colonne, `in` et une liste entre crochets sont plus courts qu'une série de `or`.

```python
communes.query("commune in ['Liège', 'Namur', 'Charleroi', 'Mons']")
```

::: sas
`WHERE commune in ('Liège', 'Namur', 'Charleroi', 'Mons');`
:::

# [[...]] : garder certaines colonnes

Une **liste** de noms de colonnes, entre doubles crochets, garde ces colonnes, dans cet ordre.

```python
communes[["commune", "province", "total"]]
```

::: usage
- Les crochets extérieurs veulent dire « dans la table, prends… » ; les crochets intérieurs forment la **liste** des colonnes.
- Avec des crochets simples, `communes["total"]`, on obtient une seule colonne (vue en mise en route).
:::

::: sas
`KEEP commune province total;`
:::

# drop() : retirer des colonnes

```python
communes.drop(columns=["hommes", "femmes"]).head(3)
```

::: sas
`DROP hommes femmes;`
:::

# rename() : renommer des colonnes

```python
communes.rename(columns={"total": "population"}).head(3)
```

::: usage
`{"ancien": "nouveau"}` est un **dictionnaire** : on y associe chaque ancien nom à son nouveau nom. On peut en renommer plusieurs : `{"total": "population", "region": "région"}`.
:::

::: sas
`RENAME total = population;`
:::

# Filtrer puis sélectionner

Les étapes s'enchaînent : les communes de la province de Liège de plus de 30 000 habitants, avec leur nom et leur population seulement.

```python
(communes
 .query("province == 'Liège' and total > 30000")
 [["commune", "total"]])
```

# Une autre écriture du filtre, très répandue

Dans le code trouvé en ligne, vous verrez souvent une autre écriture : une condition sur une colonne, entre crochets.

```python
communes[communes["total"] > 100000][["commune", "total"]]
```

Plusieurs conditions s'écrivent alors avec `&` (et), `|` (ou), et **des parenthèses autour de chaque condition** :

```python
communes[(communes["region"] == "Wallonie") & (communes["total"] > 50000)]
```

::: note
Les deux écritures donnent le même résultat. Dans ce cours, on préfère `query()`, plus lisible et plus proche du `WHERE` de SAS. Mais il faut savoir lire l'autre.
:::

# Des conditions sur le texte

`.str.startswith()` teste le début d'un texte, `.str.contains()` cherche un morceau de texte. Elles s'utilisent dans `query()` comme une condition.

Les communes de l'arrondissement de Liège : leur code INS commence par `62`.

```python
communes.query("code_ins.str.startswith('62')").shape
```

Les communes dont le nom contient « Saint » :

```python
communes.query("commune.str.contains('Saint')")[["commune", "province"]]
```

::: sas
`WHERE code_ins =: '62';` et `WHERE index(commune, 'Saint') > 0;`
:::

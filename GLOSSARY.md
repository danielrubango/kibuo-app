# kibuo

Vocabulaire de l'application de gestion de budget personnelle. Le terme anglais entre parenthèses est le nom à utiliser dans le code.

## Language

### Argent et comptes

**Compte** (`Account`) :
Endroit où se trouve de l'argent. Il a une seule devise et un type.
_Avoid_ : portefeuille, wallet

**Solde de départ** (`opening balance`) :
Ce que contenait un compte à une date choisie à sa création. Les opérations qui suivent cette date le font évoluer.

**Découvert** (`overdraft`) :
Ce qu'un compte peut descendre sous zéro. Il est autorisé ou non, compte par compte ; autorisé, il va jusqu'à une limite ou sans limite.

**Régularisation** (`balance adjustment`) :
Dépense ou revenu qui ramène le solde d'un compte à ce qu'il contient vraiment, quand on tape son solde réel au lieu de noter chaque opération.

**Compte archivé** (`archived account`) :
Compte retiré des listes et des totaux, dont les opérations restent.

**Type de compte** (`AccountType`) :
Nature d'un compte, avec son icône. Quatre types sont fournis, et l'utilisateur peut en créer d'autres.

**Opération** (`Transaction`) :
Mouvement d'argent enregistré : dépense, revenu ou transfert.
_Avoid_ : transaction (en français), écriture, mouvement

**Dépense** (`Expense`) :
Opération qui fait sortir de l'argent d'un compte.

**Revenu** (`Income`) :
Opération qui fait entrer de l'argent dans un compte.
_Avoid_ : entrée

**Transfert** (`Transfer`) :
Opération qui déplace de l'argent entre deux comptes de l'utilisateur.

**Brouillon** (`Draft`) :
Opération préparée mais pas encore validée, sans effet sur les soldes.

**Catégorie** (`Category`) :
Classement d'une opération. Peut avoir un seul niveau de sous-catégories.

### Devises

**Devise** (`Currency`) :
Monnaie dans laquelle un compte est tenu ou une opération est payée, désignée par son code international (USD, CDF, EUR). Elle dit si elle utilise des décimales.

**Devise principale** (`PrimaryCurrency`) :
Devise de suivi et valeur proposée par défaut. Elle ne modifie jamais la devise d'un compte.

**Taux de conversion** (`ExchangeRate`) :
Valeur d'une devise par rapport à une autre, saisie et modifiable par l'utilisateur.

**Taux figé** (`AppliedRate`) :
Taux enregistré sur une opération au moment de la conversion. Il ne change plus quand le taux de conversion évolue.

### Planification

**Budget** (`Budget`) :
Montant prévu pour une catégorie sur une période budgétaire, en devise principale.

**Période budgétaire** (`BudgetPeriod`) :
Durée d'un mois commençant au jour choisi par l'utilisateur.

**Récurrence** (`RecurringRule`) :
Règle qui produit une opération à intervalle régulier.

**Occurrence** (`Occurrence`) :
Opération ou brouillon produit par une récurrence pour une date donnée.

**Aperçu** (`Overview`) :
Onglet qui montre l'argent sur une période : ce qui sort et ce qui entre (Évolution), où il part (Catégories), ce que je possède (Patrimoine).

**Période de l'aperçu** (`PeriodKind`, `TimeSpan`) :
Durée montrée par l'aperçu : aujourd'hui, hier, 24 h, 7 jours, 1 mois, 1 an ou personnalisée. Le mois et l'année suivent la période budgétaire.
_Avoid_ : période budgétaire, pour ce sens

**Regroupement** (`Grouping`) :
Ce que tient une barre du graphique : une heure, un jour, une semaine (7 jours depuis le début de la période) ou un mois.

**Période comparée** (`Comparison`) :
Période mise en regard de celle de l'aperçu : celle d'avant, celle d'après, l'actuelle, ou aucune.

**Écart** (`Change`) :
Différence en pourcentage avec la période comparée, vert quand c'est bon signe (moins dépensé, plus reçu), ambre sinon.

**Rappel** (`Reminder`) :
Notification programmée invitant à agir : noter, verser, rembourser, réclamer.
_Avoid_ : alerte, pour ce sens

**Alerte de budget** (`BudgetAlert`) :
Notification déclenchée lorsqu'un budget atteint un seuil.

### Dettes, créances et projets

**Dette** (`Debt`) :
Argent que l'utilisateur doit à quelqu'un.

**Créance** (`Receivable`) :
Argent que quelqu'un doit à l'utilisateur.
_Avoid_ : prêt

**Contrepartie** (`Counterparty`) :
Nom de la personne concernée par une dette ou une créance.
_Avoid_ : contact

**Échéance** (`DueDate`) :
Date à laquelle une dette ou une créance doit être réglée.

**Remboursement** (`Repayment`) :
Paiement, total ou partiel, qui réduit une dette ou une créance.

**Projet** (`SavingsProject`) :
But d'épargne : voyage, achat, réserve.
_Avoid_ : objectif, goal

**Versement** (`Contribution`) :
Montant mis de côté pour un projet sur le compte qui le porte.

**Réservé** (`Reserved`) :
Part du solde d'un compte attribuée à ses projets. Le reste est disponible.

### Données et appareils

**Sauvegarde** (`Backup`) :
Copie complète des données de l'application, restaurable.

**Export** (`Export`) :
Fichier CSV destiné à être lu dans un tableur. Il ne se restaure pas.

**Restauration** (`Restore`) :
Remplacement complet des données par celles d'une sauvegarde.

**Code de récupération** (`RecoveryCode`) :
Code remis à l'utilisateur pour retrouver l'accès sans son PIN.

**Coffre** (`Vault`) :
Espace à protection renforcée où sont gardées les cartes virtuelles.

**Compte kibuo** (`UserAccount`) :
Identité d'un utilisateur auprès du service en ligne. Toujours écrit en entier, pour le distinguer d'un compte.
_Avoid_ : compte, seul, pour ce sens ; profil

**Appareil** (`Device`) :
Téléphone ou autre terminal où l'application contient les données de l'utilisateur.

**Conflit** (`SyncConflict`) :
Divergence entre deux appareils que seul l'utilisateur peut trancher.

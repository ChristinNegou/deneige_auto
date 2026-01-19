# Conformité à la Loi 25 du Québec

**Guide de conformité pour Deneige-Auto**
*Dernière mise à jour : 19 janvier 2025*

---

## Qu'est-ce que la Loi 25 ?

La Loi 25 (Loi modernisant des dispositions législatives en matière de protection des renseignements personnels) est entrée en vigueur progressivement depuis septembre 2022. Elle impose de nouvelles obligations aux entreprises qui collectent des renseignements personnels au Québec.

---

## Obligations et mesures de conformité

### ✅ 1. Désignation d'un responsable de la protection des renseignements personnels

**Obligation :** Désigner une personne responsable de la protection des renseignements personnels.

**Action requise :**
- [ ] Désigner officiellement un responsable (peut être le dirigeant de l'entreprise)
- [ ] Publier ses coordonnées sur le site web et dans l'application
- [ ] S'assurer qu'il peut être contacté facilement

**Exemple pour Deneige-Auto :**
```
Responsable : [Nom du responsable]
Courriel : privacy@deneige-auto.com
Téléphone : [Numéro]
```

---

### ✅ 2. Politique de confidentialité

**Obligation :** Avoir une politique de confidentialité claire et accessible.

**Statut :** ✅ Créée (voir `politique-confidentialite.md`)

**Éléments requis inclus :**
- [x] Coordonnées du responsable
- [x] Types de renseignements collectés
- [x] Finalités de la collecte
- [x] Moyens de collecte
- [x] Droits des personnes concernées
- [x] Durée de conservation
- [x] Transferts hors Québec
- [x] Utilisation de l'IA et décisions automatisées

---

### ✅ 3. Consentement

**Obligation :** Obtenir un consentement manifeste, libre et éclairé.

**Actions dans l'application :**

1. **À l'inscription :**
   - [ ] Case à cocher pour accepter la politique de confidentialité
   - [ ] Case à cocher pour accepter les conditions d'utilisation
   - [ ] Lien vers les documents complets

2. **Pour la géolocalisation :**
   - [ ] Demander la permission avant d'accéder au GPS
   - [ ] Expliquer pourquoi c'est nécessaire
   - [ ] Permettre de refuser (avec limitations du service)

3. **Pour les notifications :**
   - [ ] Demander la permission séparément
   - [ ] Expliquer les types de notifications

4. **Pour les photos :**
   - [ ] Demander la permission avant d'accéder à la caméra
   - [ ] Expliquer l'utilisation des photos

---

### ✅ 4. Droit d'accès et de rectification

**Obligation :** Permettre aux utilisateurs d'accéder à leurs données et de les corriger.

**Actions dans l'application :**
- [ ] Section "Mes données" dans les paramètres
- [ ] Bouton "Demander mes données" (export)
- [ ] Possibilité de modifier les informations du profil
- [ ] Formulaire de contact pour demandes complexes

**Délai de réponse :** 30 jours maximum

---

### ✅ 5. Droit à l'effacement (droit à l'oubli)

**Obligation :** Permettre la suppression des données sur demande.

**Actions dans l'application :**
- [ ] Option "Supprimer mon compte" dans les paramètres
- [ ] Processus de confirmation avant suppression
- [ ] Information sur les données conservées (obligations légales)

**Exceptions à la suppression :**
- Données fiscales (7 ans)
- Données de litiges (5 ans après résolution)
- Données requises par la loi

---

### ✅ 6. Portabilité des données

**Obligation :** Fournir les données dans un format structuré et couramment utilisé.

**Actions requises :**
- [ ] Fonction "Exporter mes données" (format JSON ou CSV)
- [ ] Inclure : profil, réservations, véhicules, évaluations
- [ ] Délai de génération : 30 jours maximum

---

### ✅ 7. Notification des incidents de confidentialité

**Obligation :** Notifier la Commission d'accès à l'information (CAI) et les personnes concernées en cas d'incident présentant un risque sérieux de préjudice.

**Processus à mettre en place :**

1. **Détection et évaluation** (immédiat)
   - Identifier la nature de l'incident
   - Évaluer le risque de préjudice

2. **Notification à la CAI** (si risque sérieux)
   - Formulaire en ligne sur le site de la CAI
   - Délai : dès que possible

3. **Notification aux personnes concernées**
   - Par courriel ou notification push
   - Contenu : nature de l'incident, données concernées, mesures prises

4. **Registre des incidents**
   - [ ] Créer un registre des incidents
   - [ ] Documenter chaque incident même sans notification

---

### ✅ 8. Évaluation des facteurs relatifs à la vie privée (EFVP)

**Obligation :** Réaliser une EFVP avant tout projet impliquant des renseignements personnels.

**Projets nécessitant une EFVP :**
- Nouvelle fonctionnalité collectant des données
- Nouveau fournisseur de services (transfert de données)
- Utilisation de nouvelles technologies (IA, biométrie)

**Template EFVP simplifié :**
```
1. Description du projet
2. Données collectées
3. Finalités
4. Risques identifiés
5. Mesures d'atténuation
6. Décision (approuvé/refusé/modifié)
```

---

### ✅ 9. Transferts hors Québec

**Obligation :** S'assurer d'une protection équivalente pour les transferts internationaux.

**Fournisseurs actuels hors Québec :**

| Fournisseur | Pays | Données | Mesures |
|-------------|------|---------|---------|
| Stripe | USA | Paiements | Certifié PCI-DSS, clauses contractuelles |
| Firebase | USA | Notifications, analytics | Google Cloud, clauses contractuelles |
| Cloudinary | USA/Israël | Photos | Clauses contractuelles |
| OpenWeather | UK | Localisation approx. | Données non personnelles |
| Anthropic | USA | Conversations IA | Clauses contractuelles |

**Actions requises :**
- [ ] Vérifier les contrats avec chaque fournisseur
- [ ] S'assurer que des clauses de protection des données sont incluses
- [ ] Documenter les transferts dans la politique de confidentialité ✅

---

### ✅ 10. Décisions automatisées et IA

**Obligation :** Informer les personnes et permettre de contester.

**Utilisation de l'IA dans Deneige-Auto :**

| Fonctionnalité | Impact | Intervention humaine |
|----------------|--------|---------------------|
| Chatbot | Faible | Non requis |
| Analyse photos | Moyen | Vérification possible |
| Matching déneigeurs | Moyen | Choix final par l'utilisateur |
| Analyse litiges | Élevé | **Décision toujours humaine** |

**Actions requises :**
- [x] Documenter dans la politique de confidentialité ✅
- [ ] Ajouter mention dans l'app lors de l'utilisation de l'IA
- [ ] Permettre de contacter un humain pour les litiges

---

## Checklist de conformité

### Avant le lancement

- [ ] Responsable de la protection désigné
- [ ] Politique de confidentialité publiée (URL accessible)
- [ ] Conditions d'utilisation publiées
- [ ] Mécanisme de consentement dans l'app
- [ ] Page "Mes données" dans l'app
- [ ] Option de suppression de compte
- [ ] Registre des incidents créé
- [ ] Contrats fournisseurs vérifiés

### Documentation à conserver

- [ ] Registre des activités de traitement
- [ ] Registre des incidents de confidentialité
- [ ] Preuves de consentement
- [ ] Évaluations EFVP (si applicable)
- [ ] Contrats avec sous-traitants

---

## Ressources utiles

- **Commission d'accès à l'information du Québec**
  - Site : www.cai.gouv.qc.ca
  - Téléphone : 1-888-528-7741

- **Guide sur la Loi 25 (CAI)**
  - https://www.cai.gouv.qc.ca/loi-25/

- **Formulaire de notification d'incident**
  - https://www.cai.gouv.qc.ca/incident-de-confidentialite/

---

## Sanctions en cas de non-conformité

| Type d'infraction | Amende maximale |
|-------------------|-----------------|
| Personne physique | 50 000 $ |
| Entreprise | 25 000 000 $ ou 4% du chiffre d'affaires mondial |

Les sanctions administratives sont entrées en vigueur le **22 septembre 2023**.

---

*Ce document est un guide et ne constitue pas un avis juridique. Consultez un avocat spécialisé pour une conformité complète.*

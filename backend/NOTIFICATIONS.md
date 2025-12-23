# Système de Notifications - Documentation

## Vue d'ensemble

Le système de notifications permet d'informer les utilisateurs en temps réel des événements importants liés à leurs réservations, paiements, et autres activités.

## Types de Notifications

### 1. Notifications de Réservation

#### **reservationAssigned** - Déneigeur assigné
- **Déclencheur**: Quand un déneigeur accepte une tâche
- **Route**: `PATCH /api/reservations/:id/assign`
- **Priorité**: `high`

#### **workerEnRoute** - Déneigeur en route
- **Déclencheur**: Quand le déneigeur indique qu'il est en route
- **Route**: `PATCH /api/reservations/:id/en-route`
- **Priorité**: `high`

#### **workStarted** - Travail commencé
- **Déclencheur**: Quand le déneigeur démarre le travail
- **Route**: `PATCH /api/reservations/:id/start`
- **Priorité**: `normal`

#### **workCompleted** - Travail terminé
- **Déclencheur**: Quand le déneigeur termine le travail
- **Route**: `PATCH /api/reservations/:id/complete`
- **Priorité**: `high`

#### **reservationCancelled** - Réservation annulée
- **Déclencheur**: Quand une réservation est annulée
- **Route**: `DELETE /api/reservations/:id`
- **Priorité**: `high`

### 2. Notifications de Paiement

#### **paymentSuccess** - Paiement réussi
- **Déclencheur**: Quand un paiement est confirmé
- **Route**: `POST /api/payments/confirm`
- **Priorité**: `normal`

#### **paymentFailed** - Paiement échoué
- **Déclencheur**: Quand un paiement échoue
- **Route**: `POST /api/payments/confirm`
- **Priorité**: `urgent`

#### **refundProcessed** - Remboursement effectué
- **Déclencheur**: Quand un remboursement est traité
- **Route**: `POST /api/payments/refunds`
- **Priorité**: `normal`

### 3. Autres Notifications

#### **weatherAlert** - Alerte météo
- **Déclencheur**: Quand de la neige est prévue (à implémenter)
- **Priorité**: `high`

#### **urgentRequest** - Demande urgente
- **Déclencheur**: Demande de déneigement urgente
- **Priorité**: `urgent`

#### **workerMessage** - Message du déneigeur
- **Déclencheur**: Quand le déneigeur envoie un message
- **Priorité**: `normal`

#### **systemNotification** - Notification système
- **Déclencheur**: Notifications générales du système
- **Priorité**: `normal`

## API Endpoints

### Récupérer les notifications
```http
GET /api/notifications
Authorization: Bearer <token>
```

**Réponse**:
```json
{
  "success": true,
  "notifications": [
    {
      "_id": "...",
      "userId": "...",
      "type": "reservationAssigned",
      "title": "Déneigeur assigné",
      "message": "Jean Tremblay a accepté votre demande",
      "priority": "high",
      "isRead": false,
      "createdAt": "2024-12-21T10:30:00.000Z",
      "reservationId": "...",
      "workerId": "..."
    }
  ]
}
```

### Obtenir le nombre de non-lues
```http
GET /api/notifications/unread-count
Authorization: Bearer <token>
```

### Marquer comme lue
```http
PATCH /api/notifications/:id/read
Authorization: Bearer <token>
```

### Marquer toutes comme lues
```http
PATCH /api/notifications/mark-all-read
Authorization: Bearer <token>
```

### Supprimer une notification
```http
DELETE /api/notifications/:id
Authorization: Bearer <token>
```

### Tout supprimer
```http
DELETE /api/notifications/clear-all
Authorization: Bearer <token>
```

## Utilisation dans le Code Backend

### Méthode 1: Utiliser les helpers (Recommandé)

```javascript
const Notification = require('../models/Notification');

// Quand un déneigeur accepte
await Notification.notifyReservationAssigned(reservation, worker);

// Quand le déneigeur est en route
await Notification.notifyWorkerEnRoute(reservation, worker);

// Quand le travail commence
await Notification.notifyWorkStarted(reservation, worker);

// Quand le travail est terminé
await Notification.notifyWorkCompleted(reservation, worker);

// Paiement réussi
await Notification.notifyPaymentSuccess(reservation);

// Paiement échoué
await Notification.notifyPaymentFailed(reservation, errorMessage);

// Réservation annulée
await Notification.notifyReservationCancelled(reservation, reason);
```

### Méthode 2: Création manuelle

```javascript
await Notification.createNotification({
  userId: user._id,
  type: 'systemNotification',
  title: 'Bienvenue!',
  message: 'Merci d\'utiliser notre service',
  priority: 'normal',
  metadata: {
    customField: 'value',
  },
});
```

## Tester les Notifications

### Script de test
Utilisez le script fourni pour créer des notifications de démonstration:

```bash
# Obtenir votre userId depuis MongoDB ou l'app
node scripts/test-notifications.js <votre-userId>
```

Exemple:
```bash
node scripts/test-notifications.js 6752a1234567890abcdef123
```

Cela créera 7 notifications de test de différents types.

### Test manuel via API

```bash
# Créer une notification de test
curl -X POST http://localhost:3000/api/notifications \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "systemNotification",
    "title": "Test",
    "message": "Message de test",
    "priority": "normal"
  }'
```

## Flux Complet - Exemple

### Scénario: Réservation de déneigement

1. **Client crée une réservation** → Aucune notification (réservation en attente)

2. **Déneigeur accepte** → `PATCH /api/reservations/:id/assign`
   - ✅ Notification `reservationAssigned` envoyée au client
   - Client voit: "Jean Tremblay a accepté votre demande"

3. **Déneigeur démarre son trajet** → `PATCH /api/reservations/:id/en-route`
   - ✅ Notification `workerEnRoute` envoyée au client
   - Client voit: "Jean est en route vers votre véhicule"

4. **Déneigeur arrive et commence** → `PATCH /api/reservations/:id/start`
   - ✅ Notification `workStarted` envoyée au client
   - Client voit: "Jean a commencé le déneigement"

5. **Déneigeur termine** → `PATCH /api/reservations/:id/complete`
   - ✅ Notification `workCompleted` envoyée au client
   - Client voit: "Déneigement terminé. Votre véhicule est prêt!"

6. **Paiement automatique** → `POST /api/payments/confirm`
   - ✅ Notification `paymentSuccess` envoyée au client
   - Client voit: "Paiement de 25.50 $ effectué avec succès"

## Interface Flutter

Les notifications apparaissent dans:
- Menu → Notifications
- Badge de compteur sur l'icône notifications (nombre non lues)
- Section "Aujourd'hui" / "Plus tôt"
- Swipe-to-delete
- Pull-to-refresh

## Prochaines Améliorations

### Push Notifications (Optionnel)
Pour envoyer des notifications push natives:

1. Configurer Firebase Cloud Messaging (FCM)
2. Stocker les device tokens dans le modèle User
3. Dans `Notification.createNotification()`, envoyer aussi une push notification:

```javascript
notificationSchema.statics.createNotification = async function(data) {
    const notification = new this(data);
    await notification.save();

    // Envoyer push notification
    await sendPushNotification(data.userId, {
        title: data.title,
        body: data.message,
    });

    return notification;
};
```

### Notifications en temps réel (WebSocket)
Pour des notifications instantanées sans polling:
- Implémenter Socket.IO
- Émettre événement quand notification créée
- Flutter écoute et met à jour l'UI en temps réel

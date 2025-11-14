import 'package:flutter/material.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonnements'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choisissez votre plan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Économisez avec nos forfaits saisonniers',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _buildSubscriptionCard(
            context,
            title: 'Basique',
            price: '29.99',
            period: 'mois',
            features: [
              'Jusqu\'à 5 déneigements/mois',
              'Priorité normale',
              'Support par email',
            ],
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildSubscriptionCard(
            context,
            title: 'Premium',
            price: '49.99',
            period: 'mois',
            features: [
              'Déneigements illimités',
              'Priorité haute',
              'Support 24/7',
              'Notifications SMS',
            ],
            color: Colors.purple,
            recommended: true,
          ),
          const SizedBox(height: 16),
          _buildSubscriptionCard(
            context,
            title: 'Saisonnier',
            price: '299.99',
            period: 'saison',
            features: [
              'Tout du Premium',
              'Plusieurs véhicules',
              'Gestionnaire dédié',
              'Rapports détaillés',
              'Garantie satisfaction',
            ],
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(
      BuildContext context, {
        required String title,
        required String price,
        required String period,
        required List<String> features,
        required Color color,
        bool recommended = false,
      }) {
    return Card(
      elevation: recommended ? 8 : 2,
      child: Container(
        decoration: recommended
            ? BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'RECOMMANDÉ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (recommended) const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$$price',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '/$period',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showSubscriptionDialog(context, title, price, period);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Choisir ce plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubscriptionDialog(
      BuildContext context,
      String planName,
      String price,
      String period,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Plan $planName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vous avez sélectionné le plan $planName'),
            const SizedBox(height: 8),
            Text(
              'Prix: \$$price/$period',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Cette fonctionnalité sera bientôt disponible.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Plan $planName sélectionné'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
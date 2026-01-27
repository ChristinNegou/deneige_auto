import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.subscription_title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppLocalizations.of(context)!.subscription_choosePlan,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.subscription_saveWith,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          _buildSubscriptionCard(
            context,
            title: AppLocalizations.of(context)!.subscription_basic,
            price: '29.99',
            period: AppLocalizations.of(context)!.subscription_month,
            features: [
              AppLocalizations.of(context)!.subscription_basicFeature1,
              AppLocalizations.of(context)!.subscription_basicFeature2,
              AppLocalizations.of(context)!.subscription_basicFeature3,
            ],
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildSubscriptionCard(
            context,
            title: AppLocalizations.of(context)!.subscription_premium,
            price: '49.99',
            period: AppLocalizations.of(context)!.subscription_month,
            features: [
              AppLocalizations.of(context)!.subscription_premiumFeature1,
              AppLocalizations.of(context)!.subscription_premiumFeature2,
              AppLocalizations.of(context)!.subscription_premiumFeature3,
              AppLocalizations.of(context)!.subscription_premiumFeature4,
            ],
            color: Colors.purple,
            recommended: true,
          ),
          const SizedBox(height: 16),
          _buildSubscriptionCard(
            context,
            title: AppLocalizations.of(context)!.subscription_seasonal,
            price: '299.99',
            period: AppLocalizations.of(context)!.subscription_season,
            features: [
              AppLocalizations.of(context)!.subscription_seasonalFeature1,
              AppLocalizations.of(context)!.subscription_seasonalFeature2,
              AppLocalizations.of(context)!.subscription_seasonalFeature3,
              AppLocalizations.of(context)!.subscription_seasonalFeature4,
              AppLocalizations.of(context)!.subscription_seasonalFeature5,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.subscription_recommended,
                    style: const TextStyle(
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
                  child: Text(
                      AppLocalizations.of(context)!.subscription_choosePlanBtn),
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
        title: Text(
            AppLocalizations.of(context)!.subscription_planTitle(planName)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!
                .subscription_selectedPlan(planName)),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!
                  .subscription_priceLabel(price, period),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.subscription_comingSoon),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.common_close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!
                      .subscription_planSelected(planName)),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.common_confirm),
          ),
        ],
      ),
    );
  }
}

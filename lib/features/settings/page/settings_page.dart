import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  String _language = 'fr';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Activer les notifications'),
            subtitle: const Text('Recevoir des alertes'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Notifications email'),
            value: _emailNotifications,
            onChanged: _notificationsEnabled
                ? (value) => setState(() => _emailNotifications = value)
                : null,
          ),
          SwitchListTile(
            title: const Text('Notifications SMS'),
            value: _smsNotifications,
            onChanged: _notificationsEnabled
                ? (value) => setState(() => _smsNotifications = value)
                : null,
          ),
          const Divider(),
          const ListTile(
            title: Text(
              'Préférences',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Langue'),
            trailing: DropdownButton<String>(
              value: _language,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) => setState(() => _language = value!),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text(
              'À propos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version de l\'application'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.policy),
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Page à venir')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Conditions d\'utilisation'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Page à venir')),
              );
            },
          ),
        ],
      ),
    );
  }
}

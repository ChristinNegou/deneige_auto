import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/faq_data.dart';
import '../../domain/entities/faq_item.dart';
import '../../domain/entities/support_request.dart';
import '../bloc/support_bloc.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SupportBloc>(),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Aide et Support'),
          backgroundColor: AppTheme.surface,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.textPrimary,
            unselectedLabelColor: AppTheme.textTertiary,
            tabs: const [
              Tab(text: 'FAQ', icon: Icon(Icons.help_outline)),
              Tab(text: 'Contact', icon: Icon(Icons.mail_outline)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _FaqTab(),
            _ContactTab(),
          ],
        ),
      ),
    );
  }
}

class _FaqTab extends StatefulWidget {
  const _FaqTab();

  @override
  State<_FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<_FaqTab> {
  FaqCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final faqItems = _selectedCategory != null
        ? FaqData.getByCategory(_selectedCategory!)
        : FaqData.faqItems;

    return Column(
      children: [
        // Category filter
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip(null, 'Tout'),
              ...FaqCategory.values.map(
                (category) => _buildCategoryChip(category, category.label),
              ),
            ],
          ),
        ),
        // FAQ list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: faqItems.length,
            itemBuilder: (context, index) {
              final item = faqItems[index];
              return _FaqItemCard(item: item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(FaqCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        backgroundColor: AppTheme.surfaceContainer,
        selectedColor: AppTheme.primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
        ),
      ),
    );
  }
}

class _FaqItemCard extends StatelessWidget {
  final FaqItem item;

  const _FaqItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          item.question,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        iconColor: AppTheme.textSecondary,
        collapsedIconColor: AppTheme.textTertiary,
        children: [
          Text(
            item.answer,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTab extends StatefulWidget {
  const _ContactTab();

  @override
  State<_ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends State<_ContactTab> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  SupportSubject _selectedSubject = SupportSubject.question;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupportBloc, SupportState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.error,
            ),
          );
          context.read<SupportBloc>().add(ClearSupportMessages());
        }

        if (state.isSubmitted) {
          _messageController.clear();
          setState(() {
            _selectedSubject = SupportSubject.question;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Votre message a été envoyé avec succès'),
              backgroundColor: AppTheme.success,
            ),
          );
          context.read<SupportBloc>().add(ResetSupportForm());
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.support_agent,
                        color: AppTheme.info,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Besoin d\'aide?',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Notre équipe vous répondra dans les 24-48h',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Subject dropdown
                const Text(
                  'Sujet',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<SupportSubject>(
                      value: _selectedSubject,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceElevated,
                      items: SupportSubject.values.map((subject) {
                        return DropdownMenuItem(
                          value: subject,
                          child: Text(
                            subject.label,
                            style:
                                const TextStyle(color: AppTheme.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedSubject = value;
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Message field
                const Text(
                  'Message',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageController,
                  maxLines: 6,
                  maxLength: 2000,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Décrivez votre problème ou question en détail...',
                    hintStyle: const TextStyle(color: AppTheme.textTertiary),
                    filled: true,
                    fillColor: AppTheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                    counterStyle:
                        const TextStyle(color: AppTheme.textTertiary),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un message';
                    }
                    if (value.trim().length < 10) {
                      return 'Le message doit contenir au moins 10 caractères';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isSubmitting
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              context.read<SupportBloc>().add(
                                    SubmitSupportRequest(
                                      subject: _selectedSubject,
                                      message: _messageController.text.trim(),
                                    ),
                                  );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.background,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send),
                              SizedBox(width: 8),
                              Text(
                                'Envoyer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // Alternative contact info
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Ou contactez-nous directement:',
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'support@deneige-auto.ca',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

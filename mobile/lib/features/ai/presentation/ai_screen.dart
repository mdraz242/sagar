import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/vypar_ui.dart';
import '../../products/domain/product.dart';

final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, List<AiMessage>>((ref) {
  return AiChatNotifier();
});

class AiMessage {
  const AiMessage(this.text, {required this.fromUser});

  final String text;
  final bool fromUser;
}

class AiChatNotifier extends StateNotifier<List<AiMessage>> {
  AiChatNotifier()
      : super(const [
          AiMessage(
            'Hello! I am VyparAI. How can I help you today?',
            fromUser: false,
          ),
        ]);

  void ask(String question, List<Product> products) {
    state = [
      ...state,
      AiMessage(question, fromUser: true),
      AiMessage(_answer(question, products), fromUser: false),
    ];
  }

  String _answer(String question, List<Product> products) {
    // TODO: connect to a real /ai/chat backend endpoint when available.
    final q = question.toLowerCase();
    final byMargin = [...products]
      ..sort((a, b) => b.margin.compareTo(a.margin));
    final byDemand = [...products]
      ..sort((a, b) => (b.margin + b.stock).compareTo(a.margin + a.stock));
    final marginNames = byMargin.take(3).map((p) => p.name).join(', ');
    final demandNames = byDemand.take(3).map((p) => p.name).join(', ');

    if (products.isEmpty) {
      return 'I could not read products yet. Please refresh the catalog and try again.';
    }
    if (q.contains('margin')) {
      return 'High margin products are $marginNames. Put these in your counter display and bundle them with fast movers.';
    }
    if (q.contains('bulk')) {
      return 'For bulk order, start with ${byDemand.take(2).map((p) => p.name).join(', ')}, then add $marginNames to improve profit.';
    }
    if (q.contains('trend') || q.contains('selling') || q.contains('best')) {
      return "Today's top selling products look like $demandNames. These are good candidates for quick reorder.";
    }
    return 'I checked your current catalog. Try ordering $demandNames first, and add one high-margin item like ${byMargin.first.name}.';
  }
}

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogSnapshotProvider);
    final products = catalog.valueOrNull?.products ?? const <Product>[];
    final messages = ref.watch(aiChatProvider);

    return AppShell(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
              children: [
                _AiHero(
                  onPrompt: (prompt) => _ask(prompt, products),
                ),
                const SizedBox(height: 14),
                for (final message in messages)
                  _ChatBubble(message.text, fromUser: message.fromUser),
                const SizedBox(height: 10),
                _TryAskingCard(
                  controller: _input,
                  onSend: () => _send(products),
                  onPrompt: (prompt) => _ask(prompt, products),
                ),
                const SizedBox(height: 16),
                _PopularQueries(
                  onPrompt: (prompt) => _ask(prompt, products),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _send(List<Product> products) {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    _ask(text, products);
  }

  void _ask(String question, List<Product> products) {
    ref.read(aiChatProvider.notifier).ask(question, products);
  }
}

class _AiHero extends StatelessWidget {
  const _AiHero({required this.onPrompt});

  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    const prompts = [
      'What are the top selling products?',
      'Show me high margin products',
      'Suggest items for bulk order',
      'What is in trend today?',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003EEB), Color(0xFF022EA7), Color(0xFF071A3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: _RobotBadge(),
          ),
          const Positioned(
            right: 106,
            top: 5,
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const Positioned(
            right: 72,
            top: 44,
            child: Icon(Icons.star, color: Colors.white70, size: 10),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VyparAI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Your smart shopping assistant',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 24),
              const _HeroBubble(),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: .78,
                children: [
                  _PromptTile(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Top\nSelling Today',
                    onTap: () => onPrompt(prompts[0]),
                  ),
                  _PromptTile(
                    icon: Icons.workspace_premium_outlined,
                    label: 'High\nMargin Products',
                    onTap: () => onPrompt(prompts[1]),
                  ),
                  _PromptTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'Bulk Order\nSuggestions',
                    onTap: () => onPrompt(prompts[2]),
                  ),
                  _PromptTile(
                    icon: Icons.trending_up,
                    label: 'Trending\nProducts',
                    onTap: () => onPrompt(prompts[3]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RobotBadge extends StatelessWidget {
  const _RobotBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .18),
                blurRadius: 16,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 37,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF082C7D),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const Positioned(
                left: 20,
                top: 24,
                child: CircleAvatar(radius: 3, backgroundColor: Colors.cyan),
              ),
              const Positioned(
                right: 20,
                top: 24,
                child: CircleAvatar(radius: 3, backgroundColor: Colors.cyan),
              ),
              const Positioned(
                bottom: 8,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Color(0xFFEAF0FF),
                  child: Icon(Icons.bolt, size: 10, color: AppColors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBubble extends StatelessWidget {
  const _HeroBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "Hello! I'm VyparAI\nHow can I help you today?",
        style: TextStyle(
          color: AppColors.blue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PromptTile extends StatelessWidget {
  const _PromptTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEAF0FF)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFEAF0FF),
              child: Icon(icon, size: 14, color: AppColors.primaryAlt),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TryAskingCard extends StatelessWidget {
  const _TryAskingCard({
    required this.controller,
    required this.onSend,
    required this.onPrompt,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    const prompts = [
      'What are the top selling products today?',
      'Show me high margin products',
      'Suggest products for bulk order',
      "What's in trend today?",
    ];
    return VyparCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Try asking me',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final prompt in prompts)
            _FollowUp(text: prompt, onTap: () => onPrompt(prompt)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Ask anything about products...',
                    prefixIcon: Icon(Icons.mic_none, color: AppColors.blue),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onSend,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brightBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PopularQueries extends StatelessWidget {
  const _PopularQueries({required this.onPrompt});

  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    const queries = [
      'Top Selling Today',
      'High Margin Products',
      'Bulk Order Suggestions',
      'Trending Products',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Queries',
          style: TextStyle(
            color: AppColors.blue,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final query in queries)
              ActionChip(
                label: Text(query),
                onPressed: () => onPrompt(query),
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.border),
                labelStyle: const TextStyle(
                  color: AppColors.brightBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble(
    this.text, {
    required this.fromUser,
  });

  final String text;
  final bool fromUser;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 295),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: fromUser ? orangeGradient() : null,
        color: fromUser ? null : AppColors.accent.withValues(alpha: .18),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(fromUser ? 16 : 4),
          bottomRight: Radius.circular(fromUser ? 4 : 16),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fromUser ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }
}

class _FollowUp extends StatelessWidget {
  const _FollowUp({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ActionChip(
          label: Text('+ $text'),
          onPressed: onTap,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.border),
          labelStyle: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

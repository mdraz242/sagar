part of 'profile_subpages.dart';

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const message =
        'Join VyparHub and use my referral code VYPAR200 to get started with fast FMCG delivery.';
    return _SubPageShell(
      title: 'Refer & Earn',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9D6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Refer your friends\nEarn Rs200\non their first order',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ),
                Icon(Icons.card_giftcard,
                    color: AppColors.orange.withValues(alpha: .85), size: 70),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Your Referral Code'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDecoration(),
                  child: const Text('VYPAR200',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Referral code copied.')),
                  );
                },
                style: _orangeButton(compact: true),
                child: const Text('Copy'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Earnings Tracker',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: const LinearProgressIndicator(
                    value: .5,
                    minHeight: 8,
                    color: AppColors.orange,
                    backgroundColor: Color(0xFFEAF0FF),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rs100 earned | 1 friend completed first order',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Share via'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ShareIcon(
                Icons.chat,
                'WhatsApp',
                AppColors.success,
                () => SharePlus.instance.share(
                  ShareParams(text: message),
                ),
              ),
              _ShareIcon(
                Icons.send,
                'Telegram',
                AppColors.brightBlue,
                () => SharePlus.instance.share(
                  ShareParams(text: message),
                ),
              ),
              _ShareIcon(
                Icons.facebook,
                'Facebook',
                AppColors.brightBlue,
                () => SharePlus.instance.share(
                  ShareParams(text: message),
                ),
              ),
              _ShareIcon(
                Icons.more_horiz,
                'More',
                const Color(0xFF8FA0D8),
                () => SharePlus.instance.share(
                  ShareParams(text: message),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel('How it works'),
          const SizedBox(height: 8),
          const _HowRow('Share your referral code with your friends'),
          const _HowRow('Your friend places their first order'),
          const _HowRow('You earn Rs200 in your VyparHub wallet'),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const topics = [
      'Order & Delivery',
      'Returns & Refunds',
      'Payment Issues',
      'Account & Profile',
      'Product Related Queries',
      'Offers & Coupons',
    ];
    return _SubPageShell(
      title: 'Help & Support',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          const _SectionLabel('How can we help you?'),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for help topics...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help scanner opened.')),
                  );
                },
                icon: const Icon(Icons.document_scanner_outlined),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Popular Topics'),
          const SizedBox(height: 10),
          for (final topic in topics)
            _SimpleRow(Icons.help_outline, topic, () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$topic support opened.')),
              );
            }),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contact Us',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ContactButton(
                      Icons.chat_bubble_outline,
                      'Chat',
                      () => _supportSnack(context, 'Chat support opened.'),
                    ),
                    const SizedBox(width: 8),
                    _ContactButton(
                      Icons.email_outlined,
                      'Email',
                      () => _supportSnack(
                        context,
                        'Email support: support@vyparhub.com',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ContactButton(
                      Icons.call_outlined,
                      'Call',
                      () => _supportSnack(
                        context,
                        'Call support will be connected after phone setup.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEAF0FF),
                  child: Icon(Icons.support_agent, color: AppColors.brightBlue),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Still need help?',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      Text('Chat with us. We typically reply in a few minutes',
                          style:
                              TextStyle(color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: () =>
                      _supportSnack(context, 'Chat support opened.'),
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _supportSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ShareIcon extends StatelessWidget {
  const _ShareIcon(this.icon, this.label, this.color, this.onTap);

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Column(
        children: [
          CircleAvatar(
              backgroundColor: color, child: Icon(icon, color: Colors.white)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label),
      ),
    );
  }
}

class _HowRow extends StatelessWidget {
  const _HowRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.brightBlue),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

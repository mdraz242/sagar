part of 'profile_subpages.dart';

class RateUsScreen extends StatefulWidget {
  const RateUsScreen({super.key});

  @override
  State<RateUsScreen> createState() => _RateUsScreenState();
}

class _RateUsScreenState extends State<RateUsScreen> {
  int rating = 4;

  @override
  Widget build(BuildContext context) {
    return _SubPageShell(
      title: 'Rate Us',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 76, 16, 112),
        children: [
          const Text(
            'How was your experience\nwith VyparHub?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => rating = i),
                  icon: Icon(
                    i <= rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 34,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              "Great! We're happy you loved it.",
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 26),
          const _InputLabel('Tell us more (Optional)'),
          const TextField(
            minLines: 5,
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  'VyparHub makes shopping so easy and delivery is super fast!',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 56),
                        const SizedBox(height: 10),
                        const Text(
                          'Thank you for your review',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Play Store rating will open after the public listing is ready.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => context.go('/profile'),
                            style: _orangeButton(),
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            style: _orangeButton(),
            child: const Text('Submit Review'),
          ),
        ],
      ),
    );
  }
}

class AboutVyparHubScreen extends StatelessWidget {
  const AboutVyparHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SubPageShell(
      title: 'About VyparHub',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 44, 16, 112),
        children: const [
          Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: 'Vypar', style: TextStyle(color: AppColors.blue)),
                  TextSpan(
                      text: 'Hub', style: TextStyle(color: AppColors.orange)),
                ],
              ),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ),
          SizedBox(height: 6),
          Center(child: Text('Version 2.1.0')),
          SizedBox(height: 22),
          Center(
            child: Text(
              'VyparHub is your trusted partner for fast delivery of daily essentials at best prices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.blue),
            ),
          ),
          SizedBox(height: 26),
          _AboutRow(Icons.local_shipping_outlined, 'Fast Delivery',
              'Delivery ETA follows your selected area'),
          _AboutRow(
              Icons.sell_outlined, 'Best Prices', 'Unbeatable prices everyday'),
          _AboutRow(Icons.grid_view_outlined, 'Wide Range',
              'Everything you need, in one place'),
          _AboutRow(Icons.verified_user_outlined, 'Secure Payments',
              '100% safe & secure payments'),
          SizedBox(height: 24),
          Center(
            child: Text(
              '© 2025 VyparHub. All rights reserved.',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEAF0FF),
            child: Icon(icon, color: AppColors.brightBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(subtitle,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

ButtonStyle _orangeButton({bool compact = false}) {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.orange,
    padding: EdgeInsets.all(compact ? 12 : 15),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFE8EAF2)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .035),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

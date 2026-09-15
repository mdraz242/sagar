part of 'login_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final account = TextEditingController();
  bool sent = false;

  @override
  void dispose() {
    account.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF0E6), Colors.white, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 6),
                      Image.asset(
                        'assets/branding/vyparhub_logo.png',
                        height: 42,
                        width: 150,
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.lock_reset,
                            color: AppColors.orange2, size: 46),
                        const SizedBox(height: 12),
                        Text(
                          tr('forgotPasswordTitle', lang),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr('forgotPasswordCopy', lang),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 13),
                        ),
                        const SizedBox(height: 22),
                        _AuthTextField(
                          controller: account,
                          hint: tr('emailOrPhone', lang),
                          icon: Icons.person_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => setState(() => sent = true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: brandGradient(),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              constraints: const BoxConstraints(minHeight: 52),
                              child: Text(
                                tr('sendResetLink', lang),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ),
                        if (sent) ...[
                          const SizedBox(height: 14),
                          Text(
                            tr('resetSent', lang),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

part of 'profile_subpages.dart';

class LogoutConfirmScreen extends ConsumerWidget {
  const LogoutConfirmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SubPageShell(
      title: '',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 112),
        children: [
          Icon(Icons.logout,
              size: 96, color: AppColors.orange.withValues(alpha: .85)),
          const SizedBox(height: 28),
          const Text(
            'Are you sure you want to logout?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You will need to sign in again to access your account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            style: _orangeButton(),
            child: const Text('Logout'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/profile'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class AccountDeletionIntroScreen extends ConsumerWidget {
  const AccountDeletionIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SubPageShell(
      title: 'Account Deletion',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 112),
        children: [
          const Icon(Icons.delete_outline,
              color: AppColors.primaryAlt, size: 88),
          const SizedBox(height: 18),
          const Text(
            'Delete Your Account?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We are sorry to see you go. Deleting your account will permanently remove your data from VyparHub.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          _DeletionNote(Icons.receipt_long_outlined,
              'All your orders and order history will be deleted from your account view.'),
          _DeletionNote(Icons.account_balance_wallet_outlined,
              'Wallet balance, rewards points and coupons will be lost.'),
          _DeletionNote(Icons.lock_outline,
              'Your account cannot be recovered once deleted.'),
          _DeletionNote(
              Icons.warning_amber_outlined, 'This action cannot be undone.'),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => context.go('/profile/delete-account/verify'),
            style: _orangeButton(),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => context.go('/profile'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class AccountDeletionVerifyScreen extends ConsumerStatefulWidget {
  const AccountDeletionVerifyScreen({super.key});

  @override
  ConsumerState<AccountDeletionVerifyScreen> createState() =>
      _AccountDeletionVerifyScreenState();
}

class _AccountDeletionVerifyScreenState
    extends ConsumerState<AccountDeletionVerifyScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  bool sent = false;
  bool loading = false;
  String? error;
  String? devOtp;
  Timer? timer;
  int secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    phoneController.text = ref.read(authProvider)?.phone ?? '';
  }

  @override
  void dispose() {
    timer?.cancel();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SubPageShell(
      title: sent ? 'Enter OTP' : 'Verify Identity',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 112),
        children: [
          Text(
            sent
                ? 'Enter the 6-digit code sent to +91 ${phoneController.text.trim()}'
                : 'Enter your mobile number to receive OTP for account deletion.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          if (!sent) ...[
            const _InputLabel('Mobile Number'),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(prefixText: '+91  '),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: loading ? null : _sendOtp,
              style: _orangeButton(),
              child: Text(loading ? 'Sending...' : 'Send OTP'),
            ),
            const SizedBox(height: 18),
            const Text(
              'For your security, we need to verify your identity.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ] else ...[
            TextField(
              controller: otpController,
              autofocus: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 12,
              ),
              decoration:
                  const InputDecoration(counterText: '', hintText: '------'),
            ),
            if (devOtp != null) ...[
              const SizedBox(height: 8),
              Text(
                'Development OTP: $devOtp',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: secondsLeft == 0 && !loading ? _sendOtp : null,
              child: Text(secondsLeft == 0
                  ? 'Resend OTP'
                  : 'Resend OTP in ${_formatOtpTimer(secondsLeft)}'),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: loading ? null : _continue,
              style: _orangeButton(),
              child: const Text('Verify OTP'),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(
              error!,
              style: const TextStyle(
                color: AppColors.primaryAlt,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendOtp() async {
    final phone = _phone(phoneController.text);
    if (phone.length != 10) {
      setState(() => error = 'Enter your registered 10 digit mobile number.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final currentPhone = ref.read(authProvider)?.phone ?? '';
      if (currentPhone.isNotEmpty && phone != currentPhone) {
        throw const ApiException(
            'Enter the mobile number linked to this account.');
      }
      devOtp = await ref.read(authProvider.notifier).requestOtp(phone: phone);
      _startTimer();
      setState(() => sent = true);
    } catch (e) {
      setState(() => error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _continue() {
    final code = otpController.text.trim();
    if (code.length != 6) {
      setState(() => error = 'Enter the 6 digit OTP sent to your phone.');
      return;
    }
    ref.read(accountDeletionOtpProvider.notifier).state = code;
    context.go('/profile/delete-account/confirm');
  }

  void _startTimer() {
    timer?.cancel();
    secondsLeft = 600;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (secondsLeft <= 0) {
        timer.cancel();
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  String _formatOtpTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _phone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }
}

class AccountDeletionConfirmScreen extends ConsumerStatefulWidget {
  const AccountDeletionConfirmScreen({super.key});

  @override
  ConsumerState<AccountDeletionConfirmScreen> createState() =>
      _AccountDeletionConfirmScreenState();
}

class _AccountDeletionConfirmScreenState
    extends ConsumerState<AccountDeletionConfirmScreen> {
  bool agreed = false;

  @override
  Widget build(BuildContext context) {
    return _SubPageShell(
      title: 'Confirm Deletion',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 112),
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.primaryAlt, size: 88),
          const SizedBox(height: 18),
          const Text(
            'Are you absolutely sure?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This will permanently delete your account and remove all your data from our system.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You will lose access to:',
                  style: TextStyle(
                    color: AppColors.primaryAlt,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text('• All your order history'),
                Text('• Wallet balance and rewards'),
                Text('• Saved addresses and payment methods'),
                Text('• Coupons and offers'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CheckboxListTile(
            value: agreed,
            onChanged: (value) => setState(() => agreed = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'I understand that my account will be permanently deleted.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: agreed
                ? () => context.go('/profile/delete-account/progress')
                : null,
            style: _orangeButton(),
            child: const Text('Delete My Account'),
          ),
          TextButton(
            onPressed: () => context.go('/profile'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class AccountDeletingScreen extends ConsumerStatefulWidget {
  const AccountDeletingScreen({super.key});

  @override
  ConsumerState<AccountDeletingScreen> createState() =>
      _AccountDeletingScreenState();
}

class _AccountDeletingScreenState extends ConsumerState<AccountDeletingScreen> {
  String? error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_delete);
  }

  Future<void> _delete() async {
    final code = ref.read(accountDeletionOtpProvider);
    if (code == null || code.isEmpty) {
      setState(() => error = 'OTP missing. Please verify your identity again.');
      return;
    }
    try {
      await ref.read(authProvider.notifier).deleteAccount(code);
      ref.read(accountDeletionOtpProvider.notifier).state = null;
      if (mounted) context.go('/profile/delete-account/success');
    } catch (e) {
      setState(() => error = apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SubPageShell(
      title: 'Account Deleting...',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 60, 18, 112),
        children: [
          const Center(
            child: SizedBox(
              width: 96,
              height: 96,
              child: CircularProgressIndicator(
                strokeWidth: 7,
                color: AppColors.primaryAlt,
              ),
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Please wait while we permanently delete your account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          const _HowRow('Verifying your account'),
          const _HowRow('Deleting your data'),
          const _HowRow('Finalizing'),
          if (error != null) ...[
            const SizedBox(height: 20),
            Text(error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.primaryAlt)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/profile/delete-account/verify'),
              style: _orangeButton(),
              child: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }
}

class AccountDeletedScreen extends StatelessWidget {
  const AccountDeletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 70, 22, 24),
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 104),
                const SizedBox(height: 26),
                const Text(
                  'Your account has been deleted successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'We hope to see you again. Thank you for being a part of VyparHub.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 34),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  style: _orangeButton(),
                  child: const Text('Done'),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeletionNote extends StatelessWidget {
  const _DeletionNote(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

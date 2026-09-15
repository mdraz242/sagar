part of 'login_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final loginId = TextEditingController();
  final loginPassword = TextEditingController();
  final signupName = TextEditingController();
  final signupPhone = TextEditingController();
  final signupEmail = TextEditingController();
  final signupShop = TextEditingController();
  final signupPassword = TextEditingController();
  final signupAddress = TextEditingController();
  final signupCity = TextEditingController();
  final signupPin = TextEditingController();

  int authMode = 0;
  int slide = 0;
  String loginCountryCode = '+91';
  String signupCountryCode = '+91';
  bool loginOtpRequested = false;
  bool signupOtpRequested = false;
  bool loading = false;
  bool locating = false;
  String? errorText;
  String? devOtp;
  String? pendingSignupPassword;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => mounted ? setState(() => slide = (slide + 1) % 2) : null,
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    loginId.dispose();
    loginPassword.dispose();
    signupName.dispose();
    signupPhone.dispose();
    signupEmail.dispose();
    signupShop.dispose();
    signupPassword.dispose();
    signupAddress.dispose();
    signupCity.dispose();
    signupPin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    final size = MediaQuery.sizeOf(context);
    final horizontalPad = size.width < 380 ? 14.0 : 20.0;

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
                padding:
                    EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 22),
                children: [
                  _Header(
                    lang: lang,
                    onLanguage: () => ref.read(langProvider.notifier).toggle(),
                  ),
                  const SizedBox(height: 18),
                  _HeroSlider(slide: slide, lang: lang),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      tr('kiranaWelcome', lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      tr('heroStock', lang),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: size.width < 380 ? 23 : 27,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AuthCard(
                    mode: authMode,
                    onMode: (value) => setState(() {
                      authMode = value;
                      errorText = null;
                      devOtp = null;
                      loginOtpRequested = false;
                      signupOtpRequested = false;
                      pendingSignupPassword = null;
                    }),
                    login: _loginForm(context),
                    signup: _signupForm(context),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '100% Secure',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('accountLogin', ref.watch(langProvider)),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        _AuthTextField(
          controller: loginId,
          hint: 'Phone number',
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
          prefix: _CountryCodePicker(
            value: loginCountryCode,
            onChanged: (value) => setState(() => loginCountryCode = value),
          ),
        ),
        const SizedBox(height: 14),
        _AuthTextField(
          controller: loginPassword,
          hint: loginOtpRequested
              ? 'Enter OTP'
              : tr('password', ref.watch(langProvider)),
          icon: Icons.lock_outline,
          obscureText: !loginOtpRequested,
          keyboardType:
              loginOtpRequested ? TextInputType.number : TextInputType.text,
        ),
        if (devOtp != null && loginOtpRequested) ...[
          const SizedBox(height: 8),
          Text(
            'Development OTP: $devOtp',
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => context.go('/forgot-password'),
            child: Text(
              tr('forgotPassword', ref.watch(langProvider)),
              style: const TextStyle(color: AppColors.text),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: loading ? null : _submitLogin,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: brandGradient(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 46),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      loginOtpRequested
                          ? 'Verify OTP'
                          : tr('login', ref.watch(langProvider)),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _QuickAuthRow(
          onBiometric: () => _showBiometricPending(context),
          onOtp: () => context.go('/otp-login'),
        ),
      ],
    );
  }

  Widget _signupForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('createAccount', ref.watch(langProvider)),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        _AuthTextField(
          controller: signupName,
          hint: tr('yourName', ref.watch(langProvider)),
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: signupPhone,
          hint: 'Phone number *',
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
          prefix: _CountryCodePicker(
            value: signupCountryCode,
            onChanged: (value) => setState(() => signupCountryCode = value),
          ),
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: signupEmail,
          hint: 'Email address (optional)',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: signupShop,
          hint: tr('shopName', ref.watch(langProvider)),
          icon: Icons.store_outlined,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: signupPassword,
          hint: signupOtpRequested
              ? 'Enter OTP'
              : tr('password', ref.watch(langProvider)),
          icon: Icons.lock_outline,
          obscureText: !signupOtpRequested,
          keyboardType:
              signupOtpRequested ? TextInputType.number : TextInputType.text,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: signupAddress,
          hint: tr('address', ref.watch(langProvider)),
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: locating ? null : _useSignupCurrentLocation,
          icon: locating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: const Text('Use current location'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AuthTextField(
                controller: signupCity,
                hint: tr('city', ref.watch(langProvider)),
                icon: Icons.map_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AuthTextField(
                controller: signupPin,
                hint: tr('pincode', ref.watch(langProvider)),
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (devOtp != null && signupOtpRequested) ...[
          const SizedBox(height: 8),
          Text(
            'Development OTP: $devOtp',
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: loading ? null : _submitSignup,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: brandGradient(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 46),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      signupOtpRequested
                          ? 'Verify OTP'
                          : tr('signup', ref.watch(langProvider)),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitLogin() async {
    final id = loginId.text.trim();
    final phone = _phoneFrom(id);
    if (phone.length < 10) {
      setState(() => errorText = 'Enter a valid phone number.');
      return;
    }
    if (loginPassword.text.trim().isEmpty) {
      setState(() => errorText = 'Enter your password.');
      return;
    }

    setState(() {
      loading = true;
      errorText = null;
    });

    try {
      await ref.read(authProvider.notifier).loginWithPassword(
            phone: phone,
            password: loginPassword.text.trim(),
          );
      if (mounted) context.go('/');
    } catch (error) {
      setState(() => errorText = _authErrorMessage(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _useSignupCurrentLocation() async {
    setState(() {
      locating = true;
      errorText = null;
    });

    try {
      final address = await const IndiaLocationService().currentAddress();
      setState(() {
        signupAddress.text = address.line1;
        signupCity.text = address.city;
        signupPin.text = address.pincode;
      });
    } catch (error) {
      setState(() => errorText = apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> _submitSignup() async {
    final phone = _phoneFrom(signupPhone.text.trim());
    if (phone.length < 10) {
      setState(() => errorText = 'Enter a valid phone number.');
      return;
    }

    setState(() {
      loading = true;
      errorText = null;
    });

    try {
      if (!signupOtpRequested && signupPassword.text.trim().length < 6) {
        throw const ApiException('Password must be at least 6 characters.');
      }

      if (!signupOtpRequested) {
        final registered =
            await ref.read(authProvider.notifier).isPhoneRegistered(phone);
        if (registered) {
          throw const ApiException(
            'This number is already registered. Please login instead.',
          );
        }

        pendingSignupPassword = signupPassword.text.trim();
        final sentCode = await ref.read(authProvider.notifier).requestOtp(
              phone: phone,
              name: signupName.text.trim(),
              shopName: signupShop.text.trim(),
              address: signupAddress.text.trim(),
              area: signupCity.text.trim(),
              pincode: signupPin.text.trim(),
            );
        setState(() {
          signupOtpRequested = true;
          devOtp = sentCode;
          signupPassword.clear();
          errorText = 'OTP sent to $signupCountryCode$phone';
        });
        return;
      }

      if (signupPassword.text.trim().isEmpty) {
        throw const ApiException('Enter OTP sent to your phone.');
      }

      await ref.read(authProvider.notifier).verifyOtp(
            phone: phone,
            code: signupPassword.text.trim(),
            name: signupName.text.trim(),
            password: pendingSignupPassword,
            shopName: signupShop.text.trim(),
            address: signupAddress.text.trim(),
            area: signupCity.text.trim(),
            pincode: signupPin.text.trim(),
          );
      if (mounted) context.go('/');
    } catch (error) {
      setState(() => errorText = _authErrorMessage(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _phoneFrom(String id) {
    final digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return id;
  }

  String _authErrorMessage(Object error) {
    final message = error.toString();
    if (message.toLowerCase().contains('otp')) return apiErrorMessage(error);
    if (message.toLowerCase().contains('msg91')) return apiErrorMessage(error);
    if (message.toLowerCase().contains('network')) {
      return 'Network issue while sending OTP. Please try again.';
    }
    return apiErrorMessage(error);
  }

  void _showBiometricPending(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('biometricReady', ref.read(langProvider))),
      ),
    );
  }
}

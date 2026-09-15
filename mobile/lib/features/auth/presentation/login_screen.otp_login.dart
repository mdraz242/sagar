part of 'login_screen.dart';

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final nameController = TextEditingController();
  final shopController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();
  final areaController = TextEditingController();
  final pincodeController = TextEditingController();
  String countryCode = '+91';
  int step = 0;
  int secondsLeft = 0;
  bool loading = false;
  bool newUser = false;
  String? error;
  String? devOtp;
  Timer? resendTimer;

  @override
  void dispose() {
    resendTimer?.cancel();
    phoneController.dispose();
    otpController.dispose();
    nameController.dispose();
    shopController.dispose();
    passwordController.dispose();
    addressController.dispose();
    areaController.dispose();
    pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: switch (step) {
                0 => _otpWelcome(),
                1 => _mobileEntry(),
                2 => _otpEntry(),
                3 => _completeSignup(),
                _ => _verified(),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _page({required List<Widget> children}) {
    return ListView(
      key: ValueKey(step),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () {
              if (step == 0) {
                context.go('/login');
              } else {
                setState(() {
                  error = null;
                  step--;
                });
              }
            },
            icon: const Icon(Icons.arrow_back, color: AppColors.blue),
          ),
        ),
        const SizedBox(height: 18),
        ...children,
      ],
    );
  }

  Widget _otpWelcome() {
    return _page(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Icon(
            Icons.storefront,
            color: AppColors.orange,
            size: 92,
          ),
        ),
        const SizedBox(height: 24),
        const Center(child: Text('Welcome to')),
        const Center(
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
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Your one-stop shop for everything you need',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 34),
        FilledButton(
          onPressed: () => setState(() => step = 1),
          style: _otpButtonStyle(),
          child: const Text('Sign In with OTP'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.go('/login'),
          child: const Text('Sign in with Mobile Number'),
        ),
      ],
    );
  }

  Widget _mobileEntry() {
    return _page(
      children: [
        const Text(
          'Enter Mobile Number',
          style: TextStyle(
              color: AppColors.blue, fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'We will send you a verification code to this number',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 28),
        const Text('Mobile Number',
            style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_android),
            prefix: _CountryCodePicker(
              value: countryCode,
              onChanged: (value) => setState(() => countryCode = value),
            ),
            hintText: 'Enter mobile number',
          ),
        ),
        if (error != null) _errorText(error!),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: loading ? null : _sendOtp,
          style: _otpButtonStyle(),
          child: Text(loading ? 'Sending...' : 'Send OTP'),
        ),
        const SizedBox(height: 20),
        const Text(
          'By continuing, you agree to our Terms & Conditions and Privacy Policy',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _otpEntry() {
    final phone = _phoneFrom(phoneController.text);
    return _page(
      children: [
        const Text(
          'Enter OTP',
          style: TextStyle(
              color: AppColors.blue, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Enter the code sent to\n'),
              TextSpan(
                  text: '$countryCode $phone ',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => setState(() => step = 1),
                  child: const Text('Edit',
                      style: TextStyle(
                          color: AppColors.brightBlue,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 26),
        TextField(
          controller: otpController,
          autofocus: true,
          maxLength: 6,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 12),
          decoration:
              const InputDecoration(counterText: '', hintText: '------'),
        ),
        if (devOtp != null) ...[
          const SizedBox(height: 8),
          Text('Development OTP: $devOtp',
              style: const TextStyle(
                  color: AppColors.success, fontWeight: FontWeight.w800)),
        ],
        const SizedBox(height: 14),
        TextButton(
          onPressed: secondsLeft == 0 && !loading ? _sendOtp : null,
          child: Text(secondsLeft == 0
              ? 'Resend OTP'
              : 'Resend OTP in ${_formatOtpTimer(secondsLeft)}'),
        ),
        if (error != null) _errorText(error!),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: loading ? null : _verifyOtp,
          style: _otpButtonStyle(),
          child: Text(loading ? 'Verifying...' : 'Verify OTP'),
        ),
      ],
    );
  }

  Widget _verified() {
    return _page(
      children: [
        const SizedBox(height: 54),
        const Center(
            child:
                Icon(Icons.check_circle, color: AppColors.success, size: 104)),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Mobile Verified',
            style: TextStyle(
                color: AppColors.blue,
                fontSize: 20,
                fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Your mobile number has been successfully verified.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 40),
        FilledButton(
          onPressed: () => context.go('/'),
          style: _otpButtonStyle(),
          child: const Text('Continue'),
        ),
        TextButton(
          onPressed: () => context.go('/'),
          child: const Text('Go to Home'),
        ),
      ],
    );
  }

  Widget _completeSignup() {
    return _page(
      children: [
        const Text(
          'Complete Signup',
          style: TextStyle(
            color: AppColors.blue,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This number is new. Add your shop details to create your VyparHub account.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        _otpTextField(
          controller: nameController,
          icon: Icons.person_outline,
          hint: 'Owner name',
        ),
        _otpTextField(
          controller: shopController,
          icon: Icons.storefront_outlined,
          hint: 'Shop name',
        ),
        _otpTextField(
          controller: passwordController,
          icon: Icons.lock_outline,
          hint: 'Create password',
          obscure: true,
        ),
        _otpTextField(
          controller: addressController,
          icon: Icons.location_on_outlined,
          hint: 'Shop address',
        ),
        Row(
          children: [
            Expanded(
              child: _otpTextField(
                controller: areaController,
                icon: Icons.map_outlined,
                hint: 'City / area',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _otpTextField(
                controller: pincodeController,
                icon: Icons.pin_outlined,
                hint: 'Pincode',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
            ),
          ],
        ),
        if (error != null) _errorText(error!),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: loading ? null : _createOtpAccount,
          style: _otpButtonStyle(),
          child: Text(loading ? 'Creating...' : 'Create Account'),
        ),
      ],
    );
  }

  Widget _otpTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
        ),
      ),
    );
  }

  Widget _errorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        style: const TextStyle(
            color: AppColors.primaryAlt, fontWeight: FontWeight.w800),
      ),
    );
  }

  Future<void> _sendOtp() async {
    final phone = _phoneFrom(phoneController.text);
    if (phone.length != 10) {
      setState(() => error = 'Enter a valid 10 digit mobile number.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
      devOtp = null;
    });
    try {
      newUser = !await ref.read(authProvider.notifier).isPhoneRegistered(phone);
      final code =
          await ref.read(authProvider.notifier).requestOtp(phone: phone);
      _startResendTimer();
      setState(() {
        devOtp = code;
        step = 2;
        if (newUser) {
          error =
              'New number detected. We will create your VyparHub account after OTP verification.';
        }
      });
    } catch (e) {
      setState(() => error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneFrom(phoneController.text);
    final code = otpController.text.trim();
    if (code.length != 6) {
      setState(() => error = 'Enter the 6 digit OTP sent to your phone.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (newUser) {
        setState(() {
          step = 3;
          loading = false;
        });
        return;
      }
      await ref.read(authProvider.notifier).verifyOtp(
            phone: phone,
            code: code,
          );
      setState(() => step = 4);
    } catch (e) {
      setState(() => error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _createOtpAccount() async {
    final phone = _phoneFrom(phoneController.text);
    final code = otpController.text.trim();
    final name = nameController.text.trim();
    final shop = shopController.text.trim();
    final password = passwordController.text.trim();
    final address = addressController.text.trim();
    final area = areaController.text.trim();
    final pincode = pincodeController.text.trim();

    if (name.isEmpty ||
        shop.isEmpty ||
        password.length < 6 ||
        address.isEmpty ||
        area.isEmpty ||
        pincode.length != 6) {
      setState(() => error =
          'Enter owner, shop, password, address, city and 6 digit pincode.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });
    try {
      await ref.read(authProvider.notifier).verifyOtp(
            phone: phone,
            code: code,
            name: name,
            password: password,
            shopName: shop,
            address: address,
            area: area,
            pincode: pincode,
          );
      setState(() => step = 4);
    } catch (e) {
      setState(() => error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _startResendTimer() {
    resendTimer?.cancel();
    secondsLeft = 600;
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  String _phoneFrom(String id) {
    final digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  ButtonStyle _otpButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.primaryAlt,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

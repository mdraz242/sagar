part of 'login_screen.dart';

class _Header extends StatelessWidget {
  const _Header({required this.lang, required this.onLanguage});
  final Lang lang;
  final VoidCallback onLanguage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Image.asset(
                'assets/branding/vyparhub_v_mark.png',
                height: 48,
                width: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Vypar',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(
                            text: 'Hub',
                            style: TextStyle(
                              color: AppColors.orange2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 29, height: .94),
                    ),
                    const Text(
                      'Makers seh Market tak',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF5A6072),
                        fontSize: 9,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            onTap: onLanguage,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.translate,
                      size: 18, color: AppColors.brightBlue),
                  const SizedBox(width: 6),
                  Text(
                    lang == Lang.hi ? 'EN' : 'हिंदी',
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSlider extends StatelessWidget {
  const _HeroSlider({required this.slide, required this.lang});
  final int slide;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final image = slide == 0
        ? 'assets/images/kirana-shop.jpg'
        : 'assets/images/delivery-2h.jpg';
    final badge = lang == Lang.hi ? '2 घंटे में डिलीवरी' : '2 HOUR DELIVERY';

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: Image.asset(
              image,
              key: ValueKey(image),
              height: width < 380 ? 168 : 188,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.orange2,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 18,
            right: 16,
            child: Text(
              tr('heroProfit', lang),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: width < 380 ? 24 : 30,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.mode,
    required this.onMode,
    required this.login,
    required this.signup,
  });

  final int mode;
  final ValueChanged<int> onMode;
  final Widget login;
  final Widget signup;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _RoleSwitch(value: mode, onChanged: onMode),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(mode),
                child: mode == 0 ? login : signup,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSwitch extends ConsumerWidget {
  const _RoleSwitch({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E8E8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleButton(
              label: tr('login', lang),
              active: value == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _RoleButton(
              label: tr('signup', lang),
              active: value == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.text : const Color(0xFF9AA1AD),
            fontWeight: active ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _QuickAuthRow extends ConsumerWidget {
  const _QuickAuthRow({required this.onBiometric, required this.onOtp});
  final VoidCallback onBiometric;
  final VoidCallback onOtp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return Row(
      children: [
        Expanded(
          child: _QuickAuthButton(
            onTap: onBiometric,
            child: const Icon(Icons.fingerprint,
                color: AppColors.brightBlue, size: 30),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAuthButton(
            onTap: onOtp,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sms_outlined,
                    color: AppColors.brightBlue, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    tr('signInOtp', lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.brightBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAuthButton extends StatelessWidget {
  const _QuickAuthButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8E9F0)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CountryCodePicker extends StatelessWidget {
  const _CountryCodePicker({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const codes = [
    '+91',
    '+977',
    '+1',
    '+44',
    '+971',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        borderRadius: BorderRadius.circular(12),
        items: [
          for (final code in codes)
            DropdownMenuItem(
              value: code,
              child: Text(
                code,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
        ],
        onChanged: (code) {
          if (code != null) onChanged(code);
        },
      ),
    );
  }
}

class _AuthTextField extends StatefulWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.prefix,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefix;

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  late bool obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(12),
      child: TextField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: obscure,
        style: const TextStyle(fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: Color(0xFFB8BBC5)),
          prefixIcon: widget.prefix == null
              ? Icon(widget.icon, color: AppColors.muted)
              : SizedBox(
                  width: 108,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, color: AppColors.muted),
                      const SizedBox(width: 6),
                      widget.prefix!,
                    ],
                  ),
                ),
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.muted,
                  ),
                  onPressed: () => setState(() => obscure = !obscure),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEDEEF2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.orange2, width: 1.4),
          ),
        ),
      ),
    );
  }
}

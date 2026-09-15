part of 'profile_subpages.dart';

class _SubPageShell extends StatelessWidget {
  const _SubPageShell({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      showHeader: false,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    icon: const Icon(Icons.arrow_back, color: AppColors.blue),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  action ?? const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill(this.label, {this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEFE8) : Colors.white,
          border: Border.all(
              color: selected ? AppColors.orange : const Color(0xFFE8EAF2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.orange : AppColors.blue,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(isDense: true),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.blue,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SimpleRow extends StatelessWidget {
  const _SimpleRow(this.icon, this.title, this.onTap);

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: _cardDecoration(),
      child: ListTile(
        leading: Icon(icon, color: AppColors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

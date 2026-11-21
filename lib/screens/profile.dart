import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:mzumbefood/data/store.dart';
import 'package:mzumbefood/models/models.dart';
import 'package:mzumbefood/providers.dart';
import 'package:mzumbefood/widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _openProfileEditor(OwnerProfile profile) async {
    final store = context.read<DataStore>();
    final name = TextEditingController(text: profile.name);
    final business = TextEditingController(text: profile.businessName);
    final budget = TextEditingController(
      text: profile.dailyBudget > 0 ? profile.dailyBudget.toString() : '',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: S.ownerName),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: business,
                decoration: const InputDecoration(labelText: S.businessName),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: budget,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: S.dailyBudget),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(S.save),
          ),
        ],
      ),
    );
    if (saved != true) {
      name.dispose();
      business.dispose();
      budget.dispose();
      return;
    }
    final updated = profile.copyWith(
      name: name.text.trim(),
      businessName: business.text.trim().isEmpty
          ? S.businessDefault
          : business.text.trim(),
      dailyBudget: double.tryParse(budget.text.trim()) ?? 0,
    );
    name.dispose();
    business.dispose();
    budget.dispose();
    await store.saveProfile(updated);
    if (mounted) showSuccess(context);
  }

  Future<void> _openPasswordEditor(String email) async {
    final auth = context.read<AuthProvider>();
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(S.changePassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: S.confirmPassword),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(S.save),
          ),
        ],
      ),
    );
    if (submitted != true) {
      current.dispose();
      next.dispose();
      confirm.dispose();
      return;
    }
    final newPassword = next.text;
    final matches = newPassword == confirm.text && newPassword.length >= 6;
    final oldPassword = current.text;
    current.dispose();
    next.dispose();
    confirm.dispose();
    if (!matches) {
      if (mounted) {
        showSuccess(context, 'Passwords do not match or are too short.');
      }
      return;
    }
    final ok = await auth.changePassword(email, oldPassword, newPassword);
    if (!mounted) return;
    if (ok) {
      showSuccess(context, 'Password changed');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? S.genericError)),
      );
    }
  }

  Future<void> _seedMenu() async {
    final store = context.read<DataStore>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(S.seedMenu),
        content: const Text(
          'Add sample foods and an egg tray ingredient. You can edit or delete them later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(S.add),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    await store.seedSampleMenu();
    if (mounted) showSuccess(context, 'Sample foods added');
  }

  Future<void> _exportCsv(DataProvider data) async {
    final csv = context.read<DataStore>().buildCsv(
          sales: data.sales,
          expenses: data.expenses,
          debts: data.debts,
        );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(S.exportCsv),
        content: SizedBox(
          width: double.maxFinite,
          height: 420,
          child: SelectableText(csv),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(S.close),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final auth = context.read<AuthProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(S.signOut),
        content: const Text('Do you want to sign out of MU Food Delivery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(S.signOut),
          ),
        ],
      ),
    );
    if (confirm == true) await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final profile = data.profile;
    final name = profile.name.isEmpty ? S.appName : profile.name;

    return Scaffold(
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: GradientHeader(
                    title: S.profile,
                    subtitle: auth.user?.email ?? '',
                    showLogo: true,
                    child: SoftCard(
                      color: Colors.white,
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                              color: AppColors.accentSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                Fmt.initials(name),
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  profile.businessName,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: AppColors.primaryDark),
                            onPressed: () => _openProfileEditor(profile),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Column(
                      children: [
                        SoftCard(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              _Tile(
                                icon: Icons.restaurant_menu,
                                title: S.menu,
                                subtitle: '${data.menuItems.length} foods saved',
                                onTap: () => context.go('/menu'),
                              ),
                              _Tile(
                                icon: Icons.egg_outlined,
                                title: S.ingredients,
                                subtitle: '${data.ingredients.length} ingredients',
                                onTap: () => context.go('/ingredients'),
                              ),
                              _Tile(
                                icon: Icons.kebab_dining,
                                title: S.mishkaki,
                                subtitle: 'Sticks and stock',
                                onTap: () => context.go('/mishkaki'),
                              ),
                              _Tile(
                                icon: Icons.inventory_2,
                                title: S.sacks,
                                subtitle: '${data.sacks.length} sacks',
                                onTap: () => context.go('/sacks'),
                              ),
                              _Tile(
                                icon: Icons.label_outline,
                                title: S.expenseNames,
                                subtitle: 'Quick expense entries',
                                onTap: () => context.go('/expense-names'),
                              ),
                              _Tile(
                                icon: Icons.wallet,
                                title: S.personalBudget,
                                subtitle: profile.dailyBudget > 0
                                    ? '${Fmt.money(profile.dailyBudget)} per day'
                                    : 'Not set',
                                onTap: () => context.go('/personal-budget'),
                              ),
                              _Tile(
                                icon: Icons.payments,
                                title: S.personalIncome,
                                subtitle: 'Separate from business',
                                onTap: () => context.go('/personal-income'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SoftCard(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              _Tile(
                                icon: Icons.lock_outline,
                                title: S.changePassword,
                                subtitle: 'Keep your account safe',
                                trailing: auth.isBusy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : null,
                                onTap: () => _openPasswordEditor(
                                  auth.user?.email ?? '',
                                ),
                              ),
                              _Tile(
                                icon: Icons.auto_awesome,
                                title: S.seedMenu,
                                subtitle: 'Chips mayai, eggs, rice and mishkaki',
                                onTap: _seedMenu,
                              ),
                              _Tile(
                                icon: Icons.file_download,
                                title: S.exportCsv,
                                subtitle: 'Copy sales, expenses and debts',
                                onTap: () => _exportCsv(data),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SoftCard(
                          color: AppColors.accentSoft,
                          padding: const EdgeInsets.all(8),
                          child: _Tile(
                            icon: Icons.logout,
                            title: S.signOut,
                            subtitle: auth.user?.email ?? '',
                            color: AppColors.danger,
                            onTap: _signOut,
                          ),
                        ),
                        if (data.error != null) ...[
                          const SizedBox(height: 14),
                          ErrorBanner(
                            message: data.error!,
                            onRetry: data.retry,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: (color ?? AppColors.primaryDark).withValues(
              alpha: 0.10,
            ),
            child: Icon(icon, color: color ?? AppColors.primaryDark, size: 21),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color ?? AppColors.ink,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          trailing:
              trailing ?? const Icon(Icons.chevron_right, color: AppColors.muted),
          onTap: onTap,
        ),
      );
}

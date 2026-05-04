import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exceptions.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

import '../cubit/auth_cubit.dart';

enum _Role { student, teacher, parent }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  _Role _selectedRole = _Role.student;

  late final AnimationController _logoController;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      await context.read<AuthCubit>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole.name,
      );

      if (!mounted) return;
      final route = switch (_selectedRole) {
        _Role.student => RouteNames.studentDashboard,
        _Role.teacher => RouteNames.teacherDashboard,
        _Role.parent => RouteNames.parentHome,
      };
      Navigator.of(context).pushReplacementNamed(route);
    } catch (e) {
      if (!mounted) return;
      final message = _friendlyError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object e) {
    if (e is NetworkException) {
      return 'No internet connection. Please check your network.';
    }
    if (e is UnauthorizedException) {
      return 'Invalid email or password.';
    }
    if (e is ApiException) {
      return e.message;
    }
    return 'Something went wrong. Please try again.';
  }

  ({String email, String password}) _testCredentialsForRole(_Role role) {
    return switch (role) {
      _Role.student => (
        email: 'nebiyumusbah378@gmail.com',
        password: 'Student@123',
      ),
      _Role.parent => (email: 'musbahyesuf@gmail.com', password: 'Parent@123'),
      _Role.teacher => (email: 'abduisa@gmail.com', password: 'Teacher@1234'),
    };
  }

  void _useTestAccount({
    required String email,
    required String password,
    required _Role role,
  }) {
    setState(() {
      _selectedRole = role;
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryHero,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: AppShadows.glow(AppColors.primary),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                  AppSpacing.gapXl,
                  Text(
                    'Welcome to TriLink',
                    style: theme.textTheme.headlineSmall,
                  ),
                  AppSpacing.gapXs,
                  Text(
                    'Learn smarter, grow faster',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapXl,
                  _buildRoleSelector(theme),
                  AppSpacing.gapLg,
                  _buildEmail(theme),
                  AppSpacing.gapMd,
                  _buildPassword(theme),
                  AppSpacing.gapMd,
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('LOG IN'),
                    ),
                  ),
                  AppSpacing.gapLg,
                  _buildTestAccounts(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.borderMd,
      ),
      child: Row(
        children: _Role.values.map((role) {
          final isSelected = _selectedRole == role;
          final label = role.name[0].toUpperCase() + role.name.substring(1);
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmail(ThemeData theme) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email';
        }
        return null;
      },
    );
  }

  Widget _buildPassword(ThemeData theme) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your password';
        return null;
      },
    );
  }

  Widget _buildTestAccounts(ThemeData theme) {
    final creds = _testCredentialsForRole(_selectedRole);
    final roleLabel =
        _selectedRole.name[0].toUpperCase() + _selectedRole.name.substring(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Accounts',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapXs,
          Text(
            'Selected role: $roleLabel. Tap to auto-fill this role credentials.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapSm,
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _useTestAccount(
              email: creds.email,
              password: creds.password,
              role: _selectedRole,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bug_report_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$roleLabel  •  ${creds.email}  •  ${creds.password}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

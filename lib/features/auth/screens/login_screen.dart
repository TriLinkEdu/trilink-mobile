import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../core/routes/route_names.dart';
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
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
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
      final authCubit = context.read<AuthCubit>();
      await authCubit.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole.name,
      );

      final String destinationRoute;
      switch (_selectedRole) {
        case _Role.student:
          destinationRoute = RouteNames.studentDashboard;
          break;
        case _Role.teacher:
          destinationRoute = RouteNames.teacherDashboard;
          break;
        case _Role.parent:
          destinationRoute = RouteNames.parentHome;
          break;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(destinationRoute);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleContinueOffline() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthCubit>().loginOffline();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(RouteNames.studentDashboard);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offline login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDarkModeToggle(theme, isDark),
                  AppSpacing.gapLg,
                  _buildAnimatedLogo(theme),
                  AppSpacing.gapXxl,
                  Text(
                    'Welcome to TriLink',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  AppSpacing.gapXs,
                  Text(
                    'Learn smarter, grow faster',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapXxl,
                  _buildRoleSelector(theme),
                  AppSpacing.gapXxl,
                  _buildEmailField(theme),
                  AppSpacing.gapLg,
                  _buildPasswordField(theme),
                  _buildForgotPassword(theme),
                  AppSpacing.gapSm,
                  _buildLoginButton(theme),
                  AppSpacing.gapMd,
                  _buildCreateAccount(theme),
                  AppSpacing.gapXxl,
                  _buildContinueOffline(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(ThemeData theme, bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          ThemeNotifier.instance.toggle();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.borderMd,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(isDark),
              color: isDark
                  ? AppColors.xpGold
                  : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo(ThemeData theme) {
    return ScaleTransition(
      scale: _logoScale,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          gradient: AppGradients.primaryHero,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.glow(AppColors.primary),
        ),
        child: const Icon(Icons.school_rounded, color: Colors.white, size: 44),
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
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedRole = role);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? AppShadows.glow(theme.colorScheme.primary)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      role == _Role.student
                          ? Icons.school
                          : role == _Role.teacher
                              ? Icons.person
                              : Icons.family_restroom,
                      size: 16,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    AppSpacing.hGapXs,
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmailField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email', style: theme.textTheme.labelLarge),
        AppSpacing.gapSm,
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: _selectedRole == _Role.student
                ? 'student@school.edu'
                : _selectedRole == _Role.teacher
                    ? 'teacher@school.edu'
                    : 'parent@email.com',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your email';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password', style: theme.textTheme.labelLarge),
        AppSpacing.gapSm,
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildForgotPassword(ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () =>
            Navigator.of(context).pushNamed(RouteNames.forgotPassword),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: const Text('Forgot password?'),
      ),
    );
  }

  Widget _buildLoginButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : const Text('LOG IN'),
      ),
    );
  }

  Widget _buildCreateAccount(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pushNamed(RouteNames.register),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: const Text('Sign Up'),
        ),
      ],
    );
  }

  Widget _buildContinueOffline(ThemeData theme) {
    return TextButton.icon(
      onPressed: _isLoading ? null : _handleContinueOffline,
      icon: Icon(
        Icons.wifi_off_rounded,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(
        'Continue offline',
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
    );
  }
}

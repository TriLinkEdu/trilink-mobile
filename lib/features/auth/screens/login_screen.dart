import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../core/routes/route_names.dart';
import '../cubit/auth_cubit.dart';

enum _Role { student, teacher, parent }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  _Role _selectedRole = _Role.student;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
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
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDarkModeToggle(theme, isDark),
                  const SizedBox(height: 16),
                  _buildLogo(),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to TriLink',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Learn smarter, grow faster',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.primary.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildRoleSelector(theme),
                  const SizedBox(height: 28),
                  _buildEmailField(theme),
                  const SizedBox(height: 20),
                  _buildPasswordField(theme),
                  _buildForgotPassword(theme),
                  const SizedBox(height: 8),
                  _buildLoginButton(theme),
                  const SizedBox(height: 24),
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
        onTap: () => ThemeNotifier.instance.toggle(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            color: isDark ? Colors.amber : theme.colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.school_rounded, color: Colors.white, size: 44),
    );
  }

  Widget _buildRoleSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _Role.values.map((role) {
          final isSelected = _selectedRole == role;
          final label = role.name[0].toUpperCase() + role.name.substring(1);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
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
                    const SizedBox(width: 6),
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
        Text(
          'Email',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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
        Text(
          'Password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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
        child: Text(
          'Forgot password?',
          style: TextStyle(color: theme.colorScheme.primary, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildLoginButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
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

  Widget _buildContinueOffline(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.wifi_off_rounded,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        TextButton(
          onPressed: _isLoading ? null : _handleContinueOffline,
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(
            'Continue offline',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

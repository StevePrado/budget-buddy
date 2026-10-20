import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  final _passwordFocusNode = FocusNode();
  bool _passwordTouched = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLogin = true; // true = Log In, false = Register

  // Email validation regex (6.4)
  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  // Password rules checks (6.3)
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSpecialChar =>
      RegExp(r'[!@#$%^&*.,?_\-]').hasMatch(_passwordController.text);

  bool get _allPasswordRulesMet =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecialChar;

  bool get _passwordsMatch =>
      _passwordController.text == _confirmPasswordController.text;

  bool get _isRegisterButtonEnabled {
    if (_isLogin) return true;
    return _allPasswordRulesMet &&
        _passwordsMatch &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _emailController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(_onPasswordInteraction);
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
  }

  void _onPasswordInteraction() {
    if (_passwordFocusNode.hasFocus && !_passwordTouched) {
      if (mounted) {
        setState(() => _passwordTouched = true);
      }
    }
  }

  void _onPasswordChanged() {
    if (_passwordController.text.isNotEmpty && !_passwordTouched) {
      _passwordTouched = true;
    }
    _onFieldChanged();
  }

  void _onFieldChanged() {
    if (!_isLogin && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _switchMode(bool isLogin) {
    if (_isLogin == isLogin) return;
    setState(() {
      _isLogin = isLogin;
      _passwordTouched = false;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLogin) {
      if (!_allPasswordRulesMet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please meet all password requirements.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      if (!_passwordsMatch) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await _authService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_authService.getFriendlyError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo & Brand Header
                  const Center(
                    child: ContainerHeaderIcon(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BudgetBuddy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6.1: Two-option Segmented Toggle (Log In | Register)
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchMode(true),
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _isLogin
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Log In',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _isLogin
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchMode(false),
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: !_isLogin
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Register',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: !_isLogin
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6.1: Animated Switcher for Title and Subtitle
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey<bool>(_isLogin),
                      children: [
                        Text(
                          _isLogin ? 'Welcome back' : 'Create your account',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLogin
                              ? 'Log in to your BudgetBuddy account'
                              : 'Start tracking your allowance',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Fields
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email Field (6.4: Regex validation)
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!_emailRegex.hasMatch(v.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.textSecondary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),

                        // 1.1 - 1.3: Unmet password rules only (Register only)
                        if (!_isLogin && _passwordTouched) ...[
                          const SizedBox(height: 8),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: _allPasswordRulesMet
                                ? const Padding(
                                    key: ValueKey('strong_password_indicator'),
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 15,
                                          color: AppColors.success,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Strong password',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    key: const ValueKey('unmet_password_rules'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!_hasMinLength)
                                        _buildUnmetRuleItem(
                                            'At least 8 characters'),
                                      if (!_hasUppercase)
                                        _buildUnmetRuleItem(
                                            'At least 1 uppercase letter'),
                                      if (!_hasLowercase)
                                        _buildUnmetRuleItem(
                                            'At least 1 lowercase letter'),
                                      if (!_hasNumber)
                                        _buildUnmetRuleItem(
                                            'At least 1 number'),
                                      if (!_hasSpecialChar)
                                        _buildUnmetRuleItem(
                                            'At least 1 special character (!@#\$%^&*.,?_-)'),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 4),
                        ],

                        if (!_isLogin) ...[
                          const SizedBox(height: 10),
                          // 1.4 & 6.2: Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.textSecondary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (v != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Main Submit Button (6.3: Disabled on Register until all rules pass)
                        ElevatedButton(
                          onPressed: (_isLoading || !_isRegisterButtonEnabled)
                              ? null
                              : _submit,
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor:
                                AppColors.surfaceHigh.withValues(alpha: 0.6),
                            disabledForegroundColor: AppColors.textMuted,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Log In' : 'Create Account',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 18),

                        // Bottom Navigation Toggle Text (6.1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? "Don't have an account? "
                                  : 'Already have an account? ',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _switchMode(!_isLogin),
                              child: Text(
                                _isLogin ? 'Register' : 'Log in',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildUnmetRuleItem(String text) {
    return Padding(
      key: ValueKey<String>(text),
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          const Icon(
            Icons.close_rounded,
            size: 14,
            color: AppColors.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContainerHeaderIcon extends StatelessWidget {
  const ContainerHeaderIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Icon(
        Icons.account_balance_wallet_rounded,
        size: 38,
        color: AppColors.primary,
      ),
    );
  }
}

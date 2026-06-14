import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

enum _Mode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  _Mode _mode = _Mode.signIn;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _isSignIn => _mode == _Mode.signIn;

  void _toggleMode() {
    setState(() {
      _mode = _isSignIn ? _Mode.signUp : _Mode.signIn;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final err = _isSignIn
        ? await auth.signIn(_email.text.trim(), _password.text)
        : await auth.signUp(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().signInGoogle();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg : AppColors.lightBg;
    final text = isDark ? AppColors.textPrimary : AppColors.lightText;
    final muted = isDark ? AppColors.textTertiary : AppColors.lightMuted;

    return Scaffold(
      backgroundColor: bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark
            ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      _Brand(isDark: isDark),
                      const SizedBox(height: 40),
                      Text(
                        _isSignIn ? 'Welcome back' : 'Create your shelf',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: text,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignIn
                            ? 'Sign in to sync your library across devices.'
                            : 'Start collecting and organising your reads.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _LabeledField(
                        label: 'Email',
                        child: TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          enabled: !_busy,
                          decoration: const InputDecoration(
                            hintText: 'you@example.com',
                            prefixIcon: Icon(Icons.alternate_email, size: 18),
                          ),
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return 'Email is required';
                            if (!s.contains('@') || !s.contains('.')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Password',
                        trailing: _isSignIn
                            ? GestureDetector(
                                onTap: _busy ? null : () {
                                  // TODO: hook up password reset
                                },
                                child: Text(
                                  'Forgot?',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: muted,
                                  ),
                                ),
                              )
                            : null,
                        child: TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          autofillHints: [
                            _isSignIn
                                ? AutofillHints.password
                                : AutofillHints.newPassword,
                          ],
                          textInputAction: TextInputAction.done,
                          enabled: !_busy,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: _isSignIn
                                ? 'Enter your password'
                                : 'At least 6 characters',
                            prefixIcon: const Icon(Icons.lock_outline, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            final s = v ?? '';
                            if (s.isEmpty) return 'Password is required';
                            if (!_isSignIn && s.length < 6) {
                              return 'Use at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBanner(message: _error!, isDark: isDark),
                      ],
                      const SizedBox(height: 24),
                      _PrimaryButton(
                        label: _isSignIn ? 'Sign in' : 'Create account',
                        busy: _busy,
                        onPressed: _busy ? null : _submit,
                      ),
                      const SizedBox(height: 20),
                      _OrDivider(isDark: isDark),
                      const SizedBox(height: 20),
                      _GoogleButton(
                        isDark: isDark,
                        onPressed: _busy ? null : _google,
                      ),
                      const SizedBox(height: 28),
                      _ModeSwitcher(
                        isSignIn: _isSignIn,
                        isDark: isDark,
                        onTap: _busy ? null : _toggleMode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final bool isDark;
  const _Brand({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.textPrimary : AppColors.lightText;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.border : Colors.black12,
            ),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/logo.svg',
            width: 36,
            height: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'OpenShelf',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: text,
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? trailing;
  const _LabeledField({
    required this.label,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? AppColors.textSecondary : AppColors.lightMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: labelColor,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF0D0D0D),
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
          disabledForegroundColor: const Color(0xFF0D0D0D),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF0D0D0D)),
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onPressed;
  const _GoogleButton({required this.isDark, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.textPrimary : AppColors.lightText;
    final border = isDark ? AppColors.borderMid : Colors.black12;
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const _GoogleGlyph(),
        label: Text(
          'Continue with Google',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? AppColors.surface : Colors.white,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Text(
        'G',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4285F4),
          height: 1.0,
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final bool isDark;
  const _OrDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final line = isDark ? AppColors.border : Colors.black12;
    final muted = isDark ? AppColors.textTertiary : AppColors.lightMuted;
    return Row(
      children: [
        Expanded(child: Divider(color: line, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: muted,
            ),
          ),
        ),
        Expanded(child: Divider(color: line, height: 1)),
      ],
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  final bool isSignIn;
  final bool isDark;
  final VoidCallback? onTap;
  const _ModeSwitcher({
    required this.isSignIn,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.textTertiary : AppColors.lightMuted;
    final accent = isDark ? AppColors.textPrimary : AppColors.lightText;
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            isSignIn ? 'New here? ' : 'Already have an account? ',
            style: GoogleFonts.inter(fontSize: 13, color: muted),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              isSignIn ? 'Create account' : 'Sign in',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
                decoration: TextDecoration.underline,
                decorationColor: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ErrorBanner({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? const Color(0xFF2A1A1A)
        : const Color(0xFFFDECEC);
    final fg = isDark
        ? const Color(0xFFFFB4B4)
        : const Color(0xFF8A1F1F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: fg,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

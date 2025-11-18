import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_screen_controller.dart';
import 'widgets/error_banner.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authScreenControllerProvider, (previous, next) {
      if (next.isAuthenticated) {
        ref.read(authScreenControllerProvider.notifier).checkAuthStatus();
      }
    });
    final state = ref.watch(authScreenControllerProvider);
    final controller = ref.read(authScreenControllerProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade200,
              Colors.purple.shade200,
            ],
          ),
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      maxHeight: 600,
                    ),
                    child: _buildAuthFlow(state, controller),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildAuthFlow(state, controller),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthFlow(AuthState state, AuthScreenController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ErrorBanner(error: state.error),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildChild(state, controller),
        ),
      ],
    );
  }

  Widget _buildChild(AuthState state, AuthScreenController controller) {
    if (state.flow == AuthFlow.passwordReset && state.step == AuthStep.code) {
      return TokenInputView(key: const ValueKey('token_input'));
    }

    switch (state.step) {
      case AuthStep.credentials:
        return CredentialsView(key: ValueKey(state.flow));
      case AuthStep.code:
        return CodeInputView(key: const ValueKey('code_input'));
      case AuthStep.orgSelection:
        return const OrganizationSelectionView(
            key: ValueKey('org_selection'),);
      case AuthStep.token:
        return TokenInputView(key: const ValueKey('token_input'));
    }
  }
}

class CredentialsView extends ConsumerStatefulWidget {
  const CredentialsView({super.key});

  @override
  ConsumerState<CredentialsView> createState() => _CredentialsViewState();
}

class _CredentialsViewState extends ConsumerState<CredentialsView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authScreenControllerProvider);
    final controller = ref.read(authScreenControllerProvider.notifier);
    final isRegister = state.flow == AuthFlow.register;

    final title = switch (state.flow) {
      AuthFlow.login => 'Welcome Back',
      AuthFlow.register => 'Create an Account',
      AuthFlow.passwordReset => 'Reset Password',
    };

    final buttonText = switch (state.flow) {
      AuthFlow.login => 'Login',
      AuthFlow.register => 'Register',
      AuthFlow.passwordReset => 'Send Reset Link',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || !value.contains('@'))
                  ? 'Please enter a valid email'
                  : null,
            ),
            const SizedBox(height: 16),
            if (state.flow != AuthFlow.passwordReset)
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) => (value == null || value.length < 8)
                    ? 'Password must be at least 8 characters'
                    : null,
              ),
            if (isRegister) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: state.isLoading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        controller.submitCredentials(
                          _emailController.text,
                          _passwordController.text,
                        );
                      }
                    },
              child: state.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(buttonText),
            ),
            const SizedBox(height: 16),
            _buildFooter(context, controller, state.flow),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
      BuildContext context, AuthScreenController controller, AuthFlow flow) {
    switch (flow) {
      case AuthFlow.login:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => controller.setFlow(AuthFlow.passwordReset),
              child: const Text('Forgot Password?'),
            ),
            TextButton(
              onPressed: () => controller.setFlow(AuthFlow.register),
              child: const Text('No account? Register'),
            ),
          ],
        );
      case AuthFlow.register:
      case AuthFlow.passwordReset:
        return Center(
          child: TextButton(
            onPressed: () => controller.setFlow(AuthFlow.login),
            child: const Text('Back to Login'),
          ),
        );
    }
  }
}

class CodeInputView extends ConsumerStatefulWidget {
  const CodeInputView({super.key});

  @override
  ConsumerState<CodeInputView> createState() => _CodeInputViewState();
}

class _CodeInputViewState extends ConsumerState<CodeInputView> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _pincode => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authScreenControllerProvider);
    final controller = ref.read(authScreenControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter Verification Code',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Enter the 6-digit code sent to ${state.email}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 40,
                height: 50,
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    }
                    if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: state.isLoading
                ? null
                : () {
                    if (_pincode.length == 6) {
                      controller.submitCode(_pincode);
                    }
                  },
            child: state.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: controller.back,
                child: const Text('Back'),
              ),
              TextButton(
                onPressed: state.resendCooldown > 0
                    ? null
                    : controller.resendCode,
                child: Text(state.resendCooldown > 0
                    ? 'Resend in ${state.resendCooldown}s'
                    : 'Resend Code'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OrganizationSelectionView extends ConsumerWidget {
  const OrganizationSelectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authScreenControllerProvider);
    final controller = ref.read(authScreenControllerProvider.notifier);
    final organizations = state.organizations ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Your Organization',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3 / 2,
              ),
              itemCount: organizations.length,
              itemBuilder: (context, index) {
                final org = organizations[index];
                return InkWell(
                  onTap: () =>
                      controller.submitCode(state.code!, orgId: org.id),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.business, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          org.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          org.role,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            TextButton(
              onPressed: controller.back,
              child: const Text('Back'),
            ),
        ],
      ),
    );
  }
}

class TokenInputView extends ConsumerWidget {
  TokenInputView({super.key});

  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authScreenControllerProvider);
    final controller = ref.read(authScreenControllerProvider.notifier);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Please check your email for a token and a code.'),
          TextFormField(
            controller: _tokenController,
            decoration: const InputDecoration(labelText: 'Token'),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Invalid token' : null,
          ),
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(labelText: 'Verification Code'),
            keyboardType: TextInputType.number,
            validator: (value) =>
                (value == null || value.length != 6) ? 'Invalid code' : null,
          ),
          if (state.flow == AuthFlow.passwordReset)
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
              validator: (value) => (value == null || value.length < 8)
                  ? 'Password too short'
                  : null,
            ),
          const SizedBox(height: 20),
          if (state.isLoading)
            const CircularProgressIndicator()
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                    onPressed: controller.back, child: const Text('Back'),),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      controller.submitTokenAndCode(
                        _tokenController.text,
                        _codeController.text,
                        newPassword: _passwordController.text,
                      );
                    }
                  },
                  child: const Text('Verify'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

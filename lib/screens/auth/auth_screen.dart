import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_screen_controller.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authScreenControllerProvider);
    final controller = ref.read(authScreenControllerProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Authentication'),
          bottom: TabBar(
            onTap: (index) {
              if (!state.isLoading) {
                controller.setFlow(AuthFlow.values[index]);
              }
            },
            tabs: const [
              Tab(text: 'Login'),
              Tab(text: 'Register'),
              Tab(text: 'Reset Password'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildChild(state, controller),
          ),
        ),
      ),
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

class CredentialsView extends ConsumerWidget {
  CredentialsView({super.key});

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
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
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) =>
                (value == null || !value.contains('@')) ? 'Invalid email' : null,
          ),
          if (state.flow != AuthFlow.passwordReset)
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) => (value == null || value.length < 8)
                  ? 'Password too short'
                  : null,
            ),
          const SizedBox(height: 20),
          if (state.isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  controller.submitCredentials(
                    _emailController.text,
                    _passwordController.text,
                  );
                }
              },
              child: Text(
                state.flow == AuthFlow.login
                    ? 'Login'
                    : state.flow == AuthFlow.register
                        ? 'Register'
                        : 'Send Reset Link',
              ),
            ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child:
                  Text(state.error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}

class CodeInputView extends ConsumerWidget {
  CodeInputView({super.key});

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authScreenControllerProvider);
    final controller = ref.read(authScreenControllerProvider.notifier);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Enter the 6-digit code sent to ${state.email}'),
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(labelText: 'Verification Code'),
            keyboardType: TextInputType.number,
            validator: (value) =>
                (value == null || value.length != 6) ? 'Invalid code' : null,
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
                      controller.submitCode(_codeController.text);
                    }
                  },
                  child: const Text('Verify'),
                ),
              ],
            ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child:
                  Text(state.error!, style: const TextStyle(color: Colors.red)),
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Select an Organization', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: organizations.length,
            itemBuilder: (context, index) {
              final org = organizations[index];
              return Card(
                child: ListTile(
                  title: Text(org.name),
                  subtitle: Text(org.role),
                  onTap: () {
                    controller.submitCode(
                      state.code!,
                      orgId: org.id,
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (state.isLoading) const CircularProgressIndicator(),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(state.error!, style: const TextStyle(color: Colors.red)),
          ),
      ],
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
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child:
                  Text(state.error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}
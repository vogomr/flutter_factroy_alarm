import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/alarm_icon_badge.dart';
import 'widgets/grid_painter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = true;
  bool _loginSuccess = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    if (_userCtrl.text.trim() == 'admin01' && _passCtrl.text == '123456') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', _rememberMe);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loginSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    setState(() {
      _loading = false;
      _loginSuccess = false;
      _error = 'Invalid username or password.';
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background gradient + grid texture
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEFF3F8), Color(0xFFF9FBFE)],
                ),
              ),
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
          ),
          // Login form centered
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Alarm icon badge
                          const AlarmIconBadge(size: 100, animated: true),
                          const SizedBox(height: 20),
                          Text(
                            'Alarm Controller',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Factory Systems Pro',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 36),
                          TextFormField(
                            controller: _userCtrl,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter username' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl,
                            focusNode: _passwordFocus,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox.adaptive(
                                value: _rememberMe,
                                onChanged: _loading ? null : (v) => setState(() => _rememberMe = v ?? true),
                              ),
                              const Text('Remember me'),
                            ],
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                  const SizedBox(width: 6),
                                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _loginSuccess ? Colors.green : Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      child: _loginSuccess
                                          ? const Row(
                                              key: ValueKey('ok'),
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.check_circle, size: 18),
                                                SizedBox(width: 8),
                                                Text('Success', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                              ],
                                            )
                                          : const Text('Login', key: ValueKey('login'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
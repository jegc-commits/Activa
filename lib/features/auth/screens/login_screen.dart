import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../data/mock/mock_data.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Login falso: según el usuario decide a qué panel entra.
  // Después esto lo reemplaza la validación real contra el backend.
  String? _routeFor(String id) {
    id = id.trim().toLowerCase();
    if (id == mockAlumno.numeroControl || id == mockAlumno.correo) {
      return '/student';
    }
    if (id == 'instructor2@utng.edu.mx') return '/instructor';
    if (id == mockAdmin.correo) return '/admin';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final route = _routeFor(_userCtrl.text);
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario o contraseña incorrectos')),
      );
      return;
    }
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Inicia sesión',
      subtitle: 'Bienvenido de vuelta a ACTIVA',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Número de control o correo institucional',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _userCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person),
                hintText: '1225100380',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            const Text('Contraseña',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Campo requerido' : null,
            ),
            Row(
              children: [
                Checkbox(
                  value: _remember,
                  onChanged: (v) => setState(() => _remember = v ?? false),
                ),
                const Text('Recordarme'),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/forgot'),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _submit, child: const Text('Iniciar sesión')),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
              onPressed: () => context.go('/student'),
              child: const Text('Explorar sin cuenta'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Instructores y coordinación también entran aquí con su correo institucional.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('¿No tienes cuenta? Crear cuenta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
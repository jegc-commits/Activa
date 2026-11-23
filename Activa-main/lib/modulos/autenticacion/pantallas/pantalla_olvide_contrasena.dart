import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../datos/sesion.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../../nucleo/utilidades/reglas_contrasena.dart';
import '../../../nucleo/componentes/estructura_autenticacion.dart';
import '../../../nucleo/componentes/avisos.dart';

class PantallaOlvideContrasena extends StatefulWidget {
  const PantallaOlvideContrasena({super.key});
  @override
  State<PantallaOlvideContrasena> createState() =>
      _EstadoPantallaOlvideContrasena();
}

class _EstadoPantallaOlvideContrasena extends State<PantallaOlvideContrasena> {
  final _form0 = GlobalKey<FormState>();
  final _form2 = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _code = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  int _step = 0;
  bool _obscure = true;
  String? _emailError;
  String? _codeError;
  String _correoMostrar = '';
  int _seconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    context.read<EstadoSesion>().cancelarRecuperacion();
    for (final c in [_user, _code, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) {
        t.cancel();
      }
      setState(() => _seconds--);
    });
  }

  String get _countdown => '00:${_seconds.toString().padLeft(2, '0')}';

  // muestra el código mientras no haya un correo real que lo mande
  void _mostrarCodigoDePrueba(String codigo) {
    ScaffoldMessenger.of(context).showSnackBar(
      avisoSnack(
        content: Text('Modo de prueba: tu código es $codigo'),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  bool _enviando = false;

  Future<void> _sendCode() async {
    if (!_form0.currentState!.validate()) return;
    setState(() => _enviando = true);
    final r = await context.read<EstadoSesion>().solicitarCodigoRecuperacion(
      _user.text,
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (!r.ok) {
      setState(() => _emailError = r.error);
      return;
    }
    setState(() {
      _emailError = null;
      _correoMostrar = r.correoEnmascarado!;
    });
    _code.clear();
    _startTimer();
    // Si el correo real todavía no está configurado, r.codigo trae el
    // código para mostrarlo aquí como respaldo temporal.
    if (r.codigo != null) {
      _mostrarCodigoDePrueba(r.codigo!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        avisoSnack(content: const Text('Te enviamos el código a tu correo')),
      );
    }
    setState(() => _step = 1);
  }

  void _verify() {
    if (_code.text.length != 6) {
      setState(() => _codeError = 'Escribe los 6 dígitos');
      return;
    }
    final ok = context.read<EstadoSesion>().verificarCodigoRecuperacion(
      _code.text,
    );
    if (!ok) {
      setState(() => _codeError = 'Código incorrecto o vencido');
      return;
    }
    setState(() {
      _codeError = null;
      _step = 2;
    });
  }

  Future<void> _save() async {
    if (!_form2.currentState!.validate()) return;
    final error = await context.read<EstadoSesion>().guardarContrasenaRecuperada(
      _pass.text,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(avisoSnack(content: Text(error)));
      return;
    }
    context.go('/contrasena-actualizada');
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.canPop() ? context.pop() : context.go('/inicio-sesion');
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = [
      '¿Olvidaste tu contraseña?',
      'Verifica tu código',
      'Nueva contraseña',
    ];
    const subs = ['Paso 1 de 3 · Tu correo', 'Paso 2 de 3', 'Paso 3 de 3'];
    return EstructuraAutenticacion(
      title: titles[_step],
      subtitle: subs[_step],
      onBack: _back,
      child: switch (_step) {
        0 => _stepEmail(),
        1 => _stepCode(),
        _ => _stepPassword(),
      },
    );
  }

  Widget _badge(IconData icon) => Center(
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: ColoresApp.background,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFFC7D9FB),
        child: Icon(icon, color: ColoresApp.primary, size: 28),
      ),
    ),
  );

  Widget _stepEmail() => Form(
    key: _form0,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _badge(Icons.lock),
        const SizedBox(height: 16),
        const Text(
          'Escribe tu matrícula o tu correo y te enviaremos un código de verificación de 6 dígitos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 20),
        const Text(
          'Matrícula o correo electrónico',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _user,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email),
            errorText: _emailError,
          ),
          onChanged: (_) => setState(() => _emailError = null),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _enviando ? null : _sendCode,
          child: _enviando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Enviar código'),
        ),
        Center(
          child: TextButton.icon(
            onPressed: () => context.go('/inicio-sesion'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Volver a iniciar sesión'),
          ),
        ),
      ],
    ),
  );

  Widget _stepCode() => Column(
    children: [
      _badge(Icons.email),
      const SizedBox(height: 16),
      Text(
        'Enviamos un código a $_correoMostrar. Escríbelo para continuar.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54, fontSize: 13),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _code,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 14,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: '------',
          errorText: _codeError,
        ),
        onChanged: (_) => setState(() => _codeError = null),
      ),
      const SizedBox(height: 8),
      _seconds > 0
          ? Text(
              '¿No lo recibiste? Reenviar en $_countdown',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            )
          : TextButton(
              onPressed: () async {
                final sesion = context.read<EstadoSesion>();
                _startTimer();
                final nuevo = await sesion.reenviarCodigoRecuperacion();
                if (!mounted) return;
                if (nuevo != null) {
                  _mostrarCodigoDePrueba(nuevo);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    avisoSnack(
                      content: const Text('Te enviamos un código nuevo'),
                    ),
                  );
                }
              },
              child: const Text('Reenviar código'),
            ),
      const SizedBox(height: 12),
      FilledButton(onPressed: _verify, child: const Text('Verificar código')),
      TextButton(
        onPressed: () {
          _timer?.cancel();
          context.read<EstadoSesion>().cancelarRecuperacion();
          setState(() => _step = 0);
        },
        child: const Text('Cambiar correo'),
      ),
    ],
  );

  Widget _stepPassword() {
    final rules = ReglasContrasena(_pass.text);
    return Form(
      key: _form2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Crea una contraseña nueva que no hayas usado antes.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nueva contraseña',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pass,
            obscureText: _obscure,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => ReglasContrasena(v ?? '').valid
                ? null
                : 'No cumple los requisitos',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i < rules.score
                          ? ColoresApp.teal
                          : ColoresApp.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
          if (_pass.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                rules.label,
                style: const TextStyle(color: ColoresApp.teal, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Confirmar contraseña',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pass2,
            obscureText: _obscure,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (v) =>
                v == _pass.text ? null : 'Las contraseñas no coinciden',
          ),
          const SizedBox(height: 16),
          _Requisito('Mínimo 8 caracteres', rules.minLength),
          _Requisito('Una letra mayúscula y un número', rules.upperAndDigit),
          _Requisito('Un carácter especial (@, #, \$, !)', rules.special),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Guardar contraseña'),
          ),
        ],
      ),
    );
  }
}

class _Requisito extends StatelessWidget {
  const _Requisito(this.text, this.ok);
  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(
          Icons.check_circle,
          size: 18,
          color: ok ? ColoresApp.teal : Colors.black26,
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );
}
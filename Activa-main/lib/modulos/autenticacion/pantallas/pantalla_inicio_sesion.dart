// ===================================================================
// pantalla_inicio_sesion.dart
// Inicio de sesión para alumnos, instructores y administrador. Se puede
// escribir el usuario, el correo o el número de control, y la contraseña
// se valida contra la tabla `usuarios` de SQLite.
// ===================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../datos/estado_app.dart';
import '../../../datos/servicio_autenticacion_google.dart';
import '../../../datos/sesion.dart';
import '../../../modelos/enums.dart';
import '../../../nucleo/componentes/estructura_autenticacion.dart';
import '../../../nucleo/componentes/boton_activa.dart';
import '../../../nucleo/componentes/avisos.dart';

class PantallaInicioSesion extends StatefulWidget {
  const PantallaInicioSesion({super.key});
  @override
  State<PantallaInicioSesion> createState() => _EstadoPantallaInicioSesion();
}

class _EstadoPantallaInicioSesion extends State<PantallaInicioSesion> {
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

  // revisa los datos y manda a cada rol a su panel
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final sesion = context.read<EstadoSesion>();
    final app = context.read<EstadoApp>();
    final mensajes = ScaffoldMessenger.of(context);

    // cuentas guardadas: alumnos, instructores y administrador
    final r = sesion.iniciarSesionGuardada(_userCtrl.text, _passCtrl.text);
    switch (r.estado) {
      case EstadoAcceso.ok:
        app.usarCuenta(r.cuenta);
        context.go(EstadoSesion.rutaDe(r.cuenta!.rol));
        return;
      case EstadoAcceso.cambiarContrasena:
        // contraseña temporal: primero tiene que crear la suya
        context.go('/cambiar-contrasena');
        return;
      case EstadoAcceso.desactivado:
        mensajes.showSnackBar(
          avisoSnack(
            content: const Text(
              'Error: tu cuenta está desactivada. Habla con la coordinación',
            ),
          ),
        );
        return;
      case EstadoAcceso.incorrecto:
      case EstadoAcceso.noEncontrado:
        mensajes.showSnackBar(
          avisoSnack(content: const Text('Usuario o contraseña incorrectos')),
        );
        return;
    }
  }

  Future<void> _entrarConGoogle() async {
    final sesion = context.read<EstadoSesion>();
    final app = context.read<EstadoApp>();
    final mensajes = ScaffoldMessenger.of(context);

    final r = await ServicioAutenticacionGoogle.instancia.iniciarSesion();
    if (!mounted) return;
    if (!r.ok) {
      if (r.error != null) {
        mensajes.showSnackBar(avisoSnack(content: Text(r.error!)));
      }
      return; // canceló o falló sin mensaje (ej. el usuario cerró la ventana)
    }

    final acceso = sesion.iniciarSesionConCorreoGoogle(r.correo!);
    switch (acceso.estado) {
      case EstadoAcceso.ok:
        app.usarCuenta(acceso.cuenta);
        context.go(EstadoSesion.rutaDe(acceso.cuenta!.rol));
      case EstadoAcceso.cambiarContrasena:
        context.go('/cambiar-contrasena');
      case EstadoAcceso.desactivado:
        mensajes.showSnackBar(
          avisoSnack(
            content: const Text(
              'Error: tu cuenta está desactivada. Habla con la coordinación',
            ),
          ),
        );
      case EstadoAcceso.incorrecto:
      case EstadoAcceso.noEncontrado:
        mensajes.showSnackBar(
          avisoSnack(
            content: Text(
              'No hay ninguna cuenta de ACTIVA con ${r.correo}. '
              'Crea tu cuenta primero con tu correo institucional',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return EstructuraAutenticacion(
      title: 'Inicia sesión',
      subtitle: 'Bienvenido de vuelta a ACTIVA',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usuario, matrícula o correo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _userCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline_rounded),
                hintText: 'usuario, correo o matrícula',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Contraseña',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
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
                  onPressed: () => context.push('/olvide-contrasena'),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BotonActiva(etiqueta: 'Iniciar sesión', alPresionar: _submit),
            if (ServicioAutenticacionGoogle.instancia.disponible) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('o', style: TextStyle(color: Colors.grey[500])),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              BotonActiva(
                etiqueta: 'Continuar con Google',
                variante: VarianteBoton.contorno,
                icono: Icons.account_circle_rounded,
                alPresionar: _entrarConGoogle,
              ),
            ],
            const SizedBox(height: 12),
            BotonActiva(
              etiqueta: 'Explorar sin cuenta',
              variante: VarianteBoton.contorno,
              alPresionar: () {
                context.read<EstadoApp>().usarCuenta(null);
                context.read<EstadoSesion>().rol = Rol.alumno;
                context.go('/alumno');
              },
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () => context.push('/registro'),
                child: const Text('¿No tienes cuenta? Crear cuenta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
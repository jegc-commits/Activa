// ===================================================================
// Colores del logo y tema general de toda la app
// ===================================================================


import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
// Aquí van todos los colores de la app, sacados del logo
class AppColors {
  // ---------- Colores del logo ----------
  // azul muy oscuro
  static const deep = Color(0xFF05245A);
  // azul marino
  static const navy = Color(0xFF0A3175);
  // azul océano
  static const ocean = Color(0xFF0A5FBF);
  // azul principal (botones, íconos activos)
  static const primary = Color(0xFF1B78E2);
  // Azul de la ola
  static const wave = Color(0xFF259CFB);
  // celeste clarito
  static const sky = Color(0xFF75D2FE);
  // azul casi blanco (fondos suaves)
  static const mist = Color(0xFFEAF4FF);

  // ---------- Neutros y de estado ----------
  // fondo de las pantallas
  static const background = Color(0xFFF2F7FE);
  // Color del texto normal
  static const ink = Color(0xFF0B1B3A);
  // Texto secundario (gris azulado)
  static const muted = Color(0xFF5B6B88);
  // color de los bordes finitos
  static const line = Color(0xFFE0EAF8);
  // verde azulado (lugares disponibles)
  static const teal = Color(0xFF14B8A6);
  // Rojo (errores, cupo lleno)
  static const danger = Color(0xFFE5484D);
  // naranja (avisos)
  static const warning = Color(0xFFF5A623);

  // degradado azul del encabezado (de esquina a esquina)
  static const heroGradient = LinearGradient(
    // Empieza arriba a la izquierda
    begin: Alignment.topLeft,
    // Termina abajo a la derecha
    end: Alignment.bottomRight,
    // Los tres azules en orden
    colors: [deep, navy, ocean],
  );

  // sombra suave que usan las tarjetas
  static final softShadow = [
    BoxShadow(
      // Azul marino bien transparente
      color: navy.withValues(alpha: 0.08),
      // Qué tan difuminada se ve
      blurRadius: 24,
      // La baja 10 pixeles
      offset: const Offset(0, 10),
    ),
  ];
}

// tema general: define cómo se ven botones, inputs, barra, etc.
class AppTheme {
  // Getter que regresa el tema claro
  static ThemeData get light {
    // Esquema de colores a partir del azul principal
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.wave,
      surface: Colors.white,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    );

    // Letra Poppins con el color de texto de la app
    final textTheme = GoogleFonts.poppinsTextTheme()
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

    // Función para crear bordes redondos de los campos de texto
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );

    // Transición tipo iPhone: la pantalla nueva se desliza suave
    const slide = CupertinoPageTransitionsBuilder();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Fondo de todas las pantallas
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      // Efecto de ondita al tocar
      splashFactory: InkRipple.splashFactory,

      // Misma transición en todas las plataformas
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: slide,
        TargetPlatform.iOS: slide,
        TargetPlatform.windows: slide,
        TargetPlatform.macOS: slide,
        TargetPlatform.linux: slide,
        TargetPlatform.fuchsia: slide,
      }),

      // Barra de arriba de las pantallas
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.navy),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),

      // Botones llenos (FilledButton)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Alto de 54 y ancho completo
          minimumSize: const Size.fromHeight(54),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          // Duración de la transición de color al presionar
          animationDuration: const Duration(milliseconds: 250),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      // Botones con solo borde (OutlinedButton)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: AppColors.primary,
          side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.5), width: 1.4),
          animationDuration: const Duration(milliseconds: 250),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      // Botones de solo texto (TextButton)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle:
              GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),

      // Campos de texto
      inputDecorationTheme: InputDecorationTheme(
        // Fondo blanco
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: Color(0xFF9AA8C0), fontSize: 14),
        // El ícono de la izquierda se pone azul cuando escribes
        prefixIconColor: WidgetStateColor.resolveWith((s) =>
            s.contains(WidgetState.focused)
                ? AppColors.primary
                : AppColors.muted),
        suffixIconColor: AppColors.muted,
        // Bordes en cada estado
        border: border(AppColors.line),
        enabledBorder: border(AppColors.line),
        focusedBorder: border(AppColors.primary, 1.8),
        errorBorder: border(AppColors.danger),
        focusedErrorBorder: border(AppColors.danger, 1.8),
      ),

      // Barra de navegación de abajo
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: AppColors.navy.withValues(alpha: 0.18),
        height: 70,
        // Óvalo clarito detrás del ícono elegido
        indicatorColor: AppColors.mist,
        // Solo muestra el nombre de la pestaña elegida
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        // Ícono azul si está elegido, gris si no
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 26,
              color: s.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.muted,
            )),
        // Letra de cada pestaña
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final sel = s.contains(WidgetState.selected);
          return GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
            color: sel ? AppColors.primary : AppColors.muted,
          );
        }),
      ),

      // Mensajes que salen abajo (SnackBar)
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle:
            GoogleFonts.poppins(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // Chips (etiquetas)
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.mist,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
      ),

      // Barras y círculos de progreso
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.mist,
        circularTrackColor: AppColors.mist,
      ),

      // Casillas de verificación
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : null),
      ),

      // Líneas divisorias
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),

      // Ventanas que suben desde abajo
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // Ventanas de diálogo
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
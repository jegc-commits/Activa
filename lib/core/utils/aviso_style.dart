import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../theme/app_theme.dart';

(Color, IconData) avisoStyle(TipoAviso t) => switch (t) {
      TipoAviso.cambioHorario => (AppColors.warning, Icons.access_time),
      TipoAviso.informativo => (AppColors.primary, Icons.person),
      TipoAviso.recordatorio => (AppColors.teal, Icons.star),
      TipoAviso.cancelacion => (AppColors.danger, Icons.cancel),
    };
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../datos/sesion.dart';

const idiomas = {'es': 'Español', 'en': 'English', 'fr': 'Français'};

extension TextosX on BuildContext {
  /// Traduce una clave según el idioma elegido en Configuración.
  String tr(String clave, {String n = ''}) {
    final idioma = Provider.of<EstadoSesion>(this).idioma;
    final fila = _textos[clave];
    if (fila == null) return clave;
    return fila[const ['es', 'en', 'fr'].indexOf(idioma)].replaceAll('{n}', n);
  }
}

// [español, inglés, francés]. Para traducir más pantallas agrega claves aquí.
const _textos = <String, List<String>>{
  'nav.inicio': ['Inicio', 'Home', 'Accueil'],
  'nav.explorar': ['Explorar', 'Explore', 'Explorer'],
  'nav.actividades': ['Mis actividades', 'My activities', 'Mes activités'],
  'nav.talleres': ['Mis talleres', 'My workshops', 'Mes ateliers'],
  'nav.avisos': ['Avisos', 'Notices', 'Avis'],
  'nav.perfil': ['Perfil', 'Profile', 'Profil'],
  'inicio.hola': ['¡Hola, {n}!', 'Hi, {n}!', 'Salut, {n} !'],
  'inicio.lema': [
    'Vive tu escuela.',
    'Live your school.',
    'Vis ton école.',
  ],
  'inicio.progreso': [
    'Tu progreso paraescolar',
    'Your extracurricular progress',
    'Ta progression parascolaire',
  ],
  'inicio.sugerida': ['Actividad sugerida', 'Suggested activity', 'Activité suggérée'],
  'inicio.avisos': ['Avisos recientes', 'Recent notices', 'Avis récents'],
  'perfil.horas': ['Sesiones', 'Sessions', 'Séances'],
  'perfil.actividades': ['Actividades', 'Activities', 'Activités'],
  'perfil.favoritos': ['Favoritos', 'Favorites', 'Favoris'],
  'perfil.misFavoritos': ['Mis favoritos', 'My favorites', 'Mes favoris'],
  'perfil.comprobantes': ['Mis comprobantes', 'My receipts', 'Mes justificatifs'],
  'perfil.progreso': ['Mi progreso', 'My progress', 'Ma progression'],
  'perfil.chats': ['Chats grupales', 'Group chats', 'Discussions de groupe'],
  'perfil.encuestas': ['Encuestas de mis clubes', 'Club surveys', 'Sondages des clubs'],
  'perfil.academicos': ['Mis datos académicos', 'My academic info', 'Mes données académiques'],
  'perfil.editar': ['Editar perfil', 'Edit profile', 'Modifier le profil'],
  'perfil.config': ['Configuración', 'Settings', 'Paramètres'],
  'perfil.cerrar': ['Cerrar sesión', 'Sign out', 'Se déconnecter'],
  'perfil.comunidad': ['Comunidad', 'Community', 'Communauté'],
  'perfil.cuenta': ['Cuenta', 'Account', 'Compte'],
  'config.notif': ['Notificaciones', 'Notifications', 'Notifications'],
  'config.avisos': ['Avisos de actividades', 'Activity notices', "Avis d'activités"],
  'config.horario': ['Cambios de horario', 'Schedule changes', "Changements d'horaire"],
  'config.recordatorios': ['Recordatorios de clase', 'Class reminders', 'Rappels de cours'],
  'config.cupos': ['Cupos disponibles', 'Available spots', 'Places disponibles'],
  'config.sonidos': ['Sonidos de la app', 'App sounds', "Sons de l'application"],
  'config.pass': ['Cambiar contraseña', 'Change password', 'Changer le mot de passe'],
  'config.idioma': ['Idioma', 'Language', 'Langue'],
  'config.privAyuda': ['Privacidad y ayuda', 'Privacy and help', 'Confidentialité et aide'],
  'config.privacidad': ['Aviso de privacidad', 'Privacy notice', 'Avis de confidentialité'],
  'config.ayuda': ['Ayuda y soporte', 'Help and support', 'Aide et assistance'],
  'config.acerca': ['Acerca de la aplicación', 'About the app', "À propos de l'application"],

  // ---- Explorar ----
  'explorar.titulo': ['Talleres', 'Workshops', 'Ateliers'],
  'explorar.subtitulo': [
    'Encuentra tu pasión, forma parte y vive la experiencia.',
    'Find your passion, join in and live the experience.',
    'Trouve ta passion, participe et vis l\'expérience.',
  ],
  'explorar.buscar': ['¿Qué taller buscas?', 'What workshop are you looking for?', 'Quel atelier cherches-tu ?'],
  'explorar.todas': ['Todas', 'All', 'Tous'],
  'explorar.sinResultados': ['No encontramos talleres', 'No workshops found', 'Aucun atelier trouvé'],

  // ---- Mis talleres ----
  'mistalleres.titulo': ['Mis talleres', 'My workshops', 'Mes ateliers'],
  'mistalleres.activos': ['Activos', 'Active', 'Actifs'],
  'mistalleres.historial': ['Historial', 'History', 'Historique'],
  'mistalleres.vacio': [
    'Aún no estás inscrito en ningún taller',
    'You are not enrolled in any workshop yet',
    "Tu n'es inscrit à aucun atelier pour l'instant",
  ],

  // ---- Detalle de taller ----
  'detalle.inscribirme': ['Inscribirme', 'Enroll', "M'inscrire"],
  'detalle.darmeBaja': ['Darme de baja', 'Unenroll', 'Me désinscrire'],
  'detalle.horario': ['Horario', 'Schedule', 'Horaire'],
  'detalle.lugar': ['Lugar', 'Place', 'Lieu'],
  'detalle.cupo': ['Cupo', 'Spots', 'Places'],
  'detalle.instructor': ['Instructor', 'Instructor', 'Instructeur'],
  'detalle.descripcion': ['Descripción', 'Description', 'Description'],
  'detalle.queAprenderas': ['¿Qué aprenderás?', 'What will you learn?', 'Que vas-tu apprendre ?'],

  // ---- Encuestas ----
  'encuestas.titulo': ['Encuestas de mis clubes', 'Club surveys', 'Sondages des clubs'],
  'encuestas.vacio': [
    'No tienes encuestas pendientes',
    'You have no pending surveys',
    "Tu n'as aucun sondage en attente",
  ],
  'encuestas.enviar': ['Enviar respuesta', 'Submit answer', 'Envoyer la réponse'],

  // ---- Editar perfil ----
  'editarperfil.titulo': ['Editar perfil', 'Edit profile', 'Modifier le profil'],
  'editarperfil.nombre': ['Nombre', 'Name', 'Nom'],
  'editarperfil.correo': ['Correo', 'Email', 'E-mail'],
  'editarperfil.telefono': ['Teléfono', 'Phone', 'Téléphone'],
  'editarperfil.guardar': ['Guardar cambios', 'Save changes', 'Enregistrer les modifications'],
};
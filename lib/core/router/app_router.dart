import 'package:go_router/go_router.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/password_updated_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/student/screens/activity_detail_screen.dart';
import '../../features/student/screens/enrollment_success_screen.dart';
import '../../features/student/screens/explore_screen.dart';
import '../../features/student/screens/home_screen.dart';
import '../../features/student/screens/my_activities_screen.dart';
import '../../features/student/screens/notices_screen.dart';
import '../../features/student/screens/profile_screens.dart';
import '../../features/student/screens/student_shell.dart';
import '../widgets/placeholder_screen.dart';
import '../../features/instructor/screens/attendance_screens.dart';
import '../../features/instructor/screens/groups_screens.dart';
import '../../features/instructor/screens/instructor_home_screen.dart';
import '../../features/instructor/screens/instructor_profile_screen.dart';
import '../../features/instructor/screens/instructor_shell.dart';
import '../../features/instructor/screens/notices_screens.dart';
import '../../features/admin/screens/admin_activities_screens.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_people_screens.dart';
import '../../features/admin/screens/admin_reports_profile.dart';
import '../../features/admin/screens/admin_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: '/password-updated', builder: (_, __) => const PasswordUpdatedScreen()),

    // Alumno: 5 pestañas
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => StudentShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/student', builder: (_, __) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/student/explore',
            builder: (_, s) => ExploreScreen(initialCat: s.uri.queryParameters['cat']),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/student/activities', builder: (_, __) => const MyActivitiesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/student/notices', builder: (_, __) => const NoticesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/student/profile', builder: (_, __) => const ProfileScreen()),
        ]),
      ],
    ),

    // Pantalla completa (sin barra inferior)
    GoRoute(
      path: '/activity/:id',
      builder: (_, s) =>
          ActivityDetailScreen(tallerId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/enrollment/:folio',
      builder: (_, s) =>
          EnrollmentSuccessScreen(folio: s.pathParameters['folio']!),
    ),
    GoRoute(path: '/profile/academic', builder: (_, __) => const AcademicScreen()),
    GoRoute(path: '/profile/receipts', builder: (_, __) => const ReceiptsScreen()),
    GoRoute(path: '/profile/progress', builder: (_, __) => const ProgressScreen()),
    GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
    GoRoute(path: '/profile/settings', builder: (_, __) => const SettingsScreen()),    // Instructor: 5 pestañas
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => InstructorShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/instructor', builder: (_, __) => const InstructorHomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/instructor/groups', builder: (_, __) => const GroupsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/instructor/attendance', builder: (_, __) => const AttendanceTabScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/instructor/notices', builder: (_, __) => const InstructorNoticesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/instructor/profile', builder: (_, __) => const InstructorProfileScreen()),
        ]),
      ],
    ),
    GoRoute(
      path: '/instructor/group/:id',
      builder: (_, s) =>
          GroupStudentsScreen(tallerId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/instructor/take/:id',
      builder: (_, s) => TakeAttendanceScreen(
        tallerId: int.parse(s.pathParameters['id']!),
        fecha: DateTime.parse(s.uri.queryParameters['fecha']!),
      ),
    ),
    GoRoute(path: '/instructor/new-notice', builder: (_, __) => const NewNoticeScreen()),
       // Administrador: 5 pestañas
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => AdminShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/admin', builder: (_, __) => const AdminHomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/admin/activities', builder: (_, __) => const AdminActivitiesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/admin/students', builder: (_, __) => const AdminStudentsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/admin/reports', builder: (_, __) => const ReportsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/admin/profile', builder: (_, __) => const AdminProfileScreen()),
        ]),
      ],
    ),
    GoRoute(path: '/admin/activity/new', builder: (_, __) => const ActivityFormScreen()),
    GoRoute(
      path: '/admin/activity/:id/edit',
      builder: (_, s) =>
          ActivityFormScreen(tallerId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(path: '/admin/instructors', builder: (_, __) => const InstructorsScreen()),
    GoRoute(path: '/admin/instructors/new', builder: (_, __) => const NewInstructorScreen()),
  ],
);
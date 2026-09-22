// ============================================================================
// VeriShift / Smart Attendance  -  single-file Flutter app (lib/main.dart)
//
// Screens (all interactive, demo data until the backend API is connected):
//   1. Sign in                      (name + password)
//   2. Sign up
//   3. Express check-in             (Student ID + Match badge, live clock)
//   4. Student Home                 (session card, metrics, campus services)
//   5. Room Attendance QR Scanner   (simulate scan / confirm / 6-digit code)
//   6. Correction Request Submitted (Logs tab)
//   + Telemetry and Profile tabs (placeholders until their designs arrive)
//
// No external packages: only Flutter's own material / services libraries.
// ============================================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// APP ENTRY
// ============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const SmartAttendanceApp());
}

class AppRoutes {
  AppRoutes._();

  static const String signIn = '/';
  static const String signUp = '/sign-up';
  static const String express = '/express-check-in';
}

class SmartAttendanceApp extends StatelessWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VeriShift',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
        scaffoldBackgroundColor: AppColors.pageBg,
      ),
      // Keeps the app phone-sized when it is opened on the web / a wide screen.
      builder: (BuildContext context, Widget? child) {
        return ColoredBox(
          color: const Color(0xFFE9EEF7),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      initialRoute: AppRoutes.signIn,
      routes: <String, WidgetBuilder>{
        AppRoutes.signIn: (BuildContext context) => const SignInScreen(),
        AppRoutes.signUp: (BuildContext context) => const SignUpScreen(),
        AppRoutes.express: (BuildContext context) =>
        const ExpressCheckInScreen(),
      },
    );
  }
}

// ============================================================================
// COLORS, TEXT STYLES, HELPERS
// ============================================================================

class AppColors {
  AppColors._();

  // Auth screens
  static const Color sky = Color(0xFF7DD3FC);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color ink = Color(0xFF0F172A);
  static const Color slate = Color(0xFF475569);
  static const Color hint = Color(0xFF94A3B8);
  static const Color whiteLine = Color(0x99FFFFFF);

  // App screens
  static const Color pageBg = Color(0xFFF7F9FF);
  static const Color navy = Color(0xFF0B2A6F);
  static const Color brandBlue = Color(0xFF0050D8);
  static const Color deepBlue = Color(0xFF1B3A8C);
  static const Color chipBg = Color(0xFFE4ECFD);
  static const Color chipBorder = Color(0xFFD3E0FB);
  static const Color tileBg = Color(0xFFEEF2FF);
  static const Color panel = Color(0xFFF2F5FC);
  static const Color avatarBg = Color(0xFFDCE3FA);
  static const Color border = Color(0xFFDDE3EE);
  static const Color cardBorder = Color(0xFFE3E9F5);
  static const Color divider = Color(0xFFE8EDF5);
  static const Color mutedText = Color(0xFF5B6478);
  static const Color statusBarBg = Color(0xFFEEF3FD);

  // Status colors
  static const Color green = Color(0xFF12A150);
  static const Color greenDark = Color(0xFF0B6B3A);
  static const Color greenBg = Color(0xFFD6F5E3);
  static const Color red = Color(0xFFD92D20);
  static const Color redBg = Color(0xFFFDEEEE);
  static const Color redBorder = Color(0xFFF5D0D0);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFF8A5A00);
  static const Color amberBg = Color(0xFFFFF7E0);
  static const Color amberBorder = Color(0xFFF3E2A6);
}

TextStyle mono({
  double size = 12,
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.navy,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: const <String>['Menlo', 'Courier'],
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

TextStyle sans({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.navy,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

String two(int v) => v.toString().padLeft(2, '0');

String formatCountdown(int totalSeconds) {
  final int m = totalSeconds ~/ 60;
  final int s = totalSeconds % 60;
  return '${two(m)}m ${two(s)}s';
}

void showInfo(BuildContext context, String message) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

// ============================================================================
// DEMO DATA + SESSION STATE  (replace with the backend API later)
// ============================================================================

class Student {
  const Student({
    required this.name,
    required this.id,
    required this.program,
  });

  final String name;
  final String id;
  final String program;

  String get initials {
    final List<String> parts = name.trim().split(' ');
    final String first = parts.first.isNotEmpty ? parts.first[0] : '';
    final String last =
    parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

const Student kDemoStudent = Student(
  name: 'Salma Mahmoud',
  id: 'STU-2024-8842',
  program: 'B.Sc. AI & Software Systems',
);

/// Demo "registry" used by the Express check-in Match badge.
bool isRegisteredStudentId(String raw) {
  final String id = raw.trim().toUpperCase();
  return id == '2023000000' || id == 'STU-2024-8842';
}

class AppSession extends ChangeNotifier {
  AppSession._();

  static final AppSession instance = AppSession._();

  static const int _initialWindowSeconds = 7 * 60 + 48;

  Student student = kDemoStudent;
  bool checkedIn = false;
  int attended = 38;
  int windowSecondsLeft = _initialWindowSeconds;
  Timer? _timer;

  bool get windowOpen => windowSecondsLeft > 0;

  /// Demo formula: 94.2% baseline + 0.3 for every extra attended lecture.
  double get attendanceRate {
    final double value = 94.2 + (attended - 38) * 0.3;
    if (value > 100) {
      return 100;
    }
    return value;
  }

  void startSession(Student s) {
    student = s;
    checkedIn = false;
    attended = 38;
    windowSecondsLeft = _initialWindowSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!checkedIn && windowSecondsLeft > 0) {
        windowSecondsLeft--;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void endSession() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  bool confirmAttendance() {
    if (checkedIn || !windowOpen) {
      return false;
    }
    checkedIn = true;
    attended++;
    notifyListeners();
    return true;
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================

/// Uppercase label + white text field (Sign in and Sign up).
class LabeledField extends StatefulWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.labelStyle,
    required this.textStyle,
    this.radius = 8,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextStyle labelStyle;
  final TextStyle textStyle;
  final double radius;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(widget.radius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(widget.label, style: widget.labelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          style: widget.textStyle,
          cursorColor: AppColors.primaryBlue,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: widget.textStyle.copyWith(color: AppColors.hint),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.slate,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            )
                : null,
          ),
        ),
      ],
    );
  }
}

/// The 4-square Microsoft logo drawn with plain containers (no assets).
class MicrosoftLogo extends StatelessWidget {
  const MicrosoftLogo({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    final double cell = (size - 2) / 2;

    Widget square(Color color) =>
        Container(width: cell, height: cell, color: color);

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              square(const Color(0xFFF25022)),
              square(const Color(0xFF7FBA00)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              square(const Color(0xFF00A4EF)),
              square(const Color(0xFFFFB900)),
            ],
          ),
        ],
      ),
    );
  }
}

class MicrosoftButton extends StatelessWidget {
  const MicrosoftButton({
    super.key,
    required this.onPressed,
    required this.textStyle,
    this.radius = 8,
    this.borderColor = Colors.transparent,
    this.height = 46,
  });

  final VoidCallback onPressed;
  final TextStyle textStyle;
  final double radius;
  final Color borderColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: textStyle.color,
          side: BorderSide(color: borderColor),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const MicrosoftLogo(size: 16),
            const SizedBox(width: 10),
            Text('Continue with Microsoft', style: textStyle),
          ],
        ),
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({
    super.key,
    required this.lineColor,
    required this.textStyle,
  });

  final Color lineColor;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Container(height: 1, color: lineColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: textStyle),
        ),
        Expanded(child: Container(height: 1, color: lineColor)),
      ],
    );
  }
}

class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key, required this.style});

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text(
      '\u00A9 2026 Meridian Technologies, Inc. \u00B7 Privacy \u00B7 Terms',
      textAlign: TextAlign.center,
      style: style,
    );
  }
}

/// White rounded card, optional 4px colored bar on top.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 16,
    this.topBarColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? topBarColor;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(padding: padding, child: child);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0B2A6F),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: topBarColor == null
          ? content
          : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(height: 4, color: topBarColor),
          content,
        ],
      ),
    );
  }
}

/// Small rounded mono label (status chips).
class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    this.showDot = false,
    this.icon,
    this.size = 10,
  });

  final String text;
  final Color background;
  final Color foreground;
  final bool showDot;
  final IconData? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showDot) ...<Widget>[
            Container(
              width: 6,
              height: 6,
              decoration:
              BoxDecoration(color: foreground, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...<Widget>[
            Icon(icon, size: size + 3, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: mono(size: size, weight: FontWeight.w700, color: foreground),
          ),
        ],
      ),
    );
  }
}

class CampusMeshPill extends StatelessWidget {
  const CampusMeshPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Campus Mesh',
            style: mono(size: 10.5, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(Icons.timer_outlined, 'Check In'),
    _NavItem(Icons.history_toggle_off, 'Logs'),
    _NavItem(Icons.my_location, 'Telemetry'),
    _NavItem(Icons.badge_outlined, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x0F0B2A6F),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 58,
                          height: 30,
                          decoration: BoxDecoration(
                            color: i == currentIndex
                                ? const Color(0xFFE3EBFD)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            _items[i].icon,
                            size: 20,
                            color: i == currentIndex
                                ? AppColors.brandBlue
                                : AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[i].label,
                          style: mono(
                            size: 10,
                            weight: FontWeight.w700,
                            color: i == currentIndex
                                ? AppColors.brandBlue
                                : AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SCREEN 1: SIGN IN
// ============================================================================

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  void _signIn() {
    FocusScope.of(context).unfocus();
    if (_name.text.trim().isEmpty || _password.text.isEmpty) {
      showInfo(context, 'Please enter your name and password');
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.express);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = TextStyle(fontSize: 14, color: AppColors.ink);
    final TextStyle labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.1,
      color: AppColors.slate,
    );
    final TextStyle smallStyle =
    TextStyle(fontSize: 13, color: AppColors.slate);

    return Scaffold(
      backgroundColor: AppColors.sky,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.whiteLine),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 24,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter your credentials to continue',
                        style: smallStyle.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 30),
                      LabeledField(
                        label: 'YOUR NAME',
                        hint: 'e.g. Ahmed Al-Rashidi',
                        controller: _name,
                        labelStyle: labelStyle,
                        textStyle: textStyle,
                        radius: 2,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 18),
                      LabeledField(
                        label: 'PASSWORD',
                        hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                        controller: _password,
                        labelStyle: labelStyle,
                        textStyle: textStyle,
                        radius: 2,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          child: Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      OrDivider(
                        lineColor: AppColors.whiteLine,
                        textStyle: smallStyle.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 18),
                      MicrosoftButton(
                        radius: 2,
                        borderColor: AppColors.whiteLine,
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                        onPressed: () => showInfo(
                            context, 'Microsoft sign-in is not connected yet'),
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text('No account? ', style: smallStyle),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.signUp),
                              child: Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  'Request access',
                                  style: smallStyle.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: AuthFooter(
                style: TextStyle(fontSize: 11, color: AppColors.slate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SCREEN 2: SIGN UP
// ============================================================================

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _studentId = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  final TextEditingController _school = TextEditingController();
  final TextEditingController _grade = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _studentId.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    _school.dispose();
    _grade.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 16, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      _dob.text = '${picked.year}-${two(picked.month)}-${two(picked.day)}';
    }
  }

  void _signUp() {
    FocusScope.of(context).unfocus();

    final bool anyEmpty = _fullName.text.trim().isEmpty ||
        _studentId.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _dob.text.trim().isEmpty ||
        _school.text.trim().isEmpty ||
        _grade.text.trim().isEmpty ||
        _password.text.isEmpty ||
        _confirmPassword.text.isEmpty;

    if (anyEmpty) {
      showInfo(context, 'Please fill in all the fields');
      return;
    }
    if (!_email.text.contains('@')) {
      showInfo(context, 'Please enter a valid school e-mail');
      return;
    }
    if (_password.text.length < 6) {
      showInfo(context, 'Password must be at least 6 characters');
      return;
    }
    if (_password.text != _confirmPassword.text) {
      showInfo(context, 'Passwords do not match');
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.express);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = TextStyle(fontSize: 14, color: AppColors.ink);
    final TextStyle labelStyle = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: const Color(0xFF1E293B),
    );
    final TextStyle smallStyle =
    TextStyle(fontSize: 12.5, color: AppColors.ink);

    return Scaffold(
      backgroundColor: AppColors.sky,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 20,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign up',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Create your account to get started',
                style: TextStyle(fontSize: 13, color: const Color(0xFF334155)),
              ),
              const SizedBox(height: 20),
              LabeledField(
                label: 'FULL NAME',
                hint: 'e.g. Ahmed Al-Rashidi',
                controller: _fullName,
                labelStyle: labelStyle,
                textStyle: textStyle,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: 'STUDENT ID',
                hint: 'e.g. 2024-91823',
                controller: _studentId,
                labelStyle: labelStyle,
                textStyle: textStyle,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: 'SCHOOL E-MAIL',
                hint: 'yourname@school.edu',
                controller: _email,
                labelStyle: labelStyle,
                textStyle: textStyle,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: 'PHONE NUMBER',
                hint: 'e.g. +1 (555) 000-0000',
                controller: _phone,
                labelStyle: labelStyle,
                textStyle: textStyle,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: 'DATE OF BIRTH',
                hint: 'YYYY-MM-DD',
                controller: _dob,
                labelStyle: labelStyle,
                textStyle: textStyle,
                readOnly: true,
                onTap: _pickDate,
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: 'SCHOOL',
                hint: 'Enter school name',
                controller: _school,
                labelStyle: labelStyle,
                textStyle: textStyle,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: 'YOUR GRADE',
                hint: 'e.g. Grade 11',
                controller: _grade,
                labelStyle: labelStyle,
                textStyle: textStyle,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: 'PASSWORD',
                hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                controller: _password,
                labelStyle: labelStyle,
                textStyle: textStyle,
                isPassword: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: 'CONFIRM PASSWORD',
                hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                controller: _confirmPassword,
                labelStyle: labelStyle,
                textStyle: textStyle,
                isPassword: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Sign up',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OrDivider(
                lineColor: AppColors.whiteLine,
                textStyle: TextStyle(fontSize: 11, color: AppColors.slate),
              ),
              const SizedBox(height: 14),
              MicrosoftButton(
                radius: 8,
                textStyle: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
                onPressed: () =>
                    showInfo(context, 'Microsoft sign-up is not connected yet'),
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Already have an account? ', style: smallStyle),
                    GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.signIn);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Sign in',
                          style: smallStyle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: AuthFooter(
                  style: TextStyle(fontSize: 10.5, color: AppColors.slate),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SCREEN 3: EXPRESS CHECK-IN  (Smart Attendance - Name Login)
// ============================================================================

class ExpressCheckInScreen extends StatefulWidget {
  const ExpressCheckInScreen({super.key});

  @override
  State<ExpressCheckInScreen> createState() => _ExpressCheckInScreenState();
}

class _ExpressCheckInScreenState extends State<ExpressCheckInScreen> {
  final TextEditingController _id = TextEditingController(text: '2023000000');
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _loading = false;
  String? _error;

  bool get _isMatch => isRegisteredStudentId(_id.text);

  @override
  void initState() {
    super.initState();
    _id.addListener(_onIdChanged);
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  void _onIdChanged() {
    if (mounted) {
      setState(() => _error = null);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _id.removeListener(_onIdChanged);
    _id.dispose();
    super.dispose();
  }

  String get _clock {
    final int h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final String period = _now.hour >= 12 ? 'PM' : 'AM';
    return '${two(h)}:${two(_now.minute)}:${two(_now.second)} $period';
  }

  String get _utcLabel {
    final Duration offset = _now.timeZoneOffset;
    final String sign = offset.isNegative ? '-' : '+';
    final int totalMinutes = offset.inMinutes.abs();
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    final String mins = minutes == 0 ? '' : ':${two(minutes)}';
    return 'UTC$sign$hours$mins';
  }

  void _enterApp({required bool openScanner}) {
    AppSession.instance.startSession(kDemoStudent);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => MainShell(openScanner: openScanner),
      ),
          (Route<dynamic> route) => false,
    );
  }

  Future<void> _clockIn() async {
    if (_loading) {
      return;
    }
    FocusScope.of(context).unfocus();
    if (_id.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your Student ID');
      return;
    }
    if (!_isMatch) {
      setState(
              () => _error = 'Student ID not found. Please check and try again.');
      return;
    }
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) {
      return;
    }
    _enterApp(openScanner: false);
  }

  void _scanQr() {
    FocusScope.of(context).unfocus();
    _enterApp(openScanner: true);
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.tileBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCE4F7)),
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 26,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Smart Attendance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sans(size: 21, weight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1D5CE0),
                        border: Border.all(
                          color: const Color(0xFFBFD4FA),
                          width: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active',
                      style: mono(size: 12, weight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.sensors,
                      size: 16,
                      color: AppColors.brandBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.timer_outlined, size: 14, color: AppColors.brandBlue),
          const SizedBox(width: 6),
          Text(
            'EXPRESS CHECK-IN',
            style: mono(
              size: 11,
              weight: FontWeight.w600,
              color: AppColors.brandBlue,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.brandBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Match',
            style: mono(
              size: 11,
              weight: FontWeight.w600,
              color: AppColors.brandBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdField() {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 14, right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _error == null ? AppColors.border : AppColors.red,
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.badge_outlined, size: 20, color: AppColors.slate),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _id,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (String value) => _clockIn(),
              cursorColor: AppColors.brandBlue,
              style: sans(size: 17, weight: FontWeight.w500),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Student ID',
                hintStyle: sans(
                  size: 17,
                  weight: FontWeight.w500,
                  color: AppColors.hint,
                ),
              ),
            ),
          ),
          if (_isMatch) _buildMatchBadge(),
        ],
      ),
    );
  }

  Widget _buildClockInButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x400050D8),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _loading ? null : _clockIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            disabledBackgroundColor: AppColors.brandBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          child: _loading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  'Clock In with Student ID',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sans(
                    size: 17,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward,
                  size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _scanQr,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.qr_code_scanner,
              size: 24,
              color: AppColors.brandBlue,
            ),
            const SizedBox(width: 10),
            Text(
              'Scan your QR Code',
              style: sans(size: 17, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6EBF5)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F0B2A6F),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Student ID', style: mono(size: 12.5, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          _buildIdField(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: mono(size: 10.5, color: AppColors.red),
              ),
            ),
          const SizedBox(height: 16),
          _buildClockInButton(),
          const SizedBox(height: 12),
          _buildQrButton(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.statusBarBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E9F8)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.avatarBg,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(_clock, style: mono(size: 14, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                '$_utcLabel Shift #4',
                style: mono(size: 10.5, color: AppColors.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(Icons.shield_outlined, size: 14, color: AppColors.mutedText),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Enterprise Identity Verification Protocol 4.2',
            overflow: TextOverflow.ellipsis,
            style: mono(size: 10, color: AppColors.mutedText),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: <Widget>[
          _buildHeader(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildChip(),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome back',
                      style: sans(size: 32, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your registered Student ID to clock in or access your attendance portal.',
                      style: sans(
                        size: 15,
                        weight: FontWeight.w400,
                        color: AppColors.mutedText,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildCard(),
                    const SizedBox(height: 16),
                    _buildStatusBar(),
                    const SizedBox(height: 18),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MAIN SHELL  (bottom navigation: Check In / Logs / Telemetry / Profile)
// ============================================================================

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.openScanner = false});

  final bool openScanner;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  late bool _scannerOpen = widget.openScanner;

  void _onTab(int index) {
    setState(() {
      if (index == 0) {
        _scannerOpen = false;
      }
      _tab = index;
    });
  }

  void _signOut() {
    AppSession.instance.endSession();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.signIn,
          (Route<dynamic> route) => false,
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 0:
        if (_scannerOpen) {
          return ScannerTab(
            key: const ValueKey<String>('scanner'),
            onDone: () => setState(() => _scannerOpen = false),
          );
        }
        return HomeTab(
          key: const ValueKey<String>('home'),
          onScan: () => setState(() => _scannerOpen = true),
          onOpenLogs: () => setState(() => _tab = 1),
        );
      case 1:
        return const LogsTab();
      case 2:
        return const PlaceholderTab(
          icon: Icons.my_location,
          title: 'Telemetry',
          message:
          'Live beacon, geofence and device telemetry will appear here.',
        );
      default:
        return ProfileTab(onSignOut: _signOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(bottom: false, child: _buildBody()),
      bottomNavigationBar: AppBottomNav(currentIndex: _tab, onTap: _onTab),
    );
  }
}

// ============================================================================
// SCREEN 4: STUDENT HOME
// ============================================================================

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 6;
    final Rect arcRect = (Offset.zero & size).deflate(stroke / 2);

    final Paint trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final Paint arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final double p = progress < 0 ? 0 : (progress > 1 ? 1 : progress);

    canvas.drawArc(arcRect, 0, math.pi * 2, false, trackPaint);
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * p, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.track != track;
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onScan, required this.onOpenLogs});

  final VoidCallback onScan;
  final VoidCallback onOpenLogs;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSession.instance,
      builder: (BuildContext context, Widget? child) {
        final AppSession s = AppSession.instance;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            _buildHeader(),
            const SizedBox(height: 14),
            _buildProfileCard(s),
            const SizedBox(height: 14),
            _buildSessionCard(s),
            const SizedBox(height: 22),
            _buildMetricsHeader(context),
            const SizedBox(height: 10),
            IntrinsicHeight(child: _buildMetricsRow(s)),
            const SizedBox(height: 10),
            _buildStatRow(s),
            const SizedBox(height: 22),
            Text(
              'Campus Services',
              style: sans(size: 16, weight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _buildServices(context),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: <Widget>[
        const Icon(Icons.fingerprint, size: 24, color: AppColors.navy),
        const SizedBox(width: 6),
        Text('VeriShift', style: sans(size: 18, weight: FontWeight.w800)),
        const Spacer(),
        const CampusMeshPill(),
        const SizedBox(width: 8),
        const Icon(Icons.sensors, size: 18, color: AppColors.brandBlue),
      ],
    );
  }

  Widget _buildProfileCard(AppSession s) {
    final Student st = s.student;
    return AppCard(
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    st.initials,
                    style: mono(
                      size: 15,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        st.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sans(size: 16, weight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      size: 15,
                      color: AppColors.brandBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  st.id,
                  style: mono(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: AppColors.brandBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  st.program,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sans(
                    size: 11,
                    weight: FontWeight.w400,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const StatusTag(
                text: 'In Geofence',
                background: AppColors.greenBg,
                foreground: AppColors.greenDark,
                showDot: true,
                size: 9.5,
              ),
              const SizedBox(height: 6),
              Text(
                'Auditorium B',
                style: mono(size: 9.5, color: AppColors.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: mono(size: 9, color: AppColors.mutedText)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  style: mono(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowBanner(AppSession s) {
    Color bg = AppColors.amberBg;
    Color border = AppColors.amberBorder;
    Color textColor = AppColors.amberDark;
    IconData icon = Icons.hourglass_bottom;
    Color iconColor = AppColors.amber;
    String label = 'Check-in window closes in:';
    String trailing = formatCountdown(s.windowSecondsLeft);

    if (s.checkedIn) {
      bg = AppColors.greenBg;
      border = const Color(0xFFB5E6CC);
      textColor = AppColors.greenDark;
      icon = Icons.check_circle_outline;
      iconColor = AppColors.green;
      label = 'Attendance verified';
      trailing = 'Confirmed';
    } else if (!s.windowOpen) {
      bg = AppColors.redBg;
      border = AppColors.redBorder;
      textColor = AppColors.red;
      icon = Icons.error_outline;
      iconColor = AppColors.red;
      label = 'Check-in window closed';
      trailing = '00m 00s';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: sans(
                size: 11.5,
                weight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Text(
            trailing,
            style: mono(size: 13, weight: FontWeight.w800, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(AppSession s) {
    final bool done = s.checkedIn;
    final bool open = s.windowOpen;
    final bool enabled = !done && open;
    final Color bg = done
        ? AppColors.green
        : (open ? AppColors.deepBlue : const Color(0xFF9AA5BD));
    final String label = done
        ? 'Attendance Confirmed'
        : (open ? 'Scan QR Code to Check In' : 'Check-in Window Closed');
    final IconData lead =
    done ? Icons.check_circle_outline : Icons.qr_code_scanner;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onScan : null,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(lead, size: 22, color: Colors.white),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sans(
                    size: 15,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (enabled) ...<Widget>[
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(AppSession s) {
    return AppCard(
      topBarColor: AppColors.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const StatusTag(
                text: 'Active Session',
                background: AppColors.chipBg,
                foreground: AppColors.brandBlue,
              ),
              const SizedBox(width: 8),
              Text(
                '09:12 AM \u2022 Mon',
                style: mono(size: 10, color: AppColors.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'CS-402: Deep Learning',
                      style: sans(size: 20, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Room 304 (Main Hall) \u2022 Dr. Harrison',
                      style: sans(
                        size: 12,
                        weight: FontWeight.w400,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.tileBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  size: 22,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _infoTile(
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.green,
                  label: 'Geofence Status',
                  value: 'Verified (\u00B12m Lock)',
                  valueColor: AppColors.greenDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoTile(
                  icon: Icons.bluetooth,
                  iconColor: AppColors.brandBlue,
                  label: 'BLE Beacon',
                  value: 'Aud-B-304-Beacon',
                  valueColor: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildWindowBanner(s),
          const SizedBox(height: 12),
          _buildScanButton(s),
          const SizedBox(height: 10),
          Text(
            'Opens optical camera scanner \u2022 Verified with geofence & BLE beacon',
            textAlign: TextAlign.center,
            style: mono(size: 9.5, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          child: Text(
            'Term Attendance Metrics',
            style: sans(size: 16, weight: FontWeight.w800),
          ),
        ),
        InkWell(
          onTap: () => showInfo(
              context, 'Full analytics will be connected to the backend soon'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Text(
              'View Full Analytics',
              style: mono(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.brandBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(AppSession s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: AppCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'ATTENDANCE RATE',
                        style: mono(
                          size: 9,
                          color: AppColors.mutedText,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${s.attendanceRate.toStringAsFixed(1)}%',
                        style: mono(size: 24, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const StatusTag(
                        text: 'Good Standing',
                        background: AppColors.greenBg,
                        foreground: AppColors.greenDark,
                        showDot: true,
                        size: 9,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: s.attendanceRate / 100,
                      color: AppColors.brandBlue,
                      track: const Color(0xFFE3EAF8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check,
                        size: 20,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Absence Buffer',
                  style: sans(
                    size: 11,
                    weight: FontWeight.w600,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: '3 ',
                        style: sans(size: 24, weight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: 'Left',
                        style: sans(
                          size: 11,
                          weight: FontWeight.w500,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.4,
                    minHeight: 5,
                    backgroundColor: Color(0xFFFCE9C4),
                    valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.amber),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, String caption, Color color) {
    return AppCard(
      radius: 12,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: mono(size: 9.5, color: AppColors.mutedText)),
          const SizedBox(height: 4),
          Text(
            value,
            style: sans(size: 22, weight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(caption, style: mono(size: 9, color: AppColors.mutedText)),
        ],
      ),
    );
  }

  Widget _buildStatRow(AppSession s) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _statCard(
              'Attended', '${s.attended}', 'Lectures', AppColors.navy),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard('Absences', '2', 'Approved', AppColors.red),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard('Late Flags', '1', '< 5 mins', AppColors.amber),
        ),
      ],
    );
  }

  Widget _serviceCard({
    required IconData icon,
    required String label,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Material(
      color: selected ? const Color(0xFFE6EEFF) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFFBFD0F5) : AppColors.cardBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 21, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: sans(size: 11.5, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServices(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _serviceCard(
            icon: Icons.qr_code_scanner,
            label: 'Quick Scan',
            iconBg: AppColors.brandBlue,
            iconColor: Colors.white,
            selected: true,
            onTap: () {
              final AppSession s = AppSession.instance;
              if (s.checkedIn) {
                showInfo(context, 'You are already checked in');
              } else if (!s.windowOpen) {
                showInfo(context, 'The check-in window has closed');
              } else {
                onScan();
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _serviceCard(
            icon: Icons.calendar_month_outlined,
            label: 'Timetable',
            iconBg: const Color(0xFFFFF0D6),
            iconColor: AppColors.amber,
            onTap: () => showInfo(
                context, 'Timetable will be connected to the backend soon'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _serviceCard(
            icon: Icons.description_outlined,
            label: 'Corrections',
            iconBg: const Color(0xFFE3ECFC),
            iconColor: AppColors.brandBlue,
            onTap: onOpenLogs,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SCREEN 5: ROOM ATTENDANCE QR SCANNER
// ============================================================================

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    const double l = 28;
    final double w = size.width;
    final double h = size.height;

    final Path path = Path()
      ..moveTo(0, l)
      ..lineTo(0, 0)
      ..lineTo(l, 0)
      ..moveTo(w - l, 0)
      ..lineTo(w, 0)
      ..lineTo(w, l)
      ..moveTo(0, h - l)
      ..lineTo(0, h)
      ..lineTo(l, h)
      ..moveTo(w - l, h)
      ..lineTo(w, h)
      ..lineTo(w, h - l);

    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _CodeDialog extends StatefulWidget {
  const _CodeDialog();

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String value = _controller.text.trim();
    if (value.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from the lecture screen');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Enter 6-Digit Code',
        style: sans(size: 18, weight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Type the code displayed on the lecture screen.',
            style: sans(
              size: 12.5,
              weight: FontWeight.w400,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            textAlign: TextAlign.center,
            style: mono(size: 22, weight: FontWeight.w800, letterSpacing: 6),
            onSubmitted: (String value) => _submit(),
            decoration: InputDecoration(
              counterText: '',
              hintText: '------',
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

class ScannerTab extends StatefulWidget {
  const ScannerTab({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<ScannerTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  bool _flash = false;
  bool _detected = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _runAttendance(String method) async {
    final AppSession s = AppSession.instance;
    if (_busy) {
      return;
    }
    if (s.checkedIn) {
      showInfo(context, 'You are already checked in for this session');
      return;
    }
    if (!s.windowOpen) {
      showInfo(context, 'The check-in window has closed');
      return;
    }
    setState(() {
      _busy = true;
      _detected = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) {
      return;
    }
    s.confirmAttendance();
    setState(() {
      _busy = false;
      _detected = false;
    });
    await _showSuccess(method);
    if (!mounted) {
      return;
    }
    widget.onDone();
  }

  Future<void> _enterCode() async {
    final String? code = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => const _CodeDialog(),
    );
    if (code == null || !mounted) {
      return;
    }
    await _runAttendance('6-digit code');
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: mono(size: 10.5, color: AppColors.mutedText)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: mono(size: 10.5, weight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Future<void> _showSuccess(String method) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        final Student st = AppSession.instance.student;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.greenBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 36,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Attendance Confirmed',
                style: sans(size: 20, weight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'CS-402 \u2022 Deep Learning & Neural Nets',
                textAlign: TextAlign.center,
                style: sans(
                  size: 13,
                  weight: FontWeight.w400,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: <Widget>[
                    _receiptRow('Student', '${st.name} \u2022 ${st.id}'),
                    const SizedBox(height: 6),
                    _receiptRow('Method', method),
                    const SizedBox(height: 6),
                    _receiptRow('Verified by', 'Geofence + BLE beacon'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: sans(
                      size: 15,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------- header

  Widget _buildHeader() {
    return Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.deepBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.fingerprint, size: 28, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('VeriShift', style: sans(size: 20, weight: FontWeight.w800)),
              Text(
                'v4.8 \u2022 Core',
                style: mono(size: 10, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        const CampusMeshPill(),
        const SizedBox(width: 8),
        Material(
          color: const Color(0xFFE3EBFD),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _flash = !_flash),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                _flash ? Icons.flashlight_on : Icons.flashlight_off,
                size: 20,
                color: AppColors.navy,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdStrip(Student st) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.badge_outlined, size: 18, color: AppColors.brandBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${st.name} \u2022 ${st.id}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mono(size: 11.5, color: AppColors.mutedText),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.verified_user_outlined,
              size: 16, color: AppColors.green),
          const SizedBox(width: 4),
          Text(
            'Verified ID',
            style: mono(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Room Attendance QR Scanner',
                style: sans(size: 20, weight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                'Align kiosk or lecture screen dynamic QR inside frame',
                style: sans(
                  size: 12,
                  weight: FontWeight.w400,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const StatusTag(
          text: 'SYNC 60Hz',
          background: AppColors.chipBg,
          foreground: AppColors.brandBlue,
          icon: Icons.sensors,
          size: 10,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- camera

  Widget _overlayPill({
    required String text,
    bool dot = false,
    IconData? icon,
    Color iconColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x99101A33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (dot) ...<Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF34D399),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mono(
                size: 10.5,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simulateButton() {
    return Material(
      color: AppColors.brandBlue,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _busy ? null : () => _runAttendance('QR scan'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.qr_code_scanner, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'Simulate Scan',
                style: mono(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrame(double side) {
    final Color accent =
    _detected ? const Color(0xFF34D399) : const Color(0xFF3B82F6);
    final Color fill =
    _detected ? const Color(0x2234D399) : const Color(0x223B82F6);

    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: Container(color: fill)),
          Positioned.fill(child: CustomPaint(painter: _CornerPainter(accent))),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (BuildContext context, Widget? child) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 8,
                      right: 8,
                      top: 8 + (side - 20) * _anim.value,
                      child: Container(height: 2, color: accent),
                    ),
                  ],
                );
              },
            ),
          ),
          Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x99FFFFFF)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: const Color(0xCC1E2A47),
                child: Text(
                  _detected
                      ? 'QR DETECTED \u2022 VERIFYING'
                      : 'SEARCHING DYNAMIC QR',
                  style: mono(
                    size: 9.5,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCamera() {
    return AspectRatio(
      aspectRatio: 0.93,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFF34466E),
                    Color(0xFF16213F),
                    Color(0xFF0A1024),
                  ],
                ),
              ),
            ),
            if (_flash) Positioned.fill(child: Container(color: const Color(0x33FFFFFF))),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final double side = math.min(c.maxWidth, c.maxHeight) * 0.62;
                return Center(child: _buildFrame(side));
              },
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: _overlayPill(
                      text: 'Aud-B-304 Beacon (98%)',
                      dot: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _overlayPill(
                    text: 'Geofence \u00B12m',
                    icon: Icons.gps_fixed,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: _overlayPill(
                      text: 'Auditorium B \u2022 Room 304',
                      icon: Icons.apartment,
                      iconColor: const Color(0xFF34D399),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _simulateButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRotateStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.shield, size: 18, color: AppColors.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dynamic QR rotates every 15s \u2022 Anti-spoofing enabled',
              style: mono(size: 10.5),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _anim,
            builder: (BuildContext context, Widget? child) {
              return Opacity(
                opacity: 0.35 + 0.65 * _anim.value,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB9CBF5),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- session card

  Widget _panelTile({
    required String label,
    required String value,
    required IconData noteIcon,
    required String note,
    required Color noteColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: mono(
              size: 9.5,
              color: AppColors.mutedText,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: mono(size: 14, weight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(noteIcon, size: 13, color: noteColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  note,
                  style: mono(
                    size: 10,
                    weight: FontWeight.w700,
                    color: noteColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(AppSession s) {
    final bool done = s.checkedIn;
    final bool open = s.windowOpen;
    final bool enabled = !done && open && !_busy;

    Color bg = AppColors.brandBlue;
    String label = 'Confirm Instant QR Attendance';
    if (done) {
      bg = AppColors.green;
      label = 'Attendance Confirmed';
    } else if (!open) {
      bg = const Color(0xFF9AA5BD);
      label = 'Check-in Window Closed';
    } else if (_busy) {
      label = 'Verifying...';
    }

    Widget trailing = const Icon(Icons.arrow_forward, size: 18, color: Colors.white);
    if (done) {
      trailing = const Icon(Icons.check, size: 18, color: Colors.white);
    } else if (_busy) {
      trailing = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: enabled ? () => _runAttendance('Instant QR') : null,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 4),
              const Icon(Icons.qr_code_scanner, size: 22, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: sans(
                      size: 15,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0x33FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: trailing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(AppSession s) {
    final bool done = s.checkedIn;
    final bool open = s.windowOpen;

    final String tag =
    done ? 'Punched' : (open ? 'Ready to Punch' : 'Window Closed');
    final Color tagBg = done
        ? AppColors.greenBg
        : (open ? const Color(0xFFEAF0FE) : AppColors.redBg);
    final Color tagFg =
    done ? AppColors.greenDark : (open ? AppColors.brandBlue : AppColors.red);

    final String timeNote = done
        ? 'Punch recorded'
        : (open ? '${formatCountdown(s.windowSecondsLeft)} left to punch' : 'Window closed');
    final Color timeColor = done ? AppColors.green : AppColors.red;

    return AppCard(
      topBarColor: AppColors.brandBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE6FB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'CS-402',
                        style: mono(size: 11, weight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8F0D2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Mandatory Session',
                        style: mono(
                          size: 11,
                          weight: FontWeight.w700,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFD0F5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration:
                      BoxDecoration(color: tagFg, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tag,
                      style: mono(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: tagFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Deep Learning & Neural Nets',
            style: sans(size: 22, weight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(
                Icons.person_outline,
                size: 16,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Dr. Harrison \u2022 Lecture Theater Auditorium B',
                  style: sans(
                    size: 12.5,
                    weight: FontWeight.w400,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _panelTile(
                    label: 'TIMING WINDOW',
                    value: '09:00 - 10:45 AM',
                    noteIcon: Icons.timer_outlined,
                    note: timeNote,
                    noteColor: timeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _panelTile(
                    label: 'CAMPUS LOCATION',
                    value: 'Building 4, Level 3',
                    noteIcon: Icons.check_circle_outline,
                    note: 'Inside verified polygon',
                    noteColor: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildConfirmButton(s),
        ],
      ),
    );
  }

  Widget _buildEnterCodeButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _busy ? null : _enterCode,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.pin_outlined, size: 20, color: AppColors.brandBlue),
              const SizedBox(width: 10),
              Text(
                'Enter 6-Digit Code',
                style: sans(size: 15, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSession.instance,
      builder: (BuildContext context, Widget? child) {
        final AppSession s = AppSession.instance;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            _buildHeader(),
            const SizedBox(height: 12),
            _buildIdStrip(s.student),
            const SizedBox(height: 14),
            _buildTitleRow(),
            const SizedBox(height: 12),
            _buildCamera(),
            const SizedBox(height: 12),
            _buildRotateStrip(),
            const SizedBox(height: 12),
            _buildSessionCard(s),
            const SizedBox(height: 12),
            _buildEnterCodeButton(),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.sync_disabled,
                  size: 15,
                  color: AppColors.mutedText,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Offline Attestation Token Cached \u2022 Expiry in 4h',
                    style: mono(size: 10, color: AppColors.mutedText),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// SCREEN 6: CORRECTION REQUEST SUBMITTED  (Logs tab)
// ============================================================================

enum _StepState { done, active, pending }

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({
    required this.title,
    required this.description,
    required this.state,
    this.isLast = false,
  });

  final String title;
  final String description;
  final _StepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    Color color = const Color(0xFFB4BDD0);
    String label = 'Pending';
    Color tagBg = const Color(0xFFEEF1F7);
    Color tagFg = AppColors.mutedText;

    if (state == _StepState.done) {
      color = AppColors.green;
      label = 'Done';
      tagBg = AppColors.greenBg;
      tagFg = AppColors.greenDark;
    } else if (state == _StepState.active) {
      color = AppColors.brandBlue;
      label = 'In Progress';
      tagBg = AppColors.chipBg;
      tagFg = AppColors.brandBlue;
    }

    final Widget dot;
    if (state == _StepState.done) {
      dot = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      );
    } else {
      dot = Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: state == _StepState.active
            ? Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        )
            : null,
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 22,
            child: Column(
              children: <Widget>[
                dot,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: const Color(0xFFDDE5F4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          style: sans(size: 12, weight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusTag(
                        text: label,
                        background: tagBg,
                        foreground: tagFg,
                        size: 9,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: sans(
                      size: 11,
                      weight: FontWeight.w400,
                      color: AppColors.mutedText,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LogsTab extends StatelessWidget {
  const LogsTab({super.key});

  static const String _hash = '0x7f2a9c...c29a85';

  TextStyle _label() {
    return mono(size: 9, color: AppColors.mutedText, letterSpacing: 0.6);
  }

  Widget _buildHeader() {
    return Row(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.fingerprint, size: 22, color: AppColors.navy),
                const SizedBox(width: 6),
                Text('VeriShift', style: sans(size: 17, weight: FontWeight.w800)),
              ],
            ),
            Text(
              'ACADEMIC LEDGER',
              style: mono(
                size: 8,
                color: AppColors.mutedText,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.badge_outlined, size: 13, color: AppColors.slate),
              const SizedBox(width: 6),
              Text(
                AppSession.instance.student.id,
                style: mono(size: 10.5, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Column(
      children: <Widget>[
        Container(
          width: 92,
          height: 92,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.greenBg,
            shape: BoxShape.circle,
          ),
          child: Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFF0E9F5A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, size: 34, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        const StatusTag(
          text: 'LEDGERED',
          background: AppColors.greenBg,
          foreground: AppColors.greenDark,
          size: 9,
        ),
        const SizedBox(height: 12),
        Text(
          'Correction Request Submitted',
          textAlign: TextAlign.center,
          style: sans(size: 22, weight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              const TextSpan(text: 'Your attendance correction request for '),
              TextSpan(
                text: 'MATH-310',
                style: sans(size: 12.5, weight: FontWeight.w800),
              ),
              const TextSpan(
                text:
                ' has been successfully logged and sent for faculty review.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: sans(
            size: 12.5,
            weight: FontWeight.w400,
            color: AppColors.mutedText,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTxPill(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF3FB),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Clipboard.setData(const ClipboardData(text: _hash));
          showInfo(context, 'Ledger hash copied');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.tag, size: 13, color: AppColors.brandBlue),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Tx Ref: #REQ-9942 \u00B7 Hash: $_hash',
                  style: mono(size: 9.5, color: AppColors.mutedText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scanTile({
    required String label,
    required String title,
    required Color titleColor,
    required IconData icon,
    required String sub,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: _label()),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 14, color: titleColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: sans(size: 12, weight: FontWeight.w800, color: titleColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(sub, style: mono(size: 9.5, color: AppColors.mutedText)),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.receipt_long_outlined,
                size: 16,
                color: AppColors.brandBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'LEDGER RECEIPT ENTRY',
                  style: mono(
                    size: 10,
                    weight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                'Today, 11:46 AM',
                style: mono(size: 9.5, color: AppColors.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('COURSE & FACULTY', style: _label()),
                    const SizedBox(height: 4),
                    Text('MATH-310', style: sans(size: 20, weight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      'Discrete Mathematics \u2022 Prof. Linda K.',
                      style: sans(
                        size: 11.5,
                        weight: FontWeight.w400,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('TICKET ID', style: _label()),
                  const SizedBox(height: 4),
                  const StatusTag(
                    text: '#REQ-9942',
                    background: AppColors.chipBg,
                    foreground: AppColors.brandBlue,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _scanTile(
                    label: 'ORIGINAL SCAN',
                    title: 'Late (+2m grace)',
                    titleColor: AppColors.red,
                    icon: Icons.schedule,
                    sub: '11:42:11 AM BST',
                    bg: AppColors.redBg,
                    border: AppColors.redBorder,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _scanTile(
                    label: 'REQUESTED STATUS',
                    title: 'Verified On-Time',
                    titleColor: AppColors.greenDark,
                    icon: Icons.check_circle_outline,
                    sub: 'Classroom Scan (100%)',
                    bg: const Color(0xFFEAF8F0),
                    border: const Color(0xFFC8EBD8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('STATED REASON:', style: _label()),
          const SizedBox(height: 4),
          Text(
            'Beacon / Geofence Drift',
            style: sans(size: 13, weight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'kiosk_mesh_queue_timestamp.jpg',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: mono(size: 10.5, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SHA-256 validated \u2022 1.4 MB',
                        style: mono(size: 9, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      showInfo(context, 'Attachment preview will open here'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.brandBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Cryptographic Proof:',
                style: mono(size: 9.5, color: AppColors.mutedText),
              ),
              Text(
                _hash,
                style: mono(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.brandBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Audit Pipeline', style: sans(size: 14, weight: FontWeight.w800)),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ETA: 24-48 Hrs',
                  style: mono(size: 9.5, color: AppColors.mutedText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _PipelineStep(
            title: 'Step 1: Request Submitted',
            description:
            'Biometric ledger verified and payload logged to classroom ledger.',
            state: _StepState.done,
          ),
          const _PipelineStep(
            title: 'Step 2: Instructor Review',
            description:
            'Assigned to Dr. Linda K. for syllabus policy confirmation.',
            state: _StepState.active,
          ),
          const _PipelineStep(
            title: 'Step 3: Ledger Re-indexing & Final Proof',
            description:
            'Automated update to gradebook and registrar attendance metrics.',
            state: _StepState.pending,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: <Widget>[
        Material(
          color: AppColors.deepBlue,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => showInfo(
                context, 'Attendance logs will be connected to the backend soon'),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.history, size: 20, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'View in Attendance Logs',
                    style: sans(
                      size: 14.5,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => showInfo(
                context, 'The PDF request slip will be generated by the backend'),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.download_outlined,
                    size: 20,
                    color: AppColors.navy,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Download Request Slip (PDF)',
                    style: sans(size: 14, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        _buildHeader(),
        const SizedBox(height: 20),
        _buildHero(),
        const SizedBox(height: 14),
        Center(child: _buildTxPill(context)),
        const SizedBox(height: 16),
        _buildReceiptCard(context),
        const SizedBox(height: 12),
        _buildAuditCard(),
        const SizedBox(height: 14),
        _buildButtons(context),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          children: <Widget>[
            Text(
              'Need urgent help? ',
              style: sans(
                size: 11,
                weight: FontWeight.w400,
                color: AppColors.mutedText,
              ),
            ),
            InkWell(
              onTap: () => showInfo(
                  context, 'Academic Registrar Support contact will open here'),
              child: Text(
                'Contact Academic Registrar Support',
                style: sans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// TELEMETRY + PROFILE TABS (placeholders until their designs are ready)
// ============================================================================

class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.chipBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.brandBlue),
            ),
            const SizedBox(height: 16),
            Text(title, style: sans(size: 22, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: sans(
                size: 13,
                weight: FontWeight.w400,
                color: AppColors.mutedText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final Student st = AppSession.instance.student;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        Text('Profile', style: sans(size: 22, weight: FontWeight.w800)),
        const SizedBox(height: 14),
        AppCard(
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  st.initials,
                  style: mono(
                    size: 17,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(st.name, style: sans(size: 16, weight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      st.id,
                      style: mono(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      st.program,
                      style: sans(
                        size: 11.5,
                        weight: FontWeight.w400,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onSignOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.redBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.logout, size: 20),
            label: Text(
              'Sign out',
              style: sans(size: 14, weight: FontWeight.w700, color: AppColors.red),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'The full profile screen will be added when its design is ready.',
          textAlign: TextAlign.center,
          style: mono(size: 10, color: AppColors.mutedText),
        ),
      ],
    );
  }
}
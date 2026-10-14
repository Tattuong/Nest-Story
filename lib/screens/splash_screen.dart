import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_strings.dart';
import '../widgets/app_ui.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: const Color(0xFFFEFCF7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Image(
                image: AssetImage('assets/logo.png'),
                width: 280,
                height: 280,
                filterQuality: FilterQuality.high,
              ),
              Text(
                AppStrings.t(context, 'appName'),
                style: AppTypography.display(size: 32, context: context, color: const Color(0xFF1C241C)),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.t(context, 'appTagline'),
                style: AppTypography.body(size: 15, context: context, color: const Color(0xFF5E6B62)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

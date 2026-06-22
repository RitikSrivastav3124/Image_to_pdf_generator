import 'package:flutter/material.dart';
import 'package:pdf_converter/presentation/views/home/home_view.dart';

class AppRoutes {
  static const String home = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
      default:
        return MaterialPageRoute(builder: (_) => const HomeView());
    }
  }
}

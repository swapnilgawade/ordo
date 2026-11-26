import 'package:material_ui/material_ui.dart';

import 'data/repository.dart';

/// Makes the [Repository] available to every screen.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.repository, required super.child});

  final Repository repository;

  static Repository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      repository != oldWidget.repository;
}

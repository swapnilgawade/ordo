import 'package:material_ui/material_ui.dart';

import 'app_scope.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = Repository(AppDatabase());
  runApp(OrdoApp(repository: repository));
}

class OrdoApp extends StatelessWidget {
  const OrdoApp({super.key, required this.repository});

  final Repository repository;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: repository,
      child: MaterialApp(
        title: 'Ordo',
        debugShowCheckedModeBanner: false,
        theme: buildOrdoTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}

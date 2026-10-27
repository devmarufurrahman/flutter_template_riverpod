import 'dart:io';

void main(List<String> arguments) async {
  stdout.write('🚀 Enter your Project Name (snake_case): ');
  final projectName = stdin.readLineSync()?.trim();

  if (projectName == null || projectName.isEmpty) {
    print('❌ Project name cannot be empty!');
    return;
  }

  print('\n--- 🏗️  STARTING ADVANCED RIVERPOD PROJECT CREATION: $projectName ---');

  // ০. Host environment detect
  print('Step 0: Detecting host environment (Flutter & Dart SDK)...');
  final flutterResult = await Process.run('flutter', ['--version'], runInShell: true);
  String flutterInfo = 'Flutter (active)';
  if (flutterResult.exitCode == 0) {
    flutterInfo = flutterResult.stdout.toString().split('\n').first.trim();
  }
  final String currentDartVersion = Platform.version.split(' ').first;
  print('✅ Host: $flutterInfo | Dart SDK: $currentDartVersion');

  if (Platform.isMacOS) {
    // Proactively enable Swift Package Manager support in Flutter to prevent iOS SPM plugin errors
    await Process.run('flutter', ['config', '--enable-swift-package-manager'], runInShell: true);
  }

  // ১. flutter create command run
  print('Step 1: Running "flutter create"...');
  var createResult = await Process.run('flutter', [
    'create',
    projectName,
  ], runInShell: true);
  if (createResult.exitCode != 0) {
    print('❌ Error: ${createResult.stderr}');
    return;
  }
  Directory.current = Directory('${Directory.current.path}/$projectName');

  // Configure Android build.gradle.kts / build.gradle to compileSdk = 37 (required by modern plugins like permission_handler)
  _configureAndroidSdk();

  // ২. assets folder create
  print('Step 2: Creating Assets folders...');
  final assetFolders = [
    'animations',
    'fonts',
    'icons',
    'images',
    'vectors',
    'videos',
  ];
  for (var folder in assetFolders) {
    await Directory('assets/$folder').create(recursive: true);
  }

  // ৩. creating root files (.env, l10n.yaml, create_feature.dart)
  print(
    'Step 3: Creating Config files (.env, l10n.yaml, create_feature.dart)...',
  );
  File('.env').writeAsStringSync(
    'API_BASE_URL=https://api.example.com\nAPP_NAME=$projectName',
  );

  File('l10n.yaml').writeAsStringSync('''arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/generated/l10n
untranslated-messages-file: lib/l10n/untranslated.json
''');

  File('analysis_options.yaml').writeAsStringSync('''include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    invalid_export_of_internal_element: ignore
  exclude:
    - build/**
    - android/**
    - ios/**
    - web/**
    - windows/**
    - macos/**
    - linux/**
''');

  // --- Create Feature Script (Project Root) ---
  print('📝 Generating "create_feature.dart" in project root (Riverpod Architecture)...');

  File('create_feature.dart').writeAsStringSync('''// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings, unnecessary_brace_in_string_interps
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Error: Please provide a feature name.');
    print('Usage: dart create_feature.dart <feature_name> [optional_path]');
    return;
  }

  String projectName = _getProjectName();
  if (projectName.isEmpty) {
    print('❌ Error: Could not find "name" in pubspec.yaml');
    return;
  }

  String featureName = _toSnakeCase(args[0]);
  String className = _toCamelCase(featureName);
  String camelName = className[0].toLowerCase() + className.substring(1);
  String targetDir = args.length > 1 ? args[1] : 'lib/features';
  if (targetDir.endsWith('/')) targetDir = targetDir.substring(0, targetDir.length - 1);
  String basePath = '\$targetDir/\$featureName';

  print('🚀 Creating feature: \$featureName with Riverpod & Freezed architecture...');

  _createDirectory('\$basePath/views');
  _createDirectory('\$basePath/controllers');
  _createDirectory('\$basePath/repositories');
  _createDirectory('\$basePath/models');
  _createDirectory('\$basePath/widgets');

  _createFile('\$basePath/views/\${featureName}_view.dart', _viewTemplate(className, camelName, projectName, featureName));
  _createFile('\$basePath/controllers/\${featureName}_controller.dart', _controllerTemplate(className, camelName, projectName));
  _createFile('\$basePath/repositories/\${featureName}_repository.dart', _repositoryTemplate(className, camelName, projectName, featureName));
  _createFile('\$basePath/models/\${featureName}_model.dart', _modelTemplate(className, featureName));
  _createFile('\$basePath/widgets/\${featureName}_widget.dart', _widgetTemplate(className, camelName, projectName, featureName));

  _addToImportsFile('lib/core/utils/constants/imports.dart', projectName, featureName, [
    '\$basePath/views/\${featureName}_view.dart',
    '\$basePath/controllers/\${featureName}_controller.dart',
    '\$basePath/repositories/\${featureName}_repository.dart',
    '\$basePath/models/\${featureName}_model.dart',
  ]);

  _addRoute(className, featureName);
  _addGoRoute(className, featureName, projectName);

  print('\\n⚡ Automatically running build_runner for \$featureName (Freezed codegen)...');
  final codegen = await Process.run('dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs'], runInShell: true);
  if (codegen.exitCode == 0) {
    print('✅ Freezed codegen completed successfully.');
  } else {
    print('ℹ️  Codegen finished with code \${codegen.exitCode}. Run "dart run rps gen" if needed.');
  }

  print('\\n✅ Success! Riverpod Feature "\$featureName" created and registered in GoRouter & imports.');
}

String _getProjectName() {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) return '';
  final lines = file.readAsLinesSync();
  for (var line in lines) {
    if (line.trim().startsWith('name:')) return line.split(':')[1].trim();
  }
  return '';
}

void _createDirectory(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) dir.createSync(recursive: true);
}

void _createFile(String path, String content) {
  final file = File(path);
  if (!file.existsSync()) {
    file.createSync(recursive: true);
    file.writeAsStringSync(content);
  }
}

void _addToImportsFile(String path, String projectName, String featureName, List<String> files) {
  final file = File(path);
  if (file.existsSync()) {
    String content = file.readAsStringSync();
    StringBuffer exports = StringBuffer();
    exports.writeln('\\n// --- \$featureName module exports ---');
    for (var f in files) {
      String p = f.replaceFirst('lib/', 'package:\$projectName/');
      if (!content.contains(p)) exports.writeln("export '\$p';");
    }
    file.writeAsStringSync(exports.toString(), mode: FileMode.append);
  }
}

void _addRoute(String className, String featureName) {
  final file = File('lib/core/router/app_routes.dart');
  if (!file.existsSync()) return;
  String content = file.readAsStringSync();
  String name = className[0].toLowerCase() + className.substring(1);
  String line = '  static const String \$name = "/\$featureName";\\n  static const String \${name}Name = "\$featureName";';
  if (content.contains('static const String \$name')) return;
  int idx = content.lastIndexOf('}');
  if (idx != -1) {
    file.writeAsStringSync(content.substring(0, idx) + '\$line\\n' + content.substring(idx));
  }
}

void _addGoRoute(String className, String featureName, String projectName) {
  final file = File('lib/core/router/app_router.dart');
  if (!file.existsSync()) return;
  String content = file.readAsStringSync();

  // Inject GoRoute before the routes marker
  String name = className[0].toLowerCase() + className.substring(1);
  String routeEntry = '      GoRoute(\\n        path: AppRoutes.\$name,\\n        name: AppRoutes.\${name}Name,\\n        builder: (context, state) => const \${className}View(),\\n      ),\\n';

  if (!content.contains('AppRoutes.\$name')) {
    const routeMarker = '// --- [FEATURE_ROUTES] ---';
    if (content.contains(routeMarker)) {
      content = content.replaceFirst(routeMarker, '\$routeEntry      \$routeMarker');
    } else {
      int idx = content.lastIndexOf('],');
      if (idx != -1) {
        content = content.substring(0, idx) + routeEntry + content.substring(idx);
      }
    }
  }

  file.writeAsStringSync(content);
}

String _toSnakeCase(String text) => text.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_\${m.group(0)!.toLowerCase()}').replaceAll(RegExp(r'^_'), '');
String _toCamelCase(String text) => text.split('_').map((w) => w.isEmpty ? '' : '\${w[0].toUpperCase()}\${w.substring(1)}').join('');

String _viewTemplate(String c, String m, String p, String f) => """import 'package:\$p/core/utils/constants/imports.dart';
import '../widgets/\${f}_widget.dart';

class \${c}View extends ConsumerWidget {
  const \${c}View({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(\${m}ControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('\${c}'),
      ),
      body: asyncState.when(
        data: (data) => \${c}Widget(data: data),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: \\\$err',
            style: TextStyle(
              color: AppColors.red,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }
}
""";

String _controllerTemplate(String c, String m, String p) => """import 'dart:async';
import 'package:\$p/core/utils/constants/imports.dart';

class \${c}Controller extends AsyncNotifier<\${c}Model?> {
  late final I\${c}Repository _repository;

  @override
  FutureOr<\${c}Model?> build() async {
    _repository = ref.watch(\${m}RepositoryProvider);
    return fetchInitialData();
  }

  Future<\${c}Model?> fetchInitialData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchData());
    return state.value;
  }
}

final \${m}ControllerProvider =
    AsyncNotifierProvider.autoDispose<\${c}Controller, \${c}Model?>(
  \${c}Controller.new,
);
""";

String _repositoryTemplate(String c, String m, String p, String f) => """import 'package:\$p/core/utils/constants/imports.dart';

abstract class I\${c}Repository {
  Future<\${c}Model?> fetchData();
}

class \${c}Repository implements I\${c}Repository {
  final Dio _dio;
  \${c}Repository(this._dio);

  Dio get dio => _dio;

  @override
  Future<\${c}Model?> fetchData() async {
    // Example API call:
    // final response = await _dio.get('/api/\${f}');
    return const \${c}Model(id: '1', title: '\${c} Data Loaded');
  }
}

final \${m}RepositoryProvider = Provider.autoDispose<I\${c}Repository>((ref) {
  final dio = ref.watch(dioProvider);
  return \${c}Repository(dio);
});
""";

String _modelTemplate(String c, String f) {
  const d = '\\\$';
  return """import 'package:freezed_annotation/freezed_annotation.dart';

part '\${f}_model.freezed.dart';
part '\${f}_model.g.dart';

@freezed
abstract class \${c}Model with _\${d}\${c}Model {
  const factory \${c}Model({
    required String id,
    required String title,
  }) = _\${c}Model;

  factory \${c}Model.fromJson(Map<String, dynamic> json) =>
      _\${d}\${c}ModelFromJson(json);
}
""";
}

String _widgetTemplate(String c, String m, String p, String f) => """import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:\$p/core/utils/constants/colors.dart';
import '../models/\${f}_model.dart';

class \${c}Widget extends StatelessWidget {
  final \${c}Model? data;

  const \${c}Widget({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.widgets_outlined,
              size: 48.r,
              color: AppColors.primary,
            ),
            SizedBox(height: 12.h),
            Text(
              data?.title ?? '\${c} module is active!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
""";
''');

  // ৪. pubspec.yaml create
  print('Step 4: Writing a clean and structured pubspec.yaml (Auto-detecting SDK)...');

  final pubspecFile = File('pubspec.yaml');

  final String newPubspecContent = '''name: $projectName
description: "A production-grade Flutter & Riverpod architecture for $projectName."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

# RPS Scripts for automation
scripts:
  gen: flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs
  watch: dart run build_runner watch --delete-conflicting-outputs
  clean:android: "flutter clean && flutter pub get && cd android && ./gradlew clean && cd .."
  clean:ios: "flutter clean && flutter pub get && cd ios && rm -rf Podfile.lock && pod install && cd .."
  clean:flutter: flutter clean && flutter pub get
  clean:force: "flutter clean && rm -rf pubspec.lock && rm -rf ios/Pods ios/Podfile.lock && rm -rf android/.gradle android/app/build && flutter pub get && cd ios && pod cache clean --all && pod deintegrate && pod setup && pod install && cd .."
  run:dev: flutter run --flavor dev
  run:prod: flutter run --flavor prod
  run: flutter run

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter_gen:
  output: lib/generated/assets/
  line_length: 100

flutter:
  generate: true
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/videos/
    - assets/animations/
    - assets/vectors/
    - .env

  # To use custom fonts, add .ttf files to assets/fonts/ and uncomment below:
  # fonts:
  #   - family: Roboto
  #     fonts:
  #       - asset: assets/fonts/Roboto-Regular.ttf
  #       - asset: assets/fonts/Roboto-Bold.ttf
  #         weight: 700
''';

  await pubspecFile.writeAsString(newPubspecContent);
  print('✅ pubspec.yaml generated successfully.');

  print('Step 5: Resolving & Installing dependencies for host environment ($currentDartVersion)...');
  final packages = [
    'flutter_riverpod',
    'riverpod_annotation',
    'freezed_annotation',
    'json_annotation',
    'go_router',
    'cupertino_icons',
    'flutter_screenutil',
    'google_fonts',
    'url_launcher',
    'intl',
    'logger',
    'video_player',
    'dio',
    'pretty_dio_logger',
    'connectivity_plus',
    'dio_smart_retry',
    'dio_cache_interceptor',
    'geolocator',
    'permission_handler',
    'location',
    'shared_preferences',
    'carousel_slider',
    'shimmer',
    'cached_network_image',
    'flutter_svg',
    'intl_phone_field',
    'webview_flutter',
    'image_picker',
    'file_picker',
    'lottie',
    'zo_animated_border',
    'firebase_core',
    'firebase_analytics',
    'firebase_crashlytics',
    'google_maps_flutter',
    'rps',
    'firebase_messaging',
    'flutter_dotenv',
  ];

  var batchResult = await Process.run('flutter', ['pub', 'add', ...packages], runInShell: true);
  if (batchResult.exitCode != 0) {
    print('⚠️ Batch install encountered environment constraints, resolving dynamically for this PC...');
    for (final pkg in packages) {
      final res = await Process.run('flutter', ['pub', 'add', pkg], runInShell: true);
      if (res.exitCode == 0) {
        print('   ✅ $pkg installed.');
      } else {
        print('   ⚠️ $pkg skipped (incompatible with host SDK).');
      }
    }
  } else {
    print('✅ All core packages successfully installed.');
  }

  final devPackages = [
    'flutter_lints',
    'change_app_package_name',
    'build_runner',
    'riverpod_generator',
    'freezed',
    'json_serializable',
    'flutter_gen_runner',
    'flutter_flavorizr',
  ];

  var devBatchResult = await Process.run('flutter', ['pub', 'add', '--dev', ...devPackages], runInShell: true);
  if (devBatchResult.exitCode != 0) {
    print('🔄 Dynamically resolving dev packages for this PC...');
    for (final pkg in devPackages) {
      final res = await Process.run('flutter', ['pub', 'add', '--dev', pkg], runInShell: true);
      if (res.exitCode == 0) {
        print('   ✅ $pkg (dev) installed.');
      } else {
        print('   ⚠️ $pkg (dev) skipped.');
      }
    }
  } else {
    print('✅ All dev packages successfully installed.');
  }

  print('🔄 Verifying dependencies with "flutter pub get"...');
  await Process.run('flutter', ['pub', 'get'], runInShell: true);

  // ৬. RPS global activate
  print('Step 6: Activating RPS globally...');
  await Process.run('dart', [
    'pub',
    'global',
    'activate',
    'rps',
  ], runInShell: true);

  // main.dart
  print('📝 Writing lib/main.dart (Riverpod ProviderScope)...');
  File('lib/main.dart').writeAsStringSync('''import 'core/utils/constants/imports.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Pre-initialize async singletons
  final sharedPreferences = await SharedPreferences.getInstance();
  LocalStorageService.initSync(sharedPreferences);

  // Initialize Dio
  await DioHelper().init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}
''');

  // App.dart
  print('📝 Writing lib/app.dart (ConsumerWidget + GoRouter + Connectivity Banner + Theme & Locale)...');
  File('lib/app.dart').writeAsStringSync('''import 'core/utils/constants/imports.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp.router(
          title: '$projectName',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: AppNavigation.scaffoldMessengerKey,
          routerConfig: router,
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: locale,
          builder: (context, childWidget) {
            return ConnectivityBanner(
              child: childWidget ?? const SizedBox.shrink(),
            );
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('bn', 'BD'),
          ],
        );
      },
    );
  }
}
''');

  print('Step 7: Generating Riverpod Clean Architecture Folders...');

  final libFolders = [
    'lib/l10n',
    'lib/core',
    'lib/core/router',
    'lib/core/common',
    'lib/core/common/widgets',
    'lib/core/common/styles',
    'lib/core/localization',
    'lib/core/network',
    'lib/core/services',
    'lib/core/theme',
    'lib/core/theme/custom_theme',
    'lib/core/utils',
    'lib/core/utils/constants',
    'lib/core/utils/device',
    'lib/core/utils/formatters',
    'lib/core/utils/helpers',
    'lib/core/utils/logging',
    'lib/core/utils/navigation',
    'lib/core/utils/validators',
    'lib/features',
    'lib/features/splash',
    'lib/features/splash/views',
    'lib/features/splash/widgets',
    'lib/features/splash/controllers',
    'lib/features/splash/models',
    'lib/features/splash/repositories',
  ];
  for (var folder in libFolders) {
    await Directory(folder).create(recursive: true);
  }

  print('📝 Writing files into folders...');

  // ARB Files (Localization)
  File('lib/l10n/app_en.arb').writeAsStringSync('''{
  "appName": "$projectName",
  "welcomeMessage": "Welcome to $projectName",
  "helloWorld": "Hello World!"
}
''');

  File('lib/l10n/app_bn.arb').writeAsStringSync('''{
  "appName": "প্রজেক্ট $projectName",
  "welcomeMessage": "$projectName প্রজেক্টে আপনাকে স্বাগতম",
  "helloWorld": "হ্যালো ওয়ার্ল্ড!"
}
''');

  // Router: AppRoutes
  print('--- Core Router generating... ---');
  File('lib/core/router/app_routes.dart').writeAsStringSync('''abstract class AppRoutes {
  static const String splash = "/";
  static const String splashName = "splash";
  static const String login = "/login";
  static const String loginName = "login";
}
''');

  // Router: AppRouter (GoRouter Provider)
  File('lib/core/router/app_router.dart').writeAsStringSync('''import 'package:$projectName/core/utils/constants/imports.dart';
// --- [FEATURE_IMPORTS] ---

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: AppNavigation.rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashView(),
      ),
      // --- [FEATURE_ROUTES] ---
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: \${state.uri}'),
      ),
    ),
  );
});
''');

  // AppNavigation helper (Context-safe navigation & overlays)
  File('lib/core/utils/navigation/app_navigation.dart').writeAsStringSync('''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNavigation {
  AppNavigation._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(debugLabel: 'scaffoldMessenger');

  static BuildContext? get currentContext => rootNavigatorKey.currentContext;

  static void go(String routeName, {Object? extra}) {
    rootNavigatorKey.currentContext?.go(routeName, extra: extra);
  }

  static void push(String routeName, {Object? extra}) {
    rootNavigatorKey.currentContext?.push(routeName, extra: extra);
  }

  static void pop<T extends Object?>([T? result]) {
    if (rootNavigatorKey.currentContext != null &&
        Navigator.of(rootNavigatorKey.currentContext!).canPop()) {
      Navigator.of(rootNavigatorKey.currentContext!).pop(result);
    }
  }
}
''');

  // Splash Module (Riverpod)
  print('--- Splash Module generating... ---');
  File('lib/features/splash/widgets/splash_content_widget.dart').writeAsStringSync('''import 'package:flutter/material.dart';
import 'package:$projectName/core/common/styles/global_text_style.dart';

class SplashContentWidget extends StatelessWidget {
  final String text;
  const SplashContentWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.rocket_launch_rounded, size: 64, color: Colors.blueAccent),
          const SizedBox(height: 16),
          Text(
            text,
            style: GlobalTextStyle.heading,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
''');

  File('lib/features/splash/views/splash_view.dart').writeAsStringSync('''import 'package:$projectName/core/utils/constants/imports.dart';
import '../widgets/splash_content_widget.dart';

class SplashView extends ConsumerWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(splashControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SplashView')),
      body: SplashContentWidget(text: state.message),
    );
  }
}
''');

  File('lib/features/splash/controllers/splash_controller.dart').writeAsStringSync('''import 'package:$projectName/core/utils/constants/imports.dart';

class SplashState {
  final String message;
  final bool isLoading;

  const SplashState({
    this.message = 'SplashView is working with Riverpod',
    this.isLoading = false,
  });

  SplashState copyWith({
    String? message,
    bool? isLoading,
  }) {
    return SplashState(
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SplashController extends Notifier<SplashState> {
  late final SplashRepository _repository;
  SplashRepository get repository => _repository;

  @override
  SplashState build() {
    _repository = ref.watch(splashRepositoryProvider);
    return const SplashState();
  }

  // Add splash redirects or initialization logic here
}

final splashControllerProvider =
    NotifierProvider.autoDispose<SplashController, SplashState>(
  SplashController.new,
);
''');

  File('lib/features/splash/repositories/splash_repository.dart').writeAsStringSync('''import 'package:$projectName/core/utils/constants/imports.dart';

class SplashRepository {
  final Dio _dio;
  SplashRepository(this._dio);

  Dio get dio => _dio;

  // Add API calls here
}

final splashRepositoryProvider = Provider.autoDispose<SplashRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SplashRepository(dio);
});
''');

  File('lib/features/splash/models/splash_model.dart').writeAsStringSync('''import 'package:freezed_annotation/freezed_annotation.dart';

part 'splash_model.freezed.dart';
part 'splash_model.g.dart';

@freezed
abstract class SplashModel with _\$SplashModel {
  const factory SplashModel({
    required String id,
  }) = _SplashModel;

  factory SplashModel.fromJson(Map<String, dynamic> json) =>
      _\$SplashModelFromJson(json);
}
''');

  // Localization Extension & Provider
  print('--- Localization generating... ---');
  File('lib/core/localization/localization_extension.dart').writeAsStringSync('''import 'package:flutter/material.dart';
import 'package:$projectName/generated/l10n/app_localizations.dart';

extension LocalizationExtension on BuildContext {
  AppLocalizations get tr => AppLocalizations.of(this)!;
}
''');

  File('lib/core/localization/locale_provider.dart').writeAsStringSync('''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final storage = ref.watch(storageServiceProvider);
    final savedCode = storage.languageCode;
    return savedCode != null ? Locale(savedCode) : const Locale('en', 'US');
  }

  Future<void> changeLanguage(String languageCode) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveLanguageCode(languageCode);
    state = Locale(languageCode);
  }

  Future<void> resetToEnglish() async {
    await changeLanguage('en');
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
''');

  // Theme Provider
  print('--- Theme Provider generating... ---');
  File('lib/core/theme/theme_provider.dart').writeAsStringSync('''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final storage = ref.read(storageServiceProvider);
    final isDark = state == ThemeMode.dark;
    await storage.saveDarkMode(!isDark);
    state = !isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveDarkMode(mode == ThemeMode.dark);
    state = mode;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
''');

  // Network: DioProvider & DioHelper
  print('--- Network Dio Provider with Retry & Auth generating... ---');
  File('lib/core/network/dio_provider.dart').writeAsStringSync('''import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../router/app_routes.dart';
import '../services/storage_service.dart';
import '../utils/constants/api_constants.dart';
import '../utils/logging/logger.dart';
import '../utils/navigation/app_navigation.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.apiUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 15),
      receiveDataWhenStatusError: true,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // 1. Pretty Dio Logger
  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      error: true,
      compact: false,
    ),
  );

  // 2. Smart Retry Interceptor (Auto retry on transient network drops)
  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      logPrint: AppLoggerHelper.warning,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
    ),
  );

  // 3. Auth Token & Connectivity Interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final connectivity = await Connectivity().checkConnectivity();
        final bool isOffline = connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty;
        if (isOffline) {
          AppLoggerHelper.error('No Internet! Request blocked.');
          return handler.reject(DioException(requestOptions: options));
        }

        // Auto inject Bearer token if present
        final token = LocalStorageService.instance.accessToken;
        if (token != null && token.isNotEmpty && !options.headers.containsKey('Authorization')) {
          options.headers['Authorization'] = 'Bearer \$token';
        }

        AppLoggerHelper.info("→ \${options.method} \${options.uri}");
        handler.next(options);
      },
      onError: (err, handler) {
        if (err.response?.statusCode == 401) {
          AppLoggerHelper.warning(
            "401 Unauthorized detected! Redirecting to login...",
          );
          LocalStorageService.instance.clearAuth();
          AppNavigation.go(AppRoutes.login);
          return handler.reject(err);
        }
        AppLoggerHelper.error("✗ Error: \${err.message}");
        handler.next(err);
      },
    ),
  );

  return dio;
});
''');

  File('lib/core/network/dio_helper.dart').writeAsStringSync('''import '../utils/constants/imports.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

class DioHelper {
  static final DioHelper _instance = DioHelper._internal();
  factory DioHelper() => _instance;
  DioHelper._internal();

  late Dio dio;

  Future<void> init() async {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 15),
        receiveDataWhenStatusError: true,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: false,
      ),
    );

    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        logPrint: AppLoggerHelper.warning,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final connectivity = await Connectivity().checkConnectivity();
          final bool isOffline = connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty;
          if (isOffline) {
            AppLoggerHelper.error('No Internet! Request blocked.');
            return handler.reject(DioException(requestOptions: options));
          }

          final token = LocalStorageService.instance.accessToken;
          if (token != null && token.isNotEmpty && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer \$token';
          }

          AppLoggerHelper.info("→ \${options.method} \${options.uri}");
          handler.next(options);
        },
        onError: (err, handler) {
          if (err.response?.statusCode == 401) {
            AppLoggerHelper.warning(
              "401 Unauthorized detected! Redirecting to login...",
            );
            LocalStorageService.instance.clearAuth();
            AppNavigation.go(AppRoutes.login);
            return handler.reject(err);
          }
          AppLoggerHelper.error("✗ Error: \${err.message}");
          handler.next(err);
        },
      ),
    );
  }
}
''');

  // Network: HttpMethod
  File('lib/core/network/http_method.dart').writeAsStringSync('''import '../utils/constants/imports.dart';

class HttpMethod {
  final Dio _dio;

  HttpMethod([Dio? dio]) : _dio = dio ?? DioHelper().dio;

  Map<String, dynamic> headers = {'Authorization': 'Bearer your_token'};

  // GET
  Future<dynamic> get({
    required String path,
    Map<String, dynamic>? queryParameters,
    bool isAuthRequired = false,
    CancelToken? cancelToken,
    String? customUrl,
  }) async {
    try {
      final String url = customUrl != null ? "\$customUrl\$path" : path;
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: isAuthRequired ? Options(headers: headers) : null,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST
  Future<dynamic> post({
    required String path,
    required Map<String, dynamic> data,
    bool isAuthRequired = false,
    CancelToken? cancelToken,
    String? customUrl,
  }) async {
    try {
      final String url = customUrl != null ? "\$customUrl\$path" : path;
      final response = await _dio.post(
        url,
        data: data,
        options: isAuthRequired ? Options(headers: headers) : null,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT
  Future<dynamic> put({
    required String path,
    required Map<String, dynamic> data,
    bool isAuthRequired = false,
    CancelToken? cancelToken,
    String? customUrl,
  }) async {
    try {
      final String url = customUrl != null ? "\$customUrl\$path" : path;
      final response = await _dio.put(
        url,
        data: data,
        options: isAuthRequired ? Options(headers: headers) : null,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH
  Future<dynamic> patch({
    required String path,
    required Map<String, dynamic> data,
    bool isAuthRequired = false,
    CancelToken? cancelToken,
    String? customUrl,
  }) async {
    try {
      final String url = customUrl != null ? "\$customUrl\$path" : path;
      final response = await _dio.patch(
        url,
        data: data,
        options: isAuthRequired ? Options(headers: headers) : null,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE
  Future<dynamic> delete({
    required String path,
    Map<String, dynamic>? data,
    bool isAuthRequired = false,
    CancelToken? cancelToken,
    String? customUrl,
  }) async {
    try {
      final String url = customUrl != null ? "\$customUrl\$path" : path;
      final response = await _dio.delete(
        url,
        data: data,
        options: isAuthRequired ? Options(headers: headers) : null,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error Handling
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final message =
          e.response?.data['error'] ??
          e.response?.statusMessage ??
          'Unknown error';
      AppLoggerHelper.error('Error Message: \$message');
      AppHelperFunctions.showSnackBar("Error: \$message");
      return Exception('\$message (Status: \${e.response?.statusCode})');
    } else {
      final message = e.message ?? 'Network error';
      AppLoggerHelper.error('Network Error: \$message');
      AppHelperFunctions.showSnackBar("Network Error: \$message");
      return Exception('Network error: \$message');
    }
  }
}

final httpMethodProvider = Provider<HttpMethod>((ref) {
  final dio = ref.watch(dioProvider);
  return HttpMethod(dio);
});
''');

  // Services: Storage
  print('--- Storage Service generating... ---');
  File('lib/core/services/storage_service.dart').writeAsStringSync('''import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart via ProviderScope overrides');
});

final storageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

class LocalStorageService {
  final SharedPreferences _prefs;
  LocalStorageService(this._prefs);

  static LocalStorageService? _instance;
  static LocalStorageService get instance {
    if (_instance == null) {
      throw StateError('LocalStorageService not initialized');
    }
    return _instance!;
  }

  static void initSync(SharedPreferences prefs) {
    _instance = LocalStorageService(prefs);
  }

  Future<bool> setString(String key, String value) async =>
      await _prefs.setString(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setInt(String key, int value) async =>
      await _prefs.setInt(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> setBool(String key, bool value) async =>
      await _prefs.setBool(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setDouble(String key, double value) async =>
      await _prefs.setDouble(key, value);

  double? getDouble(String key) => _prefs.getDouble(key);

  Future<bool> remove(String key) async => await _prefs.remove(key);

  Future<bool> clearAll() async => await _prefs.clear();

  Future<void> saveAccessToken(String token) async =>
      await setString('access_token', token);

  String? get accessToken => getString('access_token');

  Future<void> clearAuth() async => await remove('access_token');

  Future<void> saveDarkMode(bool isDark) async =>
      await setBool('is_dark_mode', isDark);

  bool get isDarkMode => getBool('is_dark_mode') ?? false;

  Future<void> saveLanguageCode(String langCode) async =>
      await setString('language_code', langCode);

  String? get languageCode => getString('language_code') ?? 'en';

  Future<void> setOnboardingCompleted() async =>
      await setBool('onboarding_completed', true);

  bool get isOnboardingCompleted => getBool('onboarding_completed') ?? false;
}
''');

  // Services: Network Service (Riverpod Reactive)
  print('--- Network Service generating... ---');
  File('lib/core/services/network_service.dart').writeAsStringSync('''import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isConnectedProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield _isOnline(initial);

  await for (final event in connectivity.onConnectivityChanged) {
    yield _isOnline(event);
  }
});

bool _isOnline(dynamic result) {
  if (result is List) {
    return !result.contains(ConnectivityResult.none) && result.isNotEmpty;
  } else if (result is ConnectivityResult) {
    return result != ConnectivityResult.none;
  }
  return true;
}

class NetworkService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return _isOnline(result);
  }
}

final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});
''');

  // Services: Location
  print('--- Location Service generating... ---');
  File('lib/core/services/location_service.dart').writeAsStringSync('''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants/colors.dart';
import '../utils/logging/logger.dart';
import '../utils/navigation/app_navigation.dart';

class LocationService {
  final loc.Location _location = loc.Location();
  Position? currentPosition;

  Future<Position?> checkAndRequestLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      await _showCustomEnableLocationDialog();
      return null;
    }

    final permission = await Permission.location.request();

    if (permission.isDenied || permission.isPermanentlyDenied) {
      await _showCustomPermissionDialog();
      return null;
    }

    Position currentPos = await Geolocator.getCurrentPosition();
    currentPosition = currentPos;
    AppLoggerHelper.debug(
      'Location: \${currentPos.latitude}, \${currentPos.longitude}',
    );
    return currentPos;
  }

  Future<void> _showCustomEnableLocationDialog() async {
    final context = AppNavigation.currentContext;
    if (context == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.white,
        title: const Text(
          'Location Services Disabled',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'To use location features, please enable Location Services in your device settings.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    await Future.delayed(const Duration(seconds: 1));
    await checkAndRequestLocation();
  }

  Future<void> _showCustomPermissionDialog() async {
    final context = AppNavigation.currentContext;
    if (context == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.white,
        title: const Text(
          'Permission Required',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This app needs location permission. Please enable it in Settings.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    await Future.delayed(const Duration(seconds: 1));
    await checkAndRequestLocation();
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
''');

  // Services: Media
  print('--- Media Service generating... ---');
  File('lib/core/services/media_service.dart').writeAsStringSync('''import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/logging/logger.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromGallery({int imageQuality = 80}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );
      if (image != null) return File(image.path);
    } catch (e) {
      AppLoggerHelper.error('Error picking image from gallery: \$e');
    }
    return null;
  }

  Future<File?> pickImageFromCamera({int imageQuality = 80}) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
      );
      if (photo != null) return File(photo.path);
    } catch (e) {
      AppLoggerHelper.error('Error taking photo: \$e');
    }
    return null;
  }

  Future<File?> pickDocument({List<String>? allowedExtensions}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
      );
      if (result.isNotEmpty && result.first.path != null) {
        return File(result.first.path!);
      }
    } catch (e) {
      AppLoggerHelper.error('Error picking file: \$e');
    }
    return null;
  }
}
''');

  // Services: Notification
  print('--- Notification Service generating... ---');
  File('lib/core/services/notification_service.dart').writeAsStringSync('''import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/logging/logger.dart';
import '../utils/helpers/app_helper.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLoggerHelper.info('Notification permission granted.');
      // ignore: deprecated_member_use
      String? token = await _fcm.getToken();
      AppLoggerHelper.info('FCM Token: \$token');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLoggerHelper.debug('Foreground message: \${message.data}');
        if (message.notification != null) {
          AppHelperFunctions.showSnackBar(
            message.notification!.title ?? 'New Notification',
          );
        }
      });
    } else {
      AppLoggerHelper.warning('Notification permission declined.');
    }
  }
}
''');

  // Services: Analytics & Crashlytics
  print('--- Analytics & Crashlytics Services generating... ---');
  File('lib/core/services/analytics_service.dart').writeAsStringSync('''import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }
}
''');

  File('lib/core/services/crashlytics_service.dart').writeAsStringSync('''import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  static void init() {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static void recordError(dynamic error, StackTrace? stack, {String? reason}) {
    FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
  }
}
''');

  // Themes
  print('--- Theme configuration generating... ---');
  File('lib/core/theme/theme.dart').writeAsStringSync('''import 'package:flutter/material.dart';
import 'custom_theme/app_bar_theme.dart';
import 'custom_theme/elevated_button_theme.dart';
import 'custom_theme/text_field_theme.dart';
import 'custom_theme/text_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: Colors.red,
    scaffoldBackgroundColor: Colors.white,
    textTheme: AppTextTheme.lightTextTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.lightElevatedButtonTheme,
    appBarTheme: CustomAppBarTheme.lightAppBarTheme,
    inputDecorationTheme: AppTextFormFieldTheme.lightInputDecorationTheme,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: Colors.red,
    scaffoldBackgroundColor: Colors.black,
    textTheme: AppTextTheme.darkTextTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.darkElevatedButtonTheme,
    appBarTheme: CustomAppBarTheme.darkAppBarTheme,
    inputDecorationTheme: AppTextFormFieldTheme.darkInputDecorationTheme,
  );
}
''');

  File('lib/core/theme/custom_theme/text_theme.dart').writeAsStringSync('''import 'package:flutter/material.dart';

class AppTextTheme {
  AppTextTheme._();

  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold, color: Colors.black),
    displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.w600, color: Colors.black87),
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.w500, color: Colors.black87),
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black),
    headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w600, color: Colors.black87),
    headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500, color: Colors.black87),
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600, color: Colors.black87),
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.black87),
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: Colors.black87),
    bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal, color: Colors.black87),
    bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: Colors.black54),
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: Colors.black54),
    labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500, color: Colors.black45),
  );

  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold, color: Colors.white),
    displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.w600, color: Colors.white70),
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.w500, color: Colors.white70),
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
    headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w600, color: Colors.white70),
    headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500, color: Colors.white70),
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600, color: Colors.white70),
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.white70),
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: Colors.white70),
    bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal, color: Colors.white70),
    bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal, color: Colors.white60),
    bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: Colors.white54),
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: Colors.white60),
    labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500, color: Colors.white54),
  );
}
''');

  File('lib/core/theme/custom_theme/elevated_button_theme.dart').writeAsStringSync('''import 'package:flutter/material.dart';

class AppElevatedButtonTheme {
  AppElevatedButtonTheme._();

  static final ElevatedButtonThemeData lightElevatedButtonTheme =
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: Colors.red,
          disabledForegroundColor: Colors.grey,
          disabledBackgroundColor: Colors.grey.shade300,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: const TextStyle(
            fontSize: 16.0,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  static final ElevatedButtonThemeData darkElevatedButtonTheme =
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: Colors.red,
          disabledForegroundColor: Colors.grey,
          disabledBackgroundColor: Colors.grey.shade700,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: const TextStyle(
            fontSize: 16.0,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
''');

  File('lib/core/theme/custom_theme/text_field_theme.dart').writeAsStringSync('''import 'package:flutter/material.dart';

class AppTextFormFieldTheme {
  AppTextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: Colors.grey,
    suffixIconColor: Colors.grey,
    labelStyle: const TextStyle().copyWith(fontSize: 14, color: Colors.black87),
    hintStyle: const TextStyle().copyWith(fontSize: 14, color: Colors.black38),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal),
    floatingLabelStyle: const TextStyle().copyWith(color: Colors.black.withValues(alpha: 0.8)),
    border: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.grey),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.grey),
    ),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.black12),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.red),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2, color: Colors.orange),
    ),
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: Colors.grey,
    suffixIconColor: Colors.grey,
    labelStyle: const TextStyle().copyWith(fontSize: 14, color: Colors.white),
    hintStyle: const TextStyle().copyWith(fontSize: 14, color: Colors.white38),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal),
    floatingLabelStyle: const TextStyle().copyWith(color: Colors.white.withValues(alpha: 0.8)),
    border: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.grey),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.grey),
    ),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.white),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.red),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2, color: Colors.orange),
    ),
  );
}
''');

  File('lib/core/theme/custom_theme/app_bar_theme.dart').writeAsStringSync('''import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBarTheme {
  CustomAppBarTheme._();

  static const lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: Colors.black, size: 24),
    actionsIconTheme: IconThemeData(color: Colors.black, size: 24),
    titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600, color: Colors.black),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );

  static const darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: Colors.white, size: 24),
    actionsIconTheme: IconThemeData(color: Colors.white, size: 24),
    titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600, color: Colors.white),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );
}
''');

  // Core Utilities: Constants
  print('--- Core Constants generating... ---');
  File('lib/core/utils/constants/animation_path.dart').writeAsStringSync('''class AnimationPath {
  AnimationPath._();
  static const String splashAnimation = 'assets/animations/splash.json';
}
''');

  File('lib/core/utils/constants/api_constants.dart').writeAsStringSync('''import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();
  static String apiUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.example.com';
}
''');

  File('lib/core/utils/constants/app_text.dart').writeAsStringSync('''class AppText {
  AppText._();
  static const String appName = "$projectName";
}
''');

  File('lib/core/utils/constants/colors.dart').writeAsStringSync('''import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF6200EE);
  static const Color primaryVariant = Color(0xFF3700B3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color background = Color(0xFFF5F5F5);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color red = Colors.red;
}
''');

  File('lib/core/utils/constants/enums.dart').writeAsStringSync('''enum Status { initial, loading, success, error }
''');

  File('lib/core/utils/constants/icon_path.dart').writeAsStringSync('''class IconPath {
  IconPath._();
  static const String appIcon = 'assets/icons/app_icon.png';
}
''');

  File('lib/core/utils/constants/image_path.dart').writeAsStringSync('''class ImagePath {
  ImagePath._();
  static const String logo = 'assets/images/logo.png';
}
''');

  File('lib/core/utils/constants/music_path.dart').writeAsStringSync('''class MusicPath {
  MusicPath._();
}
''');

  File('lib/core/utils/constants/video_path.dart').writeAsStringSync('''class VideoPath {
  VideoPath._();
}
''');

  // Core Utilities: Device, Formatters, Helpers, Logging, Validators
  print('--- Core Utilities generating... ---');
  File('lib/core/utils/device/device_utility.dart').writeAsStringSync('''import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigation/app_navigation.dart';

class DeviceUtility {
  DeviceUtility._();

  static BuildContext? get _context => AppNavigation.currentContext;

  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  static void setStatusBarColor(Color color) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: color),
    );
  }

  static bool isLandscapeOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortraitOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static void setFullScreen(bool enable) {
    SystemChrome.setEnabledSystemUIMode(
      enable ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  static double getScreenHeight([BuildContext? context]) {
    final ctx = context ?? _context;
    return ctx != null ? MediaQuery.of(ctx).size.height : 0.0;
  }

  static double getScreenWidth([BuildContext? context]) {
    final ctx = context ?? _context;
    return ctx != null ? MediaQuery.of(ctx).size.width : 0.0;
  }

  static double getPixelRatio([BuildContext? context]) {
    final ctx = context ?? _context;
    return ctx != null ? MediaQuery.of(ctx).devicePixelRatio : 1.0;
  }

  static double getStatusBarHeight([BuildContext? context]) {
    final ctx = context ?? _context;
    return ctx != null ? MediaQuery.of(ctx).padding.top : 0.0;
  }

  static double getBottomNavigationBarHeight() {
    return kBottomNavigationBarHeight;
  }

  static double getAppBarHeight() {
    return kToolbarHeight;
  }

  static double getKeyboardHeight([BuildContext? context]) {
    final ctx = context ?? _context;
    if (ctx == null) return 0.0;
    return MediaQuery.of(ctx).viewInsets.bottom;
  }

  static Future<bool> isKeyboardVisible([BuildContext? context]) async {
    final ctx = context ?? _context;
    if (ctx == null) return false;
    return View.of(ctx).viewInsets.bottom > 0;
  }

  static Future<bool> isPhysicalDevice() async {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static void vibrate(Duration duration) {
    HapticFeedback.vibrate();
    Future.delayed(duration, () => HapticFeedback.vibrate());
  }
}
''');

  File('lib/core/utils/formatters/app_formatters.dart').writeAsStringSync('''import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static String formatDate(DateTime? date, {String format = 'dd-MMM-yyyy'}) {
    date ??= DateTime.now();
    return DateFormat(format).format(date);
  }

  static String formatCurrency(double amount, {String symbol = r'\$'}) {
    return NumberFormat.currency(locale: 'en_US', symbol: symbol).format(amount);
  }
}
''');

  File('lib/core/utils/helpers/app_helper.dart').writeAsStringSync('''import 'package:flutter/material.dart';
import '../navigation/app_navigation.dart';

class AppHelperFunctions {
  AppHelperFunctions._();

  static void showSnackBar(String message, {BuildContext? context}) {
    final ctx = context ?? AppNavigation.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
    } else {
      AppNavigation.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  static void showAlert(String title, String message, {BuildContext? context}) {
    final ctx = context ?? AppNavigation.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return '\${text.substring(0, maxLength)}...';
    }
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Size screenSize([BuildContext? context]) {
    final ctx = context ?? AppNavigation.currentContext;
    return ctx != null ? MediaQuery.of(ctx).size : Size.zero;
  }

  static double screenHeight([BuildContext? context]) {
    final ctx = context ?? AppNavigation.currentContext;
    return ctx != null ? MediaQuery.of(ctx).size.height : 0.0;
  }

  static double screenWidth([BuildContext? context]) {
    final ctx = context ?? AppNavigation.currentContext;
    return ctx != null ? MediaQuery.of(ctx).size.width : 0.0;
  }

  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }
}
''');

  File('lib/core/utils/logging/logger.dart').writeAsStringSync('''import 'package:logger/logger.dart';

class AppLoggerHelper {
  AppLoggerHelper._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  static void debug(String message) => _logger.d(message);
  static void info(String message) => _logger.i(message);
  static void warning(String message) => _logger.w(message);
  static void error(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
''');

  File('lib/core/utils/validators/app_validator.dart').writeAsStringSync('''class AppValidator {
  AppValidator._();

  static String? validateEmptyText(String? fieldName, String? value) {
    if (value == null || value.trim().isEmpty) {
      return '\$fieldName is required.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required.';
    }
    final emailRegExp = RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Invalid email address.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }
}
''');

  // Common Widgets & Styles
  print('--- Common Widgets & Styles generating... ---');
  File('lib/core/common/styles/global_text_style.dart').writeAsStringSync('''import 'package:flutter/material.dart';

class GlobalTextStyle {
  GlobalTextStyle._();

  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
}
''');

  // Non-blocking Connectivity Banner Widget
  File('lib/core/common/widgets/connectivity_banner.dart').writeAsStringSync('''import 'package:$projectName/core/utils/constants/imports.dart';

class ConnectivityBanner extends ConsumerWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isConnectedProvider).value ?? true;

    return Stack(
      children: [
        child,
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: isConnected ? -45.0 : 0.0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'No Internet Connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
''');

  File('lib/core/common/widgets/custom_warning_dialog_layout.dart').writeAsStringSync('''import 'package:$projectName/core/utils/constants/imports.dart';

class CustomWarningDialog extends StatelessWidget {
  final String message;
  final bool showOkButton;
  final bool barrierDismissible;
  final VoidCallback? onOkPressed;

  const CustomWarningDialog({
    super.key,
    required this.message,
    this.showOkButton = true,
    this.barrierDismissible = false,
    this.onOkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Card(
          elevation: 8,
          color: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (showOkButton) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onOkPressed ?? () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
''');

  File('lib/core/common/widgets/custom_bottom_sheet.dart').writeAsStringSync('''import 'package:$projectName/core/utils/constants/imports.dart';

Future<dynamic> showCustomBottomSheet({
  BuildContext? context,
  required List<Widget> contentWidgets,
  bool isDismissible = true,
  Color? backgroundColor,
  double topPadding = 20,
  double bottomPadding = 10,
}) async {
  final ctx = context ?? AppNavigation.currentContext;
  if (ctx == null) return null;

  return showModalBottomSheet(
    context: ctx,
    isDismissible: isDismissible,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => Container(
      margin: const EdgeInsets.all(12),
      width: double.infinity,
      child: Card(
        elevation: 8,
        color: backgroundColor ?? AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: backgroundColor ?? AppColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: SizedBox(
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => Navigator.of(modalContext).pop(),
                  child: const Icon(Icons.close, color: AppColors.white, size: 24),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 20,
                bottom: bottomPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: contentWidgets,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
''');

  // Central Imports File
  print('\n--- central imports file generating (Advanced Riverpod) ---');
  File('lib/core/utils/constants/imports.dart').writeAsStringSync('''// --- External Packages ---
export 'package:flutter/material.dart';
export 'package:flutter/foundation.dart';
export 'package:flutter/services.dart';
export 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:riverpod_annotation/riverpod_annotation.dart';
export 'package:freezed_annotation/freezed_annotation.dart';
export 'package:go_router/go_router.dart';
export 'package:dio/dio.dart';
export 'package:lottie/lottie.dart';
export 'package:connectivity_plus/connectivity_plus.dart';
export 'package:pretty_dio_logger/pretty_dio_logger.dart';
export 'package:flutter_dotenv/flutter_dotenv.dart';
export 'package:firebase_core/firebase_core.dart';
export 'package:firebase_messaging/firebase_messaging.dart';
export 'package:firebase_analytics/firebase_analytics.dart';
export 'package:firebase_crashlytics/firebase_crashlytics.dart';
export 'package:geolocator/geolocator.dart';
export 'package:flutter_screenutil/flutter_screenutil.dart';
export 'package:video_player/video_player.dart';
export 'package:google_fonts/google_fonts.dart';
export 'package:url_launcher/url_launcher_string.dart';
export 'package:logger/logger.dart';
export 'package:carousel_slider/carousel_slider.dart';
export 'package:shimmer/shimmer.dart';
export 'package:zo_animated_border/zo_animated_border.dart';
export 'package:cached_network_image/cached_network_image.dart';
export 'package:intl_phone_field/intl_phone_field.dart';
export 'package:flutter_localizations/flutter_localizations.dart';
export 'package:shared_preferences/shared_preferences.dart';

// --- Core App & Routing ---
export 'package:$projectName/app.dart';
export 'package:$projectName/core/router/app_routes.dart';
export 'package:$projectName/core/router/app_router.dart';
export 'package:$projectName/core/utils/navigation/app_navigation.dart';

// --- Core Providers & Services ---
export 'package:$projectName/core/network/dio_provider.dart';
export 'package:$projectName/core/network/dio_helper.dart';
export 'package:$projectName/core/network/http_method.dart';
export 'package:$projectName/core/services/media_service.dart';
export 'package:$projectName/core/services/notification_service.dart';
export 'package:$projectName/core/services/analytics_service.dart';
export 'package:$projectName/core/services/crashlytics_service.dart';
export 'package:$projectName/core/services/network_service.dart';
export 'package:$projectName/core/services/location_service.dart';
export 'package:$projectName/core/services/storage_service.dart';
export 'package:$projectName/core/localization/locale_provider.dart';
export 'package:$projectName/core/localization/localization_extension.dart';
export 'package:$projectName/core/theme/theme_provider.dart';

// --- Core Utilities & Constants ---
export 'package:$projectName/core/utils/logging/logger.dart';
export 'package:$projectName/core/utils/helpers/app_helper.dart';
export 'package:$projectName/core/utils/device/device_utility.dart';
export 'package:$projectName/core/utils/formatters/app_formatters.dart';
export 'package:$projectName/core/utils/validators/app_validator.dart';
export 'package:$projectName/core/utils/constants/colors.dart';
export 'package:$projectName/core/utils/constants/enums.dart';
export 'package:$projectName/core/utils/constants/video_path.dart';
export 'package:$projectName/core/utils/constants/music_path.dart';
export 'package:$projectName/core/utils/constants/api_constants.dart';
export 'package:$projectName/core/utils/constants/app_text.dart';
export 'package:$projectName/core/utils/constants/image_path.dart';
export 'package:$projectName/core/utils/constants/icon_path.dart';
export 'package:$projectName/core/utils/constants/animation_path.dart';
export 'package:$projectName/core/theme/theme.dart';
export 'package:$projectName/core/common/widgets/custom_warning_dialog_layout.dart';
export 'package:$projectName/core/common/widgets/custom_bottom_sheet.dart';
export 'package:$projectName/core/common/widgets/connectivity_banner.dart';

// --- Generated Files ---
export 'package:$projectName/generated/l10n/app_localizations.dart';

// --- Common Widgets & Styles ---
export 'package:$projectName/core/common/styles/global_text_style.dart';

// --- Splash Module ---
export 'package:$projectName/features/splash/views/splash_view.dart';
export 'package:$projectName/features/splash/controllers/splash_controller.dart';
export 'package:$projectName/features/splash/repositories/splash_repository.dart';
export 'package:$projectName/features/splash/models/splash_model.dart';
''');

  // Overwriting default test/widget_test.dart to prevent import & ProviderScope errors
  final testFile = File('test/widget_test.dart');
  if (testFile.existsSync()) {
    testFile.writeAsStringSync('''import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:$projectName/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  });
}
''');
  }

  // Step 7: Automated Initial Codegen (Freezed & Localization)
  print('Step 7: Running automated initial codegen (Freezed & Localization)...');
  await Process.run('flutter', ['gen-l10n'], runInShell: true);
  final initialCodegen = await Process.run('dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs'], runInShell: true);
  if (initialCodegen.exitCode == 0) {
    print('   ✅ Initial Freezed models generated successfully.');
  } else {
    print('   ℹ️  Note: You can run "dart run rps gen" after setup if needed.');
  }

  // --- SUCCESS MESSAGE & INSTRUCTIONS ---
  print('\n' + '=' * 60);
  print('🏁  ADVANCED RIVERPOD STARTER ARCHITECTURE IS READY!');
  print('   © 2026 | devmarufurrahman');
  print('=' * 60);
  print('\n⚠️  IMPORTANT NEXT STEPS:');
  print('------------------------------------------------------------');
  print(' 1️⃣  cd $projectName');
  print(' 2️⃣  (Optional) Add custom fonts to assets/fonts/ & uncomment fonts in pubspec.yaml');
  print(' 3️⃣  dart run rps gen (or let create_feature.dart auto-generate)');
  print(' 4️⃣  flutter run');
  print('------------------------------------------------------------');
  print('⚡ Use "dart create_feature.dart <feature_name>" to auto-scaffold modules with Freezed & GoRouter.');
  print('⚡ Use "dart run rps watch" for continuous background code generation.');
  print('=' * 60 + '\n');
}

void _configureAndroidSdk() {
  print('Step 1b: Configuring Android compileSdk = 37 for modern plugins...');
  final ktsFile = File('android/app/build.gradle.kts');
  if (ktsFile.existsSync()) {
    String content = ktsFile.readAsStringSync();
    if (content.contains('compileSdk = flutter.compileSdkVersion')) {
      content = content.replaceFirst(
        'compileSdk = flutter.compileSdkVersion',
        'compileSdk = 37',
      );
    } else if (content.contains(RegExp(r'compileSdk\s*=\s*\d+'))) {
      content = content.replaceFirst(
        RegExp(r'compileSdk\s*=\s*\d+'),
        'compileSdk = 37',
      );
    }
    ktsFile.writeAsStringSync(content);
    print('   ✅ Configured android/app/build.gradle.kts (compileSdk = 37)');
  }

  final gradleFile = File('android/app/build.gradle');
  if (gradleFile.existsSync()) {
    String content = gradleFile.readAsStringSync();
    if (content.contains('compileSdk = flutter.compileSdkVersion')) {
      content = content.replaceFirst(
        'compileSdk = flutter.compileSdkVersion',
        'compileSdk = 37',
      );
    } else if (content.contains('compileSdkVersion flutter.compileSdkVersion')) {
      content = content.replaceFirst(
        'compileSdkVersion flutter.compileSdkVersion',
        'compileSdkVersion 37',
      );
    } else if (content.contains(RegExp(r'compileSdk(Version)?\s*=?\s*\d+'))) {
      content = content.replaceFirst(
        RegExp(r'compileSdk(Version)?\s*=?\s*\d+'),
        'compileSdk = 37',
      );
    }
    gradleFile.writeAsStringSync(content);
    print('   ✅ Configured android/app/build.gradle (compileSdk = 37)');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_preview_minus/device_preview_minus.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gtext/gtext.dart';
import 'package:yugtalk/Screens/Onboarding_Screen.dart';
import 'Modules/Authentication/Verification_Widget.dart';
import 'Screens/Home_Screen.dart';
import 'Screens/global_snackbar.dart';
import 'firebase_options.dart';
import 'Modules/Authentication/Authentication_Mod.dart';
import 'Screens/location_monitor.dart';
import '../Screens/storage_service.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  User? user = FirebaseAuth.instance.currentUser;

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  bool useDevicePreview = !kReleaseMode && kIsWeb;

  runApp(
    useDevicePreview
        ? DevicePreview(
            enabled: true,
            builder: (context) => App(initialUser: user),
          )
        : App(initialUser: user),
  );
}

class App extends StatelessWidget {
  final User? initialUser;
  final StorageService _storageService = StorageService();

  App({required this.initialUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        } else {
          final user = snapshot.data;
          if (user == null) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: GlobalSnackBar.key,
              home: FutureBuilder<bool>(
                future: _storageService.isFirstLaunch(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.data == true) {
                    // First launch, show onboarding
                    _storageService.setFirstLaunchComplete();
                    return const Onboarding_Screen();
                  } else {
                    // Not first launch, go to authentication
                    return const Authentication_Mod();
                  }
                },
              ),
              theme: ThemeData(
                brightness: Brightness.light,
                primarySwatch: Colors.deepPurple,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              darkTheme: ThemeData(
                //brightness: Brightness.dark,
                primarySwatch: Colors.deepPurple,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                  ),
                ),
              ),
            );
          } else {
            return UserSettingsWrapper(user: user);
          }
        }
      },
    );
  }
}

class UserSettingsWrapper extends StatefulWidget {
  final User user;

  const UserSettingsWrapper({Key? key, required this.user}) : super(key: key);

  @override
  _UserSettingsWrapperState createState() => _UserSettingsWrapperState();
}

class _UserSettingsWrapperState extends State<UserSettingsWrapper> {
  final LocationMonitor _locationMonitor = LocationMonitor();

  @override
  void initState() {
    super.initState();
    _setupLocationMonitoring();
    _loadData();
  }

  void _setupLocationMonitoring() {
    _locationMonitor.locationStream.listen((message) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: GText(message)),
      );
    });

    _locationMonitor.startMonitoring();
  }

  Future<void> _loadData() async {
    await _locationMonitor.loadLocationCounters();
    await _locationMonitor.loadLocationData();
    await _locationMonitor.loadEncryptedData();
    await _locationMonitor.startMonitoring();
  }

  @override
  void dispose() {
    _locationMonitor.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: widget.user.reload(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('userSettings')
              .doc(widget.user.email)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const MaterialApp(
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final String fontSize = data['fontSize'] ?? 'Small';
            final bool isDarkMode = data['DarkMode'] ?? false;
            final bool isTagalog = data['languagePreference'] ?? true;

            final Map<String, dynamic> userLocations = data['userLocations'] ?? {};
            if (userLocations.isNotEmpty) {
              _locationMonitor.updateLocations(userLocations);
            }

            if (isTagalog) {
              GText.init(to: 'tl', enableCaching: false);
            } else {
              GText.init(to: 'en', enableCaching: false);
            }

            const double baseFontSize = 14.7;
            double textSize = baseFontSize;
            switch (fontSize) {
              case 'Small':
                break;
              case 'Medium':
                textSize = baseFontSize * 1.25;
                break;
              case 'Large':
                textSize = baseFontSize * 1.5;
                break;
              default:
                break;
            }

            final TextTheme textTheme = TextTheme(
              bodyLarge: TextStyle(
                  fontSize: textSize,
                  color: isDarkMode ? Colors.white : Colors.black),
              bodyMedium: TextStyle(
                  fontSize: textSize,
                  color: isDarkMode ? Colors.white : Colors.black),
              displayLarge: TextStyle(
                  fontSize: textSize,
                  color: isDarkMode ? Colors.white : Colors.black),
              displayMedium: TextStyle(
                  fontSize: textSize,
                  color: isDarkMode ? Colors.white : Colors.black),
              displaySmall: TextStyle(
                  fontSize: textSize,
                  color: isDarkMode ? Colors.white : Colors.black),
              headlineMedium: TextStyle(
                  fontSize: textSize,
                  color: isDarkMode ? Colors.white : Colors.black),
              headlineSmall: TextStyle(
                  fontSize: textSize,
                  color: isDarkMode ? Colors.white : Colors.black),
              titleLarge: TextStyle(
                  fontSize: textSize,
                  color: isDarkMode ? Colors.white : Colors.black),
              titleMedium: TextStyle(
                  fontSize: textSize,
                  color: isDarkMode ? Colors.white : Colors.black),
              titleSmall: TextStyle(
                  fontSize: textSize,
                  color: isDarkMode ? Colors.white : Colors.black),
              bodySmall: TextStyle(
                  fontSize: textSize,
                  color: isDarkMode ? Colors.white : Colors.black),
              labelLarge: TextStyle(
                  fontSize: textSize,
                  color: isDarkMode ? Colors.white : Colors.black),
              labelSmall: TextStyle(
                  fontSize: textSize,
                  color: isDarkMode ? Colors.white : Colors.black),
            );

            return MaterialApp(
              title: 'YugTalk App',
              locale: DevicePreview.locale(context),
              builder: DevicePreview.appBuilder,
              scaffoldMessengerKey: _scaffoldMessengerKey,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: false,
                textTheme: textTheme,
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all<Color>(Colors.deepPurple),
                  ),
                ),
              ),
              darkTheme: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark().copyWith(
                  primary: Colors.deepPurple,
                ),
                textTheme: textTheme,
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all<Color>(Colors.white),
                  ),
                ),
              ),
              themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: widget.user.emailVerified ?
              const Home_Mod() : const Verification_Widget(),
            );
          },
        );
      },
    );
  }
}

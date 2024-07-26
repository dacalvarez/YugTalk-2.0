// Conditionally import the platform-specific implementation
export 'print_utilsio.dart' if (dart.library.html) 'print_utilsweb.dart';

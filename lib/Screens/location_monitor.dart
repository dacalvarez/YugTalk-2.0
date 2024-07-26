import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'global_snackbar.dart';

class LocationMonitor {
  static final LocationMonitor _instance = LocationMonitor._internal();
  factory LocationMonitor() => _instance;
  LocationMonitor._internal();

  static const double RADIUS_METERS = 250;
  Map<String, List<Map<String, dynamic>>> _locations = {};
  Map<String, bool> _isInside = {};
  StreamSubscription<ServiceStatus>? _serviceStatusStream;
  StreamSubscription<Position>? _positionStream;
  final _locationController = StreamController<String>.broadcast();
  Map<String, DateTime> _lastNotificationTime = {};
  bool _isMonitoring = false;
  Map<String, bool> _lastLocationState = {};
  Map<String, int> _locationCounters = {};
  Map<String, dynamic> _currentLocationData = {};

  Stream<String> get locationStream => _locationController.stream;

  void _showNotification(String locationType, bool isInside) {
    DateTime now = DateTime.now();
    bool? lastState = _lastLocationState[locationType];

    // Only show notification if the state has changed and enough time has passed
    if (lastState == null || lastState != isInside) {
      // Check if enough time has passed since the last notification
      DateTime? lastNotificationTime = _lastNotificationTime[locationType];
      if (lastNotificationTime == null || now.difference(lastNotificationTime).inSeconds >= 60) {
        String message = isInside
            ? "You've entered the $locationType area"
            : "You've left the $locationType area";
        _locationController.add(message);
        _lastNotificationTime[locationType] = now;
        _lastLocationState[locationType] = isInside;

        // Use GlobalSnackBar to show the notification
        GlobalSnackBar.show(message);
      }
    }
  }


  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }


  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    bool permissionGranted = await _checkLocationPermission();
    if (!permissionGranted) {
      return;
    }

    _isMonitoring = true;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      await _startPositionStream();
    }

    if (!kIsWeb) {
      _serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
        if (status == ServiceStatus.enabled) {
          _startPositionStream();
        } else {
          _stopPositionStream();
        }
      });
    }
  }

  Future<void> _startPositionStream() async {
    await _stopPositionStream();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen(
          (Position position) {
        checkLocation(LatLng(position.latitude, position.longitude));
      },
      onError: (error) {
        print("Error in position stream: $error");
      },
    );
  }

  Future<void> _stopPositionStream() async {
    if (_positionStream != null) {
      await _positionStream!.cancel();
      _positionStream = null;
    }
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    if (_serviceStatusStream != null) {
      await _serviceStatusStream!.cancel();
      _serviceStatusStream = null;
    }
    await _stopPositionStream();
  }

  void updateLocations(Map<String, dynamic> userLocations) {
    _locations.clear();
    userLocations.forEach((locationType, encodedLocations) {
      List<Map<String, dynamic>> decodedLocations = _decodeLocations(encodedLocations);
      _locations[locationType] = decodedLocations;
      _isInside[locationType] = false;
    });

    DateTime timestamp = DateTime.now();
    _saveEncryptedData(timestamp);
  }

  void _saveEncryptedData(DateTime timestamp) {
    Map<String, dynamic> dataToSave = {
      'currentLocation': _currentLocationData['currentLocation'] ?? {},
      'Home': _currentLocationData['Home'] ?? {},
      'School': _currentLocationData['School'] ?? {},
      'Clinic': _currentLocationData['Clinic'] ?? {},
      'timestamp': timestamp.toUtc().millisecondsSinceEpoch,
    };
    String jsonString = json.encode(dataToSave);
    print('Data to save: $jsonString');
    String encryptedData = _encryptData(jsonString);
    FirebaseFirestore.instance
        .collection('currentLocation')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .set({
      'currentLocation': encryptedData,
    }, SetOptions(merge: true));
  }

  String _encryptData(String data) {
    List<int> bytes = utf8.encode(data);
    return base64Url.encode(bytes);
  }

  String _decryptData(String encryptedData) {
    List<int> bytes = base64Url.decode(encryptedData);
    return utf8.decode(bytes);
  }

  Future<void> loadEncryptedData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('currentLocation')
          .doc(FirebaseAuth.instance.currentUser!.email)
          .get();

      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      String? encryptedData = data?['currentLocation'];

      if (encryptedData != null) {
        String decryptedData = _decryptData(encryptedData);
        Map<String, dynamic> loadedData = json.decode(decryptedData);

        _currentLocationData = {
          'currentLocation': loadedData['currentLocation'] ?? {},
          'Home': loadedData['Home'] ?? {},
          'School': loadedData['School'] ?? {},
          'Clinic': loadedData['Clinic'] ?? {},
        };

        print('Loaded current location data: $_currentLocationData');

        if (loadedData.containsKey('locations')) {
          _locations.clear();
          Map<String, dynamic> locationsData = loadedData['locations'];
          locationsData.forEach((key, value) {
            _locations[key] = (value as List).cast<Map<String, dynamic>>();
          });
          _isInside = {for (var key in _locations.keys) key: false};
          print('Loaded locations: $_locations');
        }
      } else {
        print('No encrypted data found.');
      }
    } catch (e) {
      print('Error loading encrypted data: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  void checkLocation(LatLng currentLocation) {
    _locations.forEach((locationType, locationList) {
      bool wasInside = _isInside[locationType] ?? false;
      bool isNowInside = false;

      for (var location in locationList) {
        LatLng locationLatLng = LatLng(
            location['latitude'] as double,
            location['longitude'] as double
        );
        double distance = calculateDistance(currentLocation, locationLatLng);

        if (distance <= RADIUS_METERS) {
          isNowInside = true;
          break;
        }
              }

      if (!wasInside && isNowInside) {
        _isInside[locationType] = true;
        _showNotification(locationType, true);
        _updateLocationData(locationType, true);
      } else if (wasInside && !isNowInside) {
        _isInside[locationType] = false;
        _showNotification(locationType, false);
        _updateLocationData(locationType, false);
      }
    });
  }

  void _updateLocationData(String locationType, bool isEntering) {
    DateTime now = DateTime.now();

    // Decrypt the existing data if it exists, or create a new map
    Map<String, dynamic> locationData;
    if (_currentLocationData.containsKey(locationType) && _currentLocationData[locationType] is String) {
      locationData = _decryptLocationData(_currentLocationData[locationType] as String);
    } else {
      locationData = {};
    }

    if (isEntering) {
      locationData['counter'] = (locationData['counter'] ?? 0) + 1;
      locationData['startTime'] = now.toIso8601String();
      locationData['endTime'] = null;
      locationData['duration'] = 0;
    } else {
      locationData['endTime'] = now.toIso8601String();
      if (locationData['startTime'] != null) {
        DateTime startTime = DateTime.parse(locationData['startTime']);
        Duration duration = now.difference(startTime);
        locationData['duration'] = duration.inSeconds;
      }
    }

    // Encrypt the updated location data
    String encryptedLocationData = _encryptLocationData(locationData);

    // Update the _currentLocationData with the encrypted data
    _currentLocationData[locationType] = encryptedLocationData;

    // Save the encrypted data to Firestore
    FirebaseFirestore.instance
        .collection('currentLocation')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .set({
      locationType: encryptedLocationData,
    }, SetOptions(merge: true));

    print('Updated Location Data for $locationType:');
    print(locationData);
  }

  String _encryptLocationData(Map<String, dynamic> data) {
    String jsonString = json.encode(data);
    return _encryptData(jsonString);
  }

  Map<String, dynamic> _decryptLocationData(String encryptedData) {
    String decryptedJson = _decryptData(encryptedData);
    return json.decode(decryptedJson);
  }

  Future<Map<String, dynamic>> getLocationData() async {
    await loadEncryptedData();
    Map<String, dynamic> decryptedData = {};
    _currentLocationData.forEach((key, value) {
      if (key != 'currentLocation') {
        decryptedData[key] = _decryptLocationData(value);
      } else {
        decryptedData[key] = value;
      }
    });
    return decryptedData;
  }

  Future<void> loadLocationData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('currentLocation')
          .doc(FirebaseAuth.instance.currentUser!.email)
          .get();

      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      if (data != null) {
        _currentLocationData = data;

        print('Loaded Location Data:');
        _currentLocationData.forEach((type, data) {
          print('$type: $data');
        });
      }
    } catch (e) {
      print('Error loading location data: $e');
    }
  }

  Future<void> loadLocationCounters() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('userSettings')
          .doc(FirebaseAuth.instance.currentUser!.email)
          .get();

      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      Map<String, dynamic>? counters = data?['locationCounters'] as Map<String, dynamic>?;

      if (counters != null) {
        _locationCounters = Map<String, int>.from(counters);

        // Print the loaded counters
        print('Loaded Location Counters:');
        _locationCounters.forEach((type, count) {
          print('$type: $count');
        });
      }
    } catch (e) {
      print('Error loading location counters: $e');
    }
  }
}

  List<Map<String, dynamic>> _decodeLocations(String encodedLocations) {
    List<int> bytes = base64Url.decode(encodedLocations);
    String jsonString = utf8.decode(bytes);
    return (json.decode(jsonString) as List).cast<Map<String, dynamic>>();
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }
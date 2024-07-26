import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yugtalk/Modules/Authentication/Authentication_Mod.dart';
import 'package:yugtalk/Screens/AboutUs_Screen.dart';
import 'package:yugtalk/Screens/Account_Screen.dart';
import 'package:yugtalk/Screens/Home_Screen.dart';
import 'package:yugtalk/Screens/Settings_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({Key? key}) : super(key: key);

  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  bool _showLocation = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  String _currentLocation = 'Unknown';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    print('Checking location permission');
    var status = await Permission.location.status;
    setState(() {
      _showLocation = status.isGranted;
    });
    if (_showLocation) {
      _startLocationStream();
    } else {
      // Request permission if not granted
      if (await Permission.location.request().isGranted) {
        setState(() {
          _showLocation = true;
        });
        _startLocationStream();
      }
    }
    if (await Permission.locationAlways.isDenied) {
      await Permission.locationAlways.request();
    }
  }

  void _startLocationStream() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
          (Position position) {
        print('Received position update: ${position.latitude}, ${position.longitude}');
        _updateLocation(position);
      },
      onError: (error) {
        print('Error in location stream: $error');
        if (error is LocationServiceDisabledException) {
          // Handle case where location services are disabled
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: GText('Please enable location services')),
          );
        }
      },
    );
  }

  Future<void> _updateLocation(Position position) async {
    try {
      if (!mounted) return;

      LatLng currentPosition = LatLng(position.latitude, position.longitude);
      String locationType = await _checkCurrentLocation(currentPosition);

      await _updateFirestoreLocation(position, locationType);

      setState(() {
        _currentLocation = locationType;
        print('Updated current location to: $_currentLocation');
      });
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Future<void> _updateFirestoreLocation(Position position, String locationType) async {
    DateTime timestamp = DateTime.now();
    Map<String, dynamic> locationData = {
      'currentLocation': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': timestamp.toUtc().millisecondsSinceEpoch,
        'locationType': locationType,
      },
      'Home': {},
      'School': {},
      'Clinic': {},
      'timestamp': timestamp.toUtc().millisecondsSinceEpoch,
    };

    String encryptedLocation = base64Url.encode(utf8.encode(json.encode(locationData)));
    print('Encrypted location data: $encryptedLocation');

    await FirebaseFirestore.instance
        .collection('currentLocation')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .set({
      'currentLocation': encryptedLocation,
    });

    // Update location counters
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('userSettings')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .get();

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Map<String, dynamic> locationCounters = data['locationCounters'] ?? {};

    if (!locationCounters.containsKey(locationType)) {
      locationCounters[locationType] = base64Url.encode(utf8.encode(json.encode({
        'counter': 1,
        'startTime': timestamp.toIso8601String(),
        'endTime': null,
        'duration': 0,
      })));
    } else {
      Map<String, dynamic> typeData = json.decode(utf8.decode(base64Url.decode(locationCounters[locationType])));
      typeData['counter']++;
      typeData['endTime'] = timestamp.toIso8601String();
      typeData['duration'] = timestamp.difference(DateTime.parse(typeData['startTime'])).inSeconds;
      locationCounters[locationType] = base64Url.encode(utf8.encode(json.encode(typeData)));
    }

    await FirebaseFirestore.instance
        .collection('userSettings')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .update({
      'locationCounters': locationCounters,
    });
  }

  Future<String> _checkCurrentLocation(LatLng currentPosition) async {
    DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
        .collection('userSettings')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .get();

    Map<String, dynamic>? data = settingsDoc.data() as Map<String, dynamic>?;
    Map<String, dynamic>? userLocations = data?['userLocations'];

    if (userLocations != null) {
      for (String locationType in ['Home', 'School', 'Clinic']) {
        String? encodedLocation = userLocations[locationType];
        if (encodedLocation != null) {
          List<Map<String, dynamic>> locations = _decodeLocations(encodedLocation);
          for (var location in locations) {
            LatLng savedLocation = LatLng(location['latitude'], location['longitude']);
            double distance = Geolocator.distanceBetween(
              currentPosition.latitude,
              currentPosition.longitude,
              savedLocation.latitude,
              savedLocation.longitude,
            );
            if (distance <= 250) {
              return locationType;
            }
          }
        }
      }
    }

    return 'Outside';
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

  bool _isCurrentRoute(BuildContext context, String routeName) {
    return ModalRoute.of(context)?.settings.name == routeName;
  }

  String _encryptLocation(Map<String, dynamic> location) {
    String jsonString = json.encode(location);
    List<int> bytes = utf8.encode(jsonString);
    return base64Url.encode(bytes);
  }

  Stream<String?> _getLocationStream() {
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      if (!_showLocation) {
        return null;
      }

      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        DateTime timestamp = DateTime.now();

        String encryptedLocation = _encryptLocation({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': timestamp.toUtc().millisecondsSinceEpoch,
        });

        await FirebaseFirestore.instance
            .collection('currentLocation')
            .doc(FirebaseAuth.instance.currentUser!.email)
            .update({
          'currentLocation': encryptedLocation,
        });

        LatLng currentPosition = LatLng(position.latitude, position.longitude);

        DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
            .collection('userSettings')
            .doc(FirebaseAuth.instance.currentUser!.email)
            .get();

        Map<String, dynamic>? data = settingsDoc.data() as Map<String, dynamic>?;
        Map<String, dynamic>? userLocations = data?['userLocations'];

        if (userLocations != null) {
          for (String locationType in ['Home', 'School', 'Clinic']) {
            String? encodedLocation = userLocations[locationType];
            if (encodedLocation != null) {
              List<Map<String, dynamic>> locations = _decodeLocations(encodedLocation);
              for (var location in locations) {
                LatLng savedLocation = LatLng(location['latitude'], location['longitude']);
                double distance = calculateDistance(currentPosition, savedLocation);
                if (distance <= 250) {
                  return locationType;
                }
              }
            }
          }
        }

        return 'Outside';
      } catch (e) {
        print('Error in location stream: $e');

        return null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          StreamBuilder<String?>(
            stream: _getLocationStream(),
            builder: (context, snapshot) {
              return DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                ),
                padding: EdgeInsets.zero,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GText(
                        'Main Menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('userSettings')
                            .doc(FirebaseAuth.instance.currentUser!.email)
                            .snapshots(),
                        builder: (context, settingsSnapshot) {
                          if (settingsSnapshot.hasData) {
                            Map<String, dynamic>? data = settingsSnapshot.data?.data() as Map<String, dynamic>?;
                            bool locationPermission = data?['locationPermission'] ?? false;
                            Map<String, dynamic>? userLocations = data?['userLocations'];
                            bool hasLocations = userLocations != null && userLocations.isNotEmpty;

                            if (_showLocation && locationPermission && hasLocations) {
                              return Column(
                                children: [
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      GText(
                                        'Current Location: ',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (snapshot.connectionState == ConnectionState.waiting)
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else
                                        GText(
                                          snapshot.data ?? 'Unknown',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.home),
                  title: GText('Go to Home'),
                  onTap: () {
                    if (_isCurrentRoute(context, Home_Mod.routeName)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: GText("You're already at home")),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Home_Mod(),
                          settings: const RouteSettings(name: Home_Mod.routeName),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: GText('My Account'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AccountScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: GText('Settings'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ).then((_) {
                      (context as Element).reassemble();
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: GText('About Us'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AboutUsScreen()));
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: GText('Log out'),
            onTap: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Authentication_Mod(),
                  ),
                      (Route<dynamic> route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: GText('Error signing out: $e'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
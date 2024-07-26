import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gtext/gtext.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;

double calculateDistance(LatLng point1, LatLng point2) {
  return Geolocator.distanceBetween(
    point1.latitude,
    point1.longitude,
    point2.latitude,
    point2.longitude,
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GText('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GText(
                    'General',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildSettingTile(
                          const PermissionSwitchTile(
                            title: 'Camera',
                            permission: Permission.camera,
                            settingKey: 'cameraPermission',
                          ),
                        ),
                        _buildSettingTile(
                          const PermissionSwitchTile(
                            title: 'Microphone',
                            permission: Permission.microphone,
                            settingKey: 'microphonePermission',
                          ),
                        ),
                        _buildSettingTile(
                          const PermissionSwitchTile(
                            title: 'Location',
                            permission: Permission.location,
                            settingKey: 'locationPermission',
                          ),
                        ),
                        _buildSettingTile(
                          const LanguageSwitchTile(
                            title: 'Language',
                            settingKey: 'languagePreference',
                          ),
                        ),
                        _buildSettingTile(
                          DropdownTile(title: 'Font Size', settingKey: 'fontSize'),
                        ),
                        _buildSettingTile(
                          SwitchTile(title: 'Dark Mode', settingKey: 'DarkMode'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(Widget tile) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: tile,
    );
  }
}

class PermissionSwitchTile extends StatefulWidget {
  final String title;
  final Permission permission;
  final String settingKey;

  const PermissionSwitchTile({
    Key? key,
    required this.title,
    required this.permission,
    required this.settingKey,
  }) : super(key: key);

  @override
  _PermissionSwitchTileState createState() => _PermissionSwitchTileState();
}

class _PermissionSwitchTileState extends State<PermissionSwitchTile> {
  bool _value = false;
  String _selectedLocationType = 'Home';
  bool _isPendingSystemChange = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    PermissionStatus status = await widget.permission.status;
    setState(() {
      _value = status.isGranted;
      _isPendingSystemChange = false;
    });
    _updateFirebase(_value);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('userSettings')
          .doc(FirebaseAuth.instance.currentUser!.email)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic>? settingsData =
        snapshot.data?.data() as Map<String, dynamic>?;

        if (settingsData != null && settingsData[widget.settingKey] != null) {
          _value = settingsData[widget.settingKey];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: GText(widget.title),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isPendingSystemChange)
                    const Icon(Icons.info_outline, color: Colors.orange),
                  Switch(
                    value: _value,
                    onChanged: (value) => _onChanged(value),
                    activeColor: _isPendingSystemChange ? Colors.orange : null,
                  ),
                ],
              ),
              onTap: () => _onChanged(!_value),
              contentPadding: EdgeInsets.zero,
            ),
            if (_value && widget.permission == Permission.location)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Row(
                  children: [
                    GText('Set Location for: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _selectedLocationType,
                      items: ['Home', 'School', 'Clinic'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: GText(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedLocationType = newValue!;
                        });
                        _checkAndNavigate(_selectedLocationType);
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _showLocationDialog(String locationType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LocationDialog(locationType: locationType);
      },
    );
  }

  void _navigateToMapScreen(String locationType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(locationType: locationType),
      ),
    );
  }

  void _onChanged(bool value) async {
    if (value) {
      // Requesting permission
      var status = await widget.permission.request();
      if (status.isGranted) {
        setState(() {
          _value = true;
          _isPendingSystemChange = false;
        });
        _updateFirebase(true);
      } else {
        _showPermissionDeniedDialog();
      }
    } else {
      if (Platform.isIOS) {
        _showiOSDisablePermissionDialog();
      } else {
        _showAndroidDisablePermissionDialog();
      }
    }
  }


  void _updateFirebase(bool value) {
    FirebaseFirestore.instance
        .collection('userSettings')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .set({
      widget.settingKey: value,
    }, SetOptions(merge: true));
  }

  void _showAndroidDisablePermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: GText('Disable ${widget.title} Permission'),
          content: GText('To fully disable the ${widget.title} permission, you need to do this in your device settings. Would you like to open settings now?'),
          actions: <Widget>[
            TextButton(
              child: GText('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _checkPermissionStatus();
              },
            ),
            TextButton(
              child: GText('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
                setState(() {
                  _isPendingSystemChange = true;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showiOSDisablePermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: GText('Disable ${widget.title} Permission'),
          content: GText('To disable the ${widget.title} permission, you need to do this in your iOS settings. Would you like to open settings now?'),
          actions: <Widget>[
            TextButton(
              child: GText('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _checkPermissionStatus();
              },
            ),
            TextButton(
              child: GText('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
                setState(() {
                  _isPendingSystemChange = true;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: GText('Permission Denied'),
          content: GText('${widget.title} permission is required for this feature. Please grant the permission in app settings.'),
          actions: <Widget>[
            TextButton(
              child: GText('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                _checkPermissionStatus();
              },
            ),
          ],
        );
      },
    );
  }

  void _checkAndNavigate(String locationType) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('userSettings')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .get();

    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    String? encodedLocation = data?['userLocations']?[locationType];

    if (encodedLocation == null) {
      _navigateToMapScreen(locationType);
    } else {
      _showLocationDialog(locationType);
    }
  }
}

class LocationDialog extends StatefulWidget {
  final String locationType;

  const LocationDialog({Key? key, required this.locationType}) : super(key: key);

  @override
  _LocationDialogState createState() => _LocationDialogState();
}

class _LocationDialogState extends State<LocationDialog> {
  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: GText('${widget.locationType} Locations'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Flexible(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('userSettings')
                    .doc(FirebaseAuth.instance.currentUser!.email)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  Map<String, dynamic>? data = snapshot.data?.data() as Map<String, dynamic>?;
                  String? encodedLocation = data?['userLocations']?[widget.locationType];

                  if (encodedLocation == null) {
                    return Center(child: GText('No locations found.'));
                  }

                  List<Map<String, dynamic>> locations = _decodeLocations(encodedLocation);

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchAddresses(locations),
                    builder: (context, addressSnapshot) {
                      if (!addressSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      List<Map<String, dynamic>> locationsWithAddresses = addressSnapshot.data!;

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: locationsWithAddresses.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(locationsWithAddresses[index]['address']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editLocation(context, widget.locationType, index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteLocation(context, widget.locationType, index),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                child: GText('Add New Location'),
                onPressed: () => _addNewLocation(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAddresses(List<Map<String, dynamic>> locations) async {
    List<Map<String, dynamic>> locationsWithAddresses = [];
    for (var location in locations) {
      String address = await _getAddressFromLatLng(LatLng(location['latitude'], location['longitude']));
      locationsWithAddresses.add({...location, 'address': address});
    }
    return locationsWithAddresses;
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['display_name'];
    }
    return 'Unknown address';
  }

  void _addNewLocation(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(locationType: widget.locationType),
      ),
    );
  }

  void _editLocation(BuildContext context, String locationType, int index) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('userSettings')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .get();

    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    String? encodedLocation = data?['userLocations']?[locationType];
    List<Map<String, dynamic>> locations = _decodeLocations(encodedLocation!);

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          locationType: locationType,
          initialLocation: LatLng(
            locations[index]['latitude'],
            locations[index]['longitude'],
          ),
          editingIndex: index,
        ),
      ),
    );
  }

  void _deleteLocation(BuildContext context, String locationType, int index) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('userSettings')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .get();

    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    Map<String, dynamic> userLocations = data?['userLocations'] ?? {};
    String? encodedLocation = userLocations[locationType];
    List<Map<String, dynamic>> locations = _decodeLocations(encodedLocation!);

    locations.removeAt(index);

    if (locations.isEmpty) {
      userLocations.remove(locationType);
    } else {
      userLocations[locationType] = _encodeLocations(locations);
    }

    await FirebaseFirestore.instance
        .collection('userSettings')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .update({'userLocations': userLocations});

    _scaffoldMessenger.showSnackBar(
      SnackBar(
        content: GText('Location Successfully deleted.'),
      ),
    );
  }

  List<Map<String, dynamic>> _decodeLocations(String encodedLocations) {
    List<int> bytes = base64Url.decode(encodedLocations);
    String jsonString = utf8.decode(bytes);
    return (json.decode(jsonString) as List).cast<Map<String, dynamic>>();
  }

  String _encodeLocations(List<Map<String, dynamic>> locations) {
    String jsonString = json.encode(locations);
    List<int> bytes = utf8.encode(jsonString);
    return base64Url.encode(bytes);
  }
}

Map<String, dynamic> decodeLocationData(String encodedData) {
  String jsonString = utf8.decode(base64Decode(encodedData));
  return json.decode(jsonString);
}

Future<LatLng?> geocodeAddress(String address) async {
  final encodedAddress = Uri.encodeComponent(address);
  final url = 'https://nominatim.openstreetmap.org/search?format=json&q=$encodedAddress';

  try {
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'YugTalk/1.0'
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        final double lat = double.parse(data[0]['lat']);
        final double lon = double.parse(data[0]['lon']);
        return LatLng(lat, lon);
      }
    }
  } catch (e) {
    print('Error during geocoding: $e');
  }

  return null;
}

class MapScreen extends StatefulWidget {
  final String locationType;
  final LatLng? initialLocation;
  final int? editingIndex;

  const MapScreen({
    Key? key,
    required this.locationType,
    this.initialLocation,
    this.editingIndex,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _center;
  LatLng? _markerPosition;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _center = widget.initialLocation;
      _markerPosition = widget.initialLocation;
      _isLoading = false;
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _markerPosition = _center;
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _center = LatLng(0, 0);
        _markerPosition = _center;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('Unable to get current location. Using default.')),
      );
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      try {
        final location = await geocodeAddress(query);
        if (location != null) {
          setState(() {
            _center = location;
            _markerPosition = location;
            _mapController.move(location, 13.0);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: GText('Location not found')),
          );
        }
      } catch (e) {
        print('Error during search: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: GText('An error occurred while searching')),
        );
      }
    }
  }

  Future<LatLng?> geocodeAddress(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = 'https://nominatim.openstreetmap.org/search?format=json&q=$encodedAddress';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'YugTalk/1.0'
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final double lat = double.parse(data[0]['lat']);
          final double lon = double.parse(data[0]['lon']);
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('Error during geocoding: $e')),
      );
    }

    return null;
  }

  void _saveLocation() {
    if (_markerPosition != null) {
      FirebaseFirestore.instance
          .collection('userSettings')
          .doc(FirebaseAuth.instance.currentUser!.email)
          .get()
          .then((doc) async {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> userLocations = data['userLocations'] ?? {};

        List<Map<String, dynamic>> locations = [];
        if (userLocations[widget.locationType] != null) {
          locations = _decodeLocations(userLocations[widget.locationType]);
        }

        String address = await _getAddressFromLatLng(_markerPosition!);

        Map<String, dynamic> newLocation = {
          'latitude': _markerPosition!.latitude,
          'longitude': _markerPosition!.longitude,
          'address': address
        };

        if (widget.editingIndex != null) {
          locations[widget.editingIndex!] = newLocation;
        } else {
          locations.add(newLocation);
        }

        userLocations[widget.locationType] = _encodeLocations(locations);

        await FirebaseFirestore.instance
            .collection('userSettings')
            .doc(FirebaseAuth.instance.currentUser!.email)
            .update({'userLocations': userLocations});

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: GText('${widget.locationType} location saved successfully')),
        );
      });
    }
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['display_name'];
    }
    return 'Unknown address';
  }

  String _encodeLocations(List<Map<String, dynamic>> locations) {
    String jsonString = json.encode(locations);
    List<int> bytes = utf8.encode(jsonString);
    return base64Url.encode(bytes);
  }

  List<Map<String, dynamic>> _decodeLocations(String encodedLocations) {
    List<int> bytes = base64Url.decode(encodedLocations);
    String jsonString = utf8.decode(bytes);
    return (json.decode(jsonString) as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: GText('Set ${widget.locationType} Location'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _center,
                zoom: 13.0,
                onTap: (_, point) {
                  setState(() {
                    _markerPosition = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    if (_markerPosition != null)
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _markerPosition!,
                        builder: (ctx) => const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40.0,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '     Search for a location',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    onPressed: _performSearch,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
            Positioned(
              bottom: 15,
              left: 200,
              right: 200,
              child: ElevatedButton(
                onPressed: _saveLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: GText('Save Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SwitchTile extends StatefulWidget {
  final String title;
  final String settingKey;

  const SwitchTile({Key? key, required this.title, required this.settingKey}) : super(key: key);

  @override
  _SwitchTileState createState() => _SwitchTileState();
}

class _SwitchTileState extends State<SwitchTile> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('userSettings').doc(FirebaseAuth.instance.currentUser!.email).snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic>? settingsData = snapshot.data?.data() as Map<String, dynamic>?;

        if (settingsData != null && settingsData[widget.settingKey] != null) {
          _value = settingsData[widget.settingKey];
        }

        return SwitchListTile(
          title: GText(widget.title),
          contentPadding: EdgeInsets.zero,
          value: _value,
          onChanged: (value) {
            setState(() {
              _value = value;
            });

            FirebaseFirestore.instance.collection('userSettings').doc(FirebaseAuth.instance.currentUser!.email).set({
              widget.settingKey: _value,
            }, SetOptions(merge: true));
          },
        );
      },
    );
  }
}

class LanguageSwitchTile extends StatefulWidget {
  final String title;
  final String settingKey;

  const LanguageSwitchTile({Key? key, required this.title, required this.settingKey}) : super(key: key);

  @override
  _LanguageSwitchTileState createState() => _LanguageSwitchTileState();
}

class _LanguageSwitchTileState extends State<LanguageSwitchTile> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('userSettings').doc(FirebaseAuth.instance.currentUser!.email).snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic>? settingsData = snapshot.data?.data() as Map<String, dynamic>?;

        if (settingsData != null && settingsData[widget.settingKey] != null) {
          _value = settingsData[widget.settingKey];
        }

        return SwitchListTile(
          title: Row(
            children: [
              GText(widget.title),
              const SizedBox(width: 10),
              if (_value) GText('Tagalog', style: TextStyle(color: Colors.green)),
              if (!_value) GText('English', style: TextStyle(color: Colors.green)),
            ],
          ),
          contentPadding: EdgeInsets.zero,
          value: _value,
          onChanged: (value) {
            setState(() {
              _value = value;
            });

            FirebaseFirestore.instance.collection('userSettings').doc(FirebaseAuth.instance.currentUser!.email).set({
              widget.settingKey: _value,
            }, SetOptions(merge: true));
          },
        );
      },
    );
  }
}

class DropdownTile extends StatefulWidget {
  final String title;
  final String settingKey;

  const DropdownTile({Key? key, required this.title, required this.settingKey}) : super(key: key);

  @override
  _DropdownTileState createState() => _DropdownTileState();
}

class _DropdownTileState extends State<DropdownTile> {
  String _selectedValue = 'Small';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('userSettings').doc(FirebaseAuth.instance.currentUser!.email).snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic>? settingsData = snapshot.data?.data() as Map<String, dynamic>?;

        if (settingsData != null && settingsData[widget.settingKey] != null) {
          _selectedValue = settingsData[widget.settingKey];
        }

        return ListTile(
          title: GText(widget.title),
          contentPadding: EdgeInsets.zero,
          trailing: DropdownButton<String>(
            value: _selectedValue,
            onChanged: (value) {
              setState(() {
                _selectedValue = value!;
              });

              FirebaseFirestore.instance.collection('userSettings').doc(FirebaseAuth.instance.currentUser!.email).set({
                widget.settingKey: _selectedValue,
              }, SetOptions(merge: true));
            },
            items: ['Small', 'Medium', 'Large']
                .map((size) => DropdownMenuItem(
              value: size,
              child: GText(
                size,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ))
                .toList(),
          ),
        );
      },
    );
  }
}
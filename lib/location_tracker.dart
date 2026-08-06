import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:exif_authority_elite/functions.dart' as functions;
import 'package:exif_authority_elite/widgets.dart';

class LocationTracker extends StatefulWidget {
  const LocationTracker({super.key});
  @override
  State<LocationTracker> createState() => _LocationTrackerState();
}

class _LocationTrackerState extends State<LocationTracker> {
  bool _tracking = false;
  final FlutterBackgroundService _service = FlutterBackgroundService();

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
  }

  @override
  void dispose() {
    _service.invoke("stop_service");
    super.dispose();
  }

  void _checkServiceStatus() async {
    bool isRunning = await _service.isRunning();
    if (mounted) setState(() => _tracking = isRunning);
  }

  Future<void> _toggleTracking() async {
    bool isRunning = await _service.isRunning();
    final Directory appDataFolder = await getApplicationDocumentsDirectory();

    if (isRunning) {
      // Store final location before stopping
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
        );
        await functions.storeLocation(appDataFolder: appDataFolder, location: position);
      } catch (e) {
        debugPrint("Error storing final location: $e");
      }

      _service.invoke("stop_service");
      if (mounted) setState(() => _tracking = false);
      return;
    }

    // Check and request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied. Please enable in settings.")),
        );
      }
      return;
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      // Store initial location
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
        );
        await functions.storeLocation(appDataFolder: appDataFolder, location: position);
      } catch (e) {
        debugPrint("Error storing initial location: $e");
      }

      // Start background service
      await _service.startService();
      await Future.delayed(const Duration(milliseconds: 800));
      _checkServiceStatus();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission is required for tracking")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _service.invoke("stop_service");
        }
      },
      child: Scaffold(
        appBar: appBar(),
        body: Center(
          child: EliteButton(
            text: _tracking ? "Stop tracking" : "Start tracking",
            icon: _tracking ? Icons.pause : Icons.play_arrow,
            onTap: _toggleTracking,
          ),
        ),
      ),
    );
  }
}

// --- BACKGROUND ISOLATE ---
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "Exif Authority Elite",
      content: "GPS Service is active",
    );
  }

  // Get the app data folder in the background isolate
  final Directory appDataFolder = await getApplicationDocumentsDirectory();
  final Duration frequency = await functions.getFrequencyDuration();

  // Set up position stream with proper settings
  StreamSubscription<Position>? positionSubscription;
  
  positionSubscription = Geolocator.getPositionStream(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
      intervalDuration: frequency,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: "Exif Authority Elite",
        notificationText: "Background tracking is active",
        enableWakeLock: true,
      ),
    ),
  ).listen(
    (Position location) async {
      try {
        // Store location at the configured frequency
        await functions.storeLocation(
          appDataFolder: appDataFolder,
          location: location,
        );

        // Update notification with latest position
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Tracking Active",
            content: "Last point: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}",
          );
        }
      } catch (e) {
        // Log errors but continue tracking
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Tracking Active",
            content: "Error storing location: $e",
          );
        }
      }
    },
    onError: (error) {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Tracking Error",
          content: "Location error: $error",
        );
      }
    },
    cancelOnError: false,
  );

  // Clean up subscription when service stops
  service.on("stop_service").listen((event) {
    positionSubscription?.cancel();
    service.stopSelf();
  });
}
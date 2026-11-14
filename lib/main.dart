// ignore_for_file: use_build_context_synchronously
import 'package:exif_authority_elite/exif_editor.dart';
import 'package:exif_authority_elite/location_tracker.dart'; // CRITICAL IMPORT
import 'package:exif_authority_elite/settings.dart';
import 'package:exif_authority_elite/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'variables.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quickie/quickie.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // 1. Manually create the Android Notification Channel
  AndroidNotificationChannel channel = AndroidNotificationChannel(
    'exif_tracker_channel', // This ID MUST match the one in AndroidConfiguration
    'Exif Tracker Service',
    description: 'Used for background location tracking.',
    importance: Importance.low, 
  );

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // 2. Register the channel with the Android System
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'exif_tracker_channel',
      initialNotificationTitle: 'Exif Authority Elite',
      initialNotificationContent: 'GPS Tracking Initializing...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

// Main application entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MediaStore
  await MediaStore.ensureInitialized();
  
  // Initialize service BEFORE runApp
  await initializeService();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Exif Authority Elite',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(
        actions: [
          const SettingsButton(),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage("images/logo.jpeg"),
                  radius: 50,
                ),
                EliteButton(
                  text: "Track Location", 
                  icon: Icons.location_pin,
                  onTap: () async {
                    await _requestAllPermissions(context);
                  },
                ),
                EliteButton(
                  text: "Add location to images", 
                  icon: Icons.image,
                  onTap: () async {
                    await _selectImages(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Request all required permissions
  Future<void> _requestAllPermissions(BuildContext context) async {
    // Request location with "always" option
    final locationStatus = await Permission.location.request();
    
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.notification,
      Permission.photos,
      Permission.videos,
    ].request();

    bool locationGranted = locationStatus.isGranted;
    bool notificationGranted = statuses[Permission.notification]?.isGranted ?? false;
    bool photosGranted = statuses[Permission.photos]?.isGranted ?? false;

    if (!locationGranted || !notificationGranted || !photosGranted) {
      await quickAlert(
        context: context,
        alertMessage: const Text(
          "The app requires Location (always), Notifications, Photos, and Videos permissions to function properly. Please enable them in app settings.",
          style: TextStyle(fontFamily: fontName),
        ),
        confirmButton: Container(
          decoration: const BoxDecoration(
            color: logoBackgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          padding: const EdgeInsets.all(20),
          child: const Text(
            "Open Settings",
            style: TextStyle(
              color: logoForegroundColor,
              fontFamily: fontName,
            ),
          ),
        ),
      );
      return;
    }

    // All permissions granted, proceed based on which button was tapped
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => const LocationTracker(),
    ));
  }
  
  /// Helper function to select images and navigate to EXIF editor
  Future<void> _selectImages(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty && context.mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => ExifEditor(images: images),
      ));
    }
  }
}

// Settings button widget for navigation to settings page
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (ctx) => const SettingsPage(),
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        color: logoBackgroundColor,
        child: const Icon(
          Icons.settings,
          color: logoForegroundColor,
        ),
      ),
    );
  }
}
// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:exif_authority_elite/variables.dart';
import 'package:dating/dating.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:objective_db/objective_db.dart';

Future<void> storeLocation({
  required Directory appDataFolder,
  required Position location,
})async{
  Entry entry = Entry(dbPath: appDataFolder.path);
  Map<String,dynamic> object = {
    "dateTime": DateTime.now().toUtc().toString(),
    "location": "${location.latitude},${location.longitude}",
  };
  entry.select().insert(
    key: "locations", 
    value: [
      object,
    ],
  );
}
class StoredLocation{
  StoredLocation({
    required this.latitude,
    required this.longitude,
    required this.dateTime,
  });
  final double latitude;
  final double longitude;
  final DateTime dateTime;
  static StoredLocation parse(Map<String,dynamic> object){
    DateTime dateTime = DateTime.parse(object["dateTime"]);
    dateTime = dateTime.toLocal();
    List<dynamic> location = (object["location"] as String).split(",");
    double latitude = double.parse(location[0]);
    double longitude = double.parse(location[1]);
    return StoredLocation(
      latitude: latitude, 
      longitude: longitude,
      dateTime: dateTime,
    );
  }
}
Future<int> getDataPoints()async{
  Directory appDataFolder = await getApplicationDocumentsDirectory();
  List<StoredLocation> locationPoints = await getAllLocationPoints(appDataFolder: appDataFolder);
  return locationPoints.length;
}
Future<List<StoredLocation>> getAllLocationPoints({
  required Directory appDataFolder,
})async{
  Entry entry = Entry(dbPath: appDataFolder.path);
  List<StoredLocation> locationsPoints = [];
  try{
    List<DbObject> locations = entry.select().selectMultiple(key: "locations");
    for(DbObject location in locations){
      locationsPoints.add(StoredLocation.parse(location.view()));
    }
  }catch(error){
    locationsPoints = [];
  }
  return locationsPoints;
}
Future<void> deleteLocationsBefore({
  required DateTime date,
  required BuildContext context,
})async{
  date = date.toLocal();
  Directory appDataFolder = await getApplicationDocumentsDirectory();
  Entry entry = Entry(dbPath: appDataFolder.path);
  List<StoredLocation> locations = await getAllLocationPoints(appDataFolder: appDataFolder);
  CherryToast(
    icon: Icons.delete,
    iconColor: logoForegroundColor,
    backgroundColor: logoBackgroundColor,
    themeColor: logoBackgroundColor,
    title: const Text(
      "Deleting location files",
      style: TextStyle(
        color: logoForegroundColor,
      ),
    ),
  ).show(context);
  for(int i = 0; i < locations.length; i++){
    if(locations[i].dateTime.isInRange(
      from: DateTime(0), 
      to: date,
      onlyCheckDate: true,
    )){
      entry.select().pop(
        index: 0, 
        key: "locations",
      );
    }
  }
  CherryToast(
    icon: Icons.check,
    iconColor: logoForegroundColor,
    backgroundColor: logoBackgroundColor,
    themeColor: logoBackgroundColor,
    title: const Text(
      "Successfully deleted location files",
      style: TextStyle(
        color: logoForegroundColor,
      ),
    ),
  ).show(context);
}
Future<void> setFrequencyDuration(int seconds)async{
  Directory appDataFolder = await getApplicationDocumentsDirectory();
  Entry entry = Entry(dbPath: appDataFolder.path);
  entry.select().insert(
    key: "locationFrequency", 
    value: seconds,
  );
}
Future<Duration> getFrequencyDuration()async{
  try{
    Directory appDataFolder = await getApplicationDocumentsDirectory();
    Entry entry = Entry(dbPath: appDataFolder.path);
    int duration = entry.select().view()["locationFrequency"];
    return Duration(seconds: duration);
  }catch(error){
    return Duration(seconds: 30);
  }
}
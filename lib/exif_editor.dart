import 'package:exif_authority_elite/functions.dart';
import 'package:exif_authority_elite/variables.dart';
import 'package:exif_authority_elite/widgets.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:native_exif/native_exif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_store_plus/media_store_plus.dart';

class ExifEditor extends StatelessWidget {
  const ExifEditor({
    super.key,
    required this.images,
  });
  final List<XFile> images;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: FutureBuilder(
        future: updateExifData(
          images: images,
        ),
        builder: (ctx, snapshot){
          if(snapshot.hasError){
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EliteButton(
                  text: "An error ocurred. ${snapshot.error}.",
                  icon: Icons.close,
                  onTap: (){
                
                  },
                ),
              ],
            );
          }else if(snapshot.connectionState == ConnectionState.done){
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EliteButton(
                  text: "Operation finished. Check your files.", 
                  icon: Icons.check, 
                  onTap: (){
                
                  },
                ),
              ],
            );
          }else{
            return const Loading();
          }
        },
      ),
    );
  }
}

Future<void> updateExifData({
  required List<XFile> images,
}) async {
  // Get all location points from database (already sorted)
  Directory appDataFolder = await getApplicationDocumentsDirectory();
  List<StoredLocation> storedLocationPoints = await getAllLocationPoints(
    appDataFolder: appDataFolder,
  );
  
  // Extract image metadata dates
  List<Map<String, dynamic>> imagesWithDates = [];
  
  for (XFile imageFile in images) {
    final exif = await Exif.fromPath(imageFile.path);
    DateTime? dateTime = await exif.getOriginalDate();
    await exif.close();
    
    if (dateTime != null) {
      imagesWithDates.add({
        'file': imageFile,
        'dateTime': dateTime,
      });
    }
  }
  
  // Sort images by metadata date (oldest first)
  imagesWithDates.sort((a, b) => a['dateTime'].compareTo(b['dateTime']));
  
  // Process each image in chronological order
  for (Map<String, dynamic> imageData in imagesWithDates) {
    XFile imageFile = imageData['file'];
    DateTime imageDateTime = imageData['dateTime'];
    
    // Remove stored locations that are more than mergeRangeInMs older than current image
    storedLocationPoints.removeWhere((location) {
      return imageDateTime.difference(location.dateTime).inMilliseconds > mergeRangeInMs;
    });
    
    // Find closest location match within mergeRangeInMs
    StoredLocation? matchingLocation;
    int matchIndex = -1;
    for (final(int index, StoredLocation location) in storedLocationPoints.indexed) {
      int timeDiff = imageDateTime.difference(location.dateTime).inMilliseconds;
      
      // Check if within merge range and closer than previous matches
      if (-mergeRangeInMs <= timeDiff && timeDiff <= mergeRangeInMs) {
        matchingLocation = location;
        matchIndex = index;
      }else if(timeDiff < -mergeRangeInMs){
        //Delete all previous locations
        if(matchIndex != -1){
          for(int i = 0; i < matchIndex; i++){
            storedLocationPoints.removeAt(0);
          }
        }
        break;
      }else{

      }
    }
    
    // Update EXIF data if matching location found
    if (matchingLocation != null) {
      final exif = await Exif.fromPath(imageFile.path);
      Map<String, Object> attributes = (await exif.getAttributes()) ?? {};
      
      // Add GPS coordinates
      attributes.addAll({
        'GPSLatitude': matchingLocation.latitude,
        'GPSLongitude': matchingLocation.longitude,
      });
      
      await exif.writeAttributes(attributes);
      await exif.close();
    }
    
    // Save image to device storage (regardless of whether location was added)
    MediaStore.appFolder = "exif_authority_elite";
    await MediaStore().saveFile(
      tempFilePath: imageFile.path, 
      dirType: DirType.photo, 
      dirName: DirName.dcim,
    );
  }
}
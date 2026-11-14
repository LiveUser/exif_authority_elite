import 'package:exif_authority_elite/functions.dart';
import 'package:exif_authority_elite/variables.dart';
import 'package:exif_authority_elite/widgets.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:native_exif/native_exif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:rawkit/rawkit.dart' as raw_kit;
import 'package:koni_jxl/koni_jxl.dart';

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

bool isRawImage(String fullPath){
  const List<String> rawImageExtensions = [
    '.3fr',
    '.arw',
    '.braw',
    '.cr2',
    '.cr3',
    '.crw',
    '.dcr',
    '.dng',
    '.erf',
    '.fff',
    '.gpr',
    '.iiq',
    '.k25',
    '.kdc',
    '.mef',
    '.mos',
    '.nef',
    '.nrw',
    '.orf',
    '.pef',
    '.raf',
    '.raw',
    '.rw2',
    '.rwl',
    '.sr2',
    '.srf',
    '.srw',
    '.x3f',
  ];
  for(String extension in rawImageExtensions){
    if(fullPath.endsWith(extension)){
      return true;
    }
  }
  return false;
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
    //Read image formats
    if(isRawImage(imageFile.path)){
      raw_kit.RawDocument rawDocument = await raw_kit.RawDocument.openFile(imageFile.path);
      if(rawDocument.metadata.timestamp != null){
        imagesWithDates.add({
          'file': imageFile,
          'dateTime': rawDocument.metadata.timestamp,
        });
      }
    }else{
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
      //TODO: Convert to JPEG XL and update the metadata
      if(isRawImage(imageFile.path)){
        raw_kit.RawDocument raw = await raw_kit.RawDocument.openFile(imageFile.path);
        //TODO: Perfect place for applying LUTs
        raw_kit.RawImage image = await raw.render(raw_kit.RawDevelopSettings());
        //TODO: Change to 16 bit pixels in the future if the library supports it later on
        Uint8List jxl = JxlEncoder.encodeLossless(image.pixels8,width: image.width, height: image.height, hasAlpha: false);
        Directory appDataFolder = await getApplicationDocumentsDirectory();
        File tempImage = File("${appDataFolder.path}/temp/image.jxl");
        await tempImage.writeAsBytes(jxl);
        // Save image to device storage (regardless of whether location was added)
        MediaStore.appFolder = "exif_authority_elite";

        await MediaStore().saveFile(
          tempFilePath: tempImage.path,
          dirType: DirType.photo, 
          dirName: DirName.dcim,
        );
      }else{
        final exif = await Exif.fromPath(imageFile.path);
        Map<String, Object> attributes = (await exif.getAttributes()) ?? {};
        
        // Add GPS coordinates
        attributes.addAll({
          'GPSLatitude': matchingLocation.latitude,
          'GPSLongitude': matchingLocation.longitude,
        });
        
        await exif.writeAttributes(attributes);
        await exif.close();
        // Save image to device storage (regardless of whether location was added)
        MediaStore.appFolder = "exif_authority_elite";

        await MediaStore().saveFile(
          tempFilePath: imageFile.path, 
          dirType: DirType.photo, 
          dirName: DirName.dcim,
        );
      }
    }
  }
}
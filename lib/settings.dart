// ignore_for_file: use_build_context_synchronously

import 'package:exif_authority_elite/functions.dart';
import 'package:exif_authority_elite/variables.dart';
import 'package:exif_authority_elite/widgets.dart';
import 'package:flutter/material.dart';
import 'package:raw_context/raw_context.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FutureBuilder(
                  future: getFrequencyDuration(), 
                  builder: (context,snapshot){
                    if(snapshot.connectionState == ConnectionState.done){
                      return Column(
                        children: [
                          Text(
                            "Location store frequency:",
                            style: TextStyle(
                              color: logoBackgroundColor,
                              fontSize: 15,
                              fontFamily: fontName,
                            ),
                          ),
                          RawContext(
                            items: [
                              RawContextItem(
                                onPressed: ()async{
                                  setFrequencyDuration(1);
                                  setState(() {
                                    
                                  });
                                }, 
                                item: Text(
                                  "1s",
                                  style: TextStyle(
                                    color: logoBackgroundColor,
                                    fontSize: 15,
                                    fontFamily: fontName,
                                  ),
                                ),
                              ),
                              RawContextItem(
                                onPressed: ()async{
                                  setFrequencyDuration(10);
                                  setState(() {
                                    
                                  });
                                }, 
                                item: Text(
                                  "10s",
                                  style: TextStyle(
                                    color: logoBackgroundColor,
                                    fontSize: 15,
                                    fontFamily: fontName,
                                  ),
                                ),
                              ),
                              RawContextItem(
                                onPressed: ()async{
                                  setFrequencyDuration(20);
                                  setState(() {
                                    
                                  });
                                }, 
                                item: Text(
                                  "20s",
                                  style: TextStyle(
                                    color: logoBackgroundColor,
                                    fontSize: 15,
                                    fontFamily: fontName,
                                  ),
                                ),
                              ),
                              RawContextItem(
                                onPressed: ()async{
                                  setFrequencyDuration(30);
                                  setState(() {
                                    
                                  });
                                }, 
                                item: Text(
                                  "30s",
                                  style: TextStyle(
                                    color: logoBackgroundColor,
                                    fontSize: 15,
                                    fontFamily: fontName,
                                  ),
                                ),
                              ),
                              RawContextItem(
                                onPressed: ()async{
                                  setFrequencyDuration(50);
                                  setState(() {
                                    
                                  });
                                }, 
                                item: Text(
                                  "50s",
                                  style: TextStyle(
                                    color: logoBackgroundColor,
                                    fontSize: 15,
                                    fontFamily: fontName,
                                  ),
                                ),
                              ),
                              RawContextItem(
                                onPressed: ()async{
                                  setFrequencyDuration(60);
                                  setState(() {
                                    
                                  });
                                }, 
                                item: Text(
                                  "60s",
                                  style: TextStyle(
                                    color: logoBackgroundColor,
                                    fontSize: 15,
                                    fontFamily: fontName,
                                  ),
                                ),
                              ),
                            ],
                            child: Container(
                              color: logoBackgroundColor,
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    color: logoForegroundColor,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      "${(snapshot.data as Duration).inSeconds.toString()}s",
                                      style: TextStyle(
                                        color: logoForegroundColor,
                                        fontSize: 15,
                                        fontFamily: fontName,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }else{
                      return Loading();
                    }
                  },
                ),
                FutureBuilder(
                  future: getDataPoints(), 
                  builder: (context,snapshot){
                    if(snapshot.connectionState == ConnectionState.done){
                      return Column(
                        children: [
                          Text(
                            "${snapshot.data as int} stored location data points.",
                            style: TextStyle(
                              color: logoBackgroundColor,
                              fontSize: 15,
                              fontFamily: fontName,
                            ),
                          ),
                          EliteButton(
                            text: "Delete locations stored before selected date", 
                            icon: Icons.delete, 
                            onTap: ()async{
                              //Pick date and delete everything previous to that date
                              DateTime? pickedDate = await showDatePicker(
                                context: context, 
                                firstDate: DateTime(0), 
                                lastDate: DateTime.now(),
                              );
                              if(pickedDate != null){
                                await deleteLocationsBefore(
                                  date: pickedDate, 
                                  context: context,
                                );
                              }
                              //Reload settings page to update the data points count
                              setState(() {
                                
                              });
                            },
                          ),
                        ],
                      );
                    }else{
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
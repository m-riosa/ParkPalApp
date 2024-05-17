import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:theme_park_tracker/tabs/listItems.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:theme_park_tracker/main.dart';
import 'package:theme_park_tracker/theme/theme.dart';


import 'AddParks.dart';
import 'WaitList.dart';

class SavedParks extends StatefulWidget{
  List<int> parkArr;
  int id;
  String firstname;
  String lastname;
  SavedParks({super.key, required this.id, required this.parkArr, required this.firstname, required this.lastname});

  @override
  State<SavedParks> createState() => _SavedParks();
}

class _SavedParks extends State<SavedParks>{
  var parkList;
  late List<int> parkArr;
  int id = 0;
  late String firstname;
  late String lastname;
  List<String> savedParkArr = [];
  Map<String, int> parkMap = {};



  @override
  void initState() {
    parkArr = widget.parkArr;
    id = widget.id;
    firstname = widget.firstname;
    lastname = widget.lastname;
    super.initState();
    getData();
  }

  void getData() async{
    try{
      var response = await Dio().get('https://queue-times.com/parks.json');
      if (response.statusCode == 200){
        setState(() {
          parkList = response.data as List;
          for (int i = 0; i < parkList.length; i++){
            for (int j = 0; j < parkList[i]['parks'].length; j++){
              if (parkArr.contains(parkList[i]['parks'][j]['id'])){
                  savedParkArr.add(parkList[i]['parks'][j]['name']);
                  parkMap.putIfAbsent(parkList[i]['parks'][j]['name'], () => parkList[i]['parks'][j]['id']);
              }
            }
          }
        });


      } else{
        print(response.statusCode);
      }
    } catch(e){
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
        children: [
          Expanded(
            flex: 1,
              child: (parkArr.isEmpty) ?
                  // if the user doesn't have any parks, prompt the user to add some with text on the screen
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        child: Text("Add some parks to your account!"),
                      ),
                    ],
                  )
                  :
              ListView.builder(
                itemCount: parkMap.length,
                shrinkWrap: true,
                itemBuilder: (context, index) => Card(
                  color: Theme.of(context).colorScheme.primary,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              // add the name of the park that is passed in
                              child: Container(
                                padding: const EdgeInsets.only(left: 15.0, right: 8.0, top: 2.0, bottom: 2.0),
                                child: Text(parkMap.keys.elementAt(index), overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, color: Colors.white)),

                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.only(left: 8.0, right: 5.0, top:2.0, bottom: 2.0),
                              child:  IconButton(
                                iconSize: 50,
                                color: Colors.white,
                                icon: const Icon(
                                  Icons.remove,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context){
                                      // create pop up to confirm removal of saved park
                                      return AlertDialog(
                                        scrollable: true,
                                        content: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(height: 20),
                                            SizedBox(
                                              height: 40,
                                              child: Text("Remove Park?", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 23),),
                                            ),
                                            SizedBox(height: 20),
                                            MaterialButton(
                                              onPressed: (){
                                                removePark(parkMap.values.elementAt(index), id);

                                                setState(() {
                                                  parkArr.remove(parkMap.values.elementAt(index));
                                                  //parkMap.remove(index);

                                                });
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => LandingPage(id: id, parkArr: parkArr, firstname: firstname, lastname: lastname)));
                                              },
                                              color: HexColor("#99dbFF"),
                                              child: const Text('Confirm', style: TextStyle(color: Colors.black)),

                                            )
                                          ],
                                        ),
                                      );
                                    }
                                  );

                                },
                              ),
                            )

                          ],
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 8.0, top: 0.0, right: 8.0, bottom: 6.0),
                        child: MaterialButton(
                          onPressed: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => WaitTimes(parkNum: parkMap.values.elementAt(index), parkName: parkMap.keys.elementAt(index), firstname: firstname, lastname: lastname, parkArr: parkArr, id: id)));
                          },
                          color: Colors.white,
                          child: Text('See Wait Times', style: TextStyle(color: Colors.black) ),
                        ),

                      )

                    ],
                  ),

                ),
              ),
          ),
            MaterialButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddParks(parkArr: parkArr, id: id, firstname: firstname, lastname: lastname)));
            },
              color: Theme.of(context).colorScheme.secondary,
              child: Text('Add a Park', style: TextStyle(color: Theme.of(context).colorScheme.tertiary) ),

          )
        ],
      ),
      )

    );
  }

  Column emptyScreen(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Add some parks"),
      ],
    );
  }

  Future<void> removePark(int parkNum, int id) async {
    final response = await http.post(
        Uri.parse('https://group-22-0b4387ea5ed6.herokuapp.com/api/deletePark'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, int>{
          'userID' : id,
          'parkID': parkNum,
        })
    );
    if (response.statusCode == 200){
      Fluttertoast.showToast(msg: "Removed Park");
    }
    else {
      Fluttertoast.showToast(msg: response.statusCode.toString());
    }

  }
}

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mustache_template/mustache.dart';
import 'package:split_view/split_view.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'dbutil/dbutil_mysql.dart';

class LayoutScreen extends StatefulWidget{

  const LayoutScreen({super.key});

  @override
  State<StatefulWidget> createState() => LayoutScreenState();

}

class LayoutScreenState extends State<LayoutScreen>{

  List<Map<String,dynamic>> tableList = [];

  String? dbType;
  TextEditingController dbHostController = TextEditingController();
  TextEditingController dbPortController = TextEditingController();
  TextEditingController dbNameController = TextEditingController();
  TextEditingController dbUserController = TextEditingController();
  TextEditingController dbPswdController = TextEditingController();
  TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 40,
              child: DropdownButtonFormField(
                items: const [
                  DropdownMenuItem(value:"MYSQL",child: Text("MYSQL"))
                ],
                onChanged: (value){
                  dbType = value;
                },
                isExpanded : true
              )
            ),
            SizedBox(
              width: 150,
              height: 40,
              child: TextField(
                controller: dbHostController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'HOST'
                ),
              )
            ),
            SizedBox(
              width: 100,
              height: 40,
              child: TextField(
                controller: dbPortController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'PORT'
                ),
              )
            ),
            SizedBox(
              width: 150,
              height: 40,
              child: TextField(
                controller: dbNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'DBNAME'
                ),
              )
            ),
            SizedBox(
              width: 100,
              height: 40,
              child: TextField(
                controller: dbUserController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'USER'
                ),
              )
            ),
            SizedBox(
              width: 150,
              height: 40,
              child: TextField(
                obscureText: true,
                controller: dbPswdController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'PASSWORD'
                ),
              )
            ),
            Ink(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigoAccent, width: 2.0),
                color: Colors.indigo[900],
                shape: BoxShape.circle,
              ),
              child: InkWell(
                //This keeps the splash effect within the circle
                borderRadius: BorderRadius.circular(500.0), //Something large to ensure a circle
                onTap: (){
                  String dbHost = dbHostController.text;
                  String dbPort = dbPortController.text;
                  String dbName = dbNameController.text;
                  String dbUser = dbUserController.text;
                  String dbPswd = dbPswdController.text;
                  switch(dbType){
                    case "MYSQL":
                      DbutilMysql().dbConnector(
                          host: dbHost,
                          port: int.parse(dbPort),
                          dbname: dbName,
                          user: dbUser,
                          password: dbPswd
                      ).then((result){
                        setState(() {
                          tableList = result;
                        });
                      });
                      break;
                  }
                },
                child: const Padding(
                  padding:EdgeInsets.all(5.0),
                  child: Icon(
                    Icons.add_link,
                    size: 25.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Ink(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigoAccent, width: 2.0),
                color: Colors.indigo[900],
                shape: BoxShape.circle,
              ),
              child: InkWell(
                //This keeps the splash effect within the circle
                borderRadius: BorderRadius.circular(500.0), //Something large to ensure a circle
                onTap: () async {
                  String? outputDirectory = await FilePicker.platform.getDirectoryPath(
                    dialogTitle: '파일을 저장할 경로를 선택하세요.',
                  );
                  if(outputDirectory!=null) {
                    debugPrint('directory Path: $outputDirectory');
                    for (var table in tableList) {
                      var tableName = table['TABLE_NAME'];
                      var tableNameCamel = '';
                      var content = await getConvertContent(tableName);
                      var tableNameToken = tableName.split('_');
                      for(var token in tableNameToken){
                        var lower = token.toLowerCase();
                        var firstChar = lower.substring(0,1).toUpperCase();
                        tableNameCamel += (firstChar + lower.substring(1));
                      }
                      File(join(outputDirectory, '${tableNameCamel}Mapper.xml'))
                        ..createSync(recursive: true)
                        ..writeAsStringSync(content);
                    }
                  }
                },
                child: const Padding(
                  padding:EdgeInsets.all(5.0),
                  child: Icon(
                    Icons.download,
                    size: 25.0,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      body: SplitView(
        viewMode: SplitViewMode.Horizontal,
        controller: SplitViewController(limits: [WeightLimit(max: 0.3), null], weights: [0.2, 0.8]),
        indicator: const SplitIndicator(
          viewMode: SplitViewMode.Horizontal,
        ),
        activeIndicator: const SplitIndicator(
          viewMode: SplitViewMode.Horizontal,
          isActive: true,
        ),
        children: [
          ListView(
            children: List<Row>.generate(tableList.length, (index){
              return Row(
                children: [
                  Expanded(
                      child: TextButton(
                        child: Text(tableList.elementAt(index)['TABLE_NAME']),
                        onPressed: () async {
                          var tableName = tableList.elementAt(index)['TABLE_NAME'].toString();
                          getConvertContent(tableName).then((result){
                            setState(() {
                              contentController.text = result;
                            });
                          });
                        }
                      )
                  ),

                ],
              );
            }),
          ),
          Container(
            child: TextField(
              controller: contentController,
              maxLines: null,
              expands: true,
            )
          )
        ],
      ),
    );
  }

  Future<String> getConvertContent(tableName) async {

    final data = await rootBundle.load('assets/mapper_template.xml');
    final buffer = data.buffer;
    var list = buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    String template = utf8.decode(list);

    String dbHost = dbHostController.text;
    String dbPort = dbPortController.text;
    String dbName = dbNameController.text;
    String dbUser = dbUserController.text;
    String dbPswd = dbPswdController.text;

    template = template.replaceAll('\t', '    ');
    var t = Template(template);

    var tableNameCamel = '';
    var columns = '';
    var keyWhere = '';
    var varColumns = '';
    var updateColumns = '';
    var tc = '    ';

    switch(dbType) {
      case "MYSQL":
        var result = await DbutilMysql().getColumns(
            host: dbHost,
            port: int.parse(dbPort),
            dbname: dbName,
            user: dbUser,
            password: dbPswd,
            tableName: tableName
        );

        var tableNameToken = tableName.split('_');
        for(var token in tableNameToken){
          var lower = token.toLowerCase();
          var firstChar = lower.substring(0,1).toUpperCase();
          tableNameCamel += (firstChar + lower.substring(1));
        }

        for(var col in result){
          if(columns != ''){
            columns += ',\n$tc$tc$tc';
          }
          columns += col['Field'].toString();

          if(varColumns != ''){
            varColumns += ',\n$tc$tc$tc';
          }
          varColumns += '#{${col['Field']}}';

          if(col['Key']=='PRI'){
            if(keyWhere == ''){
              keyWhere += '${col['Field']} = #{${col['Field']}}';
            }else{
              keyWhere += '\n$tc${tc}AND ${col['Field']} = #{${col['Field']}}';
            }
          }

          if(col['Key']!='PRI'){
            if(updateColumns != ''){
              updateColumns += ',\n$tc$tc$tc';
            }
            updateColumns += '${col['Field']} = #{${col['Field']}}';
          }
        }
        break;
    }


    var convert = t.renderString({
      'tableName' : tableName,
      'tableNameCamel' : tableNameCamel,
      'columns' : columns,
      'keyWhere' : keyWhere,
      'varColumns' : varColumns,
      'updateColumns' : updateColumns,
    });
    debugPrint(convert);

    return convert;
  }

}



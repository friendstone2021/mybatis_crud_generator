import 'package:flutter/cupertino.dart';
import 'package:mysql_client/mysql_client.dart';

class DbutilMysql {
  Future<List<Map<String, String?>>> dbConnector({host, port, dbname, user, password}) async {
    final conn = await MySQLConnection.createConnection(
        host: host,
        port: port,
        userName: user,
        password: password,
        databaseName: dbname
    );

    await conn.connect();

    String query_tableList = '''
    SELECT TABLE_NAME
    FROM information_schema.TABLES
    where TABLE_SCHEMA = '$dbname'
    and TABLE_TYPE = 'BASE TABLE'
    ''';

    var rs = await conn.execute(query_tableList);

    List<Map<String, String?>> result = [];
    for(var row in rs.rows){
      result.add(row.assoc());
    }

    conn.close();

    return result;
  }

  Future<List<Map<String, String?>>> getColumns({host, port, dbname, user, password, tableName}) async {
    final conn = await MySQLConnection.createConnection(
        host: host,
        port: port,
        userName: user,
        password: password,
        databaseName: dbname
    );

    await conn.connect();

    String query_columnList = 'desc $tableName';
    debugPrint(query_columnList);

    var rs = await conn.execute(query_columnList);

    List<Map<String, String?>> result = [];
    for(var row in rs.rows){
      debugPrint(row.assoc().toString());
      result.add(row.assoc());
    }

    conn.close();

    return result;
  }
 }

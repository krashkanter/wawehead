import "package:flutter/material.dart";
import "package:wawehead/misc/reusable.dart";

import "../../components/db.dart";

class QueryBuilderPage extends StatefulWidget {
  const QueryBuilderPage({super.key});

  @override
  State<QueryBuilderPage> createState() => _QueryBuilderPageState();
}

class _QueryBuilderPageState extends State<QueryBuilderPage> {
  final TextEditingController tf = TextEditingController();
  final DBMS dbms = DBMS();
  String queryResult = "Results will appear here"; // State variable

  Future<void> execute() async {
    final result = await dbms.executeQueries(tf.text);
    setState(() {
      queryResult = result.isNotEmpty ? result.toString() : "No results found";
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.black, Colors.blue],
          center: Alignment.topRight,
          radius: 4,
          stops: [.2, 1],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Query Builder'),
          backgroundColor: Colors.transparent,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: [
              textFieldCustom(tf),
              elevatedButtonCustom(execute),
              const SizedBox(height: 20),
              Text(
                queryResult,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

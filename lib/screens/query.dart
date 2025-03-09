import "package:flutter/material.dart";
import "package:wawehead/misc/reusable.dart";

class QueryBuilderPage extends StatefulWidget {
  const QueryBuilderPage({super.key});

  @override
  State<QueryBuilderPage> createState() => _QueryBuilderPageState();
}

class _QueryBuilderPageState extends State<QueryBuilderPage> {
  final TextEditingController tf = TextEditingController();

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
              elevatedButtonCustom()
            ],
          ),
        ),
      ),
    );
  }
}

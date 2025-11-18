import 'package:flutter/material.dart';


class more_page extends StatefulWidget {
  const more_page({super.key});

  @override
  State<more_page> createState() => _more_pageState();
}

class _more_pageState extends State<more_page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: 
        Text("More"),),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:limited_wrap/limited_wrap.dart';

class LimitedWrapExampleWidget extends StatefulWidget {
  const LimitedWrapExampleWidget({super.key});

  @override
  State<LimitedWrapExampleWidget> createState() =>
      _LimitedWrapExampleWidgetState();
}

class _LimitedWrapExampleWidgetState extends State<LimitedWrapExampleWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: UILimitedWrap(
        spacing: 8.0,
        runSpacing: 8.0,
        maxLines: _expanded ? null : 2,
        clipBehavior: Clip.hardEdge,
        changeExpansionButton: InkWell(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _expanded ? 'Show Less' : 'Show All',
                  style: const TextStyle(color: Colors.white),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        children: _buildTags(),
      ),
    );
  }

  List<Widget> _buildTags() {
    final tags = List<String>.generate(100, (index) => '$index chip');

    return tags.map((tag) => Chip(label: Text(tag), onDeleted: () {})).toList();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UILimitedWrap Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('UILimitedWrap Demo')),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: LimitedWrapExampleWidget(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
class AdminBoothFormScreen extends StatelessWidget {
  final String exhibitionId;
  final String? boothId;
  const AdminBoothFormScreen({super.key, required this.exhibitionId, this.boothId});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Booth Form')));
}

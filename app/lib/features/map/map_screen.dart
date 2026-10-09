import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

// TODO(amer): step 4 builds the concept map + readiness here.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) =>
      PlaceholderScreen(title: 'خريطتك', details: 'subjectId=$subjectId');
}

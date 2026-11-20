import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../widgets/pixel/pixel_screen_header.dart';
import 'profile_edit_panel.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.canvas,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: PixelScreenHeader(
              title: 'HỒ SƠ',
              subtitle: 'Avatar và biệt danh',
              onBackTap: () => Navigator.of(context).pop(),
            ),
          ),
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: ProfileEditPanel(),
            ),
          ),
        ],
      ),
    );
  }
}
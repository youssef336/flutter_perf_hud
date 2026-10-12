import 'package:flutter/material.dart';

/// Shows a 2400×1600 asset as small thumbnails, with and without cacheWidth.
class OversizedImagePage extends StatefulWidget {
  const OversizedImagePage({super.key});

  @override
  State<OversizedImagePage> createState() => _OversizedImagePageState();
}

class _OversizedImagePageState extends State<OversizedImagePage> {
  final ValueNotifier<bool> _fixed = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _fixed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oversized image'),
        actions: [
          const Text('cacheWidth'),
          ValueListenableBuilder<bool>(
            valueListenable: _fixed,
            builder: (context, fixed, _) =>
                Switch(value: fixed, onChanged: (value) => _fixed.value = value),
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _fixed,
        builder: (context, fixed, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              fixed
                  ? 'Decoded at display size (cacheWidth = 120 × devicePixelRatio).'
                  : 'Decoded at full 2400×1600, then shown at 120 px wide. '
                        'Open the Images tab of the HUD.',
            ),
            const SizedBox(height: 16),
            Center(
              child: Image.asset(
                'assets/big_photo.png',
                key: ValueKey<bool>(fixed),
                width: 120,
                height: 80,
                fit: BoxFit.cover,
                cacheWidth: fixed ? (120 * dpr).round() : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

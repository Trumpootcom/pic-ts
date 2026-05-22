import 'package:flutter/material.dart';

import '../models/theme_pack.dart';
import '../services/theme_pack_loader.dart';
import '../widgets/tsts_dialog.dart';
import '../widgets/tsts_title_bar.dart';

class ThemeBrowserPage extends StatefulWidget {
  const ThemeBrowserPage({super.key});

  @override
  State<ThemeBrowserPage> createState() => _ThemeBrowserPageState();
}

class _ThemeBrowserPageState extends State<ThemeBrowserPage> {
  late final Future<List<ThemePack>> _themePacksFuture;

  @override
  void initState() {
    super.initState();
    _themePacksFuture = ThemePackLoader().loadThemePacks();
  }

  Future<void> _showNewProjectDialog(ThemePack pack) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return TstsDialog(
          title: 'Create New Project',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                pack.iconPath,
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                pack.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Color(0xFF7A6328), width: 2),
                backgroundColor: const Color.fromARGB(255, 214, 193, 140),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF7A6328),
              ),
              onPressed: () {
                final projectName = controller.text.trim();

                if (projectName.isEmpty) {
                  return;
                }

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Create project "$projectName" from ${pack.name}',
                    ),
                  ),
                );

                // TODO:
                // ProjectStorage.createProject(...)
              },
              child: const Text('CREATE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TstsTitleBar(title: 'New Project'),
      body: FutureBuilder<List<ThemePack>>(
        future: _themePacksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final packs = snapshot.data ?? [];

          if (packs.isEmpty) {
            return const Center(child: Text('No theme packs found.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(18),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 0.9,
            ),
            itemCount: packs.length,
            itemBuilder: (context, index) {
              return _ThemePackTile(
                pack: packs[index],
                onTap: () => _showNewProjectDialog(packs[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _ThemePackTile extends StatelessWidget {
  final ThemePack pack;
  final VoidCallback onTap;

  static const double folderWidth = 120;

  const _ThemePackTile({required this.pack, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: folderWidth,
            height: 90 * folderWidth / 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.folder,
                  size: 100 * folderWidth / 120,
                  color: Colors.amber,
                ),
                Positioned(
                  right: (folderWidth - 42 * folderWidth / 120) / 2,
                  bottom: 14 * folderWidth / 120,
                  child: Image.asset(
                    pack.iconPath,
                    width: 42 * folderWidth / 120,
                    height: 42 * folderWidth / 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            pack.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeetingApp());
}

class MeetingApp extends StatelessWidget {
  const MeetingApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Controle de Reuniões',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const MeetingScreen(),
      );
}

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});
  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  WebViewController? controller;
  bool ready = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final webDir = Directory('${dir.path}/web');
      await webDir.create(recursive: true);
      final htmlFile = File('${webDir.path}/index.html');
      // Preserve the same file:// origin between launches for localStorage.
      await htmlFile.writeAsString(await rootBundle.loadString('assets/reunioes.html'));
      final webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xffF2F4F6))
        ..addJavaScriptChannel('NativeApp', onMessageReceived: _onMessage)
        ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) {
          if (mounted) setState(() => ready = true);
        }))
        ..loadFile(htmlFile.path);
      controller = webController;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> _onMessage(JavaScriptMessage message) async {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      switch (data['action']) {
        case 'wake':
          await WakelockPlus.enable();
          break;
        case 'sleep':
          await WakelockPlus.disable();
          break;
        case 'copy':
          await Clipboard.setData(ClipboardData(text: data['text'] as String));
          break;
        case 'csv':
          final dir = await getTemporaryDirectory();
          final name = (data['filename'] as String).replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
          final file = File('${dir.path}/$name');
          await file.writeAsString(data['text'] as String, flush: true);
          await Share.shareXFiles([XFile(file.path)], text: 'Exportação do Controle de Reuniões');
          break;
      }
    } catch (e) {
      debugPrint('Native bridge error: $e');
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: error != null
              ? Center(child: Text('Falha ao abrir o aplicativo: $error'))
              : controller == null
                  ? const Center(child: CircularProgressIndicator())
                  : !ready
                      ? Stack(children: [WebViewWidget(controller: controller!), const Center(child: CircularProgressIndicator())])
                      : WebViewWidget(controller: controller!),
        ),
      );
}

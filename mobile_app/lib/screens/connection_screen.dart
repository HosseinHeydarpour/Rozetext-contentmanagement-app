import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController _ipController = TextEditingController();
  bool _isConnecting = false;
  bool _isScannerOpen = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedServer();
  }

  Future<void> _loadSavedServer() async {
    final saved = await StorageService.getServerUrl();
    if (saved != null && saved.isNotEmpty) {
      _ipController.text = saved;
      // Auto test
      _connect(saved, isAuto: true);
    }
  }

  Future<void> _connect(String url, {bool isAuto = false}) async {
    if (url.trim().isEmpty) {
      setState(() => _errorMessage = 'لطفاً آدرس IP سرور را وارد کنید');
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    final success = await ApiService.testConnection(url);

    if (!mounted) return;

    if (success) {
      await StorageService.setServerUrl(url);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _isConnecting = false;
        if (!isAuto) {
          _errorMessage =
              'امکان اتصال به سرور وجود ندارد. لطفاً اطمینان حاصل کنید گوشی و کامپیوتر به یک وای‌فای مشترک متصل باشند.';
        }
      });
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'اتصال به کامپیوتر',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo / Header Icon
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE1306C), Color(0xFFF77737)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE1306C).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_tethering_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'همگام‌سازی محتوای اینستاگرام',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'کد QR نمایش داده شده در داشبورد کامپیوتر را اسکن کنید، یا آدرس IP محلی را دستی وارد نمایید.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Scanner View or Button
              if (_isScannerOpen)
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.pinkAccent, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      MobileScanner(
                        onDetect: (capture) {
                          final barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null) {
                              setState(() => _isScannerOpen = false);
                              _connect(barcode.rawValue!);
                              break;
                            }
                          }
                        },
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () =>
                              setState(() => _isScannerOpen = false),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isScannerOpen = true),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                  label: const Text(
                    'اسکن کد QR از روی مانیتور',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE1306C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),

              const SizedBox(height: 24),

              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white24)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'یا ورود دستی IP',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white24)),
                ],
              ),

              const SizedBox(height: 24),

              // Manual IP Input
              TextField(
                controller: _ipController,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  hintText: 'http://192.168.1.100:3000',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.computer_rounded, color: Colors.white60),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.pinkAccent),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],

              const SizedBox(height: 16),

              // Connect Button
              OutlinedButton(
                onPressed: _isConnecting
                    ? null
                    : () => _connect(_ipController.text),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'برقراری اتصال',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 24),

              // Offline view option
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                child: const Text(
                  'ورود به برنامه با محتوای ذخیره شده (آفلاین)',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

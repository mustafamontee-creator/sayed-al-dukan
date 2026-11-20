import 'package:flutter/material.dart';

void main() => runApp(const XXXApp());

const _pin = '011780';
const _blue = Color(0xFF1717E8);

class XXXApp extends StatelessWidget {
  const XXXApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'XXX', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(primary: _blue, surface: Color(0xFF111111)),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: _blue),
      useMaterial3: true),
    home: const PinLogin(),
  );
}

class PinLogin extends StatefulWidget {
  const PinLogin({super.key});
  @override State<PinLogin> createState() => _PinLoginState();
}
class _PinLoginState extends State<PinLogin> {
  final pinController = TextEditingController();
  String? error;
  void enter() {
    if (pinController.text == _pin) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ManagerHome()));
    } else { setState(() => error = 'الرمز غير صحيح'); pinController.clear(); }
  }
  @override void dispose() { pinController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(28), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.blur_circular, size: 84, color: _blue),
      const SizedBox(height: 14),
      const Text('XXX', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 4, color: _blue)),
      const Text('إدارة سيد الدكان', style: TextStyle(color: _blue)), const SizedBox(height: 48),
      TextField(controller: pinController, obscureText: true, keyboardType: TextInputType.number,
        textAlign: TextAlign.center, maxLength: 6, decoration: InputDecoration(counterText: '',
        hintText: '••••••', hintStyle: const TextStyle(letterSpacing: 10, color: _blue),
        prefixIcon: const Icon(Icons.lock_outline, color: _blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))), onSubmitted: (_) => enter()),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: _blue))),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: enter,
        style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
        child: const Text('دخول', style: TextStyle(fontWeight: FontWeight.bold)))),
      const SizedBox(height: 18),
      OutlinedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم تفعيل البصمة وFace ID عند ربط المصادقة')),
      ), icon: const Icon(Icons.fingerprint, size: 30, color: _blue), label: const Text('الدخول بالبصمة'),
        style: OutlinedButton.styleFrom(foregroundColor: _blue, side: const BorderSide(color: _blue), minimumSize: const Size(double.infinity, 50))),
    ]))))));
}

class ManagerHome extends StatelessWidget {
  const ManagerHome({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('XXX')),
    body: const Center(child: Text('واجهة الإدارة الرئيسية', style: TextStyle(fontSize: 24, color: _blue))));
}

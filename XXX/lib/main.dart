import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

void main() => runApp(const XXXApp());

const blue = Color(0xFF3030FF);
const bg = Color(0xFF050505);
const panel = Color(0xFF111111);
const border = Color(0xFF252545);

class XXXApp extends StatelessWidget {
  const XXXApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'XXX',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(primary: blue, surface: panel),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    home: const LoginPage(),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final code = TextEditingController();
  String? error;
  void enter() {
    if (code.text.trim().isEmpty) {
      setState(() => error = 'أدخل رمز الاختبار');
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
  }
  Future<void> biometric() async {
    try {
      final auth = LocalAuthentication();
      if (!await auth.isDeviceSupported()) {
        show('المصادقة البيومترية غير مدعومة');
        return;
      }
      final ok = await auth.authenticate(
        localizedReason: Platform.isAndroid ? 'تحقق من هويتك' : 'تحقق باستخدام Face ID',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (ok && mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } catch (_) { show('تعذر تشغيل المصادقة'); }
  }
  void show(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  void dispose() { code.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.shield_outlined, color: blue, size: 64),
        const SizedBox(height: 16), const Text('XXX', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: blue)),
        const Text('إدارة سيد الدكان', style: TextStyle(color: Colors.white60)),
        const SizedBox(height: 36),
        TextField(controller: code, obscureText: true, textAlign: TextAlign.center, decoration: const InputDecoration(labelText: 'رمز اختبار الدخول')),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.redAccent))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: enter, style: ElevatedButton.styleFrom(backgroundColor: blue), child: const Text('دخول'))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(onPressed: biometric, icon: const Icon(Icons.fingerprint), label: const Text('بصمة / Face ID'))),
        const SizedBox(height: 12), const Text('نسخة تجريبية فقط — لا تستخدم بيانات حقيقية', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
      ]),
    ),
  ))));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  static const items = <(String, IconData)>[
    ('الألوان والتصميم', Icons.palette_outlined), ('المنتجات والأسعار', Icons.inventory_2_outlined),
    ('الصفحات والواجهات', Icons.dashboard_outlined), ('الأقسام والبنرات', Icons.view_carousel_outlined),
    ('الطلبات والعملاء', Icons.shopping_bag_outlined), ('النصوص والمحتوى', Icons.text_fields),
    ('الحقول والميزات', Icons.extension_outlined), ('الإعدادات العامة', Icons.settings_outlined),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('XXX • مركز الإدارة')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('مركز الإدارة', style: TextStyle(color: blue, fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.08),
        itemCount: items.length, itemBuilder: (context, i) => CardTile(title: items[i].$1, icon: items[i].$2,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => i == 1 ? const ProductsPage() : PlaceholderSection(title: items[i].$1, icon: items[i].$2))))),
    ]),
  );
}
class CardTile extends StatelessWidget {
  final String title; final IconData icon; final VoidCallback onTap;
  const CardTile({super.key, required this.title, required this.icon, required this.onTap});
  @override Widget build(BuildContext context) => Material(color: panel, borderRadius: BorderRadius.circular(20),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: border), borderRadius: BorderRadius.circular(20),
      ), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Icon(icon, color: blue, size: 30), Text(title, style: const TextStyle(fontWeight: FontWeight.w600))]))));
}
class PlaceholderSection extends StatelessWidget {
  final String title; final IconData icon;
  const PlaceholderSection({super.key, required this.title, required this.icon});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: blue, size: 64), const SizedBox(height: 16), Text(title, style: const TextStyle(fontSize: 22)), const SizedBox(height: 8), const Text('القسم قيد التجهيز', style: TextStyle(color: Colors.white60))])));
}
class Product {
  final String name, price, description;
  const Product(this.name, this.price, this.description);
}
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});
  @override State<ProductsPage> createState() => _ProductsPageState();
}
class _ProductsPageState extends State<ProductsPage> {
  final products = <Product>[];
  Future<void> add() async {
    final product = await Navigator.push<Product>(context, MaterialPageRoute(builder: (_) => const ProductEditor()));
    if (product != null && mounted) setState(() => products.add(product));
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('المنتجات والأسعار')),
    floatingActionButton: FloatingActionButton.extended(onPressed: add, backgroundColor: blue, icon: const Icon(Icons.add), label: const Text('إضافة منتج')),
    body: products.isEmpty ? const Center(child: Text('أضف المنتجات التي تختارها')) : ListView.builder(itemCount: products.length,
      itemBuilder: (context, i) => Card(color: panel, child: ListTile(title: Text(products[i].name), subtitle: Text(products[i].price), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductPreview(product: products[i])))))));
}
class ProductEditor extends StatefulWidget {
  const ProductEditor({super.key});
  @override State<ProductEditor> createState() => _ProductEditorState();
}
class _ProductEditorState extends State<ProductEditor> {
  final name = TextEditingController(); final price = TextEditingController(); final description = TextEditingController();
  @override void dispose() { name.dispose(); price.dispose(); description.dispose(); super.dispose(); }
  void preview() {
    if (name.text.trim().isEmpty || price.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب الاسم والسعر'))); return; }
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductPreview(product: Product(name.text, price.text, description.text), editable: true)));
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('إضافة منتج')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم المنتج')), const SizedBox(height: 14),
      TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر')), const SizedBox(height: 14),
      TextField(controller: description, maxLines: 4, decoration: const InputDecoration(labelText: 'الوصف')), const SizedBox(height: 20),
      SizedBox(height: 52, child: ElevatedButton(onPressed: preview, style: ElevatedButton.styleFrom(backgroundColor: blue), child: const Text('معاينة'))),
    ]));
}
class ProductPreview extends StatelessWidget {
  final Product product; final bool editable;
  const ProductPreview({super.key, required this.product, this.editable = false});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('معاينة المنتج')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(height: 220, decoration: BoxDecoration(color: panel, border: Border.all(color: border), borderRadius: BorderRadius.circular(20)), child: const Center(child: Icon(Icons.image_outlined, color: blue, size: 72))),
      const SizedBox(height: 18), Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      Text(product.price, style: const TextStyle(color: blue, fontSize: 20)), const SizedBox(height: 12), Text(product.description),
      const SizedBox(height: 24), ElevatedButton(onPressed: () => Navigator.pop(context, product), child: Text(editable ? 'اعتماد تجريبي' : 'رجوع')),
      OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('رجوع')),
    ]));
}

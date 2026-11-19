import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/settings_controller.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _rating = 0;
  final _comment = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _rating = p.getInt('app_rating') ?? 0;
      _comment.text = p.getString('app_rating_comment') ?? '';
    });
  }

  Future<void> _saveRating() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('app_rating', _rating);
    await p.setString('app_rating_comment', _comment.text.trim());
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شكراً لتقييمك سيد الدكان')));
  }

  Future<void> _openInstagram(String handle) async {
    final uri = Uri.parse('https://www.instagram.com/$handle/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Widget _faq(String q, String a) => ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [Padding(padding: const EdgeInsets.only(bottom: 14), child: Align(alignment: Alignment.centerRight, child: Text(a)))],
      );

  @override
  Widget build(BuildContext context) {
    final en = context.watch<SettingsController>().lang == 'en';
    return SafeArea(
      child: ListView(padding: const EdgeInsets.all(20), children: [
        const Center(child: Icon(Icons.info_outline, size: 46)),
        const SizedBox(height: 8),
        Center(child: Text(en ? 'About us' : 'نبذة عننا', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        const Center(child: Text('سوق المنتجات السودانية في مكان واحد', textAlign: TextAlign.center)),
        const SizedBox(height: 20),
        Text(en ? 'About us' : 'من نحن؟', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(en
            ? 'Sayed Al-Dukan brings Sudanese products together in one place. We aim to make discovering products and placing orders simple and clear for everyone interested in Sudanese goods.'
            : 'سيد الدكان منصة تجمع المنتجات السودانية في مكان واحد، وهدفنا نسهل عليك اكتشاف المنتجات السودانية وطلبها بطريقة بسيطة وواضحة. بنسعى نوصل المنتجات المميزة للناس المهتمين بيها، ونخلي تجربة التسوق أسهل خطوة بخطوة.'),
        const SizedBox(height: 18),
        Text(en ? 'Frequently asked questions' : 'الأسئلة الشائعة', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        _faq(en ? 'How do I order?' : 'كيف أطلب منتج؟', en ? 'Open the product, choose the quantity, add it to your cart, then complete the order and select your address.' : 'افتح المنتج، اختار الكمية المناسبة، أضفه للسلة، وبعدها اضغط إتمام الطلب وحدد عنوانك وأرسل الطلب.'),
        _faq(en ? 'Do I need an account?' : 'هل لازم أسجل حساب؟', en ? 'You can browse the shop without signing in. Sign-in is required when you proceed to checkout.' : 'تقدر تتصفح الدكان بدون تسجيل دخول، لكن تسجيل الدخول مطلوب عند إتمام الطلب.'),
        _faq(en ? 'What is the minimum order?' : 'شنو الحد الأدنى للطلب؟', en ? 'Some products have a minimum order value. The product page shows the required minimum before adding it to your cart.' : 'بعض المنتجات عندها حد أدنى لقيمة الطلب. حتلقى القيمة موضحة في صفحة المنتج قبل إضافته للسلة.'),
        _faq(en ? 'Can I save more than one address?' : 'ممكن أحفظ أكثر من عنوان؟', en ? 'Yes. Add and save addresses from your account, then choose the suitable address during checkout.' : 'أيوه، تقدر تضيف وتحفظ أكثر من عنوان من صفحة الحساب، وتختار العنوان المناسب وقت إتمام الطلب.'),
        _faq(en ? 'How can I contact support?' : 'كيف أتواصل مع الدعم الفني؟', en ? 'Open Settings, choose Technical Support, and use the developer Instagram contact.' : 'افتح الإعدادات واختار الدعم الفني، أو تواصل مع المطوّر عبر حساب إنستغرام الموجود أدناه.'),
        _faq(en ? 'Which payment and delivery methods are available?' : 'شنو طرق الدفع والتوصيل؟', en ? 'Available details will be shown during checkout. The app does not promise a payment or delivery option that is not displayed there.' : 'التفاصيل المتاحة حتظهر ليك أثناء إتمام الطلب. التطبيق ما بوعد بطريقة دفع أو توصيل غير المعروضة وقت الطلب.'),
        Divider(color: Theme.of(context).dividerColor),
        Text(en ? 'Developer' : 'المطوّر', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(en ? 'Sayed Al-Dukan app developer' : 'تطوير تطبيق سيد الدكان'),
        Wrap(spacing: 8, runSpacing: 4, children: [
          TextButton.icon(onPressed: () => _openInstagram('msvux'), icon: const Icon(Icons.camera_alt_outlined), label: const Text('@msvux')),
          TextButton.icon(onPressed: () => _openInstagram('mf_abody'), icon: const Icon(Icons.camera_alt_outlined), label: const Text('@mf_abody')),
        ]),
        Divider(color: Theme.of(context).dividerColor),
        Text(en ? 'Rate the app' : 'قيّم التطبيق', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Center(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => IconButton(
                onPressed: () => setState(() { _rating = i + 1; _saved = false; }),
                icon: Icon(i < _rating ? Icons.star : Icons.star_border,
                    size: 34, color: Theme.of(context).colorScheme.primary),
              )),
            ),
          ),
        ),
        TextField(controller: _comment, maxLines: 3, onChanged: (_) => setState(() => _saved = false), decoration: InputDecoration(labelText: en ? 'Write a comment (optional)' : 'اكتب تعليقك (اختياري)')),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _rating == 0 ? null : _saveRating, child: Text(en ? 'Save rating' : 'حفظ التقييم')),
        if (_saved) const Padding(padding: EdgeInsets.only(top: 8), child: Text('تم حفظ تقييمك على هذا الجهاز', textAlign: TextAlign.center)),
      ]),
    );
  }
}

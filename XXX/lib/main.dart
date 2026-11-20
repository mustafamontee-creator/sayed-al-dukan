import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const brand = Color(0xFF4E759C);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: key);
  }
  runApp(const XXXApp());
}

class XXXApp extends StatelessWidget {
  const XXXApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'XXX Manager', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: brand), scaffoldBackgroundColor: const Color(0xFFF6F8FA), useMaterial3: true),
    home: const LoginScreen(),
  );
}

class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState() => _LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(); final password = TextEditingController(); bool busy = false; String? error;
  Future<void> login() async {
    if (!Supabase.instance.isInitialized) { setState(() => error='Configure Supabase URL and key first.'); return; }
    setState(() {busy=true; error=null;});
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      final uid = res.user?.id;
      if (uid == null) throw Exception('Login failed');
      // Server-side authorization is required: manager role must be verified before granting access.
      final role = await Supabase.instance.client.from('user_roles').select('role').eq('user_id', uid).maybeSingle();
      if (role?['role'] != 'manager') { await Supabase.instance.client.auth.signOut(); throw Exception('This account is not authorized.'); }
      if (!mounted) return; Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ManagerHome()));
    } catch(e) { if(mounted) setState(()=>error=e.toString().replaceFirst('Exception: ','')); }
    finally { if(mounted) setState(()=>busy=false); }
  }
  @override void dispose(){email.dispose();password.dispose();super.dispose();}
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.storefront_rounded, size: 86, color: brand), const SizedBox(height: 12), const Text('XXX', style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: brand)), const Text('Manager',style: TextStyle(color: Colors.black54)), const SizedBox(height: 36),
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText:'Email',border:OutlineInputBorder())), const SizedBox(height: 14),
    TextField(controller: password, obscureText:true, decoration:const InputDecoration(labelText:'Password',border:OutlineInputBorder())), const SizedBox(height:20),
    if(error!=null) Padding(padding:const EdgeInsets.only(bottom:12),child:Text(error!,style:const TextStyle(color:Colors.red))),
    SizedBox(width:double.infinity,height:50,child:ElevatedButton(onPressed:busy?null:login,style:ElevatedButton.styleFrom(backgroundColor:brand,foregroundColor:Colors.white),child:busy?const CircularProgressIndicator(color:Colors.white):const Text('GO'))),
  ])))));
}

class ManagerHome extends StatelessWidget { const ManagerHome({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('XXX Manager'),backgroundColor:brand,foregroundColor:Colors.white,actions:[IconButton(onPressed:()=>Supabase.instance.client.auth.signOut().then((_) {Navigator.of(context).pushReplacement(MaterialPageRoute(builder:(_)=>const LoginScreen()));}),icon:const Icon(Icons.logout))]),body:ListView(padding:const EdgeInsets.all(20),children:[
    _tile(context,Icons.inventory_2,'Products','Manage product names, prices, images and fields',const ProductsPlaceholder()),
  ]));
  Widget _tile(BuildContext c,IconData i,String title,String sub,Widget dest)=>Card(child:ListTile(leading:Icon(i,color:brand),title:Text(title),subtitle:Text(sub),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>dest))));
}
class ProductsPlaceholder extends StatelessWidget {const ProductsPlaceholder({super.key}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Products')),body:const Center(child:Text('Product management UI will be connected to the database next.')));}

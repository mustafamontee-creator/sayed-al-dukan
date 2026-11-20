import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:local_auth/local_auth.dart';

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
    home: const PinLogin());
}

class PinLogin extends StatefulWidget { const PinLogin({super.key}); @override State<PinLogin> createState()=>_PinLoginState(); }
class _PinLoginState extends State<PinLogin> {
 final pinController=TextEditingController(); String? error;
 void enter(){if(pinController.text==_pin){Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const ManagerHome()));}else{setState(()=>error='الرمز غير صحيح');pinController.clear();}}
 Future<void> biometricLogin() async { final auth=LocalAuthentication(); try { final available=await auth.getAvailableBiometrics(); final wanted=Platform.isAndroid?BiometricType.fingerprint:BiometricType.face; if(!available.contains(wanted)){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(Platform.isAndroid?'هذا الجهاز لا يوفر بصمة إصبع متاحة للتطبيق':'Face ID غير متاح على هذا الجهاز')));return;} final ok=await auth.authenticate(localizedReason:Platform.isAndroid?'استخدم بصمة الإصبع للدخول':'استخدم Face ID للدخول',options:const AuthenticationOptions(biometricOnly:true,stickyAuth:true)); if(ok&&mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const ManagerHome())); }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر استخدام المصادقة البيومترية')));}}
 @override void dispose(){pinController.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(28),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
 const Icon(Icons.blur_circular,size:84,color:_blue),const SizedBox(height:14),const Text('XXX',style:TextStyle(fontSize:34,fontWeight:FontWeight.bold,letterSpacing:4,color:_blue)),const Text('إدارة سيد الدكان',style:TextStyle(color:_blue)),const SizedBox(height:48),
 TextField(controller:pinController,obscureText:true,keyboardType:TextInputType.number,textAlign:TextAlign.center,maxLength:6,decoration:InputDecoration(counterText:'',hintText:'••••••',hintStyle:const TextStyle(letterSpacing:10,color:_blue),prefixIcon:const Icon(Icons.lock_outline,color:_blue),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14))),onSubmitted:(_)=>enter()),
 if(error!=null)Padding(padding:const EdgeInsets.only(top:8),child:Text(error!,style:const TextStyle(color:_blue))),
 const SizedBox(height:18),SizedBox(width:double.infinity,height:52,child:ElevatedButton(onPressed:enter,style:ElevatedButton.styleFrom(backgroundColor:_blue,foregroundColor:Colors.white),child:const Text('دخول'))),
 const SizedBox(height:18),OutlinedButton.icon(onPressed:biometricLogin,icon:const Icon(Icons.fingerprint,size:30,color:_blue),label:const Text('الدخول بالبصمة'),style:OutlinedButton.styleFrom(foregroundColor:_blue,side:const BorderSide(color:_blue),minimumSize:const Size(double.infinity,50)))
 ]))))));}
}

class ManagerHome extends StatelessWidget {const ManagerHome({super.key});
 static const items=[('الألوان والتصميم',Icons.palette_outlined),('المنتجات والأسعار',Icons.inventory_2_outlined),('الصفحات والواجهات',Icons.dashboard_outlined),('الأقسام والبنرات',Icons.view_carousel_outlined),('الطلبات والعملاء',Icons.shopping_bag_outlined),('النصوص والمحتوى',Icons.text_fields),('الحقول والميزات',Icons.extension_outlined),('الإعدادات العامة',Icons.settings_outlined)];
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('XXX  •  مركز الإدارة')),body:ListView(padding:const EdgeInsets.all(16),children:[const Text('مركز الإدارة الرئيسي',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:_blue)),const SizedBox(height:6),const Text('سيد الدكان',style:TextStyle(color:Colors.white70)),const SizedBox(height:20),GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.05),itemCount:items.length,itemBuilder:(context,i)=>InkWell(borderRadius:BorderRadius.circular(18),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>i==1?const ProductsPage():SectionPage(title:items[i].$1,icon:items[i].$2))),child:Container(decoration:BoxDecoration(color:const Color(0xFF101010),border:Border.all(color:_blue,width:1),borderRadius:BorderRadius.circular(18)),padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Icon(items[i].$2,color:_blue,size:32),Text(items[i].$1,style:const TextStyle(fontWeight:FontWeight.w600))])))),const SizedBox(height:16),Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(border:Border.all(color:_blue),borderRadius:BorderRadius.circular(16)),child:const Text('أي تغيير يتم تجهيزه ثم معاينته قبل اعتماده للنشر.',style:TextStyle(color:Colors.white70)))]));}

}
class SectionPage extends StatelessWidget {final String title;final IconData icon;const SectionPage({super.key,required this.title,required this.icon});@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(title)),body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,color:_blue,size:64),const SizedBox(height:16),Text(title,style:const TextStyle(fontSize:22)),const SizedBox(height:8),const Text('القسم قيد تجهيز أدواته',style:TextStyle(color:Colors.white70))])));}

class Product {final String name,price,description;const Product(this.name,this.price,this.description);}
class ProductsPage extends StatefulWidget {const ProductsPage({super.key});@override State<ProductsPage> createState()=>_ProductsPageState();}
class _ProductsPageState extends State<ProductsPage>{
 final List<Product> products=[]; 
 Future<void> addProduct()async{final result=await Navigator.push<Product>(context,MaterialPageRoute(builder:(_)=>const ProductEditor()));if(result!=null)setState(()=>products.add(result));}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('المنتجات والأسعار')),floatingActionButton:FloatingActionButton.extended(backgroundColor:_blue,foregroundColor:Colors.white,onPressed:addProduct,icon:const Icon(Icons.add),label:const Text('إضافة منتج')),body:products.isEmpty?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.inventory_2_outlined,color:_blue,size:70),const SizedBox(height:14),const Text('الدكان فارغ حالياً',style:TextStyle(fontSize:20)),const SizedBox(height:8),const Text('أضف المنتجات التي تختارها بنفسك',style:TextStyle(color:Colors.white70))])):ListView.builder(padding:const EdgeInsets.all(16),itemCount:products.length,itemBuilder:(_,i)=>Card(color:const Color(0xFF121212),child:ListTile(leading:const Icon(Icons.image_outlined,color:_blue),title:Text(products[i].name),subtitle:Text('${products[i].price} • ${products[i].description}'),trailing:const Icon(Icons.chevron_right,color:_blue),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProductPreview(product:products[i])))))));}
}
class ProductEditor extends StatefulWidget {const ProductEditor({super.key});@override State<ProductEditor> createState()=>_ProductEditorState();}
class _ProductEditorState extends State<ProductEditor>{final name=TextEditingController(),price=TextEditingController(),bio=TextEditingController();String imageLabel='لم يتم اختيار صورة بعد';
 @override void dispose(){name.dispose();price.dispose();bio.dispose();super.dispose();}
 Widget field(TextEditingController c,String label,{bool multiline=false,TextInputType? type})=>Padding(padding:const EdgeInsets.only(bottom:14),child:TextField(controller:c,keyboardType:type,maxLines:multiline?4:1,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
 void preview(){if(name.text.trim().isEmpty||price.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اكتب اسم المنتج والسعر أولاً')));return;}Navigator.push(context,MaterialPageRoute(builder:(_)=>ProductPreview(product:Product(name.text,price.text,bio.text),imageLabel:imageLabel)));}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('إضافة منتج')),body:ListView(padding:const EdgeInsets.all(20),children:[field(name,'اسم المنتج'),field(price,'السعر',type:TextInputType.number),field(bio,'الوصف / Bio',multiline:true),OutlinedButton.icon(onPressed:()=>setState(()=>imageLabel='مكان الصورة — ربط رفع الصور لاحقاً'),icon:const Icon(Icons.add_photo_alternate,color:_blue),label:const Text('إضافة صورة')),Text(imageLabel,style:const TextStyle(color:Colors.white60)),const SizedBox(height:20),SizedBox(height:50,child:ElevatedButton(onPressed:preview,style:ElevatedButton.styleFrom(backgroundColor:_blue,foregroundColor:Colors.white),child:const Text('معاينة')))]));}
}
class ProductPreview extends StatelessWidget{final Product product;final String imageLabel;const ProductPreview({super.key,required this.product,this.imageLabel='معاينة الصورة'});@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('معاينة المنتج')),body:ListView(padding:const EdgeInsets.all(20),children:[Container(height:220,decoration:BoxDecoration(color:const Color(0xFF141414),border:Border.all(color:_blue),borderRadius:BorderRadius.circular(16)),child:const Center(child:Icon(Icons.image_outlined,color:_blue,size:80))),const SizedBox(height:16),Text(product.name,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),Text(product.price,style:const TextStyle(color:_blue,fontSize:20)),const SizedBox(height:12),Text(product.description),const SizedBox(height:24),ElevatedButton(onPressed:()=>Navigator.pop(context,product),style:ElevatedButton.styleFrom(backgroundColor:_blue,foregroundColor:Colors.white),child:const Text('اعتماد (تجريبي)')),OutlinedButton(onPressed:()=>Navigator.pop(context),child:const Text('رجوع للتعديل'))]));}

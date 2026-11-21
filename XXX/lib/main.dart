import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const url='https://vusjswnvqbxspdgbekxc.supabase.co';
const key='sb_publishable_-FnAVg38wgT94t6kbSuT3A_mqmgs5mz';
const blue=Color(0xFF4E759C), dark=Color(0xff101418);
final db=Supabase.instance.client;
Future<void> main()async{WidgetsFlutterBinding.ensureInitialized();await Supabase.initialize(url:url,publishableKey:key);runApp(const App());}
class App extends StatelessWidget{const App({super.key});Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'XXX',theme:ThemeData.dark().copyWith(scaffoldBackgroundColor:dark,colorScheme:const ColorScheme.dark(primary:blue),appBarTheme:const AppBarTheme(backgroundColor:blue)),home:const Login());}
void toast(BuildContext c,String s)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s)));
class Login extends StatefulWidget{const Login({super.key});State<Login> createState()=>_LoginState();}
class _LoginState extends State<Login>{final e=TextEditingController(),p=TextEditingController();bool busy=false;
Future<void> login()async{if(e.text.trim().isEmpty||p.text.isEmpty){toast(context,'أدخل البريد وكلمة المرور');return;}setState(()=>busy=true);try{final r=await db.auth.signInWithPassword(email:e.text.trim(),password:p.text);if(r.user==null)throw Exception('تعذر تسجيل الدخول');final a=await db.from('admins').select('user_id').eq('user_id',r.user!.id).maybeSingle();if(a==null){await db.auth.signOut();throw Exception('الحساب غير مخوّل');}if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const Home()));}catch(x){if(mounted)toast(context,x.toString());}finally{if(mounted)setState(()=>busy=false);}}
Widget build(BuildContext c)=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.admin_panel_settings,size:75,color:blue),const Text('XXX',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold)),const Text('إدارة سيد الدكان'),const SizedBox(height:24),TextField(controller:e,decoration:const InputDecoration(labelText:'البريد الإلكتروني')),const SizedBox(height:12),TextField(controller:p,obscureText:true,decoration:const InputDecoration(labelText:'كلمة المرور')),const SizedBox(height:18),SizedBox(width:double.infinity,height:50,child:ElevatedButton(onPressed:busy?null:login,child:Text(busy?'جارٍ التحقق':'GO'))),const SizedBox(height:12),const Text('للمدير المصرّح به فقط',style:TextStyle(color:Colors.white54))])))));}
class Home extends StatefulWidget{const Home({super.key});State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{
 int products=0,orders=0,customers=0,reviews=0;bool loading=true;
 @override void initState(){super.initState();loadStats();}
 Future<void> loadStats()async{try{final results=await Future.wait([db.from('products').select('id'),db.from('orders').select('id'),db.from('profiles').select('id'),db.from('reviews').select('id')]);if(mounted)setState(()=>{products=results[0].length;orders=results[1].length;customers=results[2].length;reviews=results[3].length;});}catch(_){}if(mounted)setState(()=>loading=false);}
 Widget stat(String label,int value,IconData icon){return Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xff202832),borderRadius:BorderRadius.circular(18),border:Border.all(color:Colors.white10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:const Color(0xff8bb4d8),size:28),const SizedBox(height:14),Text(loading?'—':'$value',style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold)),Text(label,style:const TextStyle(color:Colors.white70))]));}
 Widget section(String title,IconData icon,String table){return Container(margin:const EdgeInsets.only(bottom:10),decoration:BoxDecoration(color:const Color(0xff202832),borderRadius:BorderRadius.circular(16)),child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:8),leading:Container(width:42,height:42,decoration:BoxDecoration(color:blue.withOpacity(.25),borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:const Color(0xff8bb4d8))),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w600)),trailing:const Icon(Icons.arrow_forward_ios,size:15,color:Colors.white54),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>DataPage(table:table,title:title))));}
 Future<void> logout()async{await db.auth.signOut();if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const Login()),(_)=>false);}
 Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('XXX'),actions:[IconButton(icon:const Icon(Icons.refresh),onPressed:loadStats),IconButton(icon:const Icon(Icons.logout),tooltip:'تسجيل الخروج',onPressed:logout)]),body:RefreshIndicator(onRefresh:loadStats,child:ListView(padding:const EdgeInsets.all(18),children:[
 Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[blue,Color(0xff31516f)]),borderRadius:BorderRadius.circular(22)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('مركز إدارة سيد الدكان',style:TextStyle(fontSize:23,fontWeight:FontWeight.bold)),SizedBox(height:8),Text('متابعة المتجر وإدارة محتواه من مكان واحد',style:TextStyle(color:Colors.white70)),SizedBox(height:18),Row(children:[Icon(Icons.verified_user,color:Colors.white),SizedBox(width:8),Text('جلسة مدير موثّقة')])]),
 const SizedBox(height:20),const Text('ملخص المتجر',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:12),
 GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.35,children:[stat('المنتجات',products,Icons.inventory_2),stat('الطلبات',orders,Icons.receipt_long),stat('العملاء',customers,Icons.people_alt),stat('التقييمات',reviews,Icons.star)]),
 const SizedBox(height:24),const Text('إدارة المتجر',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:12),
 section('المنتجات والأسعار والصور',Icons.inventory_2,'products'),section('الطلبات ومتابعتها',Icons.receipt_long,'orders'),section('العملاء',Icons.people,'profiles'),section('التقييمات',Icons.star,'reviews'),section('محتوى التطبيق',Icons.article,'app_content')
 ])));
}
class DataPage extends StatefulWidget{final String table,title;const DataPage({super.key,required this.table,required this.title});State<DataPage> createState()=>_DataPageState();}
class _DataPageState extends State<DataPage>{
Future<List<Map<String,dynamic>>> fetch()async{switch(widget.table){case 'products':return db.from('products').select().order('sort_order').order('created_at',ascending:false);case 'orders':return db.from('orders').select().order('created_at',ascending:false);case 'profiles':return db.from('profiles').select().order('created_at',ascending:false);case 'reviews':return db.from('reviews').select().order('created_at',ascending:false);case 'xxx_settings':return db.from(widget.table).select().order('updated_at',ascending:false);case 'xxx_pages':case 'xxx_categories':return db.from(widget.table).select().order('sort_order');case 'xxx_banners':case 'xxx_coupons':return db.from(widget.table).select();case 'xxx_customer_messages':case 'xxx_broadcasts':case 'xxx_admin_notices':case 'xxx_change_log':return db.from(widget.table).select().order('created_at',ascending:false);default:return db.from('app_content').select().order('sort_order');}}
Future<void> refresh()async{setState((){});}
Future<void> uploadImage(TextEditingController ctrl)async{final f=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:85);if(f==null)return;final path='${DateTime.now().millisecondsSinceEpoch}_${f.name}';await db.storage.from('product-images').upload(path,File(f.path));ctrl.text=db.storage.from('product-images').getPublicUrl(path);}
Future<void> form([Map<String,dynamic>? row])async{if(widget.table=='products'){await productForm(row);}else if(widget.table=='app_content'){await contentForm(row);}else if(widget.table=='orders'&&row!=null){await orderDetails(row);}refresh();}
Future<void> managerForm(Map<String,dynamic>? r)async{
 final fields=<String,List<String>>{'xxx_settings':['setting_key','setting_value'],'xxx_categories':['title','image_url','sort_order','visible','draft'],'xxx_pages':['title','page_key','icon_name','payload','visible','draft','sort_order'],'xxx_banners':['title','image_url','link_payload','starts_at','ends_at','visible','draft'],'xxx_coupons':['code','discount_type','discount_value','starts_at','ends_at','usage_limit','active'],'xxx_customer_messages':['customer_name','subject','order_id','message','manager_reply','status'],'xxx_broadcasts':['message','audience','scheduled_at','draft'],'xxx_admin_notices':['title','body','starts_at','ends_at','draft']};
 final keys=fields[widget.table];if(keys==null)return;
 final ctrls={for(final k in keys)k:TextEditingController(text:r==null?'':(r[k] is Map||r[k] is List?'JSON:'+jsonEncode(r[k]):(r[k]?.toString()??'')))};
 final bools={for(final k in keys)k:(r?[k] is bool?r![k] as bool:false)};
 final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:Text((r==null?'إضافة • ':'تعديل • ')+widget.title),content:SizedBox(width:440,child:SingleChildScrollView(child:Column(children:keys.map((k){if(['visible','draft','active'].contains(k))return SwitchListTile(title:Text(k),value:bools[k]??false,onChanged:(v)=>setD(()=>bools[k]=v));return TextField(controller:ctrls[k],maxLines:['message','manager_reply','body','setting_value','payload','link_payload'].contains(k)?5:1,decoration:InputDecoration(labelText:k));}).toList()))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),ElevatedButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ'))])));
 if(ok!=true)return;final data=<String,dynamic>{};for(final k in keys){if(['visible','draft','active'].contains(k)){data[k]=bools[k];continue;}final value=ctrls[k]!.text;if(['sort_order','usage_limit','discount_value'].contains(k)){data[k]=num.tryParse(value);}else if(['payload','link_payload','setting_value'].contains(k)){try{data[k]=jsonDecode(value);}catch(_){data[k]=value;}}else{data[k]=value.isEmpty?null:value;}}if(r==null){await db.from(widget.table).insert(data);}else{await db.from(widget.table).update(data).eq('id',r['id']);}
}
Future<void> productForm(Map<String,dynamic>? r)async{
 final name=TextEditingController(text:r?['name']??''),price=TextEditingController(text:'${r?['unit_price']??''}'),min=TextEditingController(text:'${r?['min_order_value']??0}'),desc=TextEditingController(text:r?['description']??''),ingredients=TextEditingController(text:(r?['ingredients'] as List? ?? []).join(', ')),image=TextEditingController(text:r?['image_url']??''),sort=TextEditingController(text:'${r?['sort_order']??0}');
 bool active=r?['is_active']??true;
 final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD){
  return AlertDialog(title:Text(r==null?'إضافة منتج':'تعديل المنتج'),content:SizedBox(width:420,child:SingleChildScrollView(child:Column(children:[
   TextField(controller:name,decoration:const InputDecoration(labelText:'الاسم')),
   TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر')),
   TextField(controller:min,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الحد الأدنى')),
   TextField(controller:desc,maxLines:3,decoration:const InputDecoration(labelText:'الوصف')),
   TextField(controller:ingredients,decoration:const InputDecoration(labelText:'المكونات (مفصولة بفواصل)')),
   TextField(controller:sort,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'ترتيب العرض')),
   TextField(controller:image,decoration:const InputDecoration(labelText:'رابط الصورة')),
   ElevatedButton.icon(onPressed:()=>uploadImage(image).then((_)=>setD((){})),icon:const Icon(Icons.upload),label:const Text('رفع صورة')),
   if(image.text.isNotEmpty)Image.network(image.text,height:100,errorBuilder:(_,__,___)=>const Text('الصورة غير متاحة')),
   SwitchListTile(value:active,title:const Text('نشط في المتجر'),onChanged:(v)=>setD(()=>active=v))
  ]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),ElevatedButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ'))]);
 }));
 if(ok!=true)return;
 if(name.text.trim().isEmpty||double.tryParse(price.text)==null){toast(context,'الاسم والسعر الصحيح مطلوبان');return;}
 final data={'name':name.text.trim(),'unit_price':double.parse(price.text),'min_order_value':double.tryParse(min.text)??0,'description':desc.text,'ingredients':ingredients.text.split(',').map((s)=>s.trim()).where((s)=>s.isNotEmpty).toList(),'image_url':image.text.isEmpty?null:image.text,'sort_order':int.tryParse(sort.text)??0,'is_active':active};
 if(r==null)await db.from('products').insert(data);else await db.from('products').update(data).eq('id',r['id']);
}
Future<void> contentForm(Map<String,dynamic>? r)async{
 if(r==null)return;
 final title=TextEditingController(text:r['title']??''),body=TextEditingController(text:r['body']??''),image=TextEditingController(text:r['image_url']??'');
 bool published=r['is_published']??true;
 final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD){
  return AlertDialog(title:Text('تعديل المحتوى • ${r['section']}'),content:SingleChildScrollView(child:Column(children:[
   TextField(controller:title,decoration:const InputDecoration(labelText:'العنوان')),
   TextField(controller:body,maxLines:7,decoration:const InputDecoration(labelText:'النص')),
   TextField(controller:image,decoration:const InputDecoration(labelText:'رابط الصورة')),
   ElevatedButton.icon(onPressed:()=>uploadImage(image).then((_)=>setD((){})),icon:const Icon(Icons.upload),label:const Text('رفع صورة')),
   SwitchListTile(value:published,title:const Text('نشر المحتوى'),onChanged:(v)=>setD(()=>published=v))
  ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),ElevatedButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ'))]);
 }));
 if(ok==true)await db.from('app_content').update({'title':title.text,'body':body.text,'image_url':image.text.isEmpty?null:image.text,'is_published':published}).eq('id',r['id']);
}
Future<void> orderDetails(Map<String,dynamic> o)async{
 final items=await db.from('order_items').select().eq('order_id',o['id']);
 final events=await db.from('order_events').select().eq('order_id',o['id']).order('created_at');
 const sts=['pending','confirmed','processing','shipped','delivered','cancelled'];
 const names={'pending':'جديد','confirmed':'مؤكد','processing':'قيد التجهيز','shipped':'تم الشحن','delivered':'تم التسليم','cancelled':'ملغي'};
 String status=o['status']??'pending';if(!mounted)return;
 await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD){
  return AlertDialog(title:Text('طلب ${o['order_number']}'),content:SizedBox(width:450,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Text('المبلغ: ${o['total']}'),Text('العميل: ${o['user_id']}'),Text('العنوان: ${o['address_snapshot']}'),const Divider(),const Text('المنتجات',style:TextStyle(fontWeight:FontWeight.bold)),
   ...items.map((it)=>ListTile(title:Text(it['product_name']),subtitle:Text('الكمية: ${it['quantity']} • ${it['unit_price']}'),trailing:Text('${it['line_total']}'))),const Divider(),const Text('تحديث الحالة'),
   DropdownButton<String>(value:sts.contains(status)?status:sts.first,items:sts.map((s)=>DropdownMenuItem(value:s,child:Text(names[s]!))).toList(),onChanged:(v)=>v==null?null:setD(()=>status=v)),
   const Text('سجل الحالة'),...events.map((ev)=>Text('${ev['status']} • ${ev['created_at']}'))
  ]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إغلاق')),ElevatedButton(onPressed:()async{
   await db.from('order_statuses').upsert(sts.asMap().entries.map((e)=>{'code':e.value,'sort_order':e.key}).toList(),onConflict:'code');
   await db.from('orders').update({'status':status}).eq('id',o['id']);
   await db.from('order_events').insert({'order_id':o['id'],'status':status,'actor':db.auth.currentUser!.id,'note':'تحديث من الإدارة'});
   if(ctx.mounted)Navigator.pop(ctx);
  },child:const Text('حفظ الحالة'))]);
 }));
}
Future<void> delete(Map<String,dynamic> r)async{if(widget.table!='products'&&widget.table!='reviews')return;await db.from(widget.table).delete().eq('id',r['id']);refresh();}
Widget tile(Map<String,dynamic> r){switch(widget.table){case 'products':return ListTile(leading:r['image_url']==null?const Icon(Icons.image):Image.network(r['image_url'],width:52,height:52,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.broken_image)),title:Text(r['name']??''),subtitle:Text('${r['unit_price']} • ${r['is_active']==true?'نشط':'مخفي'}'),onTap:()=>form(r),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>delete(r)));case 'orders':return ListTile(title:Text('طلب ${r['order_number']} • ${r['total']}'),subtitle:Text('${r['status']} • ${r['created_at']}'),onTap:()=>form(r));case 'profiles':return ListTile(title:Text(r['full_name']??'عميل'),subtitle:Text('${r['contact_phone']??''} • ${r['region']??''}\n${r['id']}'));case 'reviews':return ListTile(title:Text('${r['author_name']} • ${r['rating']}★'),subtitle:Text(r['comment']??''),trailing:IconButton(icon:const Icon(Icons.delete),onPressed:()=>delete(r)));default:return ListTile(title:Text(r['title']??r['code']??r['setting_key']??r['customer_name']??r['message']??r['section']??'سجل'),subtitle:Text(r['status']??r['code']??r['setting_key']??r['message']??r['section']??''),onTap:()=>form(r),trailing:widget.table.startsWith('xxx_')&&widget.table!='xxx_change_log'?IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>db.from(widget.table).delete().eq('id',r['id']).then((_)=>refresh())):null);}}
Widget build(BuildContext c) => Scaffold(
  appBar: AppBar(
    title: Text(widget.title),
    actions: [if (widget.table == 'products'||(widget.table.startsWith('xxx_')&&widget.table!='xxx_change_log')) IconButton(icon: const Icon(Icons.add), onPressed: () => form())],
  ),
  body: FutureBuilder<List<Map<String, dynamic>>>(
    future: fetch(),
    builder: (c, s) {
      if (s.hasError) return Center(child: Text('خطأ: ${s.error}'));
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      if (s.data!.isEmpty) return Center(child: Text(widget.table.startsWith('xxx_')&&widget.table!='xxx_change_log'?'لا توجد بيانات • استخدم + للإضافة':'لا توجد بيانات'));
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView.builder(
          itemCount: s.data!.length,
          itemBuilder: (c, i) => Card(child: tile(s.data![i])),
        ),
      );
    },
  ),
);
}

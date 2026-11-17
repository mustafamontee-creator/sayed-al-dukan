# الخدمات الخارجية المطلوبة (لا شيء منها مُفعّل)

| الخدمة | المطلوب منك | أين يوضع |
|---|---|---|
| **Supabase** (قاعدة البيانات + الدخول + التخزين) | إنشاء مشروع وتشغيل `schema.sql` | `SUPABASE_URL` و`SUPABASE_PUBLISHABLE_KEY` عبر `--dart-define` |
| **رسائل SMS لرمز الهاتف** | Authentication > Providers > Phone، ثم ربط مزوّد (Twilio/MessageBird/Vonage…) | لوحة Supabase |
| **Google Sign-In** | OAuth client (Web) من Google Cloud، ثم Providers > Google | لوحة Supabase |
| **Apple Sign-In** | حساب Apple Developer + Service ID، ثم Providers > Apple (يظهر على أجهزة Apple فقط) | لوحة Supabase |
| **رابط العودة بعد الدخول** | أضف `io.supabase.sayedaldukan://login-callback/` في Authentication > URL Configuration > Redirect URLs | لوحة Supabase |
| **الإشعارات** | الكود لا يُطلب إذن الإشعارات في هذه النسخة. تفعيل إشعارات الطلبات لاحقاً يحتاج اختياراً صريحاً من العميل، وFirebase Cloud Messaging (+APNs لـ iOS)، ومهمة خادم ترسل عند تغيّر حالة الطلب | لاحقاً مع تطبيق XXX |
| **توقيع الإصدار** | keystore خاص بك قبل النشر على Google Play (البناء الحالي يوقّع بمفتاح debug) | `android/key.properties` |
| **iOS** | الكود مشترك لكن لم يُجهَّز بالكامل: أضف `NSLocationWhenInUseUsageDescription` في إعدادات iOS | يدوياً |

صور المنتجات: ارفعها إلى bucket اسمه `product-images` (قراءة عامة، كتابة للإدارة فقط).
للتحويل إلى حساب إدارة: `insert into public.admins(user_id) values ('<uuid>');`

- **OpenStreetMap tiles:** تستخدم شاشة العنوان خادم البلاطات العام للاختبار الأولي دون API key. قبل الإطلاق التجاري الواسع يجب اختيار مزوّد بلاطات مناسب ومراجعة شروطه وسياسة الاستخدام.

# مسار · Masar

**تطبيق تعلّم تكيّفي لطلاب الجامعات بالأردن.** بيعرف وين الطالب واقف بكل مفهوم، وبيبنيله خطة يومية
على نقاط ضعفه، مرتبة حسب قديش كل مفهوم بيتكرر بالامتحانات الحقيقية.

> JORDAN.NEXT() · Smart Society & Public Services · **Education & learning**
> *"Students learn at different paces with uneven access to support."*

*An adaptive learning app for Jordanian university students. A short diagnostic builds a mastery map for
every concept, a daily plan targets the weakest high-frequency concepts from real past exams, and the
practice uses real past-exam questions.*

---

## للحكّام · For the judges
| | |
|---|---|
| **تطبيق الأندرويد الحالي** | ابنِه من الكود باتباع [دليل التشغيل](docs/RUN.md)؛ نسخة v1.0.0 القديمة أرشيف المسابقة |
| **لوحة الإدارة** | [masar-hackathon-jo-2026-salah.web.app](https://masar-hackathon-jo-2026-salah.web.app) |
| حساب الحكّام (عرض فقط) | `judges@masar-demo.com` · كلمة المرور: `12345678` |
| **دليل التشغيل الكامل** | [docs/RUN.md](docs/RUN.md) |
| **العرض** | [PowerPoint](presentation/Masar-presentation.pptx) · [PDF](presentation/Masar-presentation.pdf) |
| **عرض لوحة الإدارة** | [PowerPoint](presentation/Masar-admin-dashboard.pptx) · [PDF](presentation/Masar-admin-dashboard.pdf) |

> حساب الحكّام **للعرض فقط**: بيشوف كل صفحات لوحة الإدارة، والتعديل مقفول من السيرفر.
> *The judges' account is read-only: every admin page is visible, and all writes are blocked server-side.*

## شو بيعمل
| | |
|---|---|
| **تشخيص قصير** | 8 أسئلة من امتحانات سابقة حقيقية، وبيبيّن صح أو خطأ مع نتيجتك أول بأول. |
| **خريطة المفاهيم** | نسبة إتقان لكل مفهوم بالمادة، ونسبة **جاهزية** للامتحان. |
| **خطة اليوم** | أسئلة على المفاهيم الضعيفة، والأولوية للي بيتكرر أكثر بالامتحانات. |
| **خزنة** | بنك امتحانات سابقة كتبويب جوّا التطبيق. |
| **لوحة الإدارة** | متابعة الطلاب والمواد والأسئلة لحظياً: [masar-hackathon-jo-2026-salah.web.app](https://masar-hackathon-jo-2026-salah.web.app) |

## كيف بيقيس مستوى الطالب
نفس فكرة **تصنيف Elo** اللي بيستخدمه الاتحاد الدولي للشطرنج: كل جواب هو «مباراة» بين الطالب والسؤال.

- احتمال إنه يجاوب صح: `P = 1 / (1 + e^-(θ − d))`، حيث θ مستوى الطالب بالمفهوم و d صعوبة السؤال.
- بعد الجواب: `θ ← θ + K · (النتيجة − P)`. ‏K كبير بالبداية عشان نعرف مستواه بسرعة، وبيصغر مع التمرين.
- السؤال كمان بيتعلّم صعوبته من كل الطلاب: `d ← d − 0.05 · (النتيجة − P)`.
- **الإتقان** = `100 / (1 + e^-θ)`، و**الجاهزية** = مجموع (وزن المفهوم بالامتحانات × إتقانه).
- **أولوية الخطة** = وزن المفهوم × (1 − الإتقان).

الكود: [`functions/src/engine.ts`](functions/src/engine.ts) (السيرفر) و [`app/lib/domain/services/learning_engine.dart`](app/lib/domain/services/learning_engine.dart) (التطبيق).

## البيانات
- **5 مواد و 276 سؤال** من امتحانات سابقة حقيقية، مع **34 مفهوم** موزونة حسب تكرارها.
- الأجوبة من المصدر فقط. أي جواب مشكوك فيه بينعلَّم وما بينعرض للطالب (6 أسئلة حالياً).

## التقنيات
| الجزء | التقنية |
|---|---|
| التطبيق | Flutter (iOS + Android)، Riverpod، go_router، Clean Architecture |
| الـ backend | Firebase: Firestore، Cloud Functions (TypeScript)، Auth، Hosting |
| لوحة الإدارة | React + Vite |

```
app/        تطبيق Flutter (core · domain · data · presentation)
functions/  Cloud Functions: محرك التعلّم والخطة
admin/      لوحة الإدارة
scripts/    تجهيز البيانات واستيرادها
design/     الأيقونة والهوية البصرية
docs/       العقد المشترك وحالة المشروع
```

## التشغيل · How to run
**الدليل الكامل: [docs/RUN.md](docs/RUN.md)**: المتطلبات، خطوات البناء، التشغيل، الاختبارات، جولة الديمو، وحل المشاكل.
*Full guide: [docs/RUN.md](docs/RUN.md): requirements, build, run, tests, demo walkthrough, troubleshooting.*

| الطريقة | |
|---|---|
| **APK للأندرويد** | `flutter build apk --release` من `app/` للنسخة الحالية |
| **لوحة الإدارة** | [masar-hackathon-jo-2026-salah.web.app](https://masar-hackathon-jo-2026-salah.web.app) |
| **من الكود** | Flutter 3.47 · JDK 17+ للأندرويد · Xcode للآيفون |

```bash
git clone https://github.com/Salahianoo/masar.git
cd masar/app
flutter pub get
flutter run                          # التطبيق الكامل مع Firebase (الديمو)
flutter run --dart-define=LOCAL=true # بدون إنترنت: كل شي على الجهاز
flutter test                         # 32 اختبار
```
قاعدة بيانات مسار كانت مجهّزة بالمواد والأسئلة؛ الوضع المحلي ما يحتاج Firebase.
**تنبيه:** مشروع Firebase الخاص بمسار رجّع خطأ فوترة 403 بتاريخ 2026-10-10؛ الوضع المحلي `LOCAL=true` شغّال، والوضع المتصل يحتاج إعادة تفعيل فوترة مسار. التفاصيل في [حالة الإزالة](docs/REMOVAL-2026-10-10.md).

العرض ونسخة APK السابقة من المسابقة محفوظان كأرشيف، وفيهما وصف المرشد الذي أُزيل بعد المسابقة. النسخة الحالية من التطبيق لا تتصل بجهاز هاشمي.

## العرض · Presentation
[PowerPoint](presentation/Masar-presentation.pptx) · [PDF](presentation/Masar-presentation.pdf)

## الفريق
| مين | الشغل |
|---|---|
| **صلاح** | الـ backend على Firebase، لوحة الإدارة، وجزء من واجهات التطبيق؛ صمّم المرشد الذكي لنسخة المسابقة السابقة |
| **عامر** | أساس التطبيق، التسجيل، التشخيص، الخريطة، الرئيسية، «أنا» |
| **أسامة** | التمرين، تبويب خزنة، ملخص الجلسة |

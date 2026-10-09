# مسار (Masar)

تطبيق تعلّم تكيّفي لطلاب الجامعات بالأردن، لتحدي **Education & learning**:
*"Students learn at different paces with uneven access to support"*.

الطالب بيجاوب 8 أسئلة، وبتطلعله **خريطة** لكل مفهوم بالمادة مع نسبة إتقانه، و**نسبة جاهزية** للامتحان.
كل يوم بتطلعله **خطة** على نقاط ضعفه، مرتبة حسب قديش كل مفهوم بيتكرر بالامتحانات الحقيقية.
وإذا غلط مرتين بنفس المفهوم، **البوت** بيتدخل وبيشرحله. بنك الأسئلة جاي من **خزنة**، وهي تبويب جوّا التطبيق.

## الفريق
| مين | الأداة | الشغل | البرومت |
|---|---|---|---|
| صلاح | Codex | Firebase، backend، الربط، داشبورد الأدمن | [docs/prompts/prompt-salah-codex.md](docs/prompts/prompt-salah-codex.md) |
| صلاح | Codex | الأيقونة، الهوية، صور البوت، صور الـ pitch | [docs/prompts/prompt-salah-design-codex.md](docs/prompts/prompt-salah-design-codex.md) |
| عامر | Claude | أساس التطبيق، التسجيل، التشخيص، الخريطة، الرئيسية، «أنا» | [docs/prompts/prompt-amer-claude.md](docs/prompts/prompt-amer-claude.md) |
| أسامة | Claude | التمرين، البوت، تبويب خزنة، ملخص الجلسة | [docs/prompts/prompt-osama-claude.md](docs/prompts/prompt-osama-claude.md) |

**العقد المشترك:** [docs/CONTRACT.md](docs/CONTRACT.md). الكل بيلتزم فيه.

## كيف تبلش
```
git clone https://github.com/Salahianoo/masar.git
cd masar
git checkout -b <اسمك>/setup
```
افتح المجلد بالـ AI تبعك (Codex أو Claude)، وانسخله البرومت تبعك من `docs/prompts/`.
الـ AI رح يقرأ `AGENTS.md` أو `CLAUDE.md` لحاله، وهدول بيوجهوه للعقد.

**الترتيب:** صلاح بيعمل إعداد Firebase، وعامر بيدفع أساس التطبيق بأول ساعة لساعتين، وأسامة بيبني فوقه.
عامر وأسامة بيشتغلوا على بيانات وهمية (`flutter run --dart-define=MOCK=true`)، فما بيستنوا الـ backend.

## قواعد
- ما حدا بيعدّل ملف مش إله (العقد §2). بدك تغيير؟ احكي لصاحبه.
- أي تغيير بالعقد بيتفق عليه الفريق أول.
- كل واحد على branch تبعه، وبيدمج على `main` كثير.

## لسا لازم نقرر
- [ ] اسم التطبيق النهائي والأيقونة
- [ ] اسم البوت وشكله الـ 3D (`app/assets/mentor/`: wave, happy, thinking, sorry, pointing)
- [ ] الألوان (`app/lib/core/theme`)
- [ ] نسأل المنظمين: مسموح نجهز البيانات أو الكود قبل المسابقة؟

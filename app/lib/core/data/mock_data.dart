import '../models/models.dart';

// Sample data for MockMasarRepository: one subject, 8 concepts, 40 questions,
// 3 past papers. Answers live here only, like answerKeys/ on the server.

const mockSubjectId = 'first-aid';

const mockSubject = Subject(
  id: mockSubjectId,
  name: 'ثقافة صحية و اسعافات أولية',
  questionCount: 40,
  conceptCount: 8,
);

const mockConfig = AppConfig(mentorName: 'المرشد', mentorEnabled: true);

const mockConcepts = <Concept>[
  Concept(
    id: 'bleeding',
    subjectId: mockSubjectId,
    name: 'النزيف',
    weight: 0.18,
    order: 1,
    explanation: '''**النزيف** هو خروج الدم من الأوعية الدموية.

- **الشرياني:** دم أحمر فاتح، بيطلع بدفعات مع نبض القلب. هو الأخطر.
- **الوريدي:** دم أحمر غامق، بيسيل بهدوء.
- **الشعيري:** نقاط دم صغيرة، بسيط.

**أول إجراء:** الضغط المباشر على الجرح بقطعة قماش نظيفة. إذا ما وقف وكان النزيف شديد بطرف، بنستخدم الرباط الضاغط (التورنيكيه).
**نزيف الأنف:** ميّل الراس لقدّام واضغط على طرف الأنف، مش لورا.''',
  ),
  Concept(
    id: 'cpr',
    subjectId: mockSubjectId,
    name: 'الإنعاش القلبي',
    weight: 0.16,
    order: 2,
    explanation: '''**الإنعاش القلبي الرئوي (CPR)** للشخص اللي ما بيتنفس وقلبه واقف.

1. تأكد إن المكان آمن.
2. افحص الاستجابة واطلب الإسعاف.
3. اضغط بمنتصف الصدر (النص السفلي لعظمة القص).

- العمق عند البالغ: **5–6 سم**.
- المعدل: **100–120 ضغطة بالدقيقة**.
- النسبة: **30 ضغطة : 2 نفس**.''',
  ),
  Concept(
    id: 'fractures',
    subjectId: mockSubjectId,
    name: 'الكسور',
    weight: 0.14,
    order: 3,
    explanation: '''**الكسر** هو انقطاع باستمرارية العظم.

- **مغلق:** بدون جرح.
- **مفتوح:** في جرح بيوصل للعظم، وهو أخطر بسبب العدوى.

**العلامات:** ألم شديد، تورم، تشوّه بشكل الطرف.
**الإسعاف:** ثبّت الطرف بجبيرة تشمل المفصل اللي فوق الكسر واللي تحته. **ما بنرجّع العظم لمكانه أبداً.**''',
  ),
  Concept(
    id: 'burns',
    subjectId: mockSubjectId,
    name: 'الحروق',
    weight: 0.13,
    order: 4,
    explanation: '''**درجات الحروق:**
- **أولى:** احمرار وألم.
- **ثانية:** فقاعات وألم شديد.
- **ثالثة:** تفحّم، وممكن ما يحس بألم لأن الأعصاب تضررت.

**الإسعاف:** برّد الحرق بمي جارية فاترة 10–20 دقيقة. لا ثلج، لا معجون أسنان، ولا تفقع الفقاعات.
**الحرق الكيميائي:** اغسله بكمية كبيرة من المي الجارية.
الملابس الملزقة بالحرق ما بتنشال بالقوة.''',
  ),
  Concept(
    id: 'poisoning',
    subjectId: mockSubjectId,
    name: 'التسمم',
    weight: 0.12,
    order: 5,
    explanation: '''**السم** بيدخل الجسم بالبلع، الاستنشاق، الجلد، أو الحقن.

- **أهم معلومة:** شو المادة، قديش، وإمتى.
- **المواد الكاوية (مثل الكلور):** ما بنحفّز الاستفراغ، وبنتصل بالإسعاف.
- **أول أكسيد الكربون:** طلّع المصاب للهوا الطلق فوراً.
- **لدغة العقرب:** ما بنمص السم بالتم. ثبّت الطرف واطلب المساعدة.''',
  ),
  Concept(
    id: 'fainting',
    subjectId: mockSubjectId,
    name: 'الإغماء',
    weight: 0.10,
    order: 6,
    explanation: '''**الإغماء** فقدان مؤقت للوعي بسبب نقص وصول الدم للدماغ.

**أسباب شائعة:** الخوف الشديد، الوقوف الطويل، الحر، الجوع.
**الإسعاف:** مدّده على ظهره وارفع رجليه شوي.
إذا فاقد الوعي بس بيتنفس وما في إصابة بالرقبة: **وضعية الإفاقة** (على جنبه).
ما بنعطيه أكل أو مي وهو فاقد الوعي.''',
  ),
  Concept(
    id: 'muscle-injuries',
    subjectId: mockSubjectId,
    name: 'الإصابات العضلية',
    weight: 0.09,
    order: 7,
    explanation: '''- **الشد العضلي:** إجهاد أو تمزق بالعضلة أو الوتر.
- **الالتواء:** إصابة بأربطة المفصل.
- **الخلع:** خروج العظم من مكانه بالمفصل.

**قاعدة RICE:** راحة، ثلج، ضغط، رفع.
الثلج بيكون ملفوف بقماشة، 15–20 دقيقة، مش مباشرة عالجلد. بأول يوم كمادات باردة، مش سخنة.''',
  ),
  Concept(
    id: 'stress',
    subjectId: mockSubjectId,
    name: 'الضغط النفسي',
    weight: 0.08,
    order: 8,
    explanation: '''**الضغط النفسي** حالة بتأدي لعدم توازن داخلي عند الإنسان.

- في ضغط **إيجابي** بيحفّز، وضغط **سلبي** بيضر.
- الهرمون المرتبط فيه: **الكورتيزول**.
- **أعراض جسدية:** صداع، اضطراب نوم، شد بالعضلات.
- **التعامل الصحي:** رياضة، تنظيم الوقت، نوم كافي، والحكي مع حدا بتثق فيه.''',
  ),
];

const mockExams = <Exam>[
  Exam(
    id: 'first-aid-final-2024',
    subjectId: mockSubjectId,
    label: 'نهائي 2024',
    // Any public PDF, so Osama can test the viewer in MOCK mode.
    pdfUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    questionCount: 13,
  ),
  Exam(
    id: 'first-aid-mid-2024',
    subjectId: mockSubjectId,
    label: 'نصفي 2024',
    pdfUrl: null,
    questionCount: 15,
  ),
  Exam(
    id: 'first-aid-final-2023',
    subjectId: mockSubjectId,
    label: 'نهائي 2023',
    pdfUrl: null,
    questionCount: 12,
  ),
];

/// A question plus the fields only the server knows.
class MockQuestion {
  final Question question;
  final String answer;
  double difficulty;

  MockQuestion(this.question, this.answer, this.difficulty);
}

const _f24 = 'first-aid-final-2024';
const _m24 = 'first-aid-mid-2024';
const _f23 = 'first-aid-final-2023';

const _mcqLabels = ['أ', 'ب', 'ج', 'د'];

MockQuestion _mcq(String id, String exam, List<String> concepts, String text,
    List<String> options, String answer, double difficulty) {
  return MockQuestion(
    Question(
      id: id,
      subjectId: mockSubjectId,
      examId: exam,
      examLabel: mockExams.firstWhere((e) => e.id == exam).label,
      kind: QuestionKind.mcq,
      text: text,
      options: [
        for (var i = 0; i < options.length; i++)
          QuestionOption(label: _mcqLabels[i], text: options[i]),
      ],
      conceptIds: concepts,
    ),
    answer,
    difficulty,
  );
}

MockQuestion _tf(String id, String exam, List<String> concepts, String text, bool answer,
    double difficulty) {
  return MockQuestion(
    Question(
      id: id,
      subjectId: mockSubjectId,
      examId: exam,
      examLabel: mockExams.firstWhere((e) => e.id == exam).label,
      kind: QuestionKind.truefalse,
      text: text,
      options: const [
        QuestionOption(label: 'صح', text: 'صح'),
        QuestionOption(label: 'خطأ', text: 'خطأ'),
      ],
      conceptIds: concepts,
    ),
    answer ? 'صح' : 'خطأ',
    difficulty,
  );
}

/// Fresh copies every call (difficulty is mutable per mock instance).
/// Listed in paper order within each exam.
List<MockQuestion> buildMockQuestions() => [
      // ── نهائي 2024 ──
      _mcq('fa-bleeding-1', _f24, ['bleeding'], 'أول إجراء عند النزيف الشرياني هو:',
          ['رفع الطرف للأعلى', 'الضغط المباشر على الجرح', 'وضع كمادة باردة', 'إعطاء المصاب ماء'],
          'ب', 0.0),
      _tf('fa-bleeding-4', _f24, ['bleeding'], 'عند نزيف الأنف يُفضّل إمالة الرأس للخلف.', false,
          -0.3),
      _mcq('fa-cpr-1', _f24, ['cpr'],
          'نسبة الضغطات الصدرية إلى التنفس الصناعي عند البالغين في الإنعاش القلبي الرئوي:',
          ['15 : 2', '30 : 2', '5 : 1', '10 : 2'], 'ب', 0.1),
      _mcq('fa-fractures-1', _f24, ['fractures'], 'الكسر المفتوح هو:',
          ['كسر بدون جرح', 'كسر مع جرح يصل للعظم', 'كسر في الجمجمة فقط', 'شرخ بسيط في العظم'],
          'ب', -0.1),
      _tf('fa-fractures-5', _f24, ['fractures'],
          'من علامات الكسر: الألم الشديد والتورم وتشوّه شكل الطرف.', true, -0.6),
      _mcq('fa-burns-1', _f24, ['burns'], 'أول إسعاف للحرق الحراري البسيط:',
          ['وضع معجون أسنان', 'تبريده بماء جارٍ فاتر 10–20 دقيقة', 'وضع ثلج مباشرة عليه', 'فقع الفقاعات'],
          'ب', 0.0),
      _tf('fa-burns-5', _f24, ['burns'], 'يجب نزع الملابس الملتصقة بالحرق بالقوة.', false, -0.4),
      _mcq('fa-poisoning-1', _f24, ['poisoning'],
          'عند التسمم بمادة كاوية (مثل الكلور) عن طريق الفم:',
          ['نحفّز التقيؤ فوراً', 'لا نحفّز التقيؤ ونتصل بالإسعاف', 'نعطيه حليباً ونتركه', 'نجعله ينام'],
          'ب', 0.2),
      _mcq('fa-fainting-1', _f24, ['fainting'], 'الوضعية المناسبة لشخص أُغمي عليه وهو يتنفس:',
          ['الجلوس', 'الاستلقاء على الظهر مع رفع القدمين', 'الوقوف', 'الاستلقاء على البطن'],
          'ب', 0.0),
      _tf('fa-fainting-4', _f24, ['fainting'],
          'يُنصح بإعطاء المصاب الماء وهو فاقد للوعي.', false, -0.5),
      _mcq('fa-muscle-1', _f24, ['muscle-injuries'], 'الإسعاف الأولي للالتواء (RICE) يشمل:',
          ['الراحة والثلج والضغط والرفع', 'التدليك القوي', 'الكمادات الساخنة فوراً', 'تحريك المفصل بقوة'],
          'أ', 0.0),
      _mcq('fa-stress-1', _f24, ['stress'], 'يُعرف الضغط النفسي على أنه:',
          ['حالة تؤدي إلى عدم توازن خارجي', 'حالة تؤدي إلى عدم توازن داخلي', 'حالة تؤدي إلى توازن داخلي', 'إفراز هرمونات جديدة'],
          'ب', 0.1),
      _tf('fa-stress-5', _f24, ['stress'],
          'من الأعراض الجسدية للضغط النفسي: الصداع واضطراب النوم.', true, -0.7),

      // ── نصفي 2024 ──
      _tf('fa-bleeding-2', _m24, ['bleeding'],
          'الدم في النزيف الشرياني لونه أحمر فاتح ويخرج على شكل دفعات.', true, -0.2),
      _mcq('fa-bleeding-5', _m24, ['bleeding'], 'النزيف الوريدي يتميز بـ:',
          ['دم أحمر فاتح يتدفق بدفعات', 'دم أحمر غامق يسيل بهدوء', 'نقاط دم صغيرة من الشعيرات', 'لا يخرج دم للخارج'],
          'ب', 0.3),
      _mcq('fa-cpr-2', _m24, ['cpr'], 'معدل الضغطات الصدرية المناسب للبالغين في الدقيقة:',
          ['60–80', '100–120', '140–160', '40–60'], 'ب', 0.4),
      _tf('fa-cpr-5', _m24, ['cpr'],
          'مكان الضغطات الصدرية هو منتصف الصدر على النصف السفلي لعظمة القص.', true, -0.2),
      _tf('fa-fractures-2', _m24, ['fractures'],
          'يجب محاولة إرجاع العظم المكسور لمكانه قبل وصول الإسعاف.', false, -0.4),
      _mcq('fa-fractures-4', _m24, ['fractures'], 'عند تجبير كسر في الساعد يجب أن تشمل الجبيرة:',
          ['العظم المكسور فقط', 'المفصل فوق الكسر والمفصل تحته', 'الكتف فقط', 'الأصابع فقط'],
          'ب', 0.5),
      _tf('fa-burns-2', _m24, ['burns'], 'يُنصح بفقع فقاعات الحرق لتسريع الشفاء.', false, -0.5),
      _tf('fa-poisoning-2', _m24, ['poisoning'],
          'أول إسعاف للتسمم بغاز أول أكسيد الكربون هو نقل المصاب للهواء الطلق.', true, -0.3),
      _mcq('fa-poisoning-4', _m24, ['poisoning'], 'أهم معلومة نجمعها عند حالة التسمم:',
          ['لون ملابس المصاب', 'نوع المادة وكميتها ووقت التعرض لها', 'عمر الأشخاص الموجودين', 'درجة حرارة الغرفة'],
          'ب', -0.1),
      _tf('fa-fainting-2', _m24, ['fainting'],
          'الإغماء فقدان مؤقت للوعي بسبب نقص تدفق الدم للدماغ.', true, -0.4),
      _mcq('fa-fainting-5', _m24, ['fainting', 'stress'], 'من الأسباب الشائعة للإغماء:',
          ['الخوف الشديد والوقوف الطويل', 'شرب الماء', 'النوم الكافي', 'المشي الخفيف'], 'أ', 0.2),
      _tf('fa-muscle-2', _m24, ['muscle-injuries'],
          'يوضع الثلج مباشرة على الجلد لمدة ساعة متواصلة.', false, -0.2),
      _mcq('fa-muscle-4', _m24, ['muscle-injuries'], 'عند الشد العضلي في اليوم الأول يُفضّل:',
          ['كمادات باردة', 'كمادات ساخنة', 'تمارين قوية', 'تدليك عنيف'], 'أ', 0.3),
      _tf('fa-stress-2', _m24, ['stress'],
          'الضغط النفسي دائماً ضار ولا يوجد ضغط إيجابي.', false, 0.0),
      _mcq('fa-stress-4', _m24, ['stress'], 'الهرمون المرتبط بالاستجابة للضغط النفسي:',
          ['الأنسولين', 'الكورتيزول', 'الميلاتونين', 'هرمون النمو'], 'ب', 0.5),

      // ── نهائي 2023 ──
      _mcq('fa-bleeding-3', _f23, ['bleeding'], 'متى يُستخدم الرباط الضاغط (التورنيكيه)؟',
          ['في كل نزيف بسيط', 'عند نزيف شديد في طرف لا يتوقف بالضغط المباشر', 'عند نزيف الأنف', 'عند الكدمات'],
          'ب', 0.6),
      _tf('fa-cpr-3', _f23, ['cpr'], 'عمق الضغط على صدر البالغ حوالي 5 إلى 6 سم.', true, 0.2),
      _mcq('fa-cpr-4', _f23, ['cpr'], 'أول خطوة عند إيجاد شخص فاقد للوعي:',
          ['البدء بالضغطات فوراً', 'التأكد من أمان المكان', 'إعطاؤه ماء', 'رفع رجليه'], 'ب', 0.0),
      _mcq('fa-fractures-3', _f23, ['fractures'], 'الهدف الأساسي من تجبير الكسر:',
          ['تقويم العظم', 'منع حركة الطرف المصاب', 'تدفئة المصاب', 'إيقاف النزيف الداخلي'],
          'ب', 0.2),
      _mcq('fa-burns-3', _f23, ['burns'], 'الحرق من الدرجة الثانية يتميز بـ:',
          ['احمرار فقط', 'ظهور فقاعات وألم شديد', 'تفحّم الجلد وعدم الإحساس بالألم', 'لا يظهر عليه شيء'],
          'ب', 0.3),
      _mcq('fa-burns-4', _f23, ['burns'], 'عند الحرق الكيميائي على الجلد:',
          ['نغسله بكمية كبيرة من الماء الجاري', 'نضع عليه زيتاً', 'نغطيه فوراً بدون غسل', 'نضع مادة معاكسة لتعادله'],
          'أ', 0.4),
      _mcq('fa-poisoning-3', _f23, ['poisoning'], 'من طرق دخول السم إلى الجسم:',
          ['البلع فقط', 'البلع والاستنشاق والجلد والحقن', 'الاستنشاق فقط', 'الجلد فقط'], 'ب', 0.0),
      _tf('fa-poisoning-5', _f23, ['poisoning'],
          'لدغة العقرب تُعالج بمص السم من مكان اللدغة بالفم.', false, 0.4),
      _mcq('fa-fainting-3', _f23, ['fainting'],
          'مصاب فاقد للوعي ويتنفس ولا توجد إصابة بالرقبة، نضعه في:',
          ['وضعية الإفاقة (على جنبه)', 'وضعية الجلوس', 'على بطنه مع رفع رأسه', 'وضعية الوقوف'],
          'أ', 0.5),
      _mcq('fa-muscle-3', _f23, ['muscle-injuries'], 'الشد العضلي هو:',
          ['تمزق أو إجهاد في العضلة أو الوتر', 'كسر في العظم', 'خلع في المفصل', 'جرح في الجلد'],
          'أ', -0.1),
      _tf('fa-muscle-5', _f23, ['muscle-injuries', 'fractures'],
          'الخلع هو خروج العظم من مكانه الطبيعي في المفصل.', true, 0.1),
      _mcq('fa-stress-3', _f23, ['stress'], 'من الطرق الصحية للتعامل مع الضغط النفسي:',
          ['التدخين', 'ممارسة الرياضة وتنظيم الوقت', 'السهر الطويل', 'العزلة التامة'], 'ب', -0.3),
    ];

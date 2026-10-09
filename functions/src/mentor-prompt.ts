// Exact text between PROMPT markers in docs/mentor-persona.md.
export const MENTOR_PROMPT_TEMPLATE = `إنت {mentorName}، رفيق دراسة لطلاب الجامعة بالأردن داخل تطبيق «مسار». شغلتك تساعد الطالب يفهم مادة «{subjectName}» ويجهز لامتحانها، خطوة خطوة وعلى قدّ سرعته.

طريقة حكيك:
- عربي بلهجة أردنية خفيفة وواضحة، زي صاحب شاطر بيشرح لصاحبه. المصطلحات العلمية بتضل زي ما هي بالمادة.
- جاوب باختصار: من 3 لـ 6 جمل، إلا إذا الطالب طلب تفصيل أكثر.
- ابدأ بالفكرة الأساسية بجملة وحدة، بعدين مثال بسيط من الحياة، وبعدين نقطة «انتبه» إذا في خطأ شائع.
- اختم كل شرح بسؤال قصير بتتأكد فيه إنه فهم، زي: «طيب، لو صار كذا، شو بتعمل؟»
- لا تستخدم LaTeX ولا جداول. المعادلات اكتبها نص عادي، زي: v = d / t.
- كون مشجع بدون مبالغة. لا تحكي «سؤال رائع!» بكل رد.

حدودك:
- اعتمد فقط على «مرجع المادة» تحت. إذا الجواب مش موجود فيه، احكي بصراحة «هاد مش موجود بمادتك عندي» واقترح يسأل الدكتور. لا تخترع معلومات ولا أرقام.
- إذا الطالب سأل عن إشي برا المادة (برمجة، واجبات مواد ثانية، سوالف عامة، أي إشي مش دراسة)، اعتذر بلطف بجملة وحدة ورجّعه للمادة.
- إذا طلب جواب سؤال امتحان مباشرة، أعطيه الجواب **مع السبب**، عشان يتعلم ما يحفظ.
- لا تطلب ولا تحفظ أي معلومات شخصية.

حالة الطالب: {studentState}

مرجع المادة:
{grounding}`;

export function assembleMentorPrompt(values: {
  mentorName: string;
  subjectName: string;
  studentState: string;
  grounding: string;
}): string {
  return MENTOR_PROMPT_TEMPLATE
    .replaceAll("{mentorName}", values.mentorName)
    .replaceAll("{subjectName}", values.subjectName)
    .replaceAll("{studentState}", values.studentState)
    .replaceAll("{grounding}", values.grounding);
}

export interface GroundingQuestion {
  text: string;
  options: {label: string; text: string}[];
  answer: string;
}

export function formatGroundingQuestion(question: GroundingQuestion): string {
  const options = question.options.map((option) => `${option.label}) ${option.text}`).join(" | ");
  const correct = question.options.find((option) => option.label === question.answer);
  const answer = correct ? `${correct.label}) ${correct.text}` : question.answer;
  return `س: ${question.text}${options ? ` [${options}]` : ""} / الجواب الصحيح: ${answer}`;
}

export function approximateTokens(system: string, history: {text: string}[]): number {
  return Math.ceil((system.length + history.reduce((total, message) => total + message.text.length, 0)) / 2);
}

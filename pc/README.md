# رفيق على الـ PC

رفيق هو مرشد تطبيق مسار. بيجاوب من نفس الموديل اللي بيجاوب منه هاشمي (Qwen3.5-9B على كرت RTX 3070)، بس **من باب منفصل**:

```
askMentor (Masar Firebase) → rafeeq.salahabushamseih.com → tunnel "masar" → rafeeq-proxy.mjs :8788 ─┐
askTutor  (Khazna Firebase) → llm.salahabushamseih.com   → tunnel "hashmi" → gate.mjs :8787       ─┴→ LM Studio :1234 → GPU
```

| | هاشمي (خزنة) | رفيق (مسار) |
|---|---|---|
| الباب | `Exam-Vault/hu_pp_q/local-llm/gate.mjs` :8787 | `pc/rafeeq-proxy.mjs` :8788 |
| الـ token | `GATE_TOKEN` | `RAFEEQ_GATE_TOKEN` (غيره) |
| الـ tunnel | `hashmi` → llm.… | `masar` → rafeeq.… |
| التشغيل التلقائي | مهمة «Hashmi» | مهمة «Rafeeq» |
| الموديل | Qwen3.5-9B، محمّل **مرة وحدة** للاثنين | |

**ما في ولا ملف لخزنة بيتعدل.** وسكربت رفيق ما بيعيد تحميل الموديل إذا كان محمّل.

## ⚠️ كرت واحد = طابور واحد
LM Studio بيجاوب طلب واحد بالمرة. يعني إذا رفيق بيجاوب طالب بمسار، طالب خزنة بيستنى لحد ما يخلص الجواب (≈ 15–35 ثانية بـ `max_tokens: 500`). وممكن يطلعله «هاشمي مضغوط».

عشان هيك:
- باب رفيق بيسمح **بطلب واحد بس**، والثاني بيرجع «busy» فوراً، و`askMentor` بيتعامل معه زي انتهاء الوقت.
- **وقت المسابقة والـ demo:** `config/app.mentorSource = "cloud"`. هيك رفيق ما بيقرب على الكرت أبداً.
- **فترات الامتحانات** (ضغط على هاشمي): خلّي رفيق على `cloud`، أو اطفي مهمة «Rafeeq».
- الـ PC لرفيق مناسب للتطوير والتجربة، وللأوقات الهادية.

## التركيب (مرة وحدة، على الـ PC)
افتح PowerShell بمجلد الـ repo بعد `git pull`:

```powershell
# 1. الأسرار
Copy-Item pc\.env.example pc\.env
notepad pc\.env      # حط RAFEEQ_GATE_TOKEN (أمر التوليد موجود بالملف)

# 2. tunnel جديد لمسار (حسابك على Cloudflare مسجل أصلاً من هاشمي)
cloudflared tunnel create masar
cloudflared tunnel route dns masar rafeeq.salahabushamseih.com
Copy-Item pc\cloudflared.example.yml pc\cloudflared.yml
notepad pc\cloudflared.yml   # حط الـ tunnel id ومسار ملف الـ credentials اللي طلعوا من الأمر الأول

# 3. شغّل وجرّب
powershell -ExecutionPolicy Bypass -File pc\start-rafeeq.ps1
node pc\try-rafeeq.mjs                                   # مباشرة على LM Studio
$env:RAFEEQ_URL="https://rafeeq.salahabushamseih.com"; $env:RAFEEQ_TOKEN="<نفس التوكن>"; node pc\try-rafeeq.mjs   # من برا، عن طريق الـ tunnel

# 4. تشغيل تلقائي عند تسجيل الدخول لويندوز
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PWD\pc\start-rafeeq.ps1`""
Register-ScheduledTask -TaskName 'Rafeeq' -Action $action -Trigger (New-ScheduledTaskTrigger -AtLogOn) -RunLevel Limited
```

## بعدها، بـ Firebase تبع مسار (مش خزنة)
```bash
firebase functions:secrets:set MASAR_LLM_URL     # https://rafeeq.salahabushamseih.com
firebase functions:secrets:set MASAR_LLM_TOKEN   # نفس RAFEEQ_GATE_TOKEN
```

## الشخصية
موجودة بـ [`docs/mentor-persona.md`](../docs/mentor-persona.md). `try-rafeeq.mjs` بيقرأها من هناك، فأي تعديل عليها بتجربه فوراً.

## إذا في مشكلة
- السجلات بـ `pc\logs\`.
- الأمر `node pc\try-rafeeq.mjs` بيجاوب، بس الطلبات من برا بترجع 401؟ التوكن بـ `pc\.env` مش نفس `MASAR_LLM_TOKEN`.
- رجعتلك 503 busy؟ في طلب ثاني لرفيق شغال هسا. هاد مقصود.
- هاشمي وقف بعد ما ركّبت رفيق؟ هاد ما لازم يصير. افحص `Get-CimInstance Win32_Process | ? CommandLine -like '*gate.mjs*'`: لازم تطلع عملية وحدة، وهي تبعت هاشمي.

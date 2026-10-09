import { useEffect, useMemo, useState } from 'react'
import { onAuthStateChanged, signInWithEmailAndPassword, signOut, type User } from 'firebase/auth'
import { collection, collectionGroup, doc, getDoc, onSnapshot, updateDoc, query, orderBy, limit, type DocumentData, type Timestamp } from 'firebase/firestore'
import { BrowserRouter, NavLink, Route, Routes, useParams } from 'react-router-dom'
import { Bar, BarChart, CartesianGrid, Cell, Line, LineChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { auth, configured, db } from './firebase'
import './App.css'

type Row = DocumentData & { id: string }
type Student = Row & { displayName?: string; demo?: boolean; lastActiveAt?: Timestamp }
type Subject = Row & { name?: string; questionCount?: number; active?: boolean }
const colors = ['#1f65a6', '#36b8a9', '#f4a340', '#df5956', '#7b72c8', '#75a760']
const today = () => new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Amman' })
const num = (value: unknown) => Number(value) || 0
const pct = (value: unknown) => `${Math.round(num(value))}%`
const date = (value: unknown) => value && typeof value === 'object' && 'toDate' in value ? (value as Timestamp).toDate().toLocaleDateString('ar-JO') : '—'

function useDocs(path: string, enabled = true, recent = 0) {
  const [rows, setRows] = useState<Row[]>([])
  const [error, setError] = useState('')
  useEffect(() => {
    if (!enabled) return
    const source = collection(db, path)
    const target = recent ? query(source, orderBy('at', 'desc'), limit(recent)) : source
    return onSnapshot(target, snapshot => { setRows(snapshot.docs.map(item => ({ id: item.id, ...item.data() }))); setError('') }, issue => setError(issue.message))
  }, [path, enabled, recent])
  return { rows, error }
}
function useGroup(name: string) {
  const [rows, setRows] = useState<Row[]>([])
  useEffect(() => onSnapshot(collectionGroup(db, name), snapshot => setRows(snapshot.docs.map(item => ({ id: item.id, userId: item.ref.parent.parent?.id, ...item.data() }))), () => setRows([])), [name])
  return rows
}
function useDoc(path: string, enabled = true) {
  const [value, setValue] = useState<Row | null>(null)
  useEffect(() => enabled ? onSnapshot(doc(db, path), item => setValue(item.exists() ? { id: item.id, ...item.data() } : null)) : undefined, [path, enabled])
  return value
}

function App() {
  const [user, setUser] = useState<User | null>(null)
  const [checking, setChecking] = useState(true)
  const [allowed, setAllowed] = useState(false)
  const [error, setError] = useState('')
  useEffect(() => onAuthStateChanged(auth, async next => {
    setChecking(true); setUser(next)
    if (next) {
      try { setAllowed((await getDoc(doc(db, 'admins', next.uid))).exists()) }
      catch { setAllowed(false); setError('تعذر التحقق من صلاحية الإدارة. تحقق من اتصال Firestore.') }
    } else setAllowed(false)
    setChecking(false)
  }), [])
  if (!configured) return <div className="auth-card"><h1>لوحة مسار</h1><p>أضف إعدادات Firebase إلى <code>admin/.env.local</code> ثم أعد التشغيل.</p></div>
  if (checking) return <div className="loading">جارٍ التحقق من الحساب…</div>
  if (!user) return <Login error={error} setError={setError} />
  if (!allowed) return <div className="auth-page"><div className="auth-card"><h1>الحساب غير مخوّل</h1><p>يحتاج هذا الحساب إلى سجل admins/{user.uid} في مشروع مسار.</p>{error && <p className="error">{error}</p>}<button onClick={() => signOut(auth)}>تسجيل الخروج</button></div></div>
  return <BrowserRouter><Dashboard /></BrowserRouter>
}
function Login({ error, setError }: { error: string; setError: (value: string) => void }) {
  const [email, setEmail] = useState(''); const [password, setPassword] = useState(''); const [busy, setBusy] = useState(false)
  async function submit(event: React.FormEvent) { event.preventDefault(); setBusy(true); setError(''); try { await signInWithEmailAndPassword(auth, email.trim(), password) } catch { setError('تعذر تسجيل الدخول. تحقق من البريد وكلمة المرور.') } finally { setBusy(false) } }
  return <main className="auth-page"><form className="auth-card" onSubmit={submit}><div className="brand-mark"><img src="/masar-icon.svg" alt="شعار مسار" /></div><p className="eyebrow">MASAR · ADMIN</p><h1>لوحة إدارة مسار</h1><p>تابع تعلّم الطلاب وتقدّمهم من مكان واحد.</p><label>البريد الإلكتروني<input type="email" required value={email} onChange={event => setEmail(event.target.value)} /></label><label>كلمة المرور<input type="password" required value={password} onChange={event => setPassword(event.target.value)} /></label>{error && <p className="error">{error}</p>}<button disabled={busy}>{busy ? 'جارٍ الدخول…' : 'دخول'}</button></form></main>
}
function Dashboard() {
  const [hideDemo, setHideDemo] = useState(false)
  const { rows: users, error } = useDocs('users')
  const { rows: subjects } = useDocs('subjects')
  const { rows: stats } = useDocs('statsDaily')
  const enrollments = useGroup('enrollments')
  const attempts = useGroup('attempts')
  const students = useMemo(() => users.filter(item => !hideDemo || !item.demo) as Student[], [users, hideDemo])
  return <div className="shell"><aside className="sidebar"><div className="side-brand"><span className="brand-mark"><img src="/masar-icon.svg" alt="شعار مسار" /></span><span><strong>مسار</strong><small>لوحة الإدارة</small></span></div><nav>{[['/', 'نظرة عامة', '◫'], ['/students', 'الطلاب', '♙'], ['/subjects', 'المواد', '▤'], ['/questions', 'الأسئلة', '☷'], ['/settings', 'الإعدادات', '⚙']].map(([path, title, icon]) => <NavLink key={path} to={path} end={path === '/'} className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}><span>{icon}</span>{title}</NavLink>)}</nav><div className="side-bottom"><label className="toggle"><input type="checkbox" checked={hideDemo} onChange={event => setHideDemo(event.target.checked)} /> إخفاء البيانات التجريبية</label><button className="quiet" onClick={() => signOut(auth)}>تسجيل الخروج ↗</button></div></aside><main className="main"><header className="topbar"><div><p className="eyebrow">MASAR / ADMIN</p><h1>لوحة إدارة مسار</h1></div><div className="live-pill"><span /> بيانات حية من Firestore</div></header>{error && <p className="error">تعذر تحميل الطلاب: {error}</p>}<Routes><Route path="/" element={<Overview students={students} subjects={subjects as Subject[]} stats={stats} enrollments={enrollments} />} /><Route path="/students" element={<Students students={students} subjects={subjects as Subject[]} enrollments={enrollments} attempts={attempts} />} /><Route path="/students/:uid" element={<StudentDetail students={students} subjects={subjects as Subject[]} />} /><Route path="/subjects" element={<Subjects subjects={subjects as Subject[]} />} /><Route path="/questions" element={<Questions subjects={subjects as Subject[]} />} /><Route path="/settings" element={<Settings />} /></Routes></main></div>
}
function Heading({ title, subtitle }: { title: string; subtitle: string }) { return <div className="section-heading"><div><p className="eyebrow">إدارة التعلّم</p><h2>{title}</h2><p>{subtitle}</p></div><span className="date-chip">{new Date().toLocaleDateString('ar-JO', { day: 'numeric', month: 'long', year: 'numeric' })}</span></div> }
function Card({ label, value, note }: { label: string; value: string | number; note?: string }) { return <div className="kpi"><span>{label}</span><strong>{value}</strong><small>{note || 'بيانات مسار الحية'}</small></div> }
function Empty({ text }: { text: string }) { return <div className="empty">{text}</div> }
function Demo({ value }: { value?: boolean }) { return value ? <span className="demo-tag">بيانات تجريبية</span> : null }
function Readiness({ value }: { value: unknown }) { const score = num(value); return <div className="readiness"><span>{pct(score)}</span><div className="meter"><i style={{ width: `${Math.max(0, Math.min(100, score))}%`, background: score < 40 ? '#df5956' : score < 70 ? '#f4a340' : '#4e9e61' }} /></div></div> }

function Overview({ students, subjects, stats, enrollments }: { students: Student[]; subjects: Subject[]; stats: Row[]; enrollments: Row[] }) {
  const todayStats = stats.find(item => item.id === today())
  const visibleEnrollments = enrollments.filter(item => students.some(student => student.id === item.userId))
  const average = visibleEnrollments.length ? visibleEnrollments.reduce((sum, item) => sum + num(item.readiness), 0) / visibleEnrollments.length : 0
  const chart = [...stats].sort((a, b) => a.id.localeCompare(b.id)).slice(-14).map(item => ({ day: item.id.slice(5), active: num(item.activeUsers), answers: num(item.answers), pc: num(item.mentorBySource?.pc), cloud: num(item.mentorBySource?.cloud) }))
  return <><Heading title="نظرة عامة" subtitle="صورة سريعة عن نشاط الطلاب وتقدّمهم اليوم." /><div className="kpi-grid"><Card label="إجمالي الطلاب" value={students.length} note="الحسابات الظاهرة" /><Card label="نشطون اليوم" value={num(todayStats?.activeUsers)} /><Card label="نشطون في ٧ أيام" value={students.filter(item => item.lastActiveAt && item.lastActiveAt.toDate().getTime() >= Date.now() - 7 * 86400000).length} note="طلاب مميزون" /><Card label="إجابات اليوم" value={num(todayStats?.answers)} /><Card label="دقة اليوم" value={pct(num(todayStats?.answers) ? 100 * num(todayStats?.correct) / num(todayStats?.answers) : 0)} /><Card label="متوسط الجاهزية" value={visibleEnrollments.length ? pct(average) : '—'} /></div><div className="chart-grid"><section className="panel"><h3>النشاط خلال آخر ١٤ يوم</h3><p>الطلاب النشطون والإجابات</p>{chart.length ? <ResponsiveContainer width="100%" height={270}><LineChart data={chart}><CartesianGrid stroke="#edf1f5" vertical={false} /><XAxis dataKey="day" /><YAxis /><Tooltip /><Line type="monotone" dataKey="active" name="طلاب نشطون" stroke="#25a99e" strokeWidth={3} /><Line type="monotone" dataKey="answers" name="إجابات" stroke="#1f65a6" strokeWidth={3} /></LineChart></ResponsiveContainer> : <Empty text="لا توجد إحصاءات يومية بعد." />}</section><section className="panel"><h3>رسائل رفيق حسب المصدر</h3><p>مقارنة PC والسحابة</p>{chart.length ? <ResponsiveContainer width="100%" height={270}><BarChart data={chart}><XAxis dataKey="day" /><YAxis /><Tooltip /><Bar dataKey="pc" name="PC" fill="#36b8a9" /><Bar dataKey="cloud" name="Cloud" fill="#1f65a6" /></BarChart></ResponsiveContainer> : <Empty text="لا توجد رسائل مرشد مسجلة بعد." />}</section></div><section className="panel"><div className="panel-title"><h3>المواد المتاحة</h3><span>{subjects.length} مواد</span></div><div className="toolbar">{subjects.map(item => <span className="date-chip" key={item.id}>{item.name} · {num(item.questionCount)} سؤال</span>)}{!subjects.length && <Empty text="لم تُستورد المواد بعد." />}</div></section></>
}
function Students({ students, subjects, enrollments, attempts }: { students: Student[]; subjects: Subject[]; enrollments: Row[]; attempts: Row[] }) {
  const [search, setSearch] = useState(''); const [sort, setSort] = useState('activity')
  const visible = students.filter(item => `${item.displayName || ''} ${item.id}`.toLowerCase().includes(search.toLowerCase())).sort((a, b) => sort === 'name' ? String(a.displayName || '').localeCompare(String(b.displayName || ''), 'ar') : num(b.lastActiveAt?.seconds) - num(a.lastActiveAt?.seconds))
  return <><Heading title="الطلاب" subtitle="تابع حسابات الطلاب وموادهم ونشاطهم." /><section className="panel"><div className="toolbar"><input placeholder="ابحث باسم الطالب أو المعرّف…" value={search} onChange={event => setSearch(event.target.value)} /><select value={sort} onChange={event => setSort(event.target.value)}><option value="activity">الأحدث نشاطاً</option><option value="name">الاسم</option></select></div><div className="table-wrap"><table><thead><tr><th>الطالب</th><th>المواد والجاهزية</th><th>آخر نشاط</th><th>الإجابات</th><th /></tr></thead><tbody>{visible.map(item => <tr key={item.id}><td><strong>{item.displayName || 'طالب بدون اسم'}</strong><Demo value={item.demo} /><small>{item.id.slice(0, 12)}…</small></td><td>{enrollments.filter(enrollment => enrollment.userId === item.id).map(enrollment => <div key={enrollment.id}>{subjects.find(subject => subject.id === enrollment.id)?.name || enrollment.id}<Readiness value={enrollment.readiness} /></div>)}</td><td>{date(item.lastActiveAt)}</td><td>{attempts.filter(attempt => attempt.userId === item.id).length}</td><td><NavLink to={`/students/${item.id}`} className="text-link">عرض ←</NavLink></td></tr>)}</tbody></table></div>{!visible.length && <Empty text="لا يوجد طلاب مطابقون بعد." />}</section></>
}
function StudentDetail({ students, subjects }: { students: Student[]; subjects: Subject[] }) {
  const { uid = '' } = useParams(); const student = students.find(item => item.id === uid)
  const { rows: enrollments } = useDocs(`users/${uid}/enrollments`, Boolean(uid))
  const { rows: attempts } = useDocs(`users/${uid}/attempts`, Boolean(uid), 50)
  const { rows: plans } = useDocs(`users/${uid}/plans`, Boolean(uid))
  return <><Heading title={student?.displayName || 'ملف الطالب'} subtitle="التقدّم يتحدّث مباشرةً مع إجابات الهاتف." /><Demo value={student?.demo} /><div className="kpi-grid mini"><Card label="المواد" value={enrollments.length} /><Card label="آخر نشاط" value={date(student?.lastActiveAt)} /><Card label="آخر الإجابات" value={attempts.length} /><Card label="الخطط المكتملة" value={plans.filter(item => item.completed).length} /></div>{enrollments.map(item => <StudentSubject key={item.id} uid={uid} enrollment={item} name={subjects.find(subject => subject.id === item.id)?.name || item.id} plans={plans} />)}<section className="panel"><h3>آخر ٥٠ محاولة</h3><div className="table-wrap"><table><thead><tr><th>التاريخ</th><th>السؤال</th><th>المفهوم</th><th>المصدر</th><th>النتيجة</th></tr></thead><tbody>{attempts.map(item => <tr key={item.id}><td>{date(item.at)}</td><td>{String(item.questionId || '').slice(0, 24)}</td><td>{(item.conceptIds || []).join('، ')}</td><td>{item.source}</td><td className={item.correct ? 'good' : 'bad'}>{item.correct ? 'صحيح' : 'خطأ'}</td></tr>)}</tbody></table></div>{!attempts.length && <Empty text="لم يسجّل هذا الطالب إجابات بعد." />}</section></>
}
function StudentSubject({ uid, enrollment, name, plans }: { uid: string; enrollment: Row; name: string; plans: Row[] }) {
  const mastery = useDoc(`users/${uid}/mastery/${enrollment.id}`)
  const { rows: concepts } = useDocs(`subjects/${enrollment.id}/concepts`)
  const history = Object.entries(mastery?.history || {}).sort(([a], [b]) => a.localeCompare(b)).map(([day, score]) => ({ day: day.slice(5), score: num(score) }))
  return <section className="panel"><div className="panel-title"><h3>{name}</h3><strong>{pct(enrollment.readiness)}</strong></div><div className="detail-grid"><div><h4>خريطة المفاهيم</h4>{concepts.map(item => { const state = mastery?.concepts?.[item.id]; const score = state && num(state.attempts) ? 100 / (1 + Math.exp(-num(state.theta))) : 0; return <div className="concept-bar" key={item.id}><span>{item.name}</span><Readiness value={score} /></div> })}{!concepts.length && <Empty text="لم تُستورد مفاهيم هذه المادة بعد." />}</div><div><h4>تاريخ الجاهزية</h4>{history.length ? <ResponsiveContainer width="100%" height={170}><LineChart data={history}><XAxis dataKey="day" /><YAxis domain={[0, 100]} /><Tooltip /><Line dataKey="score" name="الجاهزية" stroke="#1f65a6" strokeWidth={3} /></LineChart></ResponsiveContainer> : <Empty text="لا يوجد تاريخ جاهزية بعد." />}<h4>الخطط المكتملة</h4><p>{plans.filter(plan => plan.id.startsWith(`${enrollment.id}_`) && plan.completed).length} من {plans.filter(plan => plan.id.startsWith(`${enrollment.id}_`)).length}</p></div></div></section>
}
function Subjects({ subjects }: { subjects: Subject[] }) { return <><Heading title="المواد" subtitle="مخطط الامتحان، إتقان الصف، والمفاهيم الأضعف." />{subjects.map(item => <SubjectDetail key={item.id} subject={item} />)}{!subjects.length && <Empty text="لا توجد مواد مستوردة بعد." />}</> }
function SubjectDetail({ subject }: { subject: Subject }) {
  const { rows: concepts } = useDocs(`subjects/${subject.id}/concepts`)
  const [editing, setEditing] = useState<string | null>(null); const [name, setName] = useState(''); const [explanation, setExplanation] = useState(''); const [error, setError] = useState('')
  const pie = concepts.map(item => ({ name: item.name, value: num(item.weight) }))
  const weakest = [...concepts].filter(item => num(item.learners) > 0).sort((a, b) => num(a.masterySum) / num(a.learners) - num(b.masterySum) / num(b.learners)).slice(0, 3)
  async function save(id: string) { try { await updateDoc(doc(db, 'subjects', subject.id, 'concepts', id), { name: name.trim(), explanation: explanation.trim() }); setEditing(null); setError('') } catch (issue) { setError(String(issue)) } }
  return <section className="panel"><div className="panel-title"><div><h3>{subject.name}</h3><p>{num(subject.questionCount)} سؤال · {concepts.length} مفهوم</p></div><span className="date-chip">{subject.active ? 'نشطة' : 'غير نشطة'}</span></div><div className="detail-grid"><div><h4>مخطط الامتحان</h4>{pie.length ? <ResponsiveContainer width="100%" height={220}><PieChart><Pie data={pie} dataKey="value" nameKey="name" innerRadius={52} outerRadius={85}>{pie.map((item, index) => <Cell key={item.name} fill={colors[index % colors.length]} />)}</Pie><Tooltip formatter={value => `${Math.round(num(value) * 100)}%`} /></PieChart></ResponsiveContainer> : <Empty text="لا توجد مفاهيم بعد." />}</div><div><h4>أضعف مفاهيم الصف</h4>{weakest.map(item => <div className="weak-line" key={item.id}><span>{item.name}</span><Readiness value={num(item.masterySum) / num(item.learners)} /></div>)}{!weakest.length && <Empty text="تظهر هنا بعد بدء محاولات الطلاب." />}</div></div><div className="table-wrap"><table><thead><tr><th>المفهوم</th><th>الوزن</th><th>متوسط الإتقان</th><th>المتعلمون</th><th /></tr></thead><tbody>{concepts.map(item => <tr key={item.id}><td>{editing === item.id ? <><input value={name} onChange={event => setName(event.target.value)} maxLength={120} /><textarea value={explanation} onChange={event => setExplanation(event.target.value)} maxLength={1200} /></> : <><strong>{item.name}</strong><small>{String(item.explanation || '').slice(0, 90)}</small></>}</td><td>{pct(num(item.weight) * 100)}</td><td>{num(item.learners) ? pct(num(item.masterySum) / num(item.learners)) : '—'}</td><td>{num(item.learners)}</td><td>{editing === item.id ? <button onClick={() => save(item.id)}>حفظ</button> : <button className="quiet" onClick={() => { setEditing(item.id); setName(item.name); setExplanation(item.explanation) }}>تعديل</button>}</td></tr>)}</tbody></table></div>{error && <p className="error">{error}</p>}</section>
}
function Questions({ subjects }: { subjects: Subject[] }) {
  const { rows: questions } = useDocs('questions'); const { rows: keys } = useDocs('answerKeys')
  const [subjectId, setSubjectId] = useState(''); const [conceptId, setConceptId] = useState(''); const [flaggedOnly, setFlaggedOnly] = useState(false); const [error, setError] = useState('')
  const { rows: concepts } = useDocs(`subjects/${subjectId || '_none'}/concepts`, Boolean(subjectId))
  const answers = new Map(keys.map(item => [item.id, item.answer]))
  const visible = questions.filter(item => (!subjectId || item.subjectId === subjectId) && (!conceptId || (item.conceptIds || []).includes(conceptId)) && (!flaggedOnly || item.flagged))
  async function toggle(item: Row) { try { await updateDoc(doc(db, 'questions', item.id), { flagged: !item.flagged }); setError('') } catch (issue) { setError(String(issue)) } }
  return <><Heading title="الأسئلة" subtitle="افحص جودة بنك الأسئلة وراجع الأسئلة المشكوك فيها." /><section className="panel"><div className="toolbar"><select value={subjectId} onChange={event => { setSubjectId(event.target.value); setConceptId('') }}><option value="">كل المواد</option>{subjects.map(item => <option key={item.id} value={item.id}>{item.name}</option>)}</select><select value={conceptId} onChange={event => setConceptId(event.target.value)}><option value="">كل المفاهيم</option>{concepts.map(item => <option key={item.id} value={item.id}>{item.name}</option>)}</select><label className="toggle"><input type="checkbox" checked={flaggedOnly} onChange={event => setFlaggedOnly(event.target.checked)} /> المشكوك فيها فقط</label></div><p className="muted">{visible.length} سؤال ظاهر</p><div className="table-wrap"><table><thead><tr><th>السؤال</th><th>الصعوبة</th><th>المحاولات</th><th>الصحيح</th><th>توزيع الخيارات</th><th>الإجابة</th><th>مشكوك فيه</th></tr></thead><tbody>{visible.map(item => <tr key={item.id}><td><strong>{item.text}</strong><small>{item.examLabel}</small></td><td>{num(item.difficulty).toFixed(2)}</td><td>{num(item.attempts)}</td><td>{num(item.attempts) ? pct(100 * num(item.correctCount) / num(item.attempts)) : '—'}</td><td>{Object.entries(item.optionCounts || {}).map(([label, count]) => `${label}: ${count}`).join(' · ') || '—'}</td><td>{answers.get(item.id) || '—'}</td><td><button className={item.flagged ? 'flag active' : 'flag'} onClick={() => toggle(item)}>{item.flagged ? 'معلّم' : 'علّم'}</button></td></tr>)}</tbody></table></div>{!visible.length && <Empty text="لا توجد أسئلة مطابقة." />}{error && <p className="error">{error}</p>}</section></>
}
function Settings() {
  const config = useDoc('config/app')
  const [draft, setDraft] = useState({ mentorName: 'رفيق', mentorEnabled: true, mentorSource: 'cloud', dailyMentorLimit: 30 }); const [message, setMessage] = useState('')
  useEffect(() => { if (config) setDraft({ mentorName: config.mentorName ?? 'رفيق', mentorEnabled: Boolean(config.mentorEnabled), mentorSource: config.mentorSource ?? 'cloud', dailyMentorLimit: num(config.dailyMentorLimit) }) }, [config])
  async function save(event: React.FormEvent) { event.preventDefault(); try { await updateDoc(doc(db, 'config/app'), draft); setMessage('تم حفظ الإعدادات.') } catch (issue) { setMessage(`تعذر الحفظ: ${String(issue)}`) } }
  return <><Heading title="الإعدادات" subtitle="تحكم بإعدادات رفيق وحدوده اليومية." /><form className="panel settings-form" onSubmit={save}><label>اسم المرشد<input value={draft.mentorName} onChange={event => setDraft({ ...draft, mentorName: event.target.value })} required /></label><label>مصدر الإجابات<select value={draft.mentorSource} onChange={event => setDraft({ ...draft, mentorSource: event.target.value })}><option value="cloud">السحابة</option><option value="pc">الكمبيوتر</option></select></label><label>الحد اليومي لكل طالب<input type="number" min="1" max="1000" value={draft.dailyMentorLimit} onChange={event => setDraft({ ...draft, dailyMentorLimit: Number(event.target.value) })} /></label><label className="toggle"><input type="checkbox" checked={draft.mentorEnabled} onChange={event => setDraft({ ...draft, mentorEnabled: event.target.checked })} /> رفيق مفعّل</label><button>حفظ الإعدادات</button>{message && <p>{message}</p>}{!config && <p className="muted">لم يُنشأ config/app بعد. يحتاج التهيئة قبل التعديل.</p>}</form></>
}
export default App

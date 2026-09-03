-- ============================================================
--  بيانات أولية (Seed Data) - نفس القوائم المستخدمة بالنماذج التجريبية
--  يُشغّل بعد schema.sql:   psql -d annual_plan_db -f seed.sql
-- ============================================================

BEGIN;

INSERT INTO subjects (name) VALUES
  ('رياضيات'), ('اللغة العربية'), ('العلوم'), ('English'), ('עברית'), ('المواضيع الاثرائية');

INSERT INTO grades (name) VALUES
  ('الأول'), ('الثاني'), ('الثالث'), ('الرابع'), ('الخامس'), ('السادس');

INSERT INTO strategies (name) VALUES
  ('التعلم التعاوني'), ('العصف الذهني'), ('حل المشكلات'),
  ('التعلم باللعب'), ('الخرائط الذهنية'), ('التعلم النشط');

INSERT INTO visual_aids (name) VALUES
  ('السبورة الذكية'), ('بطاقات تعليمية'), ('نماذج مجسمة'),
  ('عروض تقديمية'), ('فيديو تعليمي'), ('أوراق عمل');

INSERT INTO assessment_methods (name) VALUES
  ('تقييم شفوي'), ('ورقة عمل تقييمية'), ('ملاحظة مباشرة'),
  ('اختبار قصير'), ('ملف إنجاز'), ('عرض تطبيقي');

-- مجالات مادة الرياضيات - الصف الرابع (مثال، يُكرَّر لباقي الصفوف والمواد)
INSERT INTO domains (subject_id, grade_id, name, exam_weight_percent)
SELECT s.id, g.id, d.name, d.weight
FROM (VALUES
  ('الأعداد والعمليات', 35),
  ('الهندسة والقياس', 25),
  ('الإحصاء والاحتمالات', 20),
  ('حل المسائل الكلامية', 20)
) AS d(name, weight)
CROSS JOIN (SELECT id FROM subjects WHERE name = 'رياضيات') s
CROSS JOIN (SELECT id FROM grades WHERE name = 'الرابع') g;

-- مجالات مادة اللغة العربية - الصف الخامس (مثال)
INSERT INTO domains (subject_id, grade_id, name, exam_weight_percent)
SELECT s.id, g.id, d.name, d.weight
FROM (VALUES
  ('القراءة والفهم', 40),
  ('القواعد والإملاء', 30),
  ('التعبير الكتابي', 30)
) AS d(name, weight)
CROSS JOIN (SELECT id FROM subjects WHERE name = 'اللغة العربية') s
CROSS JOIN (SELECT id FROM grades WHERE name = 'الخامس') g;

COMMIT;

-- ملاحظة: باقي المجالات لكل مادة/صف تُضاف بنفس الطريقة، أو عن طريق
-- شاشة "إدارة القوائم المرجعية" مباشرة من داخل التطبيق بعد التنفيذ.

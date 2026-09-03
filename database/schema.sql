-- ============================================================
--  مخطط قاعدة بيانات "نظام الخطة التعليمية السنوية"
--  PostgreSQL - نسخة أولى مطابقة لتصميم النظام المعتمد
--
--  طريقة التنصيب:
--  1) تأكد إنه PostgreSQL مثبت على الجهاز المحلي
--  2) أنشئ قاعدة بيانات فاضية:  createdb annual_plan_db
--  3) شغّل هذا الملف:            psql -d annual_plan_db -f schema.sql
--  4) شغّل ملف seed.sql بعده لتعبئة القوائم المرجعية الأولية
-- ============================================================

BEGIN;

-- ================= الأدوار والمستخدمين =================

CREATE TYPE user_role AS ENUM ('teacher', 'subject_coordinator', 'center_coordinator', 'admin');

CREATE TABLE users (
    id            BIGSERIAL PRIMARY KEY,
    full_name     TEXT NOT NULL,
    email         TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role          user_role NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ================= المواد والصفوف =================

CREATE TABLE subjects (
    id   BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE grades (
    id   BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE teacher_assignments (
    id          BIGSERIAL PRIMARY KEY,
    teacher_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject_id  BIGINT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    grade_id    BIGINT NOT NULL REFERENCES grades(id) ON DELETE CASCADE,
    school_year TEXT NOT NULL,
    UNIQUE (teacher_id, subject_id, grade_id, school_year)
);

-- ================= القوائم المرجعية (Global) =================

CREATE TABLE strategies (
    id   BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE visual_aids (
    id   BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE assessment_methods (
    id   BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

-- المجالات التعليمية مرتبطة بمادة+صف، مع نسبتها من الامتحان
CREATE TABLE domains (
    id                  BIGSERIAL PRIMARY KEY,
    subject_id          BIGINT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    grade_id            BIGINT NOT NULL REFERENCES grades(id) ON DELETE CASCADE,
    name                TEXT NOT NULL,
    exam_weight_percent SMALLINT NOT NULL DEFAULT 0 CHECK (exam_weight_percent BETWEEN 0 AND 100),
    UNIQUE (subject_id, grade_id, name)
);

-- ================= الخطة السنوية =================

CREATE TABLE annual_plans (
    id            BIGSERIAL PRIMARY KEY,
    teacher_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject_id    BIGINT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    grade_id      BIGINT NOT NULL REFERENCES grades(id) ON DELETE CASCADE,
    school_year   TEXT NOT NULL,
    general_goal  TEXT,
    specific_goal TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (teacher_id, subject_id, grade_id, school_year)
);

CREATE TABLE plan_entries (
    id                BIGSERIAL PRIMARY KEY,
    annual_plan_id    BIGINT NOT NULL REFERENCES annual_plans(id) ON DELETE CASCADE,
    month             TEXT NOT NULL,
    unit_name         TEXT,
    domain_id         BIGINT REFERENCES domains(id) ON DELETE SET NULL,
    sub_lessons       TEXT,
    success_indicator TEXT
);

-- جداول الربط - تطبّق سلوك الـ checkbox (اختيار متعدد حقيقي)
CREATE TABLE plan_entry_strategies (
    plan_entry_id BIGINT NOT NULL REFERENCES plan_entries(id) ON DELETE CASCADE,
    strategy_id   BIGINT NOT NULL REFERENCES strategies(id) ON DELETE CASCADE,
    PRIMARY KEY (plan_entry_id, strategy_id)
);

CREATE TABLE plan_entry_visual_aids (
    plan_entry_id BIGINT NOT NULL REFERENCES plan_entries(id) ON DELETE CASCADE,
    visual_aid_id BIGINT NOT NULL REFERENCES visual_aids(id) ON DELETE CASCADE,
    PRIMARY KEY (plan_entry_id, visual_aid_id)
);

CREATE TABLE plan_entry_assessment_methods (
    plan_entry_id        BIGINT NOT NULL REFERENCES plan_entries(id) ON DELETE CASCADE,
    assessment_method_id BIGINT NOT NULL REFERENCES assessment_methods(id) ON DELETE CASCADE,
    PRIMARY KEY (plan_entry_id, assessment_method_id)
);

-- ================= التعلم الفردي =================

CREATE TABLE individual_support_plans (
    id                   BIGSERIAL PRIMARY KEY,
    annual_plan_id       BIGINT NOT NULL REFERENCES annual_plans(id) ON DELETE CASCADE,
    month                TEXT NOT NULL,
    support_teacher_name TEXT,
    gaps_addressed       TEXT,
    UNIQUE (annual_plan_id, month)
);

CREATE TABLE individual_support_students (
    id                          BIGSERIAL PRIMARY KEY,
    individual_support_plan_id BIGINT NOT NULL REFERENCES individual_support_plans(id) ON DELETE CASCADE,
    student_name                TEXT NOT NULL
);

CREATE TYPE support_assessment_type AS ENUM ('computerized_test', 'alternative_assessment');

CREATE TABLE individual_support_assessments (
    id                          BIGSERIAL PRIMARY KEY,
    individual_support_plan_id BIGINT NOT NULL REFERENCES individual_support_plans(id) ON DELETE CASCADE,
    assessment_type              support_assessment_type NOT NULL,
    occurred                     BOOLEAN NOT NULL DEFAULT false,
    assessment_date              DATE,
    UNIQUE (individual_support_plan_id, assessment_type)
);

-- مراجعة المركز المسؤول - كتابة حصرية على دور center_coordinator (تُطبَّق على مستوى التطبيق)
CREATE TABLE individual_support_reviews (
    id                          BIGSERIAL PRIMARY KEY,
    individual_support_plan_id BIGINT NOT NULL REFERENCES individual_support_plans(id) ON DELETE CASCADE,
    reviewed_by                  BIGINT NOT NULL REFERENCES users(id),
    review_note                  TEXT,
    review_date                  DATE NOT NULL,
    UNIQUE (individual_support_plan_id)
);

-- ================= خطط المركز =================

CREATE TABLE center_work_plans (
    id             BIGSERIAL PRIMARY KEY,
    coordinator_id BIGINT NOT NULL REFERENCES users(id),
    title          TEXT NOT NULL,
    team_goal      TEXT,
    school_year    TEXT NOT NULL
);

CREATE TABLE center_work_plan_items (
    id                  BIGSERIAL PRIMARY KEY,
    center_work_plan_id BIGINT NOT NULL REFERENCES center_work_plans(id) ON DELETE CASCADE,
    task_what           TEXT,
    process_how         TEXT,
    target_audience     TEXT,
    participants        TEXT,
    success_criteria    TEXT,
    assessment_tools    TEXT,
    resources           TEXT
);

-- ================= فهارس مساعدة للتقارير =================

CREATE INDEX idx_annual_plans_teacher ON annual_plans(teacher_id);
CREATE INDEX idx_plan_entries_plan ON plan_entries(annual_plan_id);
CREATE INDEX idx_plan_entries_domain ON plan_entries(domain_id);
CREATE INDEX idx_domains_subject_grade ON domains(subject_id, grade_id);

COMMIT;

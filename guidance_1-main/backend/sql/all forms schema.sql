--SCRF
create table public.student_cumulative_records (
  id serial not null,
  user_id integer not null,
  student_id character varying(50) not null,
  program_enrolled character varying(100) null,
  sex character varying(10) null,
  full_name character varying(255) null,
  address text null,
  zipcode character varying(20) null,
  age integer null,
  civil_status character varying(50) null,
  date_of_birth date null,
  place_of_birth character varying(255) null,
  lrn character varying(50) null,
  cellphone character varying(50) null,
  email_address character varying(255) null,
  father_name character varying(255) null,
  father_age integer null,
  father_occupation character varying(255) null,
  mother_name character varying(255) null,
  mother_age integer null,
  mother_occupation character varying(255) null,
  living_with_parents boolean null,
  guardian_name character varying(255) null,
  guardian_relationship character varying(100) null,
  siblings jsonb null,
  educational_background jsonb null,
  awards_received text null,
  transferee_college_name character varying(255) null,
  transferee_program character varying(255) null,
  physical_defect text null,
  allergies_food text null,
  allergies_medicine text null,
  exam_taken character varying(255) null,
  exam_date date null,
  raw_score numeric(5, 2) null,
  percentile numeric(5, 2) null,
  adjectival_rating character varying(50) null,
  created_at timestamp without time zone not null default now(),
  updated_at timestamp without time zone not null default now(),
  created_by integer null,
  updated_by integer null,
  is_active boolean null default true,
  active boolean null default true,
  status boolean null,
  constraint student_cumulative_records_pkey primary key (id),
  constraint student_cumulative_records_created_by_fkey foreign KEY (created_by) references users (id),
  constraint student_cumulative_records_updated_by_fkey foreign KEY (updated_by) references users (id),
  constraint student_cumulative_records_user_id_fkey foreign KEY (user_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_scrf_user_id on public.student_cumulative_records using btree (user_id) TABLESPACE pg_default;

create index IF not exists idx_scrf_student_id on public.student_cumulative_records using btree (student_id) TABLESPACE pg_default;

create index IF not exists idx_scrf_created_at on public.student_cumulative_records using btree (created_at) TABLESPACE pg_default;

create index IF not exists idx_scrf_active on public.student_cumulative_records using btree (active) TABLESPACE pg_default;

create trigger trigger_update_scrf_updated_at BEFORE
update on student_cumulative_records for EACH row
execute FUNCTION update_scrf_updated_at ();


-- Routine Interview
create table public.routine_interviews (
  id serial not null,
  student_id integer not null,
  name character varying(255) not null,
  date date not null,
  grade_course_year_section character varying(100) null,
  nickname character varying(100) null,
  ordinal_position character varying(50) null,
  student_description text null,
  familial_description text null,
  strengths text null,
  weaknesses text null,
  achievements text null,
  best_work_person text null,
  first_choice text null,
  goals text null,
  contribution text null,
  talents_skills text null,
  home_problems text null,
  school_problems text null,
  applicant_signature character varying(255) null,
  signature_date date null,
  created_at timestamp without time zone not null default now(),
  updated_at timestamp without time zone not null default now(),
  is_active boolean null default true,
  active boolean null default true,
  status boolean null,
  constraint routine_interviews_pkey primary key (id),
  constraint routine_interviews_student_id_fkey foreign KEY (student_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_routine_interviews_student_id on public.routine_interviews using btree (student_id) TABLESPACE pg_default;

create index IF not exists idx_routine_interviews_date on public.routine_interviews using btree (date) TABLESPACE pg_default;

create index IF not exists idx_routine_interviews_created_at on public.routine_interviews using btree (created_at) TABLESPACE pg_default;

create index IF not exists idx_routine_interviews_active on public.routine_interviews using btree (active) TABLESPACE pg_default;

--Exit Survey for Graduating Students
create table public.exit_survey_graduating (
  id serial not null,
  student_id integer not null,
  student_name character varying(255) not null,
  student_number character varying(50) not null,
  email character varying(255) not null,
  last_name character varying(255) not null,
  first_name character varying(255) not null,
  middle_name character varying(255) not null,
  selected_program public.program_type not null,
  selected_colleges jsonb not null,
  career_plans jsonb not null,
  career_aspirations text not null,
  achieving_plans text not null,
  community_contribution text not null,
  preparedness_rating smallint not null,
  need_counseling public.yes_no not null,
  lessons_rating smallint not null,
  teachers_rating smallint not null,
  knowledge_rating smallint not null,
  skills_rating smallint not null,
  values_rating smallint not null,
  practical_experiences_rating smallint not null,
  guidance_rating smallint not null,
  faculty_rating smallint not null,
  deans_rating smallint not null,
  emiso_rating smallint not null,
  library_rating smallint not null,
  laboratories_rating smallint not null,
  external_linkages_rating smallint not null,
  finance_rating smallint not null,
  registrar_rating smallint not null,
  cafeteria_rating smallint not null,
  health_clinic_rating smallint not null,
  admission_rating smallint not null,
  research_rating smallint not null,
  suggestions text not null,
  alumni_survey public.yes_no not null,
  consent_given boolean not null default false,
  created_at timestamp without time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp without time zone null default CURRENT_TIMESTAMP,
  constraint exit_survey_graduating_pkey primary key (id),
  constraint exit_survey_graduating_student_id_fkey foreign KEY (student_id) references users (id) on delete CASCADE,
  constraint exit_survey_graduating_deans_rating_check check (
    (
      (deans_rating >= 1)
      and (deans_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_emiso_rating_check check (
    (
      (emiso_rating >= 1)
      and (emiso_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_external_linkages_rating_check check (
    (
      (external_linkages_rating >= 1)
      and (external_linkages_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_faculty_rating_check check (
    (
      (faculty_rating >= 1)
      and (faculty_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_finance_rating_check check (
    (
      (finance_rating >= 1)
      and (finance_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_guidance_rating_check check (
    (
      (guidance_rating >= 1)
      and (guidance_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_health_clinic_rating_check check (
    (
      (health_clinic_rating >= 1)
      and (health_clinic_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_knowledge_rating_check check (
    (
      (knowledge_rating >= 1)
      and (knowledge_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_laboratories_rating_check check (
    (
      (laboratories_rating >= 1)
      and (laboratories_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_lessons_rating_check check (
    (
      (lessons_rating >= 1)
      and (lessons_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_library_rating_check check (
    (
      (library_rating >= 1)
      and (library_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_practical_experiences_rating_check check (
    (
      (practical_experiences_rating >= 1)
      and (practical_experiences_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_preparedness_rating_check check (
    (
      (preparedness_rating >= 1)
      and (preparedness_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_registrar_rating_check check (
    (
      (registrar_rating >= 1)
      and (registrar_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_research_rating_check check (
    (
      (research_rating >= 1)
      and (research_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_skills_rating_check check (
    (
      (skills_rating >= 1)
      and (skills_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_teachers_rating_check check (
    (
      (teachers_rating >= 1)
      and (teachers_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_admission_rating_check check (
    (
      (admission_rating >= 1)
      and (admission_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_values_rating_check check (
    (
      (values_rating >= 1)
      and (values_rating <= 5)
    )
  ),
  constraint exit_survey_graduating_cafeteria_rating_check check (
    (
      (cafeteria_rating >= 1)
      and (cafeteria_rating <= 5)
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_exit_survey_graduating_student_id on public.exit_survey_graduating using btree (student_id) TABLESPACE pg_default;

create index IF not exists idx_exit_survey_graduating_created_at on public.exit_survey_graduating using btree (created_at) TABLESPACE pg_default;

create trigger update_exit_survey_graduating_updated_at BEFORE
update on exit_survey_graduating for EACH row
execute FUNCTION update_exit_survey_graduating_updated_at_column ();

-- Exit Interview for Transferees
create table public.exit_interviews (
  id serial not null,
  student_id integer not null,
  student_name character varying(255) not null,
  student_number character varying(50) not null,
  interview_date date not null,
  grade_year_level character varying(50) not null,
  present_program character varying(255) not null,
  address text not null,
  father_name character varying(255) not null,
  mother_name character varying(255) not null,
  reason_family boolean null default false,
  reason_classmate boolean null default false,
  reason_academic boolean null default false,
  reason_financial boolean null default false,
  reason_teacher boolean null default false,
  reason_other text null,
  transfer_school text null,
  transfer_program text null,
  difficulties text null,
  suggestions text null,
  interviewee_signature text null,
  interviewer_signature text null,
  consent_given boolean null default false,
  created_at timestamp without time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp without time zone null default CURRENT_TIMESTAMP,
  constraint exit_interviews_pkey primary key (id),
  constraint exit_interviews_student_id_fkey foreign KEY (student_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_exit_interviews_student_id on public.exit_interviews using btree (student_id) TABLESPACE pg_default;

create index IF not exists idx_exit_interviews_interview_date on public.exit_interviews using btree (interview_date) TABLESPACE pg_default;

create index IF not exists idx_exit_interviews_created_at on public.exit_interviews using btree (created_at) TABLESPACE pg_default;

create trigger update_exit_interviews_updated_at BEFORE
update on exit_interviews for EACH row
execute FUNCTION update_exit_interviews_updated_at_column ();
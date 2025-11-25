-- Exit Survey for Graduating Students Table
create table public.exit_survey_graduating (
  id serial not null,
  student_id integer not null,
  student_name character varying(255) not null,
  student_number character varying(50) not null,
  email character varying(255) not null,
  last_name character varying(255) not null,
  first_name character varying(255) not null,
  middle_name character varying(255) not null,
  selected_program character varying(50) not null,
  selected_colleges jsonb not null,
  career_plans jsonb not null,
  career_aspirations text not null,
  achieving_plans text not null,
  community_contribution text not null,
  preparedness_rating smallint not null check (preparedness_rating >= 1 and preparedness_rating <= 5),
  need_counseling character varying(3) not null check (need_counseling in ('Yes', 'No')),

  -- Academic Services Ratings (1-5)
  lessons_rating smallint not null check (lessons_rating >= 1 and lessons_rating <= 5),
  teachers_rating smallint not null check (teachers_rating >= 1 and teachers_rating <= 5),
  knowledge_rating smallint not null check (knowledge_rating >= 1 and knowledge_rating <= 5),
  skills_rating smallint not null check (skills_rating >= 1 and skills_rating <= 5),
  values_rating smallint not null check (values_rating >= 1 and values_rating <= 5),
  practical_experiences_rating smallint not null check (practical_experiences_rating >= 1 and practical_experiences_rating <= 5),

  -- Satisfaction Ratings (1-5)
  guidance_rating smallint not null check (guidance_rating >= 1 and guidance_rating <= 5),
  faculty_rating smallint not null check (faculty_rating >= 1 and faculty_rating <= 5),
  deans_rating smallint not null check (deans_rating >= 1 and deans_rating <= 5),
  emiso_rating smallint not null check (emiso_rating >= 1 and emiso_rating <= 5),
  library_rating smallint not null check (library_rating >= 1 and library_rating <= 5),
  laboratories_rating smallint not null check (laboratories_rating >= 1 and laboratories_rating <= 5),
  external_linkages_rating smallint not null check (external_linkages_rating >= 1 and external_linkages_rating <= 5),
  finance_rating smallint not null check (finance_rating >= 1 and finance_rating <= 5),
  registrar_rating smallint not null check (registrar_rating >= 1 and registrar_rating <= 5),
  cafeteria_rating smallint not null check (cafeteria_rating >= 1 and cafeteria_rating <= 5),
  health_clinic_rating smallint not null check (health_clinic_rating >= 1 and health_clinic_rating <= 5),
  admission_rating smallint not null check (admission_rating >= 1 and admission_rating <= 5),
  research_rating smallint not null check (research_rating >= 1 and research_rating <= 5),

  -- Recommendations
  suggestions text not null,

  -- Alumni
  alumni_survey character varying(3) not null check (alumni_survey in ('Yes', 'No')),

  -- Consent
  consent_given boolean not null default false,

  -- Metadata
  created_at timestamp without time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp without time zone null default CURRENT_TIMESTAMP,

  constraint exit_survey_graduating_pkey primary key (id),
  constraint exit_survey_graduating_student_id_fkey foreign key (student_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index if not exists idx_exit_survey_graduating_student_id on public.exit_survey_graduating using btree (student_id) TABLESPACE pg_default;

create index if not exists idx_exit_survey_graduating_created_at on public.exit_survey_graduating using btree (created_at) TABLESPACE pg_default;

create trigger update_exit_survey_graduating_updated_at before
update on exit_survey_graduating for each row
execute function update_exit_survey_graduating_updated_at_column();

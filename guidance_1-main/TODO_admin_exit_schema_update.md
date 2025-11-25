# TODO: Apply New Exit Interview Schema to Admin Routing

## Tasks
- [ ] Update getExitInterviews method in AdminCaseRoutes to use new exit_interviews schema fields
- [ ] Update updateExitInterview method to handle new schema fields
- [ ] Add getExitSurveyGraduating method for graduating students' exit surveys
- [ ] Add updateExitSurveyGraduating method for graduating students' exit surveys

## Schema Changes
### exit_interviews table (transferring/shifting students)
- Fields: student_id, student_name, student_number, interview_date, grade_year_level, present_program, address, father_name, mother_name, reason checkboxes (family, classmate, academic, financial, teacher, other), transfer_school, transfer_program, difficulties, suggestions, signatures, consent

### exit_survey_graduating table (graduating students)
- Fields: student_id, student_name, student_number, email, names, selected_program, selected_colleges, career_plans, career_aspirations, achieving_plans, community_contribution, preparedness_rating, need_counseling, various rating fields (1-5), suggestions, alumni_survey, consent

-- =============================================================================
-- Sample catalogue data for local development ONLY.
-- Replace the codes and titles with the official NC(V) subject list before
-- any real use. Re-running is safe (ON CONFLICT DO NOTHING).
-- =============================================================================

insert into public.subjects (code, title, nqf_level, is_fundamental, pass_percentage, vocational_stream)
values
  -- NQF 2
  ('LO',      'Life Orientation',            2, true,  40, null),
  ('FAL',     'English First Additional Language', 2, true, 40, null),
  ('MATH',    'Mathematics',                 2, true,  30, null),
  ('ENGDES',  'Engineering Drawing',         2, false, 50, 'Engineering and Related Design'),
  ('ENGSCI',  'Engineering Science',         2, false, 50, 'Engineering and Related Design'),
  ('FINACC',  'Financial Accounting',        2, false, 50, 'Finance, Economics and Accounting'),
  -- NQF 3
  ('LO',      'Life Orientation',            3, true,  40, null),
  ('FAL',     'English First Additional Language', 3, true, 40, null),
  ('MATH',    'Mathematics',                 3, true,  30, null),
  ('ENGDES',  'Engineering Drawing',         3, false, 50, 'Engineering and Related Design'),
  ('ENGSCI',  'Engineering Science',         3, false, 50, 'Engineering and Related Design'),
  ('FINACC',  'Financial Accounting',        3, false, 50, 'Finance, Economics and Accounting'),
  -- NQF 4
  ('LO',      'Life Orientation',            4, true,  40, null),
  ('FAL',     'English First Additional Language', 4, true, 40, null),
  ('MATH',    'Mathematics',                 4, true,  30, null),
  ('ENGDES',  'Engineering Drawing',         4, false, 50, 'Engineering and Related Design'),
  ('ENGSCI',  'Engineering Science',         4, false, 50, 'Engineering and Related Design'),
  ('FINACC',  'Financial Accounting',        4, false, 50, 'Finance, Economics and Accounting')
on conflict (code, nqf_level) do nothing;

-- Papers: upload the PDF to the private 'past-papers' bucket first, then insert
-- a row whose file_url is the object path. Example:
--   insert into public.past_papers (subject_id, year, paper_number, file_url, is_memo)
--   select id, 2025, 1, 'nqf2/mat/2025_p1_qp.pdf', false
--     from public.subjects where code = 'MATH' and nqf_level = 2;

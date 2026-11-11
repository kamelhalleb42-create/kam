-- supabase-admin.sql  (ETAPE 3/3) — a executer dans le SQL Editor, JAMAIS depuis le navigateur.
-- 1) Creez d'abord un compte sur le site et confirmez l'e-mail.
-- 2) Authentication > Users : copiez l'UUID de ce compte et remplacez VOTRE-UUID.
insert into public.user_roles(user_id, role) values ('VOTRE-UUID', 'admin')
on conflict (user_id) do update set role = 'admin';

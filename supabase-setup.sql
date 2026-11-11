-- supabase-setup.sql  (ETAPE 1/3)  *** BASE NEUVE UNIQUEMENT ***
-- Ordre : 1) supabase-setup.sql  2) supabase-orders.sql  3) supabase-admin.sql
-- Si vos tables existent deja, ne lancez pas ce script tel quel : adaptez-le (migration separee).
-- Prix en millimes (1 TND = 1000) : entiers, sans erreur d'arrondi.
create table if not exists public.products(
 id integer primary key,
 name text not null check(length(name) between 1 and 120),
 name_en text,
 category text not null check(category in('vet','chau','acc','parf','perso')),
 description text not null default '',
 description_en text,
 price_millimes integer not null check(price_millimes>=0),
 image_url text check(image_url is null or image_url ~ '^(https://|images/)'),
 features text[] not null default '{}',
 available boolean not null default true,
 created_at timestamptz not null default now());

-- Pas de role = compte client. Seul 'admin' existe. Modifiable uniquement via SQL Editor.
create table if not exists public.user_roles(
 user_id uuid primary key references auth.users(id) on delete cascade,
 role text not null check(role in('admin')),
 created_at timestamptz not null default now());

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.user_roles where user_id=(select auth.uid()) and role='admin') $$;
revoke all on function public.is_admin() from public,anon;
grant execute on function public.is_admin() to authenticated;

alter table public.products enable row level security;
alter table public.user_roles enable row level security;
revoke all on public.products, public.user_roles from anon, authenticated;
grant select on public.products to anon, authenticated;
grant insert, update, delete on public.products to authenticated;   -- limite aux admins par les policies
grant select on public.user_roles to authenticated;                 -- aucun insert/update/delete cote navigateur

drop policy if exists products_read_available on public.products;
create policy products_read_available on public.products for select to anon, authenticated using(available);
drop policy if exists products_admin_read on public.products;
create policy products_admin_read on public.products for select to authenticated using(public.is_admin());
drop policy if exists products_admin_ins on public.products;
create policy products_admin_ins on public.products for insert to authenticated with check(public.is_admin());
drop policy if exists products_admin_upd on public.products;
create policy products_admin_upd on public.products for update to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists products_admin_del on public.products;
create policy products_admin_del on public.products for delete to authenticated using(public.is_admin());
drop policy if exists roles_own_read on public.user_roles;
create policy roles_own_read on public.user_roles for select to authenticated using(user_id=(select auth.uid()));

-- Donnees initiales (catalogue existant, prix demo en millimes)
insert into public.products(id,name,name_en,category,description,description_en,price_millimes) values
(1,'T-shirt Heritage Noir','Heritage Black Tee','vet','Le basique intemporel : coupe nette, coton doux, noir profond. Il s’associe à tout, du matin au soir.','The timeless essential: clean cut, soft cotton, deep black. Goes with everything, morning to night.',35000),
(2,'Hoodie Old Money','Old Money Hoodie','vet','Le hoodie old money : volume maîtrisé, toucher douillet, allure discrète. Le confort, version luxe.','The old money hoodie: refined volume, cosy feel, quiet allure. Comfort, luxury edition.',79000),
(3,'Pantalon Tailleur Droit','Straight Tailored Trousers','vet','Un pantalon droit à la coupe tailleur, pour une silhouette élégante et structurée, du bureau au dîner.','A straight, tailored-cut trouser for an elegant, structured silhouette, from office to dinner.',69000),
(4,'Jean Brut Indigo','Raw Indigo Jeans','vet','Un jean brut indigo qui se patine avec vous : sobre, robuste et unique au fil du temps.','A raw indigo jean that ages with you: understated, sturdy and unique over time.',75000),
(5,'Sneakers Cuir Blanc','White Leather Sneakers','chau','La sneaker en cuir blanc, épurée et polyvalente. Elle illumine chaque tenue.','The clean white leather sneaker, versatile and polished. It lifts every outfit.',149000),
(6,'Baskets Montantes Noires','Black High-top Trainers','chau','Des baskets montantes noires au caractère affirmé, pour un style urbain et raffiné.','Black high-top trainers with real character, for a refined urban style.',139000),
(7,'Sac Cabas Cuir','Leather Tote Bag','acc','Un cabas spacieux et élégant : l’allié du quotidien, pour tout emporter avec style.','A roomy, elegant tote: your everyday ally, made to carry everything in style.',99000),
(8,'Casquette Brodée Or','Gold Embroidered Cap','acc','Casquette en coton à broderie discrète : le détail chic qui signe votre look.','Cotton cap with a subtle embroidery: the chic detail that signs your look.',29000),
(9,'Bracelet Maille Dorée','Gold Chain Bracelet','acc','Un bracelet à maille dorée, fin et lumineux. À porter seul ou superposé.','A fine, luminous gold-tone chain bracelet. Wear it alone or stacked.',49000),
(10,'Oud Noir — Homme','Oud Noir — Men','parf','Un sillage profond et boisé d’oud, pour l’homme qui laisse une impression durable.','A deep, woody oud trail for the man who leaves a lasting impression.',99000),
(11,'Ambre Doré — Femme','Golden Amber — Women','parf','Une fragrance chaude d’ambre doré, sensuelle et enveloppante, pour une présence inoubliable.','A warm golden amber fragrance, sensual and enveloping, for an unforgettable presence.',95000),
(12,'T-shirt Imprimé sur Mesure','Custom Printed Tee','perso','Votre design, votre message : un t-shirt imprimé sur mesure, unique comme vous.','Your design, your message: a custom printed tee, as unique as you are.',39000),
(13,'Mug Personnalisé','Custom Mug','perso','Un mug personnalisé pour vos matins : une idée cadeau qui fait toujours plaisir.','A personalised mug for your mornings: a gift idea that always delights.',19000),
(14,'Tote Bag Personnalisé','Custom Tote Bag','perso','Un tote bag personnalisé, léger et pratique : votre style, partout avec vous.','A personalised tote bag, light and practical: your style, everywhere.',25000)
on conflict(id) do nothing;

-- supabase-orders.sql  (ETAPE 2/3) — relancable : ne supprime jamais de commande.
-- Prerequis : supabase-setup.sql (products, is_admin).
create sequence if not exists public.order_ref_seq;
create table if not exists public.orders(
 id uuid primary key default gen_random_uuid(),
 ref text not null unique,
 user_id uuid not null references auth.users(id) on delete restrict,
 attempt_id uuid not null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 items jsonb not null,            -- instantane : id, name, name_en, qty, unit_price (millimes)
 ship_to jsonb not null,
 payment text not null check(payment in('card','cod')),   -- paiement SIMULE
 subtotal integer not null check(subtotal>=0),
 shipping integer not null check(shipping>=0),
 total integer not null check(total>=0),
 status text not null default 'new' check(status in('new','preparing','done','cancelled')),
 unique(user_id, attempt_id));

create or replace function public.touch_updated_at() returns trigger language plpgsql set search_path='' as $$
begin new.updated_at=now(); return new; end $$;
drop trigger if exists orders_touch on public.orders;
create trigger orders_touch before update on public.orders for each row execute function public.touch_updated_at();

alter table public.orders enable row level security;
revoke all on public.orders from anon, authenticated;
grant select on public.orders to authenticated;
grant update(status) on public.orders to authenticated;     -- seule colonne modifiable (admins via policy)
drop policy if exists orders_own_read on public.orders;
create policy orders_own_read on public.orders for select to authenticated using(user_id=(select auth.uid()));
drop policy if exists orders_admin_read on public.orders;
create policy orders_admin_read on public.orders for select to authenticated using(public.is_admin());
drop policy if exists orders_admin_status on public.orders;
create policy orders_admin_status on public.orders for update to authenticated using(public.is_admin()) with check(public.is_admin());

-- Regles de livraison (doivent correspondre a CFG dans script.js) : 8 TND, offerte des 150 TND.
create or replace function public.create_demo_order(p_attempt uuid, p_items jsonb, p_expected_total integer, p_shipping jsonb, p_payment text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_uid uuid := (select auth.uid()); v_o public.orders; v_lines jsonb; v_sub integer; v_n integer; v_req integer;
 v_ship integer; v_total integer; v_to jsonb := '{}'::jsonb; k text;
begin
 if v_uid is null then raise exception 'NOT_AUTHENTICATED'; end if;
 select * into v_o from public.orders where user_id=v_uid and attempt_id=p_attempt;
 if found then return to_jsonb(v_o); end if;                       -- nouvelle tentative identique : meme commande
 if p_payment not in('card','cod') or jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items) not between 1 and 50 then raise exception 'INVALID_ITEMS'; end if;
 foreach k in array array['name','email','phone','addr','city','zip','country'] loop
  if coalesce(length(btrim(p_shipping->>k)),0) not between 1 and 200 then raise exception 'INVALID_SHIPPING'; end if;
  v_to := v_to || jsonb_build_object(k, btrim(p_shipping->>k));
 end loop;
 select count(distinct (e->>'id')::integer) into v_req from jsonb_array_elements(p_items) e;
 select jsonb_agg(jsonb_build_object('id',p.id,'name',p.name,'name_en',coalesce(p.name_en,p.name),'qty',q.qty,'unit_price',p.price_millimes) order by p.id),
        sum(p.price_millimes*q.qty)::integer, count(*)
   into v_lines, v_sub, v_n
 from (select (e->>'id')::integer as id, sum((e->>'q')::integer) as qty from jsonb_array_elements(p_items) e group by 1) q
 join public.products p on p.id=q.id and p.available
 where q.qty between 1 and 99;
 if v_n is distinct from v_req or v_n=0 then raise exception 'INVALID_ITEMS'; end if;
 v_ship := case when v_sub>=150000 then 0 else 8000 end;
 v_total := v_sub+v_ship;
 if p_expected_total is distinct from v_total then raise exception 'PRICE_CHANGED'; end if;
 begin
  insert into public.orders(ref,user_id,attempt_id,items,ship_to,payment,subtotal,shipping,total)
  values('ORD-'||lpad(nextval('public.order_ref_seq')::text,3,'0'),v_uid,p_attempt,v_lines,v_to,p_payment,v_sub,v_ship,v_total) returning * into v_o;
 exception when unique_violation then
  select * into v_o from public.orders where user_id=v_uid and attempt_id=p_attempt;
 end;
 return to_jsonb(v_o);
end $$;
revoke all on function public.create_demo_order(uuid,jsonb,integer,jsonb,text) from public, anon;
grant execute on function public.create_demo_order(uuid,jsonb,integer,jsonb,text) to authenticated;

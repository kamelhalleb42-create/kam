// Acces Supabase : auth, catalogue, commandes, administration. Les droits reels sont dans la base (RLS).
(() => {
const sb = window.sb;
const msg = e => { const m = (e && e.message) || String(e);
 if (/PRICE_CHANGED/.test(m)) return 'Les prix ont changé. Actualisez la page puis revalidez votre panier.';
 if (/INVALID_ITEMS|PRODUCT_UNAVAILABLE/.test(m)) return 'Panier invalide ou produit indisponible. Actualisez la page.';
 if (/INVALID_SHIPPING/.test(m)) return 'Coordonnées de livraison incomplètes.';
 if (/NOT_AUTHENTICATED/.test(m)) return 'Veuillez vous connecter.';
 if (/Invalid login/i.test(m)) return 'E-mail ou mot de passe incorrect.';
 if (/not confirmed/i.test(m)) return 'Veuillez d’abord confirmer votre e-mail.';
 if (/rate limit/i.test(m)) return 'Trop de tentatives. Réessayez plus tard.';
 return 'Erreur : ' + m; };
const ok = d => ({ ok: true, data: d }), ko = e => ({ ok: false, error: msg(e) });
window.shop = {
 onAuth: cb => sb.auth.onAuthStateChange((ev) => { if (ev === 'SIGNED_IN' || ev === 'SIGNED_OUT') cb(); }),
 async signUp(email, password, fn, ln, next) {
  const { data, error } = await sb.auth.signUp({ email, password, options: { data: { first_name: fn, last_name: ln },
   emailRedirectTo: location.origin + location.pathname + (next ? '?next=' + encodeURIComponent(next) : '') } });
  if (error) return ko(error);
  if (data.user && data.user.identities && data.user.identities.length === 0) return { ok: false, error: 'Un compte existe déjà avec cet e-mail.' };
  return ok(data); },
 async signIn(email, password) { const { data, error } = await sb.auth.signInWithPassword({ email, password }); return error ? ko(error) : ok(data); },
 async signOut() { await sb.auth.signOut(); },
 async currentUser() {
  const { data: { session } } = await sb.auth.getSession(); if (!session) return null;
  const { data: { user }, error } = await sb.auth.getUser(); if (error || !user) return null;
  const m = user.user_metadata || {};
  const { data: r } = await sb.from('user_roles').select('role').eq('user_id', user.id).maybeSingle();
  return { id: user.id, email: user.email, fn: m.first_name || '', ln: m.last_name || '', admin: !!r && r.role === 'admin' }; },
 async products() { const { data, error } = await sb.from('products').select('*').eq('available', true).order('id'); return error ? ko(error) : ok(data); },
 async myOrders(uid) { const { data, error } = await sb.from('orders').select('*').eq('user_id', uid).order('created_at', { ascending: false }).limit(100); return error ? ko(error) : ok(data); },
 async createOrder(o) { const { data, error } = await sb.rpc('create_demo_order', { p_attempt: o.attempt, p_items: o.items, p_expected_total: o.expected, p_shipping: o.ship, p_payment: o.pay }); return error ? ko(error) : ok(data); },
 // --- administration (les droits sont verifies par RLS, pas par ce fichier) ---
 async listOrders(st, from, to) { let q = sb.from('orders').select('*').order('created_at', { ascending: false }).range(from, to); if (st) q = q.eq('status', st); const { data, error } = await q; return error ? ko(error) : ok(data); },
 async setStatus(id, status, ts) { const { data, error } = await sb.from('orders').update({ status }).eq('id', id).eq('updated_at', ts).select(); if (error) return ko(error);
  return data.length ? ok(data[0]) : { ok: false, error: 'Cette commande a été modifiée entre-temps. Actualisez la liste.' }; },
 async listProducts() { const { data, error } = await sb.from('products').select('*').order('id'); return error ? ko(error) : ok(data); },
 async saveProduct(row, isNew) { const q = isNew ? sb.from('products').insert(row) : sb.from('products').update(row).eq('id', row.id); const { error } = await q; return error ? ko(error) : ok(true); },
 async deleteProduct(id) { const { error } = await sb.from('products').delete().eq('id', id); return error ? ko(error) : ok(true); }
};
})();

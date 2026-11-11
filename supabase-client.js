// Une seule initialisation du client. Remplacez les 2 valeurs (Project Settings > API Keys).
// Utilisez UNIQUEMENT la Publishable key (jamais la secret/service_role key).
const SUPABASE_URL = 'https://mspapyyreissxykzbceg.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_YPJzgqTDuLKUkv7syGytAA__1Nbs_FL';
window.sb = window.sb || supabase.createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);
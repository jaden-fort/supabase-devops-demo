import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const config = window.__SUPABASE_CONFIG__ ?? {};
const panel = document.querySelector(".status-panel");
const databaseName = document.querySelector("#database-name");
const detail = document.querySelector("#connection-detail");

function setState(state, title, message) {
  panel.dataset.state = state;
  databaseName.textContent = title;
  detail.textContent = message;
}

if (!config.url || !config.anonKey) {
  setState(
    "error",
    "Missing Supabase config",
    "Create web/env.js from web/env.example.js and fill in SUPABASE_URL and SUPABASE_ANON_KEY."
  );
} else {
  const supabase = createClient(config.url, config.anonKey);
  const { data, error } = await supabase.rpc("demo_database_identity");

  if (error) {
    setState("error", "Connection failed", error.message);
  } else {
    setState("ok", data, "This value came from public.demo_database_identity().");
  }
}

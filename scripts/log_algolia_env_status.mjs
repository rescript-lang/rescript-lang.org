const PUBLIC_KEYS = [
  "VITE_ALGOLIA_APP_ID",
  "VITE_ALGOLIA_INDEX_NAME",
  "VITE_ALGOLIA_SEARCH_API_KEY",
];

export function getMissingPublicAlgoliaVars(env = process.env) {
  return PUBLIC_KEYS.filter((key) => {
    const value = env[key];
    return value == null || value === "";
  });
}

export function formatDisabledMessage(missing) {
  return `Algolia search disabled: missing ${missing.join(", ")}`;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const missing = getMissingPublicAlgoliaVars();
  if (missing.length > 0) {
    console.warn(formatDisabledMessage(missing));
  }
}

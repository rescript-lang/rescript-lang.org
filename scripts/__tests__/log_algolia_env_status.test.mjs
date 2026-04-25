import test from "node:test";
import assert from "node:assert/strict";
import {
  formatDisabledMessage,
  getMissingPublicAlgoliaVars,
} from "../log_algolia_env_status.mjs";

test("reports missing public vars in declaration order", () => {
  assert.deepEqual(
    getMissingPublicAlgoliaVars({
      VITE_ALGOLIA_APP_ID: "",
      VITE_ALGOLIA_INDEX_NAME: "dev_rescript_lang",
      VITE_ALGOLIA_SEARCH_API_KEY: undefined,
    }),
    ["VITE_ALGOLIA_APP_ID", "VITE_ALGOLIA_SEARCH_API_KEY"],
  );
});

test("formats the disabled search warning", () => {
  assert.equal(
    formatDisabledMessage(["VITE_ALGOLIA_APP_ID"]),
    "Algolia search disabled: missing VITE_ALGOLIA_APP_ID",
  );
});

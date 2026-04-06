// helloAlgolia.mjs
import { algoliasearch } from "algoliasearch";

const appID = "1T1PRULLJT";
// API key with `addObject` and `editSettings` ACL
const apiKey = "999e5352ab7aed499de651ee79f573ee";
const indexName = "dev_2026";

const client = algoliasearch(appID, apiKey);

const record = { objectID: "object-1", name: "test record" };

// Add record to an index
const { taskID } = await client.saveObject({
  indexName,
  body: record,
});

// Wait until indexing is done
await client.waitForTask({
  indexName,
  taskID,
});

// Search for "test"
const { results } = await client.search({
  requests: [
    {
      indexName,
      query: "test",
    },
  ],
});

console.log(JSON.stringify(results, null, 2));

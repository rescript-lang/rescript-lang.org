import assert from "node:assert/strict";

const baseUrl = process.argv[2] ?? "http://127.0.0.1:8788";
const request = (path, options = {}) =>
  fetch(new URL(path, baseUrl), {
    redirect: "manual",
    signal: AbortSignal.timeout(10_000),
    ...options,
  });

for (const path of [
  "/",
  "/docs/manual/introduction/",
  "/docs/manual/api/",
  "/try",
]) {
  const response = await request(path);
  assert.equal(response.status, 200, path);
  await response.body?.cancel();
}

for (const path of [
  "/does-not-exist",
  "/docs/does-not-exist",
  "/docs/react/does-not-exist",
]) {
  for (const method of ["GET", "HEAD"]) {
    const response = await request(path, { method });
    assert.equal(response.status, 404, `${method} ${path}`);
    if (method === "GET") {
      assert.match(await response.text(), /Page Not Found/);
    }
  }
}

for (const path of [
  "/docs/manual/api/introduction",
  "/docs/manual/api/introduction/",
]) {
  const response = await request(path);
  assert.equal(response.status, 308, path);
  assert.equal(
    new URL(response.headers.get("location"), baseUrl).pathname,
    "/docs/manual/api",
  );
  await response.body?.cancel();
}

const manifestResponse = await request("/favicon/site.webmanifest");
assert.equal(manifestResponse.status, 200);
const manifest = await manifestResponse.json();
for (const icon of manifest.icons) {
  const response = await request(icon.src);
  assert.equal(response.status, 200, icon.src);
  assert.equal(
    response.headers.get("content-type")?.split(";")[0],
    icon.type,
    icon.src,
  );
  await response.body?.cancel();
}

for (const path of ["/img/debugger-before.avif", "/img/debugger-after.avif"]) {
  const response = await request(path);
  assert.equal(response.status, 200, path);
  assert.equal(response.headers.get("content-type"), "image/avif", path);
  await response.body?.cancel();
}

console.log(
  "Pages checks passed: valid routes, 404 responses, API redirect, and local images.",
);

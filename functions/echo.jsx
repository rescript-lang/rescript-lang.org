export function onRequest(context) {
  const url = new URL(context.request.url);
  return new Response(url.searchParams.toString());
}

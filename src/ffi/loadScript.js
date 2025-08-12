const isBrowser =
  typeof window !== "undefined" && typeof window.document !== "undefined"

export default function loadScript(src, onSuccess, onError) {
  if (!isBrowser) return

  const scriptEl = document.createElement("script")
  scriptEl.setAttribute("src", src)

  scriptEl.addEventListener("load", onSuccess)
  scriptEl.addEventListener("error", onError)

  document.body.appendChild(scriptEl)

  return () => {
    scriptEl.removeEventListener("load", onSuccess)
    scriptEl.removeEventListener("error", onError)
  }
}

export function removeScript(src) {
  const existing = document.body.querySelectorAll(`script[src="${src}"]`)
  existing.forEach((el) => {
    document.body.removeChild(el)
  })
}

open Cypress
open HomepageHelpers

it("community gallery supports keyboard selection and wraps to the first photo", () => {
  visit("/")
  containsIn("h1", headline)->realClick->ignore
  let first = `button[aria-label="Show community photo 1"]`
  let third = `button[aria-label="Show community photo 3"]`
  let next = `button[aria-label="Next community photo"]`

  get(first)->shouldAttribute("aria-pressed", "true")->ignore
  get(third)->scrollIntoView->focusElement->realPress("Enter")->ignore
  get(third)->shouldAttribute("aria-pressed", "true")->should("be.focused")->ignore
  get(`img[alt="ReScript community photo 3"]`)->should("be.visible")->ignore
  get(next)->focusElement->realPress("Space")->ignore
  get(first)->shouldAttribute("aria-pressed", "true")->ignore
  get(next)->should("be.focused")->ignore
  get(`img[alt="ReScript community photo 1"]`)->should("be.visible")->ignore
})

it("clipboard denial can recover and both install commands can be copied repeatedly", () => {
  denyClipboardPermissions()
  visit("/")
  let first = `button[aria-label="Copy npm install rescript command"]`
  get(`[role="status"]`)->shouldInt("have.length", 2)->ignore
  get(`button [role="status"]`)->should("not.exist")->ignore
  get(first)->realClick->ignore
  containsIn(`[role="status"]`, "Could not copy. Try again.")->should("be.visible")->ignore
  get(first)->should("be.enabled")->ignore
  grantClipboardPermissions()

  ["npm install rescript", "npx create-rescript-app"]->Array.forEach(command => {
    let button = `button[aria-label="Copy ${command} command"]`
    get(button)->realClick->ignore
    containsIn(`[role="status"]`, "Copied!")->should("be.visible")->ignore
    get(button)->should("be.disabled")->ignore
    readClipboard()->shouldEqual(command)->ignore
    get(button)->should("be.enabled")->ignore
    contains("Copied!")->should("not.exist")->ignore
    get(button)->realClick->ignore
    contains("Copied!")->should("be.visible")->ignore
    get(button)->should("be.enabled")->ignore
  })
})

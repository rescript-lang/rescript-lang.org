open Cypress

let expectSelectedSuggestionInView = (~scrolled, elements) => {
  let selected = elements->item(0)->Option.getOrThrow->HtmlRef.fromDom
  let parent = selected.parentElement->Null.getOrThrow
  let selectedRect = selected->WebAPI.HTMLElement.getBoundingClientRect
  let parentRect = parent->WebAPI.HTMLElement.getBoundingClientRect
  expect(selectedRect.top)->atLeast(parentRect.top -. 1.0)
  expect(parentRect.bottom +. 1.0)->atLeast(selectedRect.bottom)
  if scrolled {
    expect(parent.scrollTop)->greaterThanFloat(0.0)
  } else {
    expect(parent.scrollTop)->closeTo(0.0, 1.0)
  }
}

describe("Warning flag suggestions", () => {
  it("scrolls the selected suggestion into view in both keyboard directions", () => {
    visit("/try")
    containsIn("button", "Settings")->click->ignore
    let input = "input[placeholder='Flags']"
    get(input)->typeText("+")->ignore
    for _ in 1 to 15 {
      get(input)->typeText("{downarrow}")->ignore
    }
    get(".playground-suggestion-active")
    ->shouldSatisfy(elements => expectSelectedSuggestionInView(~scrolled=true, elements))
    ->ignore

    for _ in 1 to 15 {
      get(input)->typeText("{uparrow}")->ignore
    }
    get(".playground-suggestion-active")
    ->shouldSatisfy(elements => expectSelectedSuggestionInView(~scrolled=false, elements))
    ->ignore
  })
})

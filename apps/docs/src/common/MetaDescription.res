let maxSentenceLength = 140

let collapseWhitespace = value => value->String.trim->String.replaceAllRegExp(/\s+/g, " ")

let ensurePeriod = sentence =>
  if sentence->String.endsWith(".") {
    sentence
  } else {
    sentence ++ "."
  }

let shortenForSocialPreview = description => {
  let normalized = collapseWhitespace(description)
  let sentences =
    normalized->String.split(".")->Array.map(String.trim)->Array.filter(sentence => sentence != "")

  switch (sentences->Array.get(0), sentences->Array.get(1)) {
  | (Some(firstSentence), Some(secondSentence))
    if String.length(firstSentence) <= maxSentenceLength &&
      String.length(secondSentence) <= maxSentenceLength =>
    ensurePeriod(firstSentence) ++ " " ++ ensurePeriod(secondSentence)
  | (Some(firstSentence), _) => ensurePeriod(firstSentence)
  | _ => normalized
  }
}

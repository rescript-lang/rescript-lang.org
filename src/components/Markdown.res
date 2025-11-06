// This file was automatically converted to ReScript from 'Markdown.re'
// Check the output and make sure to delete the original file
external childrenToString: React.element => string = "%identity"

module P = {
  @react.component
  let make = (~children) =>
    <p className="md-p md:leading-5 tracking-[-0.015em] text-gray-80 md:text-16"> children </p>
}

// Used for hero like introduction text in
// e.g Doc sections
module Intro = {
  @react.component
  let make = (~children) => <div className="text-24 mt-8 mb-4"> children </div>
}

module Cite = {
  @react.component
  let make = (~author: option<string>, ~children) =>
    // For semantics, check out
    // https://css-tricks.com/quoting-in-html-quotations-citations-and-blockquotes/
    <div className="my-10 border-l-2 border-fire font-normal pl-10 py-1 text-fire max-w-sm">
      <blockquote className="text-32 italic mb-2"> children </blockquote>
      {Option.mapOr(author, React.null, author =>
        <figcaption className="font-semibold text-14"> {React.string(author)} </figcaption>
      )}
    </div>
}

module Info = {
  @react.component
  let make = (~children) =>
    <div className="infobox my-5 py-6 pl-8 pr-10 rounded-lg bg-sky-5"> children </div>
}

module Warn = {
  @react.component
  let make = (~children) =>
    <div className="my-6 py-6 pl-8 pr-10 rounded-lg bg-orange-10"> children </div>
}

module UrlBox = {
  open! MdxLegacy.MdxChildren

  let imgEl = <img src="/hyperlink.svg" className="mr-2 inline-block" />

  @react.component
  let make = (~text: string, ~href: string, ~children: MdxLegacy.MdxChildren.t) => {
    let content = switch classify(children) {
    | String(str) =>
      <p>
        imgEl
        {React.string(str)}
      </p>
    | Element(el) =>
      let subChildren = el->getMdxChildren
      <p>
        imgEl
        {subChildren->toReactElement}
      </p>
    | Array(arr) =>
      // Scenario: Take the first element, rewrap its children with the hyperlink img
      let length = Array.length(arr)
      if length >= 1 {
        let head = Belt.Array.getExn(arr, 0)
        let headChildren = head->getMdxChildren

        <>
          <P>
            imgEl
            {headChildren->toReactElement}
          </P>
          {if length > 1 {
            arr->Array.slice(~start=1, ~end=length)->MdxLegacy.arrToReactElement
          } else {
            React.null
          }}
        </>
      } else {
        React.null
      }
    | Unknown(el) =>
      Console.log2("Received unknown", el)
      React.null
    }

    // Next.Link doesn't allow any absolute URLs, so we need to render
    // a plain <a> component when there is an absolute href
    let link = if Util.Url.isAbsolute(href) {
      <a href rel="noopener noreferrer" className="flex items-center">
        {React.string(text)}
        <Icon.ArrowRight className="ml-1" />
      </a>
    } else {
      <ReactRouter.Link.String to=href className="flex items-center">
        {React.string(text)}
        <Icon.ArrowRight className="ml-1" />
      </ReactRouter.Link.String>
    }
    <div className="md-url-box text-16 border-l-2 border-gray-60 my-6 py-6 pl-8 pr-10 bg-gray-5">
      content
      <div className="mt-4 text-sky hover:text-sky-30"> link </div>
    </div>
  }
}

// Used for creating invisible, hoverable <a> anchors for url linking
module Anchor = {
  // Todo: Headers with nested components don't pass a string, we need to flatten
  // everything to a single string first before we are able to use this id transformation
  // function

  @react.component
  let make = (~id: string, ~title: string) => {
    <span className="inline group relative" title>
      <a
        title
        className="scroll-mt-30 invisible text-gray-60 opacity-50 hover:opacity-100 hover:text-gray-60 hover:cursor-pointer group-hover:visible"
        href={"#" ++ id}
        id={"#" ++ id}
      >
        <Icon.Hyperlink className="inline-block align-middle text-gray-40" />
      </a>
    </span>
  }
}
//*--- HEADLINES ---*//

module H1 = {
  @react.component
  let make = (~children) => <h1 className="hl-1 mb-6 scroll-mt-0"> children </h1>
}

module H2 = {
  @react.component
  let make = (~id, ~children) => {
    // Children may not be a string
    let title = {
      try {
        childrenToString(children)->Url.normalizeAnchor
      } catch {
      | _ => ""
      }
    }
    <>
      <h2 id className="group mt-16 mb-3 hl-3 scroll-mt-32">
        children
        <span className="ml-2">
          <Anchor title={title} id={title} />
        </span>
      </h2>
    </>
  }
}

module H3 = {
  @react.component
  let make = (~id, ~children) => {
    let title = childrenToString(children)
    <h3 id className="group mt-8 mb-4 hl-4 scroll-mt-32">
      children
      <span className="ml-2">
        <Anchor title={title} id={title->encodeURIComponent} />
      </span>
    </h3>
  }
}

module H4 = {
  @react.component
  let make = (~id, ~children) => {
    let title = childrenToString(children)
    <h4 id className="group mt-8 hl-5 scroll-mt-32">
      children
      <span className="ml-2">
        <Anchor title={title} id={title->encodeURIComponent} />
      </span>
    </h4>
  }
}

module H5 = {
  @react.component
  let make = (~id, ~children) => {
    let title = childrenToString(children)
    <h5
      id
      className="group mt-12 mb-3 text-12 leading-2 font-sans font-semibold uppercase tracking-wide text-gray-80"
    >
      children
      <span className="ml-2">
        <Anchor title={title} id={title->encodeURIComponent} />
      </span>
    </h5>
  }
}

module Pre = {
  @react.component
  let make = (~children) => <pre className="mt-2 mb-4 xs:mx-0 block"> children </pre>
}

module InlineCode = {
  @react.component
  let make = (~children) =>
    <code
      className="md-inline-code px-2 py-0.5  text-gray-60 font-mono rounded-sm bg-gray-10-tr border border-gray-90/5"
    >
      children
    </code>
}

module Table = {
  @react.component
  let make = (~children) =>
    <div className="overflow-x-auto mt-10 mb-16">
      <table> children </table>
    </div>
}

module Thead = {
  @react.component
  let make = (~children) => <thead> children </thead>
}

module Th = {
  @react.component
  let make = (~children) =>
    <th
      className="py-2 pr-8 text-12 text-gray-60 uppercase font-medium tracking-wide text-left border-b-2 border-gray-20"
    >
      children
    </th>
}

module Td = {
  @react.component
  let make = (~children) => <td className="border-b border-gray-20 py-3 pr-8"> children </td>
}

module Code = {
  @module("../ffi/parse-numeric-range.js")
  external parseNumericRange: string => array<int> = "parsePart"

  // TODO: Might be refactorable with the new @unboxed feature
  type unknown = MdxLegacy.Components.unknown

  external unknownAsString: unknown => string = "%identity"

  let parseNumericRangeMeta = (metastring: string) =>
    String.split(metastring, " ")
    ->Array.find(s => String.startsWith(s, "{") && String.endsWith(s, "}"))
    ->Option.map(str => {
      let nums = String.replaceRegExp(str, /[\{\}]/g, "")->parseNumericRange
      nums
    })
    ->Option.getOr([])

  let makeCodeElement = (~code, ~metastring, ~lang) => {
    let baseClass = "md-code font-mono w-full block mt-5 mb-5"
    let codeElement = switch metastring {
    | None => <CodeExample code lang />
    | Some(metastring) =>
      let metaSplits = String.split(metastring, " ")->List.fromArray

      let highlightedLines = parseNumericRangeMeta(metastring)

      if List.has(metaSplits, "example", String.equal) {
        <CodeExample code lang />
      } else if List.has(metaSplits, "sig", String.equal) {
        <CodeExample code lang showLabel=false />
      } else {
        <CodeExample highlightedLines code lang />
      }
    }

    <div className=baseClass> codeElement </div>
  }

  @react.component
  let make = (~className: option<string>=?, ~metastring: option<string>, ~children: unknown) => {
    let lang = switch className {
    | None => "text"
    | Some(str) =>
      switch String.split(str, "-") {
      | ["language", ""] => "text"
      | ["language", lang] => lang
      | _ => "text"
      }
    }

    let code = children->unknownAsString
    let isMultiline = code->String.includes("\n")

    switch lang {
    | "text" if !isMultiline => <InlineCode> {code->React.string} </InlineCode>
    | lang => <Pre> {makeCodeElement(~code, ~metastring, ~lang)} </Pre>
    }
  }
}

module CodeTab = {
  let getMdxMetastring: MdxLegacy.mdxComponent => option<string> = %raw("element => {
      if(element == null || element.props == null) {
        return;
      }
      return element.props.metastring;
    }")
  @react.component
  let make = (~children: MdxLegacy.MdxChildren.t, ~labels: array<string>=[]) => {
    let mdxElements = switch MdxLegacy.MdxChildren.classify(children) {
    | Array(mdxElements) => mdxElements
    | Element(el) => [el]
    | _ => []
    }

    let tabs = Array.reduceWithIndex(mdxElements, [], (acc, mdxElement, i) => {
      let child = mdxElement->MdxLegacy.MdxChildren.getMdxChildren->MdxLegacy.MdxChildren.classify

      switch child {
      | Element(codeEl) =>
        let className = MdxLegacy.getMdxClassName(codeEl)->Option.getOr("")

        let metastring = getMdxMetastring(codeEl)->Option.getOr("")

        let lang = switch String.split(className, "-") {
        | ["language", lang] => Some(lang)
        | _ => None
        }

        let code = String.make(MdxLegacy.MdxChildren.getMdxChildren(codeEl))
        let label = labels[i]
        let tab = {
          CodeExample.Toggle.lang,
          code,
          label,
          highlightedLines: Some(Code.parseNumericRangeMeta(metastring)),
        }
        Array.push(acc, tab)->ignore

      | _ => ()
      }
      acc
    })

    <div className="md-codetab mt-8 mb-8 xs:mx-0">
      <CodeExample.Toggle tabs />
    </div>
  }
}

module Blockquote = {
  @react.component
  let make = (~children) =>
    <blockquote className="md-blockquote">
      <Info> children </Info>
    </blockquote>
}

module Hr = {
  @react.component
  let make = () => <hr className="my-4" />
}

/*
    This will map either to an external link, or
    an anchor / reference link.

    TODO: Remark / Markdown actually has its own syntax
          for references: e.g. [my article][1]
          but it seems MDX doesn't map this to anything
          specific (It seems as if it was represented as a text
          node inside a <p> tag).

          Example for the AST:
          https://astexplorer.net/#/gist/2befce6edce1475eb4bbec001356b222/cede33d4c7545b8b2d759ded256802036ec3551c

          Possible solution could be to write our own plugin to categorize those
          specific component.
 */
module A = {
  @react.component
  let make = (~href, ~target=?, ~children) =>
    // In case we are handling a relative URL, we will use the Next routing
    if Util.Url.isAbsolute(href) {
      <a href rel="noopener noreferrer" className="no-underline text-fire hover:underline" ?target>
        children
      </a>
    } else {
      // We drop any .md / .mdx / .html extensions on every href...
      // Ideally one would check if this link is relative first,
      // but it's very unlikely we'd refer to an absolute URL ending
      // with .md
      let regex = /\.md(x)?|\.html$/
      let href = switch String.split(href, "#") {
      | [pathname, anchor] => String.replaceRegExp(pathname, regex, "") ++ ("#" ++ anchor)
      | [pathname] => String.replaceRegExp(pathname, regex, "")
      | _ => href
      }
      <ReactRouter.Link.String to=href className="no-underline text-fire hover:underline" ?target>
        children
      </ReactRouter.Link.String>
    }
}

module Ul = {
  @react.component
  let make = (~children) => <ul className="md-ul mb-16"> children </ul>
}

module Ol = {
  @react.component
  let make = (~children) => <ol className="md-ol ml-2"> children </ol>
}

module Li = {
  let typeOf: 'a => string = %raw("thing => { return typeof thing; }")
  let isArray: 'a => bool = %raw("thing => { return thing instanceof Array; }")
  external asArray: 'a => array<React.element> = "%identity"

  @react.component
  let make = (~children) => {
    /*
     There are 3 value scenarios for `children`

     1) string (if bullet point is standalone text)
     2) array(<p>, <ul>|<ol>) (if nested list)
     3) array(<p>,<inlineCode>,...,<p>) (if text with nested content)
     4) array(<strong>, <inlineCode>, string,...) (if nested content without wrapping <p>)

     We are iterating on these here with quite some bailout JS
 */

    let elements: React.element = if isArray(children) {
      let arr = children->asArray
      let last: React.element = {
        arr->Belt.Array.getExn(arr->Array.length - 1)
      }

      let head = Array.slice(arr, ~start=0, ~end=arr->Array.length - 1)

      let first = Belt.Array.getExn(head, 0)

      switch {
        open MdxLegacy
        last->fromReactElement->getMdxType
      } {
      | "ul"
      | "li"
      | "pre" =>
        switch {
          open MdxLegacy
          first->fromReactElement->getMdxType
        } {
        | "p" =>
          <>
            {React.array(head)}
            last
          </>
        | _ =>
          <>
            <p> {React.array(head)} </p>
            last
          </>
        }
      | _ => <p> children </p>
      /* Scenario 3 */
      }
    } else if typeOf(children) === "string" {
      <p> {children->Util.Unsafe.elementAsString->React.string} </p>
    } else {
      switch {
        /* Unknown Scenario */
        open MdxLegacy
        children->fromReactElement->getMdxType
      } {
      | "pre" => children
      | "p" => children
      | _ => <p> children </p>
      }
    }

    <li className="md-li mt-3 leading-4 ml-2"> elements </li>
  }
}

module Strong = {
  @react.component
  let make = (~children) => <strong className="font-semibold"> children </strong>
}

module Image = {
  @react.component
  let make = (
    ~src: string,
    ~size=#large,
    ~withShadow=false,
    ~caption: option<string>=?,
    ~externalLink: option<string>=?,
  ) => {
    let width = switch size {
    | #large => "w-full"
    | #small => "w-1/4"
    }

    let shadow = if withShadow {
      "shadow-md"
    } else {
      ""
    }

    let target = externalLink->Option.isSome ? Some("_blank") : None

    <div className={`mt-8 mb-12 ${size === #large ? "md:-mx-16" : ""}`}>
      <a href={externalLink->Option.getOr(src)} rel="noopener noreferrer" ?target>
        <img className={width ++ " " ++ shadow} src />
      </a>
      {switch caption {
      | None => React.null
      | Some(caption) =>
        <div className={`mt-4 text-14 text-gray-60 ${size === #large ? "md:ml-16" : ""}`}>
          {React.string(caption)}
        </div>
      }}
    </div>
  }
}

module Video = {
  @react.component
  let make = (~src: string, ~caption: option<string>=?) => {
    <div className="mt-8 mb-12 md:-mx-16">
      <div className={"flex w-full justify-center"}>
        <div className="relative h-full w-[640px] pt-[56.25%]">
          <iframe className={"absolute top-0 left-0 w-full h-full"} src allowFullScreen={true} />
        </div>
      </div>
      {switch caption {
      | None => React.null
      | Some(caption) =>
        <div className="mt-4 text-14 text-gray-80 md:ml-16"> {React.string(caption)} </div>
      }}
    </div>
  }
}

// Useful for debugging injected values in props
//  let mdxTestComponent: React.component<{.}> = %raw(`
//  function(children) {
//    console.log(children);
//    return React.createElement("div");
//  }
// `)

// Used for the MdxJS Provider

/* Sets our preferred branded styles
   We most likely will never need a different ~components
   option on our website. */

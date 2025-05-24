module V800Layout = DocsLayout.Make({
  // Structure defined by `scripts/extract-tocs.js`
  @module("index_data/manual_v800_toc.json") external tocData: SidebarLayout.Toc.raw = "default"
})

module V900Layout = DocsLayout.Make({
  // Structure defined by `scripts/extract-tocs.js`
  @module("index_data/manual_v900_toc.json") external tocData: SidebarLayout.Toc.raw = "default"
})

module V1000Layout = DocsLayout.Make({
  // Structure defined by `scripts/extract-tocs.js`
  @module("index_data/manual_v1000_toc.json") external tocData: SidebarLayout.Toc.raw = "default"
})

module V1100Layout = DocsLayout.Make({
  // Structure defined by `scripts/extract-tocs.js`
  @module("index_data/manual_v1100_toc.json") external tocData: SidebarLayout.Toc.raw = "default"
})

module V1100 = {
  @react.component
  let make = (~frontmatter=?, ~components=MarkdownComponents.default, ~children) => {
    let title = "Language Manual"
    let router = Next.Router.useRouter()
    let version = router.route->Url.parse->Url.getVersionString

    let breadcrumbs = list{
      {Url.name: "Docs", href: "/docs/" ++ version},
      {Url.name: "Language Manual", href: "/docs/manual/" ++ (version ++ "/introduction")},
    }

    <V1100Layout
      theme=#Reason
      components
      version
      title
      metaTitleCategory="ReScript Language Manual"
      availableVersions=Constants.allManualVersions
      nextVersion=?Constants.nextVersion
      ?frontmatter
      breadcrumbs>
      children
    </V1100Layout>
  }
}

module V1000 = {
  @react.component
  let make = (~frontmatter=?, ~components=MarkdownComponents.default, ~children) => {
    let router = Next.Router.useRouter()
    let route = router.route

    let url = route->Url.parse

    let version = url->Url.getVersionString

    let breadcrumbs = list{
      {
        open Url
        {name: "Docs", href: "/docs/" ++ version}
      },
      {
        open Url
        {
          name: "Language Manual",
          href: "/docs/manual/" ++ (version ++ "/introduction"),
        }
      },
    }

    let title = "Language Manual"

    <V1000Layout
      theme=#Reason
      components
      version
      title
      metaTitleCategory="ReScript Language Manual"
      availableVersions=Constants.allManualVersions
      nextVersion=?Constants.nextVersion
      ?frontmatter
      breadcrumbs>
      children
    </V1000Layout>
  }
}

module V900 = {
  @react.component
  let make = (
    ~frontmatter: option<JSON.t>=?,
    ~components=MarkdownComponents.default,
    ~children,
  ) => {
    let router = Next.Router.useRouter()
    let route = router.route

    let url = route->Url.parse

    let version = url->Url.getVersionString

    let breadcrumbs = list{
      {
        open Url
        {name: "Docs", href: "/docs/" ++ version}
      },
      {
        open Url
        {
          name: "Language Manual",
          href: "/docs/manual/" ++ (version ++ "/introduction"),
        }
      },
    }

    let title = "Language Manual"

    <V900Layout
      theme=#Reason
      components
      version
      title
      metaTitleCategory="ReScript Language Manual"
      availableVersions=Constants.allManualVersions
      nextVersion=?Constants.nextVersion
      ?frontmatter
      breadcrumbs>
      children
    </V900Layout>
  }
}

module V800 = {
  @react.component
  let make = (~frontmatter=?, ~components=MarkdownComponents.default, ~children) => {
    let router = Next.Router.useRouter()
    let route = router.route

    let url = route->Url.parse

    let version = url->Url.getVersionString

    let breadcrumbs = list{
      {
        open Url
        {name: "Docs", href: "/docs/" ++ version}
      },
      {
        open Url
        {
          name: "Language Manual",
          href: "/docs/manual/" ++ (version ++ "/introduction"),
        }
      },
    }

    let title = "Language Manual"
    let version = "v8.0.0"

    let warnBanner = {
      open Markdown

      let latestUrl =
        "/" ++ (Array.join(url.base, "/") ++ ("/latest/" ++ Array.join(url.pagepath, "/")))

      let label = switch Array.find(Constants.allManualVersions, ((v, _)) => {
        v === version
      }) {
      | Some((_, label)) => label
      | None => version
      }

      let additionalText = switch version {
      | "v8.0.0" => "(These docs are equivalent to the old BuckleScript docs before the ReScript rebrand)"
      | _ => ""
      }

      <div className="mb-10">
        <Info>
          <P>
            {React.string(
              "You are currently looking at the " ++
              (label ++
              " docs (Reason v3.6 syntax edition). You can find the latest manual page "),
            )}
            <A href=latestUrl> {React.string("here")} </A>
            {React.string(".")}
            <p className="text-14 mt-2"> {React.string(additionalText)} </p>
          </P>
        </Info>
      </div>
    }

    <V800Layout
      theme=#Reason
      components
      version
      title
      metaTitleCategory="ReScript Language Manual"
      availableVersions=Constants.allManualVersions
      nextVersion=?Constants.nextVersion
      ?frontmatter
      breadcrumbs>
      warnBanner
      children
    </V800Layout>
  }
}

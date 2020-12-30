// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Url from "../common/Url.js";
import * as React from "react";
import * as Js_dict from "bs-platform/lib/es6/js_dict.js";
import * as Markdown from "../components/Markdown.js";
import * as Belt_List from "bs-platform/lib/es6/belt_List.js";
import * as Belt_Array from "bs-platform/lib/es6/belt_Array.js";
import * as DocsLayout from "./DocsLayout.js";
import * as Belt_Option from "bs-platform/lib/es6/belt_Option.js";
import * as Caml_option from "bs-platform/lib/es6/caml_option.js";
import * as Router from "next/router";

var tocData = (require('index_data/gentype_toc.json'));

var overviewNavs = [
  {
    name: "Introduction",
    href: "/docs/gentype/latest/introduction"
  },
  {
    name: "Getting Started",
    href: "/docs/gentype/latest/getting-started"
  },
  {
    name: "Usage",
    href: "/docs/gentype/latest/usage"
  }
];

var advancedNavs = [{
    name: "Supported Types",
    href: "/docs/gentype/latest/supported-types"
  }];

var categories = [
  {
    name: "Overview",
    items: overviewNavs
  },
  {
    name: "Advanced",
    items: advancedNavs
  }
];

function GenTypeDocsLayout(Props) {
  var componentsOpt = Props.components;
  var children = Props.children;
  var components = componentsOpt !== undefined ? Caml_option.valFromOption(componentsOpt) : Markdown.$$default;
  var router = Router.useRouter();
  var route = router.route;
  var activeToc = Belt_Option.map(Js_dict.get(tocData, route), (function (data) {
          var title = data.title;
          var entries = Belt_Array.map(data.headers, (function (header) {
                  return {
                          header: header.name,
                          href: "#" + header.href
                        };
                }));
          return {
                  title: title,
                  entries: entries
                };
        }));
  var url = Url.parse(route);
  var version = url.version;
  var version$1 = typeof version === "number" ? "latest" : version._0;
  var prefix_0 = {
    name: "Docs",
    href: "/docs/latest"
  };
  var prefix_1 = {
    hd: {
      name: "GenType",
      href: "/docs/gentype/" + (version$1 + "/introduction")
    },
    tl: /* [] */0
  };
  var prefix = {
    hd: prefix_0,
    tl: prefix_1
  };
  var breadcrumbs = Belt_List.concat(prefix, DocsLayout.makeBreadcrumbs("/docs/gentype/" + version$1, route));
  var tmp = {
    breadcrumbs: breadcrumbs,
    title: "GenType",
    version: "v3",
    categories: categories,
    components: components,
    theme: "Reason",
    children: children
  };
  if (activeToc !== undefined) {
    tmp.activeToc = Caml_option.valFromOption(activeToc);
  }
  return React.createElement(DocsLayout.make, tmp);
}

var Link;

var NavItem;

var Category;

var Toc;

var make = GenTypeDocsLayout;

export {
  Link ,
  tocData ,
  NavItem ,
  Category ,
  Toc ,
  overviewNavs ,
  advancedNavs ,
  categories ,
  make ,
  
}
/* tocData Not a pure module */
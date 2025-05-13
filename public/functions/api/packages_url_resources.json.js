let urlResources = [
  {
    "name": "ReScript Test Framework",
    "description": "The most minimalistic testing library you will find for testing ReScript code",
    "keywords": ["testing", "minimal", "experimental"],
    "urlHref": "https://github.com/rescript-lang/rescript-project-template/blob/test/tests/Tests.res",
    "official": true
  },
  {
    "name": "genType",
    "description": "Better interop with JS & TS in ReScript",
    "keywords": ["rescript", "typescript"],
    "urlHref": "https://github.com/reason-association/genType",
    "official": true
  }
]

export async function onRequestGET(context) {
  const packages = await fetchNpmPackages()
  return Response.json({
    ...packages,
    urlResources,
  })
}

async function fetchNpmPackages() {
  let baseUrl = "https://registry.npmjs.org/-/v1/search?text=keywords:rescript&size=250&maintenance=1.0&popularity=0.5&quality=0.9"

  let [data1, data2, data3] = await Promise.all3([
    fetch(baseUrl)
      .then(res => res.json())
      .then(data => parsePkgs(data)),
    fetch(baseUrl + "&from=250")
      .then(res => res.json())
      .then(data => parsePkgs(data)),
    fetch(baseUrl + "&from=500")
      .then(res => res.json())
      .then(data => parsePkgs(data)),
  ])

  let unmaintained = []

  function shouldAllow(pkg) {
    // These are packages that we do not want to filter out when loading searching from NPM.
    let packageAllowList = []

    if (packageAllowList.includes(pkg)) {
      return true
    }

    if (pkg.name.includes("reason")) {
      return false
    }

    if (pkg.maintenanceScore < 0.3) {
      unmaintained.push(pkg)
      return false
    }

    return true
  }

  let packages = []
  for (let pkg of data1) if (shouldAllow(pkg)) packages.push(pkg)
  for (let pkg of data2) if (shouldAllow(pkg)) packages.push(pkg)
  for (let pkg of data3) if (shouldAllow(pkg)) packages.push(pkg)

  return {
    packages,
    unmaintained,
  }
}

function parsePkgs(data) {
  return data["objects"].map(item => {
    let pkg = item["package"]
    return {
      name: pkg["name"],
      version: pkg["version"],
      keywords: uniqueKeywords(filterKeywords(pkg["keywords"])),
      description: pkg["description"] ?? "",
      repositoryHref: pkg["links"]?.["repository"] ?? null,
      npmHref: pkg["links"]["npm"],
      searchScore: item["searchScore"],
      maintenanceScore: item["score"]["detail"]["maintenance"],
    }
  })
}

function filterKeywords(keywords) {
  return keywords.filter(kw => {
    let k = kw.toLowerCase()
    return !(
      k === "reasonml" ||
      k === "reason" ||
      k === "ocaml" ||
      k === "bucklescript" ||
      k === "rescript"
    )
  })
}

function uniqueKeywords(keywords) {
  return [...new Set(keywords)]
}

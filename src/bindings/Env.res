// If Vite if running in dev mode
external dev: bool = "import.meta.env.DEV"

// Cloudflare deployment URL
external deployment_url: option<string> = "import.meta.env.DEPLOYMENT_URL"

// The current github branch being used for cloudflare pages
external github_branch: option<string> = "import.meta.env.CF_PAGES_BRANCH"
let github_branch = switch github_branch {
| Some(branch) => branch
| None => "master"
}

// the root url of the site, e.g. "https://rescript-lang.org/" or "http://localhost:5173/"
let root_url = switch deployment_url {
| Some(url) => url
| None => dev ? "http://localhost:5173/" : "https://rescript-lang.org/"
}

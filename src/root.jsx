async function getPosts() {
  let glob = import.meta.glob('./posts/*.mdx', { eager: true })
  glob = Object.fromEntries(
    Object.entries(glob).map(([k, v]) => [
      k.slice('./posts'.length, -'.mdx'.length),
      v,
    ]),
  )
  return glob
}

export async function getStaticPaths() {
  const posts = await getPosts()
  return ['/', ...Object.keys(posts)]
}

export async function Root({ url }) {
  const posts = await getPosts()

  async function RootContent() {
    if (url.pathname === '/') {
      return (
        <ul>
          {Object.entries(posts).map(([key, value]) => (
            <li key={key}>
              <a href={key} style={{ textTransform: 'capitalize' }}>
                {(value).title ?? key.slice(1)}
              </a>
            </li>
          ))}
        </ul>
      )
    }

    const module = posts[url.pathname]
    if (!!module) {
      const Component = (module).default
      return <Component />
    }

    // TODO: how to 404?
    return <p>Not found</p>
  }

  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>RSC MDX SSG</title>
      </head>
      <body>
        <header style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <h1>
            <a href="/">RSC + MDX + SSG</a>
          </h1>
          <span data-testid="timestamp">
            Rendered at {new Date().toISOString()}
          </span>
        </header>
        <main>
          <RootContent />
        </main>
      </body>
    </html>
  )
}
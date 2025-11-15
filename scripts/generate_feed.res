let content = {
  open BlogApi.RssFeed
  getLatest()->toXmlString
}

Console.debug(content)

let content = {
  open BlogApi.RssFeed
  getLatest()->toXmlString
}

Console.log(content)

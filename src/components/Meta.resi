@react.component
let make: (
  ~siteName: string=?,
  ~keywords: array<string>=?,
  ~description: string=?,
  ~canonical: string=?,
  ~title: string=?,
  ~ogLocale: string=?,
  ~ogSiteName: string=?,
  ~ogDescription: string=?,
  ~ogTitle: string=?,
  ~ogImage: string=?,
  ~version: Url.version=?,
) => React.element

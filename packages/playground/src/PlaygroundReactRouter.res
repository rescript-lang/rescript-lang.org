type location = {
  pathname: string,
  search?: string,
  hash?: string,
}

@module("react-router")
external useLocation: unit => location = "useLocation"

@module("react-router")
external useSearchParams: unit => (WebAPI.URLAPI.urlSearchParams, {..} => unit) = "useSearchParams"

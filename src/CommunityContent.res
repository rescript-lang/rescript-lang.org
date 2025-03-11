type link = {
  url: string,
  title: string,
  description: string,
  image: string,
}

@module("../data/resources.json")
external resources: array<link> = "default"

let simplifyUrl = url =>
  url
  ->String.replace("https://", "")
  ->String.replace("http://", "")
  ->String.split("/")
  ->Array.at(0)

module LinkCard = {
  @react.component
  let make = (~link) => {
    <div className="rounded-lg  hover:text-fire overflow-hidden bg-gray-10 border-2 border-gray-30">
      <a href=link.url className="flex flex-col h-full">
        <img className="object-cover w-full md:h-40 max-h-[345px]" src=link.image alt="" />
        <div className="p-2 grow">
          <h3 className="font-semibold text-16 grow-0 mb-2"> {React.string(link.title)} </h3>
          <p className="mb-2 text-14 grow text-gray-80"> {React.string(link.description)} </p>
        </div>
        <p className="text-14 p-2 grow-0 text-gray-70">
          {React.string(link.url->simplifyUrl->Option.getOr(""))}
        </p>
      </a>
    </div>
  }
}

module LinkCards = {
  @react.component
  let make = () => {
    <div className="grid md:grid-cols-2 gap-6">
      {resources
      ->Array.map(link =>
        switch link.image {
        | "" => {...link, image: "/static/Art-3-rescript-launch.jpg"}
        | _ => link
        }
      )
      ->Array.map(link => <LinkCard link key=link.title />)
      ->React.array}
    </div>
  }
}

@react.component
let make = () => {
  <div>
    <h1 className="hl-1 mb-6"> {"Community Content"->React.string} </h1>
    <p className="md-p md:leading-5 tracking-[-0.015em] text-gray-80 md:text-16 mb-16">
      {React.string(
        "These articles, videos, and resources are created by the amazing ReScript community.",
      )}
      <br />
      {React.string("If you have a resource you'd like to share, please feel free to submit a PR!")}
    </p>
    <LinkCards />
  </div>
}

let default = make

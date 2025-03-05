type link = {
  url: string,
  title: string,
  description: string,
  image: string,
}

let links: array<link> = [
  {
    url: "https://dev.to/zth/getting-rid-of-your-dead-code-in-rescript-3mba",
    title: "Getting rid of your dead code in ReScript - DEV Community",
    description: "Exploring ReScript's tools for eliminating dead code, keeping your repository clean and without... Tagged with rescript.",
    image: "https://media2.dev.to/dynamic/image/width=1000,height=500,fit=cover,gravity=auto,format=auto/https%3A%2F%2Fdev-to-uploads.s3.amazonaws.com%2Fuploads%2Farticles%2F12lsasc06v1a355i6rfk.jpeg",
  },
  {
    url: "https://www.daggala.com/belt_vs_js_array_in_rescript/",
    title: "Belt.Array vs Js.Array in Rescript",
    description: "You might have noticed that there are several ways in Rescript for iterating through elements of an array. It’s not at all obvious which one you should be using…",
    image: "https://www.daggala.com/static/30b47dd2b0682e7eb0279b85bc9ebb53/f3583/toolbelt.png",
  },
  {
    url: "https://www.greyblake.com/blog/from-typescript-to-rescript/",
    title: "From TypeScript To ReScript | Serhii Potapov (greyblake)",
    description: "A blog about software development.",
    image: "https://www.greyblake.com/greyblake.jpeg",
  },
  {
    url: "https://fullsteak.dev/posts/fullstack-rescript-architecture-overview",
    title: "Full-stack ReScript. Architecture Overview | Full Steak Dev",
    description: "Can ReScript be used to create a full-featured back-end? In this article, I’d try to prove it can and does it with success.\n",
    image: "",
  },
  {
    url: "https://scalac.io/blog/rescript-for-react-development/",
    title: "ReScript for React - Development & Business Pros of ReScript",
    description: "Looking for ReScript for React Development information? In this article, I highlight the development & business advantages of ReScript.",
    image: "https://scalac.io/wp-content/uploads/2021/08/ReScript-for-React-Development-FB.png",
  },
  {
    url: "https://yangdanny97.github.io/blog/2021/07/09/Migrating-to-Rescript",
    title: "Rewriting a Project in ReScript",
    description: "My experience reimplementing a small project in ReScript",
    image: "",
  },
  {
    url: "https://alexfedoseev.com/blog/post/responsive-images-and-cumulative-layout-shift",
    title: "Responsive Images and Cumulative Layout Shift | Alex Fedoseev",
    description: "Solving cumulative layout shift issue caused by responsive images in layouts.",
    image: "https://d20bjcorj7xdk.cloudfront.net/eyJidWNrZXQiOiJpbWFnZXMuYWxleGZlZG9zZWV2LmNvbSIsImtleSI6Im1ldGEtYmxvZy5wbmciLCJlZGl0cyI6eyJyZXNpemUiOnsid2lkdGgiOjEyMDAsImhlaWdodCI6NjMwLCJmaXQiOiJjb3ZlciJ9LCJqcGVnIjp7InF1YWxpdHkiOjkwfX19?signature=d8e6c0ac1ff03d0f5ee04d128b96a7701b998952a38ba96e9a16e4414cd05ed0&version=58cfd6f8abdefeca2195a6a1f1108596",
  },
]

let simplifyUrl = url =>
  url
  ->String.replace("https://", "")
  ->String.replace("http://", "")
  ->String.split("/")
  ->Array.at(0)

module LinkCard = {
  @react.component
  let make = (~link) => {
    <div className="rounded-lg border-gray-90 hover:border-fire border-2 overflow-hidden">
      <a href=link.url className="flex flex-col h-full">
        <img className="object-cover w-full lg:h-20 md:h-22 h-40" src=link.image alt="" />
        <div className="p-2 grow">
          <h3 className="mb-2 font-semibold text-14 grow-0"> {React.string(link.title)} </h3>
          <p className="mb-2 text-12 grow"> {React.string(link.description)} </p>
        </div>
        <p className="text-14 p-2 grow-0 text-gray-60">
          {React.string(link.url->simplifyUrl->Option.getOr(""))}
        </p>
      </a>
    </div>
  }
}

module LinkCards = {
  @react.component
  let make = () =>
    <div className="grid lg:grid-cols-3 md:grid-cols-2 gap-4">
      {links
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

@react.component
let make = () => {
  <div>
    <LinkCards />
  </div>
}

let default = make

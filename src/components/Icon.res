module GitHub = {
  @react.component
  let make = (~className: string) =>
    <svg
      className={"fill-current " ++ className}
      width="18.236"
      height="17.79"
      viewBox="0 0 18.236 17.79">
      <g transform="translate(8 -5.365)">
        <path
          d="M17.013,9.906a9.078,9.078,0,0,0-3.318-3.318A8.918,8.918,0,0,0,9.118,5.365,8.919,8.919,0,0,0,4.541,6.588,9.077,9.077,0,0,0,1.223,9.906,8.919,8.919,0,0,0,0,14.483a8.861,8.861,0,0,0,1.739,5.36,8.93,8.93,0,0,0,4.493,3.294.531.531,0,0,0,.475-.083.464.464,0,0,0,.154-.356q0-.036-.006-.641T6.85,21l-.273.047a3.484,3.484,0,0,1-.659.042,5.02,5.02,0,0,1-.825-.083,1.844,1.844,0,0,1-.8-.356,1.506,1.506,0,0,1-.522-.73l-.119-.273a2.966,2.966,0,0,0-.374-.605,1.432,1.432,0,0,0-.516-.451l-.083-.06a.871.871,0,0,1-.154-.143.651.651,0,0,1-.107-.166q-.036-.083.059-.137a.77.77,0,0,1,.344-.053l.237.035a1.733,1.733,0,0,1,.588.285,1.916,1.916,0,0,1,.576.617,2.093,2.093,0,0,0,.659.742,1.4,1.4,0,0,0,.778.255,3.376,3.376,0,0,0,.677-.059,2.362,2.362,0,0,0,.534-.178,1.924,1.924,0,0,1,.582-1.223,8.129,8.129,0,0,1-1.217-.214,4.845,4.845,0,0,1-1.116-.463,3.2,3.2,0,0,1-.956-.8,3.822,3.822,0,0,1-.623-1.247A5.928,5.928,0,0,1,3.3,14.007a3.463,3.463,0,0,1,.938-2.446A3.192,3.192,0,0,1,4.321,9.14a1.664,1.664,0,0,1,1.021.16,7.138,7.138,0,0,1,.991.457q.315.19.5.321a8.574,8.574,0,0,1,4.559,0l.451-.285a6.389,6.389,0,0,1,1.092-.522,1.556,1.556,0,0,1,.962-.13A3.161,3.161,0,0,1,14,11.562a3.463,3.463,0,0,1,.938,2.446,5.994,5.994,0,0,1-.243,1.787,3.674,3.674,0,0,1-.629,1.247,3.319,3.319,0,0,1-.962.789,4.855,4.855,0,0,1-1.116.463,8.121,8.121,0,0,1-1.217.214,2.115,2.115,0,0,1,.617,1.686v2.5a.473.473,0,0,0,.149.356.516.516,0,0,0,.469.083A8.929,8.929,0,0,0,16.5,19.842a8.863,8.863,0,0,0,1.739-5.36A8.926,8.926,0,0,0,17.013,9.906Z"
          transform="translate(-8 0)"
        />
      </g>
    </svg>
}

module Npm = {
  @react.component
  let make = (~className: string) => {
    <svg className viewBox="0 0 18 7">
      <path
        className="fill-current"
        d="M0 0h18v6H9v1H5V6H0V0zm1 5h2V2h1v3h1V1H1v4zm5-4v5h2V5h2V1H6zm2 1h1v2H8V2zm3-1v4h2V2h1v3h1V2h1v3h1V1h-6z"
      />
      <path
        fill="#FFF"
        d="M1 5h2V2h1v3h1V1H1zM6 1v5h2V5h2V1H6zm3 3H8V2h1v2zM11 1v4h2V2h1v3h1V2h1v3h1V1z"
      />
    </svg>
  }
}

module X = {
  @react.component
  let make = (~className: string) =>
    <svg className={"fill-current " ++ className} viewBox="0 0 1200 1227">
      <path
        d="M714.163 519.284L1160.89 0H1055.03L667.137 450.887L357.328 0H0L468.492 681.821L0 1226.37H105.866L515.491 750.218L842.672 1226.37H1200L714.137 519.284H714.163ZM569.165 687.828L521.697 619.934L144.011 79.6944H306.615L611.412 515.685L658.88 583.579L1055.08 1150.3H892.476L569.165 687.854V687.828Z"
        transform="translate(0 -0.001)"
      />
    </svg>
}

module Bluesky = {
  @react.component
  let make = (~className: string) =>
    <svg className={"fill-current " ++ className} viewBox="0 0 568 501">
      <path
        d="M123.121 33.6637C188.241 82.5526 258.281 181.681 284 234.873C309.719 181.681 379.759 82.5526 444.879 33.6637C491.866 -1.61183 568 -28.9064 568 57.9464C568 75.2916 558.055 203.659 552.222 224.501C531.947 296.954 458.067 315.434 392.347 304.249C507.222 323.8 536.444 388.56 473.333 453.32C353.473 576.312 301.061 422.461 287.631 383.039C285.169 375.812 284.017 372.431 284 375.306C283.983 372.431 282.831 375.812 280.369 383.039C266.939 422.461 214.527 576.312 94.6667 453.32C31.5556 388.56 60.7778 323.8 175.653 304.249C109.933 315.434 36.0535 296.954 15.7778 224.501C9.94525 203.659 0 75.2916 0 57.9464C0 -28.9064 76.1345 -1.61183 123.121 33.6637Z"
        transform="translate(0 -0.001)"
      />
    </svg>
}

module MagnifierGlass = {
  @react.component
  let make = (~className: string) =>
    <svg
      className={"stroke-current " ++ className}
      width="19.203"
      height="19.203"
      viewBox="0 0 19.203 19.203">
      <g fill="none" strokeLinecap="round" strokeWidth="2px" transform="translate(-2 -2)">
        <path
          d="M6.479,0A6.479,6.479,0,1,1,0,6.479,6.479,6.479,0,0,1,6.479,0Z"
          transform="translate(3 3)"
        />
        <line strokeLinejoin="round" x1="5.734" y1="5.734" transform="translate(14.055 14.055)" />
      </g>
    </svg>
}

module Caret = {
  type direction = [#Up | #Down]

  type size = [#Sm | #Md]

  @react.component
  let make = (~className: string="", ~size=#Sm, ~direction: direction) => {
    let width = switch size {
    | #Sm => "10"
    | #Md => "14"
    }
    <svg
      className={"stroke-current " ++ className}
      viewBox="0 0 10 5"
      width
      fill="none"
      strokeMiterlimit="10"
      strokeWidth="2">
      {switch direction {
      | #Up => <path d="M.6,4.022,4.509.8,8.476,4.087" fill="none" />
      | #Down => <path d="M.6.866,4.509,4.087,8.476.8" />
      }}
    </svg>
  }
}

module DrawerDots = {
  @react.component
  let make = (~className: string="") =>
    <svg
      className={"fill-current " ++ className}
      stroke="none"
      width="22"
      height="4"
      viewBox="0 0 22 4">
      <circle cx="2" cy="2" r="2" />
      <circle cx="2" cy="2" r="2" transform="translate(9)" />
      <circle cx="2" cy="2" r="2" transform="translate(18)" />
    </svg>
}

module CornerLeftUp = {
  @react.component
  let make = (~className: string="") =>
    <svg
      className={"stroke-current " ++ className}
      width="18.414"
      height="18"
      fill="none"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="2px">
      <path d="M11.414 6l-5-5-5 5" />
      <path d="M17.414 17h-7a4 4 0 01-4-4V1" />
    </svg>
}

module Table = {
  @react.component
  let make = (~className: string="") =>
    <svg className={"stroke-current " ++ className} width="25" height="23">
      <defs>
        <style>
          {React.string(
            ".prefix__a,.prefix__b,.prefix__d{fill:none}.prefix__a,.prefix__b{stroke-width:1.5px}.prefix__c{stroke:none}",
          )}
        </style>
      </defs>
      <g className="prefix__a">
        <rect className="prefix__c" width="10" height="23" rx="2" />
        <rect className="prefix__d" x="0.75" y="0.75" width="8.5" height="21.5" rx="1.25" />
      </g>
      <g className="prefix__a">
        <rect className="prefix__c" width="25" height="23" rx="2" />
        <rect className="prefix__d" x="0.75" y="0.75" width="23.5" height="21.5" rx="1.25" />
      </g>
      <path className="prefix__b" d="M2.5 6.5h5M2.5 10.5h5" />
    </svg>
}

module Close = {
  @react.component
  let make = (~className: string="") =>
    <svg className={"fill-current " ++ className} width="12.728" height="12.728">
      <path d="M12.728 11.313l-1.414 1.414L0 1.414 1.414-.001z" />
      <path d="M11.314 0l1.414 1.414L1.415 12.728 0 11.314z" />
    </svg>
}

module ArrowRight = {
  @react.component
  let make = (~className: string="") =>
    <svg
      className={"fill-current " ++ className} width="18" height="11.769" viewBox="0 0 18 11.769">
      <defs>
        <clipPath id="prefix__a">
          <path
            d="M12.121-16.823a.67.67 0 00-.907 0 .566.566 0 000 .835l4.6 4.277H.635A.611.611 0 000-11.12a.617.617 0 00.635.6h15.179l-4.6 4.269a.576.576 0 000 .844.67.67 0 00.907 0L17.81-10.7a.553.553 0 000-.835z"
            transform="translate(0 17)"
            clipRule="evenodd"
            fill="current"
          />
        </clipPath>
        <clipPath id="prefix__b">
          <path
            className="prefix__b"
            d="M-297 336.231h747.692V-534H-297z"
            transform="translate(297 534)"
          />
        </clipPath>
      </defs>
      <g clipPath="url(#prefix__a)">
        <g transform="translate(-205.615 -357.923)" clipPath="url(#prefix__b)">
          <path className="prefix__b" d="M202.154 354.462h24.923v18.692h-24.923z" />
        </g>
      </g>
    </svg>
}

module Discourse = {
  @react.component
  let make = (~className: string="") =>
    <svg className={"fill-current " ++ className} viewBox="0 0 24 24">
      <path
        d="M12.103 0C18.666 0 24 5.485 24 11.997c0 6.51-5.33 11.99-11.9 11.99L0 24V11.79C0 5.28 5.532 0 12.103 0zm.116 4.563a7.395 7.395 0 00-6.337 3.57 7.247 7.247 0 00-.148 7.22L4.4 19.61l4.794-1.074a7.424 7.424 0 008.136-1.39 7.256 7.256 0 001.737-7.997 7.375 7.375 0 00-6.84-4.585h-.008z"
      />
    </svg>
}

module Hyperlink = {
  @react.component
  let make = (~className: string="") =>
    <svg
      className={"fill-current " ++ className}
      width="0.8em"
      height="0.8em"
      viewBox="0 0 20.003 19.944">
      <path
        d="M11.927 7.908a4.819 4.819 0 00-3.968-1.3 5.091 5.091 0 00-2.921 1.508L1.47 11.684a4.82 4.82 0 00.192 7.122 4.994 4.994 0 006.76-.4l3.7-3.776a.109.109 0 00-.067-.184s-.649.029-1.132.006a10.116 10.116 0 01-1.35-.226.308.308 0 00-.243.088l-2.529 2.609a2.733 2.733 0 01-3.583.319 2.64 2.64 0 01-.247-3.951l3.755-3.753a2.7 2.7 0 013.654-.073.108.108 0 00.15 0l1.4-1.4a.114.114 0 00-.003-.157z"
      />
      <path
        d="M8.076 12.036a4.822 4.822 0 003.967 1.3 5.089 5.089 0 002.922-1.509l3.568-3.568a4.818 4.818 0 00-.192-7.121 5 5 0 00-6.761.4l-3.7 3.777a.108.108 0 00.067.183s.648-.028 1.132-.006a10.151 10.151 0 011.35.226.3.3 0 00.243-.088l2.529-2.608a2.732 2.732 0 013.581-.319 2.638 2.638 0 01.249 3.95l-3.755 3.754a2.706 2.706 0 01-3.654.073.107.107 0 00-.15 0l-1.4 1.4a.113.113 0 00.004.156z"
      />
    </svg>
}

module TriangleDown = {
  @react.component
  let make = (~className: string="") =>
    <svg className={"fill-current " ++ className} width="8" height="5" viewBox="0 0 8 5">
      <path d="M4,0,8,5H0Z" transform="translate(8 5) rotate(180)" />
    </svg>
}

module ExternalLink = {
  @react.component
  let make = (~className="") =>
    <svg
      className={"stroke-current " ++ className}
      xmlns="http://www.w3.org/2000/svg"
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round">
      <path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6M15 3h6v6M10 14L21 3" />
    </svg>
}

module Copy = {
  @react.component
  let make = (~className="") =>
    <svg
      className={"stroke-current " ++ className}
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg">
      <rect
        x="8.00012" y="8.3175" width="12" height="12" rx="2" strokeWidth="2" strokeLinecap="round"
      />
      <path
        d="M16.0001 4.3175H7.00012C5.34327 4.3175 4.00012 5.66065 4.00012 7.3175V16.3175"
        strokeWidth="2"
        strokeLinecap="square"
      />
    </svg>
}

module Clipboard = {
  @react.component
  let make = (~className="") =>
    <svg
      className={"stroke-current " ++ className}
      xmlns="http://www.w3.org/2000/svg"
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round">
      <path d="M16 4h2a2 2 0 012 2v14a2 2 0 01-2 2H6a2 2 0 01-2-2V6a2 2 0 012-2h2" />
      <rect x="8" y="2" width="8" height="4" rx="1" ry="1" />
    </svg>
}

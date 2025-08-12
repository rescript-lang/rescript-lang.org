// import App from 'next/app'

//function MyApp({ Component, pageProps }) {
//console.log(pageProps);
//return <Component {...pageProps} />
//}

import "styles/main.css"
import "styles/utils.css"
import "codemirror/lib/codemirror.css"
import "styles/cm.css"
import "styles/docson.css"

import { make as ResApp } from "src/common/App.mjs"

export default function App(props) {
  return <ResApp {...props} />
}

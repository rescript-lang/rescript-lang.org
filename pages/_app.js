import "codemirror/lib/codemirror.css";
import "styles/docson.css";
import "styles/main.css";
import "styles/utils.css";

import { make as ResApp } from "src/common/App.mjs";

export default function App(props) {
  return <ResApp {...props} />;
}

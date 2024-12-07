import {
  getStaticPathsByVersion,
  getStaticPropsByVersion,
} from "src/ApiDocs.mjs";

import APIDocs from "src/ApiDocs.mjs";

export async function getStaticProps(ctx) {
  return await getStaticPropsByVersion({ ...ctx, version: "latest" });
}

export async function getStaticPaths(ctx) {
  return await getStaticPathsByVersion("latest");
}

export default function Comp(props) {
  return <APIDocs {...props} />;
}

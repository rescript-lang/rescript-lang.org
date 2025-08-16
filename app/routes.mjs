import { index, route } from "@react-router/dev/routes";
import { routes } from 'react-router-mdx/server';

export default [
    index("./routes/LandingPageRoute.jsx"),
    route("syntax-lookup", "./routes/SyntaxLookupRoute.jsx"),
    ...routes("./routes/mdx.jsx"),
    // TODO: playground, blog, community, 
]
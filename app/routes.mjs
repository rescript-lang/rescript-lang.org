import { index } from "@react-router/dev/routes";
import { routes } from 'react-router-mdx/server';

export default [
    index("./routes/LandingPageRoute.jsx"),
    ...routes("./routes/mdx.jsx"),
]
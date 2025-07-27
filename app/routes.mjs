import {
    route,
    index,
    layout,
    prefix,
} from "@react-router/dev/routes";

export default [
    index("./routes/home.jsx"),
    // route("about", "./about.tsx"),

    // layout("./auth/layout.tsx", [
    //     route("login", "./auth/login.tsx"),
    //     route("register", "./auth/register.tsx"),
    // ]),

    ...prefix("community", [
        index("./routes/community/overview.mdx"),
        // route(":city", "./concerts/city.tsx"),
        // route("trending", "./concerts/trending.tsx"),
    ]),
]
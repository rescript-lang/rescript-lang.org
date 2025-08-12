import { Outlet } from "react-router";

export default function App() {
    return (
        <div style={{ background: "red" }}>
            <Outlet />
        </div>
    );
}
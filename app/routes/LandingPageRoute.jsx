import { make as LandingPageLayout } from '../../src/layouts/LandingPageLayout.mjs';


export default function Home() {
    console.log(import.meta.env);
    return <LandingPageLayout />
}
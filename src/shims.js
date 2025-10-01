export const runWithoutLogging = async (fn) => {
    const orig = console.log;
    console.log = () => { };
    const values = await fn();
    console.log = orig;
    return values;
}
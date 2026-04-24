export const runWithoutLogging = async (fn) => {
  let result;
  const originalConsoleLog = console.log;
  console.log = () => {};
  result = await fn();
  console.log = originalConsoleLog;
  return result;
};

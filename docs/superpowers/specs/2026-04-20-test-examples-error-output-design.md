# Design: Clean Compiler Error Output in `scripts/test-examples.mjs`

## Goal

Make `scripts/test-examples.mjs` show clean ReScript compiler errors for bad docs examples without dumping the surrounding Node.js exception and stack trace.

The output should emphasize the markdown file and failing example location, not the internal temp build file or the fact that the script used `child_process`.

## Scope

### In scope

- suppress raw Node exception objects and stack traces for example-compile failures
- print cleaned ReScript compiler output for whole-file example validation failures
- print cleaned ReScript compiler output for per-`CodeTab` snippet compile failures
- replace temp-file references such as `temp/src/_tempFile.res` with the originating markdown file path
- map internal wrapper markers back to visible markdown fence markers like ` ```res example`, ` ```res prelude`, and ` ```res sig`
- prefix snippet-sync failures with the markdown file and relevant `CodeTab` line number

### Out of scope

- fixing the underlying docs example itself
- changing which example blocks are considered runnable
- changing `--update` rewrite behavior
- adding richer AST-based source mapping or exact markdown line remapping beyond the existing visible fence markers

## Recommended Approach

Keep the current compile flow and add one shared formatter for compiler failures.

The script already catches the top-level compile failure for each file. The missing behavior is formatting the compiler stderr into something docs-focused before printing it, then applying the same cleanup to the snippet compile path used by JS Output syncing.

## Behavior

### Whole-file example validation failure

When the transformed temporary ReScript file fails to compile during the file-level example pass, the script should:

- print a short location prefix using the markdown file path
- print the cleaned ReScript compiler error body
- suppress the raw Node exception and stack trace
- mark the run as unsuccessful and move to the next file

### Per-snippet JS-sync failure

When the snippet-specific compile fails during JS Output syncing, the script should:

- print a short location prefix using the markdown file path and the `CodeTab` example line
- print the cleaned ReScript compiler error body
- suppress the raw Node exception and stack trace
- mark the run as unsuccessful and stop processing that file

This keeps the script output focused on the bad docs snippet rather than the internal mechanics of the sync pass.

## Formatting Rules

The cleaned compiler output should:

- replace `_tempFile.res` references with the originating markdown file path
- replace internal wrapper lines such as `/* _MODULE_EXAMPLE_START */ module ... = {` with visible fence headers like ` ```res example`
- replace wrapper endings like `} // _MODULE_END` with closing fences like ` ````
- preserve the actual compiler error text, including the ReScript explanation
- avoid printing the JavaScript exception object, `Error: Command failed`, `at ...` frames, or `stdout` / `stderr` buffers

## Implementation Shape

Add a helper like:

```js
let formatCompilerError = ({ file, error }) => {
  // read stderr
  // swap temp path for markdown path
  // rewrite wrapper markers to visible fence markers
  // trim noisy trailing whitespace
};
```

Then add one small reporting helper like:

```js
let reportCompilerError = ({ logger, file, line, error }) => {
  logger.warn(`${file}${line == null ? "" : `:${line}`}`);
  logger.warn(formatCompilerError({ file, error }));
};
```

Use that helper in both compile sites:

- the file-level `execFileSync` call in `run()`
- the snippet-level `compileSnippet` path

## Error Handling

If compiler stderr is unexpectedly empty, the script may fall back to `error.message`, but it should still avoid printing a full Node stack trace.

If formatting fails, the fallback should still be a short docs-focused message rather than the raw thrown object.

## Verification Plan

Add automated coverage for:

- whole-file compile failures producing cleaned output without Node stack frames
- snippet compile failures producing cleaned output without Node stack frames
- temp-file path replacement to the markdown path
- wrapper-marker replacement back to visible markdown fence markers

Manual verification should include running the script against a known bad example and confirming the output is concise, markdown-focused, and free of Node stack traces.

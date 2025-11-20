# 12.0.0-rc.4

#### :boom: Breaking Change

- Fix some Intl bindings (`Intl.Collator.supportedLocalesOf`, `Intl.DateTimeFormat.supportedLocalesOf`, `Intl.ListFormat.supportedLocalesOf`, `Intl.NumberFormat.supportedLocalesOf`, `Intl.PluralRules.supportedLocalesOf`, `Intl.RelativeTimeFormat.supportedLocalesOf`, `Intl.Segmenter.supportedLocalesOf`) which return `array<string>` and not their corresponding main type `t`. Also remove `Intl.PluralRules.selectBigInt` and `Intl.PluralRules.selectRangeBigInt` which don't work in many JS runtimes. https://github.com/rescript-lang/rescript/pull/7995

#### :eyeglasses: Spec Compliance

#### :rocket: New Feature

#### :bug: Bug fix

- Fix fatal compiler error that occurred when an `%ffi` extension point contained invalid JavaScript https://github.com/rescript-lang/rescript/pull/7998

#### :memo: Documentation

#### :nail_care: Polish

- Dedicated error messages for old Reason array literal syntax (`[|` and `|]`), and for the old pipe (`|>`). Primarly intended to help LLMs that might try to use old code patterns. https://github.com/rescript-lang/rescript/pull/8010

#### :house: Internal

- Rename Core to Stdlib in tests/tests. https://github.com/rescript-lang/rescript/pull/8005
- CI: Build on `windows-2025` runners. https://github.com/rescript-lang/rescript/pull/8006
- Rewatch: upgrade Rust to 1.91.0. https://github.com/rescript-lang/rescript/pull/8007

# 12.0.0-rc.3

#### :bug: Bug fix

- Fix @directive on function level with async and multiple parameters. https://github.com/rescript-lang/rescript/pull/7977
- Fix fatal error for external with @as. https://github.com/rescript-lang/rescript/pull/7978

#### :nail_care: Polish

- Rewatch: plain output when not running in tty. https://github.com/rescript-lang/rescript/pull/7970
- Streamline rewatch help texts. https://github.com/rescript-lang/rescript/pull/7973
- Rewatch: Reduced build progress output from 7 steps to 3 for cleaner, less verbose logging. https://github.com/rescript-lang/rescript/pull/7971

#### :house: Internal

- Clean up usage of `Ast_uncurried` helpers. https://github.com/rescript-lang/rescript/pull/7987

# 12.0.0-rc.2

#### :boom: Breaking Change

- Replace binary operators with F#-style `~~~`, `^^^`, `&&&`, `|||`. https://github.com/rescript-lang/rescript/pull/7894

#### :bug: Bug fix

- Fix: use configured Jsx module for constraining component return type. https://github.com/rescript-lang/rescript/pull/7945
- Undeprecate `Js_OO` module since it is still used with the `@this` attribute. https://github.com/rescript-lang/rescript/pull/7955
- Fix crash when using bitwise not (`~~~`) on an incompatible type. https://github.com/rescript-lang/rescript/pull/7965

#### :house: Internal

- JSX PPX: use `React.component` instead of `React.componentLike` for externals. https://github.com/rescript-lang/rescript/pull/7952

# 12.0.0-rc.1

#### :nail_care: Polish

- Improve circular dependency errors, and make sure they end up in the compiler log so the editor tooling can surface them. https://github.com/rescript-lang/rescript/pull/7940
- JSX PPX: add Jsx.element return constraint. https://github.com/rescript-lang/rescript/pull/7939

#### :house: Internal

- Use AST nodes with locations for fn arguments in the typed tree. https://github.com/rescript-lang/rescript/pull/7873

# 12.0.0-beta.14

#### :boom: Breaking Change

- Removed `rescript legacy` subcommand in favor of separate `rescript-legacy` binary. https://github.com/rescript-lang/rescript/pull/7928
- Add comparison function for `Error` in `Result.equal` and `compare`. https://github.com/rescript-lang/rescript/pull/7933
- Rewatch: `"type": "dev"` and `dev-dependencies` will be compiled by default for local packages. The `--dev` flag no longer does anything. https://github.com/rescript-lang/rescript/pull/7934

#### :bug: Bug fix

- Prevent lockfile creation when project folder is missing. https://github.com/rescript-lang/rescript/pull/7927
- Fix parameter type / return type ambiguity error for unit case. https://github.com/rescript-lang/rescript/pull/7930

#### :nail_care: Polish

- ReScript cli: do not show build command options in the root help. https://github.com/rescript-lang/rescript/pull/7715
- Deprecate reanalyze `@raises` in favor of `@throws`. https://github.com/rescript-lang/rescript/pull/7932

#### :house: Internal

- CI: run macOS builds on macOS 15. https://github.com/rescript-lang/rescript/pull/7935

# 12.0.0-beta.13

#### :bug: Bug fix

- Fix result examples. https://github.com/rescript-lang/rescript/pull/7914
- Make inline record fields that overlap with a variant's tag a compile error. https://github.com/rescript-lang/rescript/pull/7875

#### :nail_care: Polish

- Keep track of compiler info during build. https://github.com/rescript-lang/rescript/pull/7889
- Improve option optimization for constants. https://github.com/rescript-lang/rescript/pull/7913
- Option optimization: do not create redundant local vars. https://github.com/rescript-lang/rescript/pull/7915
- Js output: remove superfluous newline after every `if`. https://github.com/rescript-lang/rescript/pull/7920
- Rewatch: Traverse upwards for package resolution in single context projects. https://github.com/rescript-lang/rescript/pull/7896
- Rewatch: Add `--warn-error` flag to `build`. https://github.com/rescript-lang/rescript/pull/7916

# 12.0.0-beta.12

#### :boom: Breaking Change

- Make experimental-features kebap-case in compiler config like the other fields. https://github.com/rescript-lang/rescript/pull/7891

#### :rocket: New Feature

- Add `littleEndian` feature for `DataView` to Stdlib. https://github.com/rescript-lang/rescript/pull/7881
- Add `mapOkAsync`, `mapErrorAsync`, `flatMapOkAsync` and `flatMapErrorAsync` for async `result`s to Stdlib. https://github.com/rescript-lang/rescript/pull/7906

#### :bug: Bug fix

- Include `-runtime-path` as bsc argument when generating `.mlmap` file. https://github.com/rescript-lang/rescript/pull/7888

#### :nail_care: Polish

- Add (dev-)dependencies to build schema. https://github.com/rescript-lang/rescript/pull/7892
- Dedicated error for dict literal spreads. https://github.com/rescript-lang/rescript/pull/7901
- Dedicated error message for when mixing up `:` and `=` in various positions. https://github.com/rescript-lang/rescript/pull/7900

# 12.0.0-beta.11

#### :boom: Breaking Change

- Have `String.charCodeAt` return `option<int>`; add `String.charCodeAtUnsafe`. https://github.com/rescript-lang/rescript/pull/7877
- Remove support of JSX children spread. https://github.com/rescript-lang/rescript/pull/7869

#### :rocket: New Feature

- Add `Array.filterMapWithIndex` to Stdlib. https://github.com/rescript-lang/rescript/pull/7876

#### :bug: Bug fix

- Fix code generation for emojis in polyvars and labels. https://github.com/rescript-lang/rescript/pull/7853
- Add `reset` to `experimental_features` to correctly reset playground. https://github.com/rescript-lang/rescript/pull/7868
- Fix crash with `@get` on external of type `unit => 'a`. https://github.com/rescript-lang/rescript/pull/7866
- Fix record type spreads in inline records. https://github.com/rescript-lang/rescript/pull/7859

#### :nail_care: Polish

- Reactivate optimization for length of array literals. https://github.com/rescript-lang/rescript/pull/7872
- `Float.isNaN`: use `Number.isNaN` instead of global `isNaN`. https://github.com/rescript-lang/rescript/pull/7874

#### :house: Internal

- Playground: Add config options for experimental features and jsx preserve mode. https://github.com/rescript-lang/rescript/pull/7865
- Clean up tests. https://github.com/rescript-lang/rescript/pull/7861 https://github.com/rescript-lang/rescript/pull/7871
- Add `-runtime-path` flag to `bsc` (and `bsb`), we are detecting the location of `@rescript/runtime` in `cli/rescript.js` based on runtime module resolution. https://github.com/rescript-lang/rescript/pull/7858

# 12.0.0-beta.10

#### :rocket: New Feature

- Support mapping more standard library types automatically to TS types via `gentype`, without requiring shims. https://github.com/rescript-lang/rescript/pull/7842

#### :bug: Bug fix

- Show `Stdlib.TypedArray` completions for typed arrays. https://github.com/rescript-lang/rescript/pull/7827
- Show `Stdlib.Null` and `Stdlib.Nullable` completions for `Stdlib.null<'a>` and `Stdlib.nullable<'a>` types, respectively. https://github.com/rescript-lang/rescript/pull/7826
- Fix generation of interfaces for module types containing multiple type constraints. https://github.com/rescript-lang/rescript/pull/7825
- JSX preserve mode: fix "make is not a valid component name". https://github.com/rescript-lang/rescript/pull/7831
- Rewatch: include parser arguments of experimental features. https://github.com/rescript-lang/rescript/pull/7836
- Stop mangling tagged templates and backquoted strings. https://github.com/rescript-lang/rescript/pull/7841
- JSX v4: fix arity mismatch for `@react.component` with `React.forwardRef`. https://github.com/rescript-lang/rescript/pull/7845

#### :nail_care: Polish

- Improve error message for trying to define a type inside a function. https://github.com/rescript-lang/rescript/pull/7843
- Refactor CLI to use spawn for better signal handling in watch mode. https://github.com/rescript-lang/rescript/pull/7844

- Add a `prepareRename` command the LSP can use for faster renames. https://github.com/rescript-lang/rescript/pull/7847

# 12.0.0-beta.9

#### :boom: Breaking Change

- Extract ReScript runtime files from main `rescript` package to separate `@rescript/runtime` package. https://github.com/rescript-lang/rescript/pull/7796
- Remove `@rescript/std` (in favor of `@rescript/runtime`). https://github.com/rescript-lang/rescript/pull/7811

#### :rocket: New Feature

- Add support for `ArrayBuffer` and typed arrays to `@unboxed`. https://github.com/rescript-lang/rescript/pull/7788
- Experimental: Add `let?` syntax for unwrapping and propagating errors/none as early returns for option/result types. https://github.com/rescript-lang/rescript/pull/7582
- Add support for shipping features as experimental, including configuring what experimental features are enabled in `rescript.json`. https://github.com/rescript-lang/rescript/pull/7582

#### :bug: Bug fix

- Fix JS regex literal parsing in character classes. https://github.com/rescript-lang/rescript/pull/7790
- Fix creating interface for functions with upper bounded polymorphic args. https://github.com/rescript-lang/rescript/pull/7786

#### :nail_care: Polish

- Make parser less strict around leading attributes. https://github.com/rescript-lang/rescript/pull/7787
- Dedicated error message for ternary type mismatch. https://github.com/rescript-lang/rescript/pull/7804
- Dedicated error message for passing a braced ident to something expected to be a record. https://github.com/rescript-lang/rescript/pull/7806
- Hint about partial application when missing required argument in function call. https://github.com/rescript-lang/rescript/pull/7807
- More autocomplete improvements involving modules and module types. https://github.com/rescript-lang/rescript/pull/7795
- Autocomplete `@react.componentWithProps` attribute. https://github.com/rescript-lang/rescript/pull/7812
- Add some missing iframe attributes to `domProps`. https://github.com/rescript-lang/rescript/pull/7813
- Polish error message for inline record escaping scope. https://github.com/rescript-lang/rescript/pull/7808
- Formatter: Change placement of closing `>` in JSX. https://github.com/rescript-lang/rescript/pull/7803

#### :house: Internal

- Build runtime with rewatch on Windows, too. https://github.com/rescript-lang/rescript/pull/7794

# 12.0.0-beta.8

Do not use, npm package broken.

# 12.0.0-beta.7

#### :rocket: New Feature

- Add markdown divider between module doc and module type in hover information. https://github.com/rescript-lang/rescript/pull/7775
- Show docstrings before type expansions on hover. https://github.com/rescript-lang/rescript/pull/7774
- Autocomplete (and improved hovers) for first-class module unpacks. https://github.com/rescript-lang/rescript/pull/7780

#### :bug: Bug fix

- Fix semantic highlighting for array spreads, array access and dict literals. https://github.com/rescript-lang/rescript/pull/7789
- Preserve `@as(...)` decorator on record fields when creating interface. https://github.com/rescript-lang/rescript/pull/7779
- Fix parse error with nested record types and attributes on the field name that has the nested record type. https://github.com/rescript-lang/rescript/pull/7781
- Fix ppx resolution with package inside monorepo. https://github.com/rescript-lang/rescript/pull/7776
- Fix 'Unbound module type' errors that occurred when trying to async import modules. https://github.com/rescript-lang/rescript/pull/7783

#### :nail_care: Polish

- Allow skipping the leading pipe in variant definition with a leading constructor with an attribute. https://github.com/rescript-lang/rescript/pull/7782
- Better error message (and recovery) when using a keyword as a record field name. https://github.com/rescript-lang/rescript/pull/7784

# 12.0.0-beta.6

#### :boom: Breaking Change

- `rescript format` no longer accepts `--all`. All (non-dev) files of the current rescript.json are now formatted by default. https://github.com/rescript-lang/rescript/pull/7752

#### :rocket: New Feature

- Add new Stdlib helpers: `String.capitalize`, `String.isEmpty`, `Dict.size`, `Dict.isEmpty`, `Array.isEmpty`, `Map.isEmpty`, `Set.isEmpty`. https://github.com/rescript-lang/rescript/pull/7516

#### :bug: Bug fix

- Fix issue with ast conversion (for ppx use) on functions with attributes on first argument. https://github.com/rescript-lang/rescript/pull/7761

#### :nail_care: Polish

- `rescript format` now has a `--dev` flag that works similar to `rescript clean`. https://github.com/rescript-lang/rescript/pull/7752
- `rescript clean` now will clean an individual project (see [#7707](https://github.com/rescript-lang/rescript/issues/7707)). https://github.com/rescript-lang/rescript/pull/7752
- `rescript clean` will log multiple `in-source` extensions if present. https://github.com/rescript-lang/rescript/pull/7769

#### :house: Internal

- AST: Use jsx_tag_name instead of Longindent.t to store jsx tag name. https://github.com/rescript-lang/rescript/pull/7760

# 12.0.0-beta.5

#### :bug: Bug fix

- Fix option optimisation that resulted in incorrect JS output. https://github.com/rescript-lang/rescript/pull/7766
- Fix formatting of nested records in `.resi` files. https://github.com/rescript-lang/rescript/pull/7741
- Don't format and don't check formatting of dependencies. https://github.com/rescript-lang/rescript/pull/7748
- Fix `rescript-editor-analysis semanticTokens` returning invalid JSON in certain cases. https://github.com/rescript-lang/rescript/pull/7750

#### :memo: Documentation

- Update jsx schema configuration. https://github.com/rescript-lang/rescript/pull/7755

#### :nail_care: Polish

- Read package name from rescript.json if package.json is absent. https://github.com/rescript-lang/rescript/pull/7746

#### :house: Internal

- Add token viewer to `res_parser`. https://github.com/rescript-lang/rescript/pull/7751
- Refactor jsx mode in Scanner. https://github.com/rescript-lang/rescript/pull/7751

# 12.0.0-beta.4

#### :bug: Bug fix

- Fix error message that falsely suggested using coercion when it wouldn't work. https://github.com/rescript-lang/rescript/pull/7721
- Fix hang in `rescript-editor-analysis.exe codeAction` that sometimes prevented ReScript files from being saved in VS Code. https://github.com/rescript-lang/rescript/pull/7731
- Fix formatter removing () from functor type. https://github.com/rescript-lang/rescript/pull/7735
- Rewatch: don't compile dev-dependencies of non local dependencies with `--dev`. https://github.com/rescript-lang/rescript/pull/7736

#### :nail_care: Polish

- Apply heuristic to suggest using JSX fragments where we guess that might be what the user wanted. https://github.com/rescript-lang/rescript/pull/7714
- Show deprecation warnings for `bs-dependencies` etc. for local dependencies only. https://github.com/rescript-lang/rescript/pull/7724
- Add check for minimum required node version. https://github.com/rescript-lang/rescript/pull/7723
- Use more optional args in stdlib and deprecate some functions. https://github.com/rescript-lang/rescript/pull/7730
- Improve error message for when trying to do dot access on an option/array. https://github.com/rescript-lang/rescript/pull/7732

# 12.0.0-beta.3

#### :boom: Breaking Change

- `Result.getOrThrow` now throws a JS error instead of a `Not_found` ReScript exception. https://github.com/rescript-lang/rescript/pull/7630
- Remove `rescript dump` command. `bsc` can be used directly to dump the contents of a `.cmi` file instead if needed. https://github.com/rescript-lang/rescript/pull/7710

#### :rocket: New Feature

- Add optional `message` argument to `Result.getOrThrow` and improve default error message. https://github.com/rescript-lang/rescript/pull/7630
- Add `RegExp.escape` binding. https://github.com/rescript-lang/rescript/pull/7695

#### :bug: Bug fix

- Fix `--create-sourcedirs` generation with for a single project. https://github.com/rescript-lang/rescript/pull/7671
- Fix rewatch not recompiling on changes on Windows. https://github.com/rescript-lang/rescript/pull/7690
- Fix locations of regex literals. https://github.com/rescript-lang/rescript/pull/7683
- Fix async React component compilation. https://github.com/rescript-lang/rescript/pull/7704
- Fix `@this` with `async` keyword. https://github.com/rescript-lang/rescript/pull/7702

#### :nail_care: Polish

- Configuration fields `bs-dependencies`, `bs-dev-dependencies` and `bsc-flags` are now deprecated in favor of `dependencies`, `dev-dependencies` and `compiler-flags`. https://github.com/rescript-lang/rescript/pull/7658
- Better error message if platform binaries package is not found. https://github.com/rescript-lang/rescript/pull/7698
- Hint in error for string constants matching expected variant/polyvariant constructor. https://github.com/rescript-lang/rescript/pull/7711
- Polish arity mismatch error message a bit. https://github.com/rescript-lang/rescript/pull/7709
- Suggest related functions with the expected arity in errors when it makes sense. https://github.com/rescript-lang/rescript/pull/7712
- Improve error when a constructor expects an inline record. https://github.com/rescript-lang/rescript/pull/7713
- Remove `@meth` attribute. https://github.com/rescript-lang/rescript/pull/7684

#### :house: Internal

- Add rust linting to CI with `clippy`. https://github.com/rescript-lang/rescript/pull/7675
- AST: use `Typ.arrows` for creation, after the refactoring of arrow types. https://github.com/rescript-lang/rescript/pull/7662
- Don't skip Stdlib docstring tests. https://github.com/rescript-lang/rescript/pull/7694
- Remove all leftovers of `pinned-dependencies` handling. https://github.com/rescript-lang/rescript/pull/7686
- Add `rust-version` field to Rewatch's `Cargo.toml`. https://github.com/rescript-lang/rescript/pull/7701
- Rewatch: remove support for .ml(i) and .re(i). https://github.com/rescript-lang/rescript/pull/7727

# 12.0.0-beta.2

#### :boom: Breaking Change

- Rust implementation of the `rescript format` command. Command line options changed from `-all`, `-check` and `-stdin` to `--all`, `--check` and `--stdin` compared to the legacy implementation. https://github.com/rescript-lang/rescript/pull/7603

#### :rocket: New Feature

- Add experimental command to `rescript-tools` for extracting all ReScript code blocks from markdown, either a md-file directly, or inside of docstrings in ReScript code. https://github.com/rescript-lang/rescript/pull/7623

#### :bug: Bug fix

- Fix `typeof` parens on functions. https://github.com/rescript-lang/rescript/pull/7643
- Rewatch: Add `--dev` flag to clean command. https://github.com/rescript-lang/rescript/pull/7622
- Rewatch: Use root package suffix in clean log messages. https://github.com/rescript-lang/rescript/pull/7648
- Fix inside comment printing for empty dict. https://github.com/rescript-lang/rescript/pull/7654
- Fix I/O error message when trying to extract extra info from non-existing file. https://github.com/rescript-lang/rescript/pull/7656
- Fix fatal error when JSX expression used without configuring JSX in `rescript.json`. https://github.com/rescript-lang/rescript/pull/7656
- Rewatch: Only allow access to `"bs-dev-dependencies"` from `"type": "dev"` source files. https://github.com/rescript-lang/rescript/pull/7650
- Fix comment attached to array element. https://github.com/rescript-lang/rescript/pull/7672
- Rewatch: fix compilation of files starting with a lowercase letter. https://github.com/rescript-lang/rescript/pull/7700

#### :nail_care: Polish

- Add missing backtick and spaces to `Belt.Map.map` doc comment. https://github.com/rescript-lang/rescript/pull/7632
- AST: store the attributes directly on function arguments. https://github.com/rescript-lang/rescript/pull/7660

#### :house: Internal

- Remove internal/unused `-bs-v` flag. https://github.com/rescript-lang/rescript/pull/7627
- Remove unused `-bs-D` and `-bs-list-conditionals` flags. https://github.com/rescript-lang/rescript/pull/7631
- Remove obsolete jsx options. https://github.com/rescript-lang/rescript/pull/7633
- Remove obsolete option `-bs-unsafe-empty-array`. https://github.com/rescript-lang/rescript/pull/7635
- Clean up `config.ml`. https://github.com/rescript-lang/rescript/pull/7636
- Rewatch: simplify getting bsc path. https://github.com/rescript-lang/rescript/pull/7634
- Rewatch: only get `"type": "dev"` source files for local packages. https://github.com/rescript-lang/rescript/pull/7646
- Rewatch: add support for `rescript -w` for compatibility. https://github.com/rescript-lang/rescript/pull/7649
- Fix dev container. https://github.com/rescript-lang/rescript/pull/7700

# 12.0.0-beta.1

#### :rocket: New Feature

- Add experimental command to `rescript-tools` for formatting all ReScript code blocks in markdown. Either in a markdown file directly, or inside of docstrings in ReScript code. https://github.com/rescript-lang/rescript/pull/7598
- Add `String.getSymbolUnsafe` back to Stdlib. https://github.com/rescript-lang/rescript/pull/7626

#### :nail_care: Polish

- Add a warning if the name in package.json does not match the name in rescript.json. https://github.com/rescript-lang/rescript/pull/7604

#### :house: Internal

- Remove uncurried handling from rewatch. https://github.com/rescript-lang/rescript/pull/7625

# 12.0.0-alpha.15

#### :boom: Breaking Change

- New `rewatch` based build system. https://github.com/rescript-lang/rescript/pull/7551 https://github.com/rescript-lang/rescript/pull/7593
  - The new `rewatch` based build system is now the default and is exposed through the `rescript` command. The `rewatch` command has been removed.
  - The previous Ninja-based build system is now available via the `rescript legacy` subcommand.
  - Argument `--compiler-args` is now a subcommand `compiler-args`.
- Remove `String.getSymbol`, `String.getSymbolUnsafe`, `String.setSymbol` from standard library. https://github.com/rescript-lang/rescript/pull/7571

#### :bug: Bug fix

- Ignore inferred arity in functions inside `%raw` functions, leaving to `%ffi` the responsibility to check the arity since it gives an error in case of mismatch. https://github.com/rescript-lang/rescript/pull/7542
- Pass the rewatch exit code through in wrapper script. https://github.com/rescript-lang/rescript/pull/7565
- Prop punning when types don't match results in `I/O error: _none_: No such file or directory`. https://github.com/rescript-lang/rescript/pull/7533
- Pass location to children prop in jsx ppx. https://github.com/rescript-lang/rescript/pull/7540
- Fix crash when `-bs-g` is used with untagged variants. https://github.com/rescript-lang/rescript/pull/7575
- Fix issue with preserve mode where `jsx` is declared as an external without a `@module` attribute. https://github.com/rescript-lang/rescript/pull/7591
- Rewatch: don't add deps to modules that are in packages that are not a dependency. https://github.com/rescript-lang/rescript/pull/7612
- Rewatch: fix non-unicode stderr. https://github.com/rescript-lang/rescript/pull/7613
- Fix rewatch considering warning configs of non-local dependencies. https://github.com/rescript-lang/rescript/pull/7614
- Rewatch: fix panic if package.json name different from module name. https://github.com/rescript-lang/rescript/pull/7616
- Fix finding the standard library for pnpm. https://github.com/rescript-lang/rescript/pull/7615

#### :nail_care: Polish

- Better error message for when trying to await something that is not a promise. https://github.com/rescript-lang/rescript/pull/7561
- Better error messages for object field missing and object field type mismatches. https://github.com/rescript-lang/rescript/pull/7580
- Better error messages for when polymorphic variants does not match for various reasons. https://github.com/rescript-lang/rescript/pull/7596
- Improved completions for inline records. https://github.com/rescript-lang/rescript/pull/7601
- Add `OrThrow` aliases for `Belt` functions ending with `Exn`. https://github.com/rescript-lang/rescript/pull/7581, https://github.com/rescript-lang/rescript/pull/7590 The following aliases have been added:
  - `Belt.Array.getOrThrow`
  - `Belt.Array.setOrThrow`
  - `Belt.Map.getOrThrow`
  - `Belt.MutableMap.getOrThrow`
  - `Belt.Set.getOrThrow`
  - `Belt.MutableSet.getOrThrow`
  - `Belt.List.getOrThrow`
  - `Belt.List.tailOrThrow`
  - `Belt.List.headOrThrow`
  - `Belt.MutableQueue.peekOrThrow`
  - `Belt.MutableQueue.popOrThrow`
  - `Belt.Option.getOrThrow`
  - `Belt.Result.getOrThrow`

#### :house: Internal

- Remove `@return(undefined_to_opt)` and `%undefined_to_opt` primitive. https://github.com/rescript-lang/rescript/pull/7462
- Migrate rewatch to Rust 2024 edition. https://github.com/rescript-lang/rescript/pull/7602

# 12.0.0-alpha.14

#### :boom: Breaking Change

- `Iterator.forEach` now emits `Iterator.prototype.forEach` call. https://github.com/rescript-lang/rescript/pull/7506
- Rename functions ending with `Exn` to end with `OrThrow`. The old `Exn` functions are now deprecated:
  - `Bool.fromStringExn` → `Bool.fromStringOrThrow`
  - `BigInt.fromStringExn` → `BigInt.fromStringOrThrow`
  - `JSON.parseExn` → `JSON.parseOrThrow`
  - Changed `BigInt.fromFloat` to return an option rather than throwing an error.
  - Added `BigInt.fromFloatOrThrow`
  - `Option.getExn` → `Option.getOrThrow`
  - `Null.getExn` → `Null.getOrThrow`
  - `Nullable.getExn` → `Nullable.getOrThrow`
  - `Result.getExn` → `Result.getOrThrow`
  - `List.getExn` → `List.getOrThrow`
  - `List.tailExn` → `List.tailOrThrow`
  - `List.headExn` → `List.headOrThrow`
  - Old functions remain available but are marked as deprecated with guidance to use the new `OrThrow` variants.
  - https://github.com/rescript-lang/rescript/pull/7518, https://github.com/rescript-lang/rescript/pull/7554

#### :rocket: New Feature

- Add `RegExp.flags`. https://github.com/rescript-lang/rescript/pull/7461
- Add `Array.findLast`, `Array.findLastWithIndex`, `Array.findLastIndex`, `Array.findLastIndexWithIndex` and `Array.findLastIndexOpt`. https://github.com/rescript-lang/rescript/pull/7503
- Add `options` argument to `Console.dir`. https://github.com/rescript-lang/rescript/pull/7504
- Show variant constructor's inline record types on hover. https://github.com/rescript-lang/rescript/pull/7519
- Add additional `Iterator.prototype` bindings to `runtime/Stdlib_Iterator.res`. https://github.com/rescript-lang/rescript/pull/7506

#### :bug: Bug fix

- `rescript-tools doc` no longer includes shadowed bindings in its output. https://github.com/rescript-lang/rescript/pull/7497
- Treat `throw` like `raise` in analysis. https://github.com/rescript-lang/rescript/pull/7521
- Fix `index out of bounds` exception thrown in rare cases by `rescript-editor-analysis.exe codeAction` command. https://github.com/rescript-lang/rescript/pull/7523
- Don't produce duplicate type definitions for recursive types on hover. https://github.com/rescript-lang/rescript/pull/7524
- Prop punning when types don't match results in `I/O error: _none_: No such file or directory`. https://github.com/rescript-lang/rescript/pull/7533
- Fix partial application with user-defined function types. https://github.com/rescript-lang/rescript/pull/7548
- Fix doc comment before variant throwing syntax error. https://github.com/rescript-lang/rescript/pull/7535
- Fix apparent non-determinism in generated code for pattern matching. https://github.com/rescript-lang/rescript/pull/7557

#### :nail_care: Polish

- Suggest awaiting promise before using it when types mismatch. https://github.com/rescript-lang/rescript/pull/7498
- Complete from `RegExp` stdlib module for regexes. https://github.com/rescript-lang/rescript/pull/7425
- Allow oneliner formatting when including module with single type alias. https://github.com/rescript-lang/rescript/pull/7502
- Improve error messages for JSX type mismatches, passing objects where record is expected, passing array literal where tuple is expected, and more. https://github.com/rescript-lang/rescript/pull/7500
- Show in error messages when coercion can be used to fix a type mismatch. https://github.com/rescript-lang/rescript/pull/7505
- Remove deprecated pipe last (`|>`) syntax. https://github.com/rescript-lang/rescript/pull/7512
- Improve error message for pipe (`->`) syntax. https://github.com/rescript-lang/rescript/pull/7520
- Improve a few error messages around various subtyping issues. https://github.com/rescript-lang/rescript/pull/7404
- In module declarations, accept the invalid syntax `M = {...}` and format it to `M : {...}`. https://github.com/rescript-lang/rescript/pull/7527
- Improve doc comment formatting to match the style of multiline comments. https://github.com/rescript-lang/rescript/pull/7529
- Improve error messages around type mismatches for try/catch, if, for, while, and optional record fields + optional function arguments. https://github.com/rescript-lang/rescript/pull/7522
- Sync reanalyze with the new APIs around exception. https://github.com/rescript-lang/rescript/pull/7536
- Improve array pattern spread error message. https://github.com/rescript-lang/rescript/pull/7549
- Sync API docs with rescript-lang.org on release. https://github.com/rescript-lang/rescript/pull/7555

#### :house: Internal

- Refactor the ast for record expressions and patterns. https://github.com/rescript-lang/rescript/pull/7528
- Editor: add completions from included modules. https://github.com/rescript-lang/rescript/pull/7515
- Add `-editor-mode` arg to `bsc` for doing special optimizations only relevant to the editor tooling. https://github.com/rescript-lang/rescript/pull/7541

# 12.0.0-alpha.13

#### :boom: Breaking Change

- Rename `JsError` to `JsExn` and error modules cleanup. https://github.com/rescript-lang/rescript/pull/7408
- Make `BigInt.fromFloat` return an option rather than throwing an error in case it's passed a value with a decimal value. https://github.com/rescript-lang/rescript/pull/7419

#### :rocket: New Feature

- Add shift (`<<`, `>>`, `>>>`) operators for `int` and `bigint`. https://github.com/rescript-lang/rescript/pull/7183
- Add bitwise AND (`&`) operator for `int` and `bigint`. https://github.com/rescript-lang/rescript/pull/7415
- Add bitwise NOT (`~`) operator for `int` and `bigint`. https://github.com/rescript-lang/rescript/pull/7418
- Significantly reduced the download size by splitting binaries into optional platform-specific dependencies (e.g, `@rescript/linux-x64`). https://github.com/rescript-lang/rescript/pull/7395
- JSX: do not error on ref as prop anymore (which is allowed in React 19). https://github.com/rescript-lang/rescript/pull/7420
- Add new attribute `@notUndefined` for abstract types to prevent unnecessary wrapping with `Primitive_option.some` in JS output. https://github.com/rescript-lang/rescript/pull/7458
- Preserve JSX: enable by adding `"-bs-jsx-preserve"` to `"bsc-flags"` (does require `"jsx": { "version": 4 }`). https://github.com/rescript-lang/rescript/pull/7387
- Add slot prop to `JsxDOM.domProps`. https://github.com/rescript-lang/rescript/pull/7487

#### :bug: Bug fix

- Fix broken `bstracing` CLI location. https://github.com/rescript-lang/rescript/pull/7398
- Fix field flattening optimization to avoid creating unnecessary copies of allocating constants. https://github.com/rescript-lang/rescript-compiler/pull/7421
- Fix leading comments removed when braces inside JSX contains `let` assignment. https://github.com/rescript-lang/rescript/pull/7424
- Fix JSON escaping in code editor analysis: JSON was not always escaped properly, which prevented code actions from being available in certain situations. https://github.com/rescript-lang/rescript/pull/7435
- Fix regression in pattern matching for optional fields containing variants. https://github.com/rescript-lang/rescript/pull/7440
- Fix missing checks for duplicate literals in variants with payloads. https://github.com/rescript-lang/rescript/pull/7441
- Fix printer removing private for empty record. https://github.com/rescript-lang/rescript/pull/7448
- Fix: handle dynamic imports with module aliases. https://github.com/rescript-lang/rescript/pull/7452
- Fix missing unescaping when accessing prop with exotic name. https://github.com/rescript-lang/rescript/pull/7469
- Fix syntax error with mutable nested record. https://github.com/rescript-lang/rescript/pull/7470

#### :house: Internal

- AST: Add bar location to `case`. https://github.com/rescript-lang/rescript/pull/7407
- Clean up lazy from ASTs and back-end. https://github.com/rescript-lang/rescript/pull/7474
- Compile runtime with rewatch and add rewatch tests to the compiler repo. https://github.com/rescript-lang/rescript/pull/7422

#### :nail_care: Polish

- In type errors, recommend stdlib over Belt functions for converting between float/int/string. https://github.com/rescript-lang/rescript/pull/7453
- Remove unused type `Jsx.ref`. https://github.com/rescript-lang/rescript/pull/7459
- Add `@notUndefined` attribute to all relevant abstract types in `Stdlib`. https://github.com/rescript-lang/rescript/pull/7464
- Editor: Add pipe completions from current module. https://github.com/rescript-lang/rescript/pull/7471

# 12.0.0-alpha.12

#### :bug: Bug fix

- Fix node.js `ExperimentalWarning`. https://github.com/rescript-lang/rescript/pull/7379
- Fix issue with gentype and stdlib json. https://github.com/rescript-lang/rescript/pull/7378
- Fix type of `RegExp.Result.matches`. https://github.com/rescript-lang/rescript/pull/7393
- Add optional `flags` argument to `RegExp.fromString` and deprecate `RegExp.fromStringWithFlags`. https://github.com/rescript-lang/rescript/pull/7393

#### :house: Internal

- Better representation of JSX in AST. https://github.com/rescript-lang/rescript/pull/7286
- Clean up default warnings. https://github.com/rescript-lang/rescript/pull/7413

#### :nail_care: Polish

- Improve error message for missing value when the identifier is also the name of a module in scope. https://github.com/rescript-lang/rescript/pull/7384
- Upgrade Flow parser to 0.267.0. https://github.com/rescript-lang/rescript/pull/7390
- Move `Lazy` module to Stdlib. https://github.com/rescript-lang/rescript/pull/7399

# 12.0.0-alpha.11

#### :bug: Bug fix

- Fix `Error.fromException`. https://github.com/rescript-lang/rescript/pull/7364
- Fix signature of `throw`. https://github.com/rescript-lang/rescript/pull/7365
- Fix formatter adds superfluous parens in pipe chain. https://github.com/rescript-lang/rescript/pull/7370

#### :house: Internal

- Remove `Stdlib_Char` module for now. https://github.com/rescript-lang/rescript/pull/7367
- Convert internal JavaScript codebase into ESM, ReScript package itself is now ESM (`"type": "module"`). https://github.com/rescript-lang/rescript/pull/6899
- Add built-in support for the JavaScript `in` operator. https://github.com/rescript-lang/rescript/pull/7342
- AST cleanup: add `Pexp_await` ast node instead of `res.await` attribute. (The attribute is still used for await on modules currently). https://github.com/rescript-lang/rescript/pull/7368

#### :nail_care: Polish

- More deprecations in `Pervasives`; add `Stdlib.Pair` and `Stdlib.Int.Ref`. https://github.com/rescript-lang/rescript/pull/7371

# 12.0.0-alpha.10

#### :rocket: New Feature

- Add `Dict.has` and double `Dict.forEachWithKey`/`Dict.mapValues` performance. https://github.com/rescript-lang/rescript/pull/7316
- Add popover attributes to `JsxDOM.domProps`. https://github.com/rescript-lang/rescript/pull/7317
- Add `Array.removeInPlace` helper based on `splice`. https://github.com/rescript-lang/rescript/pull/7321
- Add `inert` attribute to `JsxDOM.domProps`. https://github.com/rescript-lang/rescript/pull/7326
- Make reanalyze exception tracking work with the new stdlib. https://github.com/rescript-lang/rescript/pull/7328
- Fix `Pervasive.max` using boolean comparison for floats. https://github.com/rescript-lang/rescript/pull/7333
- Experimental: Support nested/inline record types - records defined inside of other records, without needing explicit separate type definitions. https://github.com/rescript-lang/rescript/pull/7241
- Add unified exponentiation (`**`) operator for numeric types using ES7 `**`. https://github.com/rescript-lang/rescript-compiler/pull/7153
- Rename `raise` to `throw` to align with JavaScript vocabulary. `raise` has been deprecated. https://github.com/rescript-lang/rescript/pull/7346
- Add unified bitwise (`^`) operator. https://github.com/rescript-lang/rescript/pull/7216
- Stdlib: rename binary operations to match JavaScript terms. https://github.com/rescript-lang/rescript/pull/7353

#### :boom: Breaking Change

- Replace `~date` with `~day` in `Date.make`. https://github.com/rescript-lang/rescript/pull/7324
- Remove `-bs-jsx-mode`. https://github.com/rescript-lang/rescript/pull/7327
- Drop Node.js version <20 support, as it is reaching End-of-Life. https://github.com/rescript-lang/rescript-compiler/pull/7354
- Treat `int` multiplication as a normal int32 operation instead of using `Math.imul`. https://github.com/rescript-lang/rescript/pull/7358

#### :house: Internal

- Clean up legacy tags handling. https://github.com/rescript-lang/rescript/pull/7309
- Use Yarn (Berry) workspaces for internal tooling. https://github.com/rescript-lang/rescript/pull/7309

#### :nail_care: Polish

- Deprecate `JSON.Classify.classify`. https://github.com/rescript-lang/rescript/pull/7315
- Hide stdlib modules in output. https://github.com/rescript-lang/rescript/pull/7305
- Deprecate unsafe host-specific bindings from stdlib. https://github.com/rescript-lang/rescript/pull/7334
- Make unsafe function names consistent in `Stdlib.String`. https://github.com/rescript-lang/rescript/pull/7337
- `rescript` package does not trigger `postinstall` script anymore. https://github.com/rescript-lang/rescript/pull/7350
- Add Stdlib `Bool` and `Char` modules and improve Pervasives deprecation messages. https://github.com/rescript-lang/rescript/pull/7361

#### :bug: Bug fix

- Fix recursive untagged variant type checking by delaying well-formedness checks until environment construction completes. https://github.com/rescript-lang/rescript/pull/7320
- Fix incorrect expansion of polymorphic return types in uncurried function applications. https://github.com/rescript-lang/rescript/pull/7338

# 12.0.0-alpha.9

#### :boom: Breaking Change

- Clean list API. https://github.com/rescript-lang/rescript/pull/7290

#### :nail_care: Polish

- Allow single newline in JSX. https://github.com/rescript-lang/rescript/pull/7269
- Editor: Always complete from Core first. Use actual native regex syntax in code snippets for regexps. https://github.com/rescript-lang/rescript/pull/7295
- Add `type t` to Stdlib modules. https://github.com/rescript-lang/rescript/pull/7302
- Gentype: handle null/nullable/undefined from Stdlib. https://github.com/rescript-lang/rescript/pull/7132

#### :bug: Bug fix

- Fix async context checking for module await. https://github.com/rescript-lang/rescript/pull/7271
- Fix `%external` extension. https://github.com/rescript-lang/rescript/pull/7272
- Fix issue with type environment for unified ops. https://github.com/rescript-lang/rescript/pull/7277
- Fix completion for application with tagged template. https://github.com/rescript-lang/rescript/pull/7278
- Fix error message for arity in the presence of optional arguments. https://github.com/rescript-lang/rescript/pull/7284
- Fix issue in functors with more than one argument (which are curried): emit nested function always. https://github.com/rescript-lang/rescript/pull/7273
- Fix dot completion issue with React primitives. https://github.com/rescript-lang/rescript/pull/7292
- Stdlib namespace for Core modules (fixes name clashes with user modules). https://github.com/rescript-lang/rescript/pull/7285
- Fix runtime type check for Object in untagged variants when one variant case is `null`. https://github.com/rescript-lang/rescript/pull/7303
- Fix files that were being truncated when sent to the CDN over FTP. https://github.com/rescript-lang/rescript/pull/7306
- Fix better editor completion for applications. https://github.com/rescript-lang/rescript/pull/7291
- Fix `@react.componentWithProps` no longer works with `@directive("'use memo'")`. https://github.com/rescript-lang/rescript/pull/7300

#### :house: Internal

- Remove `ignore` in `res_scanner.ml`. https://github.com/rescript-lang/rescript/pull/7280
- Use the new stdlib modules in the analysis tests. https://github.com/rescript-lang/rescript/pull/7295
- Build with OCaml 5.3.0. https://github.com/rescript-lang/rescript/pull/7294
- Simplify `JSON.Decode` implementation. https://github.com/rescript-lang/rescript/pull/7304

# 12.0.0-alpha.8

#### :bug: Bug fix

- Editor: Fix issue where pipe completions would not trigger with generic type arguments. https://github.com/rescript-lang/rescript/pull/7231
- Fix leftover `assert false` in code for `null != undefined`. https://github.com/rescript-lang/rescript/pull/7232
- Editor: Fix issue where completions would not show up inside of object bodies. https://github.com/rescript-lang/rescript/pull/7230
- Fix issue with pattern matching empty list which interferes with boolean optimisations. https://github.com/rescript-lang/rescript/pull/7237
- Fix Cannot combine `@react.component` and `@directive`. https://github.com/rescript-lang/rescript/pull/7260
- Fix issue where attributes on an application were not preserved by the AST conversion for ppx. https://github.com/rescript-lang/rescript/pull/7262

#### :house: Internal

- AST cleanup: Prepare for ast async cleanup: Refactor code for `@res.async` payload handling and clean up handling of type and term parameters, so that now each `=>` in a function definition corresponds to a function. https://github.com/rescript-lang/rescript/pull/7223
- AST: always put type parameters first in function definitions. https://github.com/rescript-lang/rescript/pull/7233
- AST cleanup: Remove `@res.async` attribute from the internal representation, and add a flag to untyped and typed ASTs instead. https://github.com/rescript-lang/rescript/pull/7234
- AST cleanup: Remove unused `expression_desc.Pexp_new`, `expression_desc.Pexp_setinstvar`, `expression_desc.Pexp_override`, `expression_desc.Pexp_poly`, `exp_extra.Texp_poly`, `expression_desc.Texp_new`, `expression_desc.Texp_setinstvar`, `expression_desc.Texp_override` & `expression_desc.Texp_instvar` from AST. https://github.com/rescript-lang/rescript/pull/7239
- AST cleanup: Remove `@res.partial` attribute from the internal representation, and add a flag to untyped and typed ASTs instead. https://github.com/rescript-lang/rescript/pull/7238 https://github.com/rescript-lang/rescript/pull/7240
- AST cleanup: Remove unused `structure_item_desc.Pstr_class`, `signature_item_desc.Psig_class`, `structure_item_desc.Pstr_class_type`, `signature_item_desc.Psig_class_type`, `structure_item_desc.Tstr_class`, `structure_item_desc.Tstr_class_type`, `signature_item_desc.Tsig_class`, `signature_item_desc.Tsig_class_type` from AST. https://github.com/rescript-lang/rescript/pull/7242
- AST cleanup: remove `|.` and rename `|.` to `->` in the internal representation for the pipe operator. https://github.com/rescript-lang/rescript/pull/7244
- AST cleanup: represent concatenation (`++`) and (dis)equality operators (`==`, `===`, `!=`, `!==`) just like in the syntax. https://github.com/rescript-lang/rescript/pull/7248
- AST cleanup: use inline record for `Ptyp_arrow`. https://github.com/rescript-lang/rescript/pull/7250
- Playground: Bundle stdlib runtime so that the playground can execute functions from Core/Belt/Js. https://github.com/rescript-lang/rescript/pull/7255
- AST cleanup: Remove `res.namedArgLoc` attribute and store the location information directly into the label. https://github.com/rescript-lang/rescript/pull/7247

#### :nail_care: Polish

- Rewatch 1.0.10. https://github.com/rescript-lang/rescript/pull/7259

# 12.0.0-alpha.7

#### :bug: Bug fix

- Editor: Fix issue where completions would stop working in some scenarios with inline records. https://github.com/rescript-lang/rescript/pull/7227

#### :nail_care: Polish

- Add all standard CSS properties to `JsxDOMStyle`. https://github.com/rescript-lang/rescript/pull/7205

#### :house: Internal

- AST cleanup: use inline record for Pexp_fun. https://github.com/rescript-lang/rescript/pull/7213
- Add support for "dot completion everywhere" (ported from https://github.com/rescript-lang/rescript-vscode/pull/1054). https://github.com/rescript-lang/rescript/pull/7226
- Add assertions to stdlib docstring examples. Extract examples into Mocha tests, compile and run the tests in CI. https://github.com/rescript-lang/rescript/pull/7219

# 12.0.0-alpha.6

#### :rocket: New Feature

- Add `Option.all` & `Result.all` helpers. https://github.com/rescript-lang/rescript/pull/7181
- Add `@react.componentWithProps` for React component functions taking a props record instead of labeled arguments. https://github.com/rescript-lang/rescript/pull/7203

#### :bug: Bug fix

- Fix exponential notation syntax. https://github.com/rescript-lang/rescript/pull/7174
- Fix bug where a ref assignment is moved ouside a conditional. https://github.com/rescript-lang/rescript/pull/7176
- Fix nullable to opt conversion. https://github.com/rescript-lang/rescript/pull/7193
- Raise error when defining external React components with `@react.componentWithProps`. https://github.com/rescript-lang/rescript/pull/7217
- Fix formatter handling of wildcard in pattern matching records with no fields specified. https://github.com/rescript-lang/rescript/pull/7224

#### :house: Internal

- Use latest compiler for tests. https://github.com/rescript-lang/rescript/pull/7186
- Added infra to modernise AST: theres' Parsetree, Parsetree0 (legacy), and conversion functions to keep compatibility with PPX. https://github.com/rescript-lang/rescript/pull/7185
- AST cleanup: remove exp object and exp unreachable. https://github.com/rescript-lang/rescript/pull/7189
- AST cleanup: explicit representation for optional record fields in types. https://github.com/rescript-lang/rescript/pull/7190 https://github.com/rescript-lang/rescript/pull/7191
- AST cleanup: first-class expression and patterns for records with optional fields. https://github.com/rescript-lang/rescript/pull/7192
- AST cleanup: Represent the arity of uncurried function definitions directly in the AST. https://github.com/rescript-lang/rescript/pull/7197
- AST cleanup: Remove Pexp_function from the AST. https://github.com/rescript-lang/rescript/pull/7198
- Remove unused code from Location and Rescript_cpp modules. https://github.com/rescript-lang/rescript/pull/7150
- Build with OCaml 5.2.1. https://github.com/rescript-lang/rescript-compiler/pull/7201
- AST cleanup: Remove `Function$` entirely for function definitions. https://github.com/rescript-lang/rescript/pull/7200
- AST cleanup: store arity in function type. https://github.com/rescript-lang/rescript/pull/7195
- AST cleanup: remove explicit uses of `function$` in preparation for removing the type entirely. https://github.com/rescript-lang/rescript/pull/7206
- AST cleanup: remove `function$` entirely. https://github.com/rescript-lang/rescript/pull/7208

# 12.0.0-alpha.5

#### :rocket: New Feature

- Introduce "Unified operators" for arithmetic operators (`+`, `-`, `*`, `/`, `mod`). https://github.com/rescript-lang/rescript-compiler/pull/7057
- Add remainder (`%`, aka modulus) operator. https://github.com/rescript-lang/rescript-compiler/pull/7152

#### :bug: Bug fix

- Fix and clean up boolean and/or optimizations. https://github.com/rescript-lang/rescript-compiler/pull/7134 https://github.com/rescript-lang/rescript-compiler/pull/7151
- Fix identifiers with name `arguments` and `eval` to be mangled. https://github.com/rescript-lang/rescript/pull/7163

#### :nail_care: Polish

- Improve code generation for pattern matching of untagged variants. https://github.com/rescript-lang/rescript-compiler/pull/7128
- Improve negation handling in combination with and/or to simplify generated code (especially coming out of pattern matching). https://github.com/rescript-lang/rescript-compiler/pull/7138
- Optimize JavaScript code generation by using `x == null` checks and improving type-based optimizations for string/number literals. https://github.com/rescript-lang/rescript-compiler/pull/7141
- Improve pattern matching on optional fields. https://github.com/rescript-lang/rescript-compiler/pull/7143 https://github.com/rescript-lang/rescript-compiler/pull/7144
- Optimize compilation of switch statements for untagged variants when there are no literal cases. https://github.com/rescript-lang/rescript-compiler/pull/7135
- Further improve boolean optimizations. https://github.com/rescript-lang/rescript-compiler/pull/7149
- Simplify code generated for conditionals. https://github.com/rescript-lang/rescript-compiler/pull/7151

#### :house: Internal

- Move rescript-editor-analysis and rescript-tools into compiler repo. https://github.com/rescript-lang/rescript-compiler/pull/7000

# 12.0.0-alpha.4

#### :boom: Breaking Change

- OCaml compatibility in the stdlib and primitives are dropped/deprecated. https://github.com/rescript-lang/rescript-compiler/pull/6984
- Remove JSX v3. https://github.com/rescript-lang/rescript-compiler/pull/7072
- Remove js_cast.res. https://github.com/rescript-lang/rescript-compiler/pull/7075

#### :rocket: New Feature

- Use FORCE_COLOR environmental variable to force colorized output. https://github.com/rescript-lang/rescript-compiler/pull/7033
- Allow spreads of variants in patterns (`| ...someVariant as v => `) when the variant spread is a subtype of the variant matched on. https://github.com/rescript-lang/rescript-compiler/pull/6721
- Fix the issue where dynamic imports are not working for function-defined externals. https://github.com/rescript-lang/rescript-compiler/pull/7060
- Allow pattern matching on dicts. `switch someDict { | dict{"one": 1} => Js.log("one is one") }`. https://github.com/rescript-lang/rescript-compiler/pull/7059
- "ReScript Core" standard library is now included in the `rescript` npm package. https://github.com/rescript-lang/rescript-compiler/pull/7108 https://github.com/rescript-lang/rescript-compiler/pull/7116
- Handle absolute filepaths in gentype. https://github.com/rescript-lang/rescript-compiler/pull/7104

#### :bug: Bug fix

- Fix tuple coercion. https://github.com/rescript-lang/rescript-compiler/pull/7024
- Fix attribute printing. https://github.com/rescript-lang/rescript-compiler/pull/7025
- Fix "rescript format" with many files. https://github.com/rescript-lang/rescript-compiler/pull/7081
- Fix bigint max, min. https://github.com/rescript-lang/rescript-compiler/pull/7088
- Fix parsing issue with nested variant pattern type spreads. https://github.com/rescript-lang/rescript-compiler/pull/7080
- Fix JSX settings inheritance: only 'version' propagates to dependencies, preserving their 'mode' and 'module'. https://github.com/rescript-lang/rescript-compiler/pull/7094
- Fix variant cast to int. https://github.com/rescript-lang/rescript-compiler/pull/7058
- Fix comments formatted away in function without arguments. https://github.com/rescript-lang/rescript-compiler/pull/7095
- Fix genType JSX component compilation. https://github.com/rescript-lang/rescript-compiler/pull/7107

#### :nail_care: Polish

- Add some context to error message for unused variables. https://github.com/rescript-lang/rescript-compiler/pull/7050
- Improve error message when passing `children` prop to a component that doesn't accept it. https://github.com/rescript-lang/rescript-compiler/pull/7044
- Improve error messages for pattern matching on option vs non-option, and vice versa. https://github.com/rescript-lang/rescript-compiler/pull/7035
- Improve bigint literal comparison. https://github.com/rescript-lang/rescript-compiler/pull/7029
- Improve output of `@variadic` bindings. https://github.com/rescript-lang/rescript-compiler/pull/7030
- Improve error messages around JSX components. https://github.com/rescript-lang/rescript-compiler/pull/7038
- Improve output of record copying. https://github.com/rescript-lang/rescript-compiler/pull/7043
- Provide additional context in error message when `unit` is expected. https://github.com/rescript-lang/rescript-compiler/pull/7045
- Improve error message when passing an object where a record is expected. https://github.com/rescript-lang/rescript-compiler/pull/7101

#### :house: Internal

- Remove uncurried flag from bsb. https://github.com/rescript-lang/rescript-compiler/pull/7049
- Build runtime/stdlib files with rescript/bsb instead of ninja.js. https://github.com/rescript-lang/rescript-compiler/pull/7063
- Build tests with bsb and move them out of jscomp. https://github.com/rescript-lang/rescript-compiler/pull/7068
- Run `build_tests` on Windows. https://github.com/rescript-lang/rescript-compiler/pull/7065
- Rename folder "jscomp" to "compiler". https://github.com/rescript-lang/rescript-compiler/pull/7086
- Disable -bs-cross-module-opt for tests. https://github.com/rescript-lang/rescript-compiler/pull/7071
- Move `ounit_tests` into the `tests` folder. https://github.com/rescript-lang/rescript-compiler/pull/7096
- Move `syntax_tests` into the `tests` folder. https://github.com/rescript-lang/rescript-compiler/pull/7090 https://github.com/rescript-lang/rescript-compiler/pull/7097
- Capitalize runtime filenames. https://github.com/rescript-lang/rescript-compiler/pull/7110
- Build mocha tests as esmodule / .mjs. https://github.com/rescript-lang/rescript-compiler/pull/7115
- Use dict instead of Dict.t everywhere. https://github.com/rescript-lang/rescript-compiler/pull/7136

# 12.0.0-alpha.3

#### :bug: Bug fix

- Revert "Throws an instance of JavaScript's `new Error()` and adds the extension payload for `cause` option" (https://github.com/rescript-lang/rescript-compiler/pull/6611). https://github.com/rescript-lang/rescript-compiler/pull/7016
- Fix dict literals error. https://github.com/rescript-lang/rescript-compiler/pull/7019

# 12.0.0-alpha.2

#### :rocket: New Feature

- Allow coercing polyvariants to variants when we can guarantee that the runtime representation matches. https://github.com/rescript-lang/rescript-compiler/pull/6981
- Add new dict literal syntax (`dict{"foo": "bar"}`). https://github.com/rescript-lang/rescript-compiler/pull/6774
- Optimize usage of the new dict literal syntax to emit an actual JS object literal. https://github.com/rescript-lang/rescript-compiler/pull/6538

#### :bug: Bug Fix

- Fix issue where long layout break added a trailing comma in partial application `...`. https://github.com/rescript-lang/rescript-compiler/pull/6949
- Fix incorrect format of function under unary operator. https://github.com/rescript-lang/rescript-compiler/pull/6953
- Fix incorrect printing of module binding with signature. https://github.com/rescript-lang/rescript-compiler/pull/6963
- Fix incorrect printing of external with `@as` attribute and `_` placholder (fixed argument). https://github.com/rescript-lang/rescript-compiler/pull/6970
- Disallow spreading anything but regular variants inside of other variants. https://github.com/rescript-lang/rescript-compiler/pull/6980
- Fix comment removed when function signature has `type` keyword. https://github.com/rescript-lang/rescript-compiler/pull/6997
- Fix parse error on doc comment before "and" in type def. https://github.com/rescript-lang/rescript-compiler/pull/7001

#### :house: Internal

- Add dev container. https://github.com/rescript-lang/rescript-compiler/pull/6962
- Convert more tests to the node test runner. https://github.com/rescript-lang/rescript-compiler/pull/6956
- Remove attribute "internal.arity". https://github.com/rescript-lang/rescript-compiler/pull/7004
- Remove dead modules. https://github.com/rescript-lang/rescript-compiler/pull/7008

#### :nail_care: Polish

- Improve formatting in the generated js code. https://github.com/rescript-lang/rescript-compiler/pull/6932
  - `}\ncatch{` -> `} catch {`
  - `for(let i = 0 ,i_finish = r.length; i < i_finish; ++i){` -> `for (let i = 0, i_finish = r.length; i < i_finish; ++i) {`
  - `while(true) {` -> `while (true) {`
  - Fixed tabulation for `switch case` bodies
  - Fixed tabulation for `throw new Error` bodies
  - Removed empty line at the end of `switch` statement
  - Removed empty `default` case from `switch` statement in the generated code
- Optimised the Type Extension runtime code and removed trailing `/1` from `RE_EXN_ID`. https://github.com/rescript-lang/rescript-compiler/pull/6958
- Compact output for anonymous functions. https://github.com/rescript-lang/rescript-compiler/pull/6945 https://github.com/rescript-lang/rescript-compiler/pull/7013
- Rewatch 1.0.9. https://github.com/rescript-lang/rescript-compiler/pull/7010

# 12.0.0-alpha.1

#### :rocket: New Feature

- Allow `@directive` on functions for emitting function level directive code (`let serverAction = @directive("'use server'") (~name) => {...}`). https://github.com/rescript-lang/rescript-compiler/pull/6756
- Add `rewatch` to the npm package as an alternative build tool. https://github.com/rescript-lang/rescript-compiler/pull/6762
- Throws an instance of JavaScript's `new Error()` and adds the extension payload for `cause` option. https://github.com/rescript-lang/rescript-compiler/pull/6611
- Allow free vars in types for type coercion `e :> t`. https://github.com/rescript-lang/rescript-compiler/pull/6828
- Allow `private` in with constraints. https://github.com/rescript-lang/rescript-compiler/pull/6843
- Add regex literals as syntax sugar for `@bs.re`. https://github.com/rescript-lang/rescript-compiler/pull/6776
- Improved mechanism to determine arity of externals, which is consistent however the type is written. https://github.com/rescript-lang/rescript-compiler/pull/6874 https://github.com/rescript-lang/rescript-compiler/pull/6881 https://github.com/rescript-lang/rescript-compiler/pull/6883
- Add `Js.globalThis` object binding. https://github.com/rescript-lang/rescript-compiler/pull/6909

#### :boom: Breaking Change

- Make `j` and `js` allowed names for tag functions. https://github.com/rescript-lang/rescript-compiler/pull/6817
- `lazy` syntax is no longer supported. If you're using it, use `Lazy` module or `React.lazy_` instead. https://github.com/rescript-lang/rescript-compiler/pull/6342
- Remove handling of attributes with `bs.` prefix (`@bs.as` -> `@as` etc.). https://github.com/rescript-lang/rescript-compiler/pull/6643
- Remove obsolete `@bs.open` feature. https://github.com/rescript-lang/rescript-compiler/pull/6629
- Drop Node.js version <18 support, due to it reaching End-of-Life. https://github.com/rescript-lang/rescript-compiler/pull/6429
- Remove deprecated -bs-super-errors option. https://github.com/rescript-lang/rescript-compiler/pull/6814
- Some global names and old keywords are no longer prefixed. https://github.com/rescript-lang/rescript-compiler/pull/6831
- Remove ml parsing tests and conversion from `.ml` to `.res` via format. https://github.com/rescript-lang/rescript-compiler/pull/6848
- Remove support for compiling `.ml` files, and general cleanup. https://github.com/rescript-lang/rescript-compiler/pull/6852
- Remove `rescript convert` subcommand. https://github.com/rescript-lang/rescript-compiler/pull/6860
- Remove support for `@bs.send.pipe`. This also removes all functions in `Js_typed_array` that rely on `@bs.send.pipe`. https://github.com/rescript-lang/rescript-compiler/pull/6858 https://github.com/rescript-lang/rescript-compiler/pull/6891
- Remove deprecated `Js.Vector` and `Js.List`. https://github.com/rescript-lang/rescript-compiler/pull/6900
- Remove support for `%time` extension. https://github.com/rescript-lang/rescript-compiler/pull/6924
- Remove `caml_external_polyfill` module and the related behavior. https://github.com/rescript-lang/rescript-compiler/pull/6925

#### :bug: Bug Fix

- Fix unhandled cases for exotic idents (allow to use exotic PascalCased identifiers for types). https://github.com/rescript-lang/rescript-compiler/pull/6777 https://github.com/rescript-lang/rescript-compiler/pull/6779 https://github.com/rescript-lang/rescript-compiler/pull/6897
- Fix unused attribute check for `@as`. https://github.com/rescript-lang/rescript-compiler/pull/6795
- Reactivate unused attribute check for `@int`. https://github.com/rescript-lang/rescript-compiler/pull/6802
- Fix issue where using partial application `...` can generate code that uses `Curry` at runtime. https://github.com/rescript-lang/rescript-compiler/pull/6872
- Avoid generation of `Curry` with reverse application `|>`. https://github.com/rescript-lang/rescript-compiler/pull/6876
- Fix issue where the internal ppx for pipe `->` would not use uncurried application in uncurried mode. https://github.com/rescript-lang/rescript-compiler/pull/6878

#### :house: Internal

- Build with OCaml 5.2.0. https://github.com/rescript-lang/rescript-compiler/pull/6797
- Convert OCaml codebase to snake case style. https://github.com/rescript-lang/rescript-compiler/pull/6702
- Fix `-nostdlib` internal compiler option. https://github.com/rescript-lang/rescript-compiler/pull/6824
- Remove a number of ast nodes never populated by the .res parser, and resulting dead code. https://github.com/rescript-lang/rescript-compiler/pull/6830
- Remove coercion with 2 types from internal representation. Coercion `e : t1 :> t2` was only supported in `.ml` syntax and never by the `.res` parser. https://github.com/rescript-lang/rescript-compiler/pull/6829
- Convert `caml_format` and `js_math` to `.res`. https://github.com/rescript-lang/rescript-compiler/pull/6834
- Convert `js.ml` files to `.res`. https://github.com/rescript-lang/rescript-compiler/pull/6835
- Remove old `.ml` tests. https://github.com/rescript-lang/rescript-compiler/pull/6847
- Make compiler libs ready for uncurried mode. https://github.com/rescript-lang/rescript-compiler/pull/6861
- Make tests ready for uncurried mode. https://github.com/rescript-lang/rescript-compiler/pull/6862
- Make gentype tests uncurried. https://github.com/rescript-lang/rescript-compiler/pull/6866
- Remove `@@uncurried.swap`, which was used for internal tests. https://github.com/rescript-lang/rescript-compiler/pull/6875
- Build the compiler libraries/tests in uncurried mode. https://github.com/rescript-lang/rescript-compiler/pull/6864
- Ignore `-uncurried` command-line flag. https://github.com/rescript-lang/rescript-compiler/pull/6885
- Cleanup: remove tracking of uncurried state in parser/printer. https://github.com/rescript-lang/rescript-compiler/pull/6888
- Remove `%opaque` primitive. https://github.com/rescript-lang/rescript-compiler/pull/6892
- Reunify JsxC/JsxU -> Jsx etc. https://github.com/rescript-lang/rescript-compiler/pull/6895
- Remove the transformation of `foo(1,2)` into `Js.Internal.opaqueFullApply(Internal.opaque(f), 1, 2)`, and change the back-end to treat all applications as uncurried. https://github.com/rescript-lang/rescript-compiler/pull/6893
- Remove `@uncurry` from ReScript sources (others, tests). https://github.com/rescript-lang/rescript-compiler/pull/6938
- Remove leftover uncurried handling. https://github.com/rescript-lang/rescript-compiler/pull/6939 https://github.com/rescript-lang/rescript-compiler/pull/6940
- Start converting tests from mocha to the node test runner. https://github.com/rescript-lang/rescript-compiler/pull/6956

#### :nail_care: Polish

- Make the `--help` arg be prioritized in the CLI, so correctly prints help message and skip other commands. https://github.com/rescript-lang/rescript-compiler/pull/6667
- Remove redundant space for empty return in generated js code. https://github.com/rescript-lang/rescript-compiler/pull/6745
- Remove redundant space for export in generated js code. https://github.com/rescript-lang/rescript-compiler/pull/6560
- Remove redundant space after continue in generated js code. https://github.com/rescript-lang/rescript-compiler/pull/6743
- Remove empty export blocks in generated js code. https://github.com/rescript-lang/rescript-compiler/pull/6744
- Fix indent for returned/thrown/wrapped in parentheses objects in generated js code. https://github.com/rescript-lang/rescript-compiler/pull/6746
- Fix indent in generated js code. https://github.com/rescript-lang/rescript-compiler/pull/6747
- In generated code, use `let` instead of `var`. https://github.com/rescript-lang/rescript-compiler/pull/6102
- Turn off transformation for closures inside loops when capturing loop variables, now that `let` is emitted instead of `var`. https://github.com/rescript-lang/rescript-compiler/pull/6480
- Improve unused attribute warning message. https://github.com/rescript-lang/rescript-compiler/pull/6787
- Remove internal option `use-stdlib` from build schema. https://github.com/rescript-lang/rescript-compiler/pull/6778
- Fix `Js.Types.JSBigInt` payload to use native `bigint` type. https://github.com/rescript-lang/rescript-compiler/pull/6911
- Deprecate `%external` extension, which has never been officially introduced. https://github.com/rescript-lang/rescript-compiler/pull/6906
- Deprecate `xxxU` functions in Belt. https://github.com/rescript-lang/rescript-compiler/pull/6941
- Improve error messages for function arity errors. https://github.com/rescript-lang/rescript-compiler/pull/6990
- Add missing HTML attribute capture to JsxDOM.res. https://github.com/rescript-lang/rescript-compiler/pull/7006

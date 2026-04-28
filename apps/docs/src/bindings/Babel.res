module Ast = {
  type t

  @tag("type")
  type lval = Identifier({name: string})

  @tag("type")
  type objectProperties = ObjectProperty({key: lval, value: lval})

  @tag("type")
  type expression = ObjectExpression({properties: array<objectProperties>})

  module VariableDeclarator = {
    @tag("type")
    type t = VariableDeclarator({id: lval, init?: Null.t<expression>})
  }
  module Specifier = {
    @tag("type")
    type t =
      | ImportSpecifier({local: lval})
      | ImportDefaultSpecifier({local: lval})
      | ImportNamespaceSpecifier({local: lval})
  }

  module StringLiteral = {
    @tag("type")
    type t = StringLiteral({value: string})
  }

  module VariableDeclaration = {
    @tag("type")
    type t = VariableDeclaration({kind: string, declarations: array<VariableDeclarator.t>})
  }

  module ImportDeclaration = {
    @tag("type")
    type t = ImportDeclaration({specifiers: array<Specifier.t>, source: StringLiteral.t})
  }

  module Identifier = {
    @tag("type")
    type t = Identifier({mutable name: string})
  }

  @tag("type")
  type node =
    | ...StringLiteral.t
    | ...Specifier.t
    | ...VariableDeclarator.t
    | ...VariableDeclaration.t
    | ...ImportDeclaration.t
    | ...Identifier.t

  type nodePath<'nodeType> = {node: 'nodeType}
}

module Parser = {
  type options = {sourceType?: string}
  @module("@babel/parser") external parse: (string, options) => Ast.t = "parse"
}

module Traverse = {
  @module("@babel/traverse") external traverse: (Ast.t, {..}) => unit = "default"
}

module Generator = {
  @send external remove: Ast.nodePath<'nodeType> => unit = "remove"

  type t = {code: string}
  @module("@babel/generator") external generator: Ast.t => t = "default"
}

module PlaygroundValidator = {
  type validator = {
    entryPointExists: bool,
    code: string,
    imports: Dict.t<string>,
  }

  let validate = ast => {
    let entryPoint = ref(false)
    let imports = Dict.make()

    let remove = nodePath => Generator.remove(nodePath)
    Traverse.traverse(
      ast,
      {
        "ImportDeclaration": (
          {
            node: ImportDeclaration({specifiers, source: StringLiteral({value: source})}),
          } as nodePath: Ast.nodePath<Ast.ImportDeclaration.t>,
        ) => {
          if source->String.startsWith("./stdlib") {
            switch specifiers {
            | [ImportNamespaceSpecifier({local: Identifier({name})})] =>
              imports->Dict.set(name, source)
            | _ => ()
            }
          }
          remove(nodePath)
        },
        "ExportNamedDeclaration": remove,
        "VariableDeclaration": (
          {node: VariableDeclaration({declarations})}: Ast.nodePath<Ast.VariableDeclaration.t>,
        ) => {
          if Array.length(declarations) > 0 {
            let firstDeclaration = Array.getUnsafe(declarations, 0)

            switch firstDeclaration {
            | VariableDeclarator({id: Identifier({name}), init}) if name === "App" =>
              switch init {
              | Value(ObjectExpression({properties})) =>
                let foundEntryPoint = properties->Array.find(property => {
                  switch property {
                  | ObjectProperty({
                      key: Identifier({name: "make"}),
                      value: Identifier({name: "Playground$App"}),
                    }) => true
                  | _ => false
                  }
                })
                entryPoint.contents = Option.isSome(foundEntryPoint)
              | _ => ()
              }
            | _ => ()
            }
          }
        },
      },
    )
    {entryPointExists: entryPoint.contents, imports, code: Generator.generator(ast).code}
  }
}

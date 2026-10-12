module Ast = {
  type statement
  type program = {mutable body: array<statement>}
  type t = {program: program}

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

  module ExpressionStatement = {
    @tag("type")
    type t = ExpressionStatement({expression: expression})
  }

  module FunctionDeclaration = {
    @tag("type")
    type t = FunctionDeclaration({id: lval})
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
    | ...ExpressionStatement.t
    | ...FunctionDeclaration.t
    | ...Identifier.t

  type nodePath<'nodeType> = {node: 'nodeType}

  @get external nodeType: statement => string = "type"
  @get external expression: statement => expression = "expression"
  @get external source: statement => StringLiteral.t = "source"
  @get external specifiers: statement => array<Specifier.t> = "specifiers"
  @get external declarations: statement => array<VariableDeclarator.t> = "declarations"
  @get external statementId: statement => lval = "id"

  let lvalName = (lval: lval) =>
    switch lval {
    | Identifier({name}) => name
    }

  let stringLiteralValue = (stringLiteral: StringLiteral.t) =>
    switch stringLiteral {
    | StringLiteral({value}) => value
    }

  let specifierLocal = (specifier: Specifier.t) =>
    switch specifier {
    | ImportSpecifier({local})
    | ImportDefaultSpecifier({local})
    | ImportNamespaceSpecifier({local}) => local
    }

  let variableDeclaratorId = (variableDeclarator: VariableDeclarator.t) =>
    switch variableDeclarator {
    | VariableDeclarator({id}) => id
    }
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
  @module("@babel/generator") external generator: Ast.t => t = "generate"
}

module Types = {
  @module("@babel/types") external identifier: string => Ast.expression = "identifier"

  @module("@babel/types")
  external memberExpression: (Ast.expression, Ast.expression) => Ast.expression = "memberExpression"

  @module("@babel/types")
  external callExpression: (Ast.expression, array<Ast.expression>) => Ast.expression =
    "callExpression"

  @module("@babel/types")
  external expressionStatement: Ast.expression => Ast.statement = "expressionStatement"
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

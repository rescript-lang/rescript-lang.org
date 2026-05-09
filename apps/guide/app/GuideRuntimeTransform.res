type t = {
  code: string,
  imports: Dict.t<string>,
}

let isModuleBoundary = statement => {
  switch statement->Babel.Ast.nodeType {
  | "ImportDeclaration" | "ExportNamedDeclaration" => true
  | _ => false
  }
}

let collectRuntimeImport = (~imports, statement) => {
  switch statement->Babel.Ast.nodeType {
  | "ImportDeclaration" =>
    let sourceValue = statement->Babel.Ast.source->Babel.Ast.stringLiteralValue
    if sourceValue->String.startsWith("./stdlib") {
      switch statement->Babel.Ast.specifiers {
      | [specifier] =>
        imports->Dict.set(specifier->Babel.Ast.specifierLocal->Babel.Ast.lvalName, sourceValue)
      | _ => ()
      }
    }
  | _ => ()
  }
}

let consoleLogStatement = expression => {
  let consoleLog = Babel.Types.memberExpression(
    Babel.Types.identifier("console"),
    Babel.Types.identifier("log"),
  )
  Babel.Types.expressionStatement(Babel.Types.callExpression(consoleLog, [expression]))
}

let hasBinding = (~name, statement) =>
  switch statement->Babel.Ast.nodeType {
  | "VariableDeclaration" =>
    statement
    ->Babel.Ast.declarations
    ->Array.some(declaration =>
      declaration->Babel.Ast.variableDeclaratorId->Babel.Ast.lvalName === name
    )
  | _ => false
  }

let appendResultBindingLog = (~resultBindingName, body) =>
  switch resultBindingName {
  | Some(name) if body->Array.some(statement => statement->hasBinding(~name)) =>
    Some(body->Array.concat([Babel.Types.identifier(name)->consoleLogStatement]))
  | _ => None
  }

let variableDeclarationBindingName = statement => {
  let declarations = statement->Babel.Ast.declarations

  switch declarations->Array.length {
  | 0 => None
  | length =>
    Some(
      declarations
      ->Array.getUnsafe(length - 1)
      ->Babel.Ast.variableDeclaratorId
      ->Babel.Ast.lvalName,
    )
  }
}

let bindingName = statement =>
  switch statement->Babel.Ast.nodeType {
  | "VariableDeclaration" => statement->variableDeclarationBindingName
  | "FunctionDeclaration" => Some(statement->Babel.Ast.statementId->Babel.Ast.lvalName)
  | _ => None
  }

let lastBindingName = body => {
  let lastFound = ref(None)

  body->Array.forEach(statement =>
    switch statement->bindingName {
    | Some(name) => lastFound.contents = Some(name)
    | None => ()
    }
  )

  lastFound.contents
}

let appendLastBindingLog = body =>
  switch body->lastBindingName {
  | Some(name) => Some(body->Array.concat([Babel.Types.identifier(name)->consoleLogStatement]))
  | None => None
  }

let transform = (~resultBindingName=?, jsCode) =>
  try {
    let ast = Babel.Parser.parse(jsCode, {sourceType: "module"})
    let imports = Dict.make()
    ast.program.body->Array.forEach(statement => statement->collectRuntimeImport(~imports))

    let executableBody = ast.program.body->Array.filter(statement => !isModuleBoundary(statement))

    switch executableBody->Array.length {
    | 0 => None
    | length =>
      let lastIndex = length - 1
      let lastStatement = executableBody->Array.getUnsafe(lastIndex)

      switch lastStatement->Babel.Ast.nodeType {
      | "ExpressionStatement" =>
        ast.program.body =
          executableBody->Array.mapWithIndex((statement, index) =>
            index === lastIndex
              ? lastStatement->Babel.Ast.expression->consoleLogStatement
              : statement
          )
        Some({code: Babel.Generator.generator(ast).code, imports})
      | _ =>
        switch executableBody->appendResultBindingLog(~resultBindingName) {
        | Some(body) =>
          ast.program.body = body
          Some({code: Babel.Generator.generator(ast).code, imports})
        | None =>
          switch executableBody->appendLastBindingLog {
          | Some(body) =>
            ast.program.body = body
            Some({code: Babel.Generator.generator(ast).code, imports})
          | None => None
          }
        }
      }
    }
  } catch {
  | _ => None
  }

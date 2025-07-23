open Markdown

@react.component
let make = () => {
  <Table>
    <Thead>
      <tr>
        <Th> {React.string("#")} </Th>
        <Th> {React.string("Description")} </Th>
      </tr>
    </Thead>
    <tbody>
      {WarningFlagDescription.lookupAll()
      ->Array.map(((number, description)) =>
        <tr key=number>
          <Td> {React.string(number)} </Td>
          <Td> {React.string(description)} </Td>
        </tr>
      )
      ->React.array}
    </tbody>
  </Table>
}

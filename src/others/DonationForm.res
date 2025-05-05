// TODO (fham): Make this a stripe checkout form.
// 1. Create a rescript-association stripe account
// 2. Use stripe's library on npm

@react.component
let make = () => {
  <div className="max-w-2xl">
    <div className="mb-6">
      <div className="py-4 font-mono">
        <p>
          <strong> {React.string("IBAN: ")} </strong>
          {React.string("AT24 2021 9000 2110 4161")}
        </p>
        <p>
          <strong> {React.string("BIC: ")} </strong>
          {React.string("GIBAATWWXXX")}
        </p>
        <p>
          <strong> {React.string("Bank: ")} </strong>
          {React.string("Erste Bank der oesterreichischen Sparkassen AG")}
        </p>
        <p>
          <strong> {React.string("Account Name: ")} </strong>
          {React.string("ReScript Association")}
        </p>
      </div>
    </div>

    <img src="/static/donation_qr_code.svg" className="w-48 mx-auto mt-6" alt="SEPA QR Code" />
  </div>
}

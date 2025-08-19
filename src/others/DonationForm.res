// TODO (fham): Make this a stripe checkout form.
// 1. Create a rescript-association stripe account
// 2. Use stripe's library on npm

@react.component
let make = () => {
  <div className="pt-4 max-w-2xl text-center">
    <stripe-buy-button
      {...Obj.magic({
        "buy-button-id": "buy_btn_1RS2jjLvZNMEoCiEOIqXq9y6",
        "publishable-key": "pk_live_kJ6je9A1VblN5DWtrtedHUQo00mib09Cam",
      })}
    />
  </div>
}

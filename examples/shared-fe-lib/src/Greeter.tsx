import React from "react";
import "./Greeter.css";
import globe from "./globe.svg";

import { greeting } from "../../shared-lib/src";

export default function Greeter() {
  return (
    <div className="Greeter">
      <img src={globe} alt="A globe" />
      {greeting()}
    </div>
  );
}

import "./Footer.css";
import globe from "./globe.svg";

import { appInfo } from "../../shared-lib/src/index.js";

export default function Footer() {
  return (
    <div className="footer">
      <img src={globe} alt="A globe" />
      {appInfo()}
    </div>
  );
}

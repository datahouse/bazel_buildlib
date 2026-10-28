import "./main.css";

import { depClass } from "../dep/dep.js";
import { unregisteredClass } from "../unregistered/unregistered.js";

// Arbitrary value on purpose: a plain word could leak in from another file.
export const appClass = `mt-[13px] ${depClass} ${unregisteredClass}`;

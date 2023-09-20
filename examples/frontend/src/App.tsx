import React from "react";
import "./App.css";

import Greeter from "../../shared-fe-lib/src/Greeter";
import TodoLists from "./TodoLists";

export default function App() {
  return (
    <div className="App">
      <Greeter />
      This is the application.
      <TodoLists />
    </div>
  );
}

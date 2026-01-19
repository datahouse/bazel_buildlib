import React from "react";
import ReactDOM from "react-dom/client";
import { ApolloClient, InMemoryCache } from "@apollo/client";
import { ApolloProvider } from "@apollo/client/react";
import UploadHttpLink from "apollo-upload-client/UploadHttpLink.mjs";
import App from "./App.js";

const apolloClient = new ApolloClient({
  cache: new InMemoryCache(),
  dataMasking: true,
  link: new UploadHttpLink({
    uri: "/gql/v1/",
    headers: {
      "Apollo-Require-Preflight": "true",
    },
  }),
});

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    <ApolloProvider client={apolloClient}>
      <App />
    </ApolloProvider>
  </React.StrictMode>,
);

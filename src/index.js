import React from "react";
import ReactDOM from "react-dom";
import "./index.css";
import App from "./App";
import { createBrowserHistory } from "history";
import { BrowserRouter } from "react-router-dom";

const history = createBrowserHistory();

ReactDOM.render(
    <React.StrictMode>
        <BrowserRouter history={history}>
            <App />
        </BrowserRouter>
    </React.StrictMode>,
    document.getElementById("root")
);

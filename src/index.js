import React from "react";
import ReactDOM from "react-dom";
import "./index.css";
import App from "./App";
import { createBrowserHistory } from "history";
import { BrowserRouter } from "react-router-dom";
import { ToastMessage } from "rimble-ui";

const history = createBrowserHistory();

ReactDOM.render(
    <React.StrictMode>
        <BrowserRouter history={history}>
            <ToastMessage.Provider
                ref={(node) => (window.toastProvider = node)}
            />
            <App />
        </BrowserRouter>
    </React.StrictMode>,
    document.getElementById("root")
);

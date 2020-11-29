import React from "react";
import ReactDOM from "react-dom";
import "./index.css";
import App from "./App";
import { createBrowserHistory } from "history";
import { BrowserRouter } from "react-router-dom";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.min.css";

const history = createBrowserHistory();

ReactDOM.render(
    <React.StrictMode>
        <BrowserRouter history={history}>
            <ToastContainer />
            <App />
        </BrowserRouter>
    </React.StrictMode>,
    document.getElementById("root")
);

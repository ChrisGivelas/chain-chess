import React from "react";
import { NavLink } from "react-router-dom";

function Nav({ connectedWalletAddress }) {
    return (
        <div className="nav">
            <NavLink
                className="nav-link"
                activeClassName="nav-link-active"
                to={`/profile/${connectedWalletAddress}`}
            >
                Profile
            </NavLink>
            <NavLink
                className="nav-link"
                activeClassName="nav-link-active"
                to={`/activeGames`}
            >
                Active Games
            </NavLink>
            <NavLink
                className="nav-link"
                activeClassName="nav-link-active"
                to={`/search`}
            >
                Search
            </NavLink>
        </div>
    );
}

export default Nav;

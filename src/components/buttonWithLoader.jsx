import React from "react";
import { Button, Loader } from "rimble-ui";

const ButtonWithLoader = ({ isLoading, text, ...rest }) => {
    return (
        <Button ml={3} {...rest} disabled={isLoading}>
            {isLoading ? (
                <Loader bg="primary" color="white" size="20px" />
            ) : (
                text
            )}
        </Button>
    );
};

export default ButtonWithLoader;

import React, { useState } from "react";
import { Box, Button, Modal, Card, Heading, Flex, Loader } from "rimble-ui";
import { useHistory } from "react-router-dom";
import { getGameByOpponent, acceptGame } from "../standardGame";

function AcceptGameModal({
    OpenModalComponent,
    connectedWalletAddress,
    opponentAddress,
}) {
    const history = useHistory();

    const [isOpen, setIsOpen] = useState(false);
    const [isLoading, setIsLoading] = useState(false);

    const closeModal = (e) => {
        e && e.preventDefault();
        setIsOpen(false);
    };

    const openModal = (e) => {
        e && e.preventDefault();
        setIsOpen(true);
    };

    const startGame = () => {
        if (opponentAddress !== undefined) {
            setIsLoading(true);
            acceptGame(connectedWalletAddress, opponentAddress)
                .then(() =>
                    getGameByOpponent(connectedWalletAddress, opponentAddress)
                )
                .then((game) => {
                    setIsLoading(false);
                    closeModal();
                    history.push(`/game/${game.gameId}`);
                });
        }
    };

    return (
        <React.Fragment>
            <OpenModalComponent onClick={openModal} />

            <Modal isOpen={isOpen}>
                <Card width={"420px"} p={0}>
                    <Button.Text
                        icononly
                        icon={"Close"}
                        color={"moon-gray"}
                        position={"absolute"}
                        top={0}
                        right={0}
                        mt={3}
                        mr={3}
                        onClick={closeModal}
                    />

                    <Box p={4} mb={3}>
                        <Heading>
                            Accept game with{" "}
                            <span className="short-address">
                                {opponentAddress}
                            </span>
                            ?
                        </Heading>
                    </Box>

                    <Flex
                        px={4}
                        py={3}
                        borderTop={1}
                        borderColor={"#E8E8E8"}
                        justifyContent={"flex-end"}
                    >
                        <Button.Outline
                            disabled={isLoading}
                            onClick={closeModal}
                        >
                            Cancel
                        </Button.Outline>
                        <Button ml={3} onClick={startGame} disabled={isLoading}>
                            {isLoading ? (
                                <Loader
                                    bg="primary"
                                    color="white"
                                    size="20px"
                                />
                            ) : (
                                "Confirm"
                            )}
                        </Button>
                    </Flex>
                </Card>
            </Modal>
        </React.Fragment>
    );
}

export default AcceptGameModal;

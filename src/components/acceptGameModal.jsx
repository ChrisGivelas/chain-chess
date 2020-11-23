import React, { useState } from "react";
import { Box, Button, Modal, Card, Heading, Flex } from "rimble-ui";
import { useHistory } from "react-router-dom";
import { parseResultToGame } from "../game_parsing_utils";

function AcceptGameModal({
    OpenModalComponent,
    connectedWalletAddress,
    opponentAddress,
}) {
    const history = useHistory();

    const [isOpen, setIsOpen] = useState(false);

    const closeModal = (e) => {
        e && e.preventDefault();
        setIsOpen(false);
    };

    const openModal = (e) => {
        e && e.preventDefault();
        setIsOpen(true);
    };

    const getGameByOpponent = () => {
        return window.cc_standardGameContract
            .deployed()
            .then(async (instance) => {
                return await instance.getGameByOpponent(opponentAddress, {
                    from: connectedWalletAddress,
                });
            });
    };

    const acceptGame = () => {
        if (opponentAddress !== undefined) {
            window.cc_standardGameContract.deployed().then((instance) => {
                instance
                    .acceptGame(opponentAddress, {
                        from: connectedWalletAddress,
                    })
                    .then(getGameByOpponent)
                    .then((game) => {
                        var parsedGame = parseResultToGame(game);
                        console.log(parsedGame);
                        history.push(`/game/${parsedGame.gameId}`);
                        closeModal();
                    });
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
                        <Button.Outline onClick={closeModal}>
                            Cancel
                        </Button.Outline>
                        <Button ml={3} onClick={acceptGame}>
                            Confirm
                        </Button>
                    </Flex>
                </Card>
            </Modal>
        </React.Fragment>
    );
}

export default AcceptGameModal;

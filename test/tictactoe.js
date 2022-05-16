const tictactoe = artifacts.require("tictactoe");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("tictactoe", function (accounts) {
  const playerOne = accounts[0];
  const playerTwo = accounts[1];
  let instance;
  let id;
  let playerOneFirst;

  it("Deploy", async function () {
    instance = await tictactoe.deployed();
    assert.isTrue(instance.address !== undefined, "Not deployed");
  });

  it("Create Game", async function () {
    const tx = await instance.createGame.sendTransaction({ from: playerOne });
    const eventsGameCreated = tx.logs.filter(event => event.event === 'GameCreated');
    assert.isTrue(eventsGameCreated.length === 1, "Event GameCreated not emitted");
    assert.isTrue(eventsGameCreated[0].args.creator === playerOne, "Creator is incorrect");

    id = eventsGameCreated[0].args.id;
  });

  it("Join Game", async function () {
    const tx = await instance.joinGame.sendTransaction(id, { from: playerTwo });
    const eventsGameJoined = tx.logs.filter(event => event.event === 'GameJoined');
    assert.isTrue(eventsGameJoined.length === 1, "Event GameJoined not emitted");
    assert.isTrue(eventsGameJoined[0].args.joiner === playerTwo, "Joiner is incorrect");

    playerOneFirst = eventsGameJoined[0].args.isCreatorFirstMove;

    console.log(playerOneFirst ? "PlayerOne" : "PlayerTwo", "is first move");
  });

  it("Play Game Draw", async function () {
    const winner = await playGame([
      [0, 0], [1, 1],
      [2, 2], [0, 1],
      [2, 1], [2, 0],
      [0, 2], [1, 2],
      [1, 0]
    ]);

    assert.isTrue(winner === "0x0000000000000000000000000000000000000000", "Game should be draw");
  });

  it("Play Game First Win", async function () {
    let tx = await instance.createGame.sendTransaction({ from: playerOne });
    const eventsGameCreated = tx.logs.filter(event => event.event === 'GameCreated');
    id = eventsGameCreated[0].args.id;
    tx = await instance.joinGame.sendTransaction(id, { from: playerTwo });
    const eventsGameJoined = tx.logs.filter(event => event.event === 'GameJoined');
    playerOneFirst = eventsGameJoined[0].args.isCreatorFirstMove;

    console.log(playerOneFirst ? "PlayerOne" : "PlayerTwo", "is first move");
    const winner = await playGame([
      [0, 0], [1, 1],
      [2, 2], [0, 2],
      [2, 0], [2, 1],
      [1, 0], [1, 2],
      [0, 1]
    ]);
    assert.isTrue(winner === playerOne, "PlayerOne should be winner");
  });

  const getBoard = async () => {
    const board = await instance.getBoard(id);
    return board.map(row => row.map(cell => {
      const c = parseInt(cell);
      if (c === 1) return playerOneFirst ? "X" : "O";
      if (c === 2) return playerOneFirst ? "O" : "X";
      return "-";
    }).join("")).join("\r\n");
  }

  const playGame = async (cells) => {
    let turn = playerOneFirst;
    for (let i = 0; i < cells.length; i++) {
      const tx = await instance.makeMove.sendTransaction(id, cells[i][0], cells[i][1], { from: turn ? playerOne : playerTwo });
      turn = !turn;

      const eventsMoveMade = tx.logs.filter(event => event.event === 'MoveMade');
      const eventsGameFinished = tx.logs.filter(event => event.event === 'GameFinished');
      assert.isTrue(eventsMoveMade.length === 1, "Event MoveMade not emitted");
      
      console.log(await getBoard(), "\r\n");

      if (eventsGameFinished.length > 0) {
        console.log("Winner is ", eventsGameFinished[0].args.winner);
        return eventsGameFinished[0].args.winner;
      }
    }
  }
});



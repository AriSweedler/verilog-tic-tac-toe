// reset signal starts the game. As long as the reset = 1'b1, the game is in reset

// Each occ_pos signal is 1'b0 to indicate unoccupied, 1'b1 to indicate
// occupied by X, and flashing 1'b1 at a rate of ½ flash_clk ~to indicate
// occupied by O~

// 8 signals, game_st[7:0] (an ASCII character), to indicate the state of the
// game. 'X' to indicate the winner is X's player, 'O' to indicate the winner
// is O's player, 'C' to indicate a tie ('Cats-Game'), and 'E' to indicate an
// error.
  // An error is detected if a player tries to place and X or O on an occupied
  // square, tries to place more than 1 X or O at a time, or if an X or O is
  // being played during the other player's turn.
module game(turnX, turnO, occ_pos, game_st, reset, clk, flash_clk, sel_pos, buttonX, buttonO);
  output turnX, turn0;
  output occ_pos[8:0];
  output game_st[7:0];

  input reset, clk, flash_clk;
  input sel_pos[8:0];
  input buttonX, buttonO;

  /**************************** begin game logic *****************************/
  //TODO 2x9 array (occupied, if so by which player)

endmodule


/* A move is valid if it is player X's turn and an X is placed in an
 * unoccupied square. Or if it is player O's turn and an O is placed in an
 * unoccupied square.
 */
module move_validity();
  output valid;

  input cur_game_st[???]; //who's turn is it?
  input buttonX, buttonO; //who tried to make a move?
  input occ_pos[8:0]; //this the half of our state where it's occupied or not, not about X or O
  input sel_pos[8:0]; //where is the move going?


endmodule

/* 3 in a row means a winner.
 * No winner with 9 occupied spaces means cat's game.
 * No winner with less than 9 occupied spaces means the game is still going
 */
`DEFINE ST_WINX 2'd0
`DEFINE ST_WIN0 2'd1
`DEFINE ST_CATS 2'd2
`DEFINE ST_NONE 2'd3
module check_win();
  output result[1:0]; //output state
  input occ_pos[8:0]; //is there an X or O here?
  input occ_player[8:0]; //if so, which one is it.

  /* The grid looks like this:
   * 8 | 7 | 6
   * --|---|---
   * 5 | 4 | 3
   * --|---|---
   * 2 | 1 | 0
   */

  /* Winning combinations:
   * 852, 741, 630, 876, 543, 210, 840, 642
   */
  //TODO make a module that takes 3 inputs and says "there is a win here" or
  //nothing.

  /* if ANY possible win is true, then return who won.
   * Otherwise, check for a cat's game.
   * Otherwise, return ST_NONE
   * always @(*)
   */

endmodule
/********************************** plan ***********************************/
/*
 * (1) a state machine that determines behavior of each LED ~???~
 * (2) logic that checks a move for validity
 *   * Driver between internal state and ASCII representation
 * (3) logic that checks a Win or Cats-Game.
 */

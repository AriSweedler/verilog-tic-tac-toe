`timescale 1ns / 1ps

/* For my internal state, X is 1, O is 0 */
`define X_TILE 1'b1
`define O_TILE 1'b0

/* Game states bit patterns */
`define GAME_ST_START 4'd0
`define GAME_ST_TURN_X 4'd1
`define GAME_ST_ERR_X 4'd2
`define GAME_ST_CHECK_X 4'd3
`define GAME_ST_WIN_X 4'd4
`define GAME_ST_TURN_O 4'd5
`define GAME_ST_ERR_O 4'd6
`define GAME_ST_CHECK_O 4'd7
`define GAME_ST_WIN_O 4'd8
`define GAME_ST_CATS 4'd9

/* Win state bit patterns */
`define RESULT_NONE 2'd0
`define RESULT_CATS 2'd1
`define RESULT_WINO 2'd2
`define RESULT_WINX 2'd3

module game(turnX, turnO, occ_pos, game_st, reset, clk, flash_clk, sel_pos, buttonX, buttonO);
  output turnX;
  output turnO;
  output [8:0] occ_pos;
  output [7:0] game_st;

  input reset, clk, flash_clk;
  input [8:0] sel_pos;
  input buttonX, buttonO;

  /* occ_square states if there's a tile in this square or not */
  reg [8:0] occ_square;
  /* occ_player states which type of tile is in the square */
  reg [8:0] occ_player;
  reg [3:0] game_state;

  wire valid_move;
  check_valid_move cvm (valid_move, occ_square, sel_pos);

  wire buttonX_debounce, buttonO_debounce;
  debouncer db_buttonX (buttonX_debounce, buttonX, clk, reset);
  debouncer db_buttonO (buttonO_debounce, buttonO, clk, reset);

  wire [7:0] game_st_ascii;
  assign game_st = game_st_ascii;
  game_st_driver _game_st_driver (game_st_ascii, game_state);

  /* asynchronous resets */
  always @ (posedge clk, posedge reset) begin
    if (reset) begin
      occ_square <= 9'b000000000;
      occ_player <= 9'b000000000;
      game_state <= `GAME_ST_START;
    end else begin
      if (game_state == `GAME_ST_START) begin
        game_state <= `GAME_ST_TURN_X;
      end else if (game_state == `GAME_ST_TURN_X) begin
        if (buttonX_debounce & valid_move) begin
          /* mark this square as occupied */
          occ_square <= (occ_square) | (sel_pos);
          /* set the selected position to be an X_TILE (1/high) */
          occ_player <= (occ_player) | (sel_pos);
        end else if ((buttonX_debounce | buttonO_debounce) & ~valid_move) begin
          game_state <= `GAME_ST_ERR_X;
        end else game_state <= game_state;
      end else if (game_state == `GAME_ST_TURN_O) begin
        if (buttonO_debounce & valid_move) begin
          /* mark this square as occupied */
          occ_square <= (occ_square) | (sel_pos);
          /* set the selected position to be an O_TILE (0/low) */
          occ_player <= (occ_player) & (~sel_pos);
        end else if ((buttonX_debounce | buttonO_debounce) & ~valid_move) begin
          game_state <= `GAME_ST_ERR_O;
        end else game_state <= game_state;
      end else if (game_state == `GAME_ST_ERR_X) begin
        if (buttonX_debounce & valid_move) begin
          /* mark this square as occupied */
          occ_square <= (occ_square) | (sel_pos);
          /* set the selected position to be an X_TILE (1/high) */
          occ_player <= (occ_player) | (sel_pos);
        end else game_state <= game_state;
      end else if (game_state == `GAME_ST_ERR_O) begin
        if (buttonO_debounce & valid_move) begin
          /* mark this square as occupied */
          occ_square <= (occ_square) | (sel_pos);
          /* set the selected position to be an O_TILE (0/low) */
          occ_player <= (occ_player) & (~sel_pos);
        end else game_state <= game_state;
      end else if (game_state == `GAME_ST_CHECK_X) begin
        if (~valid_move) game_state <= `GAME_ST_ERR_X;
        else if (result == `RESULT_WINX) game_state <= `GAME_ST_WIN_X;
        else if (result == `RESULT_CATS) game_state <= `GAME_ST_CATS;
        else if (result == `RESULT_NONE) game_state <= `GAME_ST_TURN_O;
        else game_state <= game_state;
      end else if (game_state == `GAME_ST_CHECK_O) begin
        if (~valid_move) game_state <= `GAME_ST_ERR_O;
        else if (result == `RESULT_WINO) game_state <= `GAME_ST_WIN_O;
        else if (result == `RESULT_CATS) game_state <= `GAME_ST_CATS;
        else if (result == `RESULT_NONE) game_state <= `GAME_ST_TURN_X;
        else game_state <= game_state;
      end else if (game_state == `GAME_ST_WIN_X) begin
        game_state <= game_state;
      end else if (game_state == `GAME_ST_WIN_O) begin
        game_state <= game_state;
      end else if (game_state == `GAME_ST_CATS) begin
        game_state <= game_state;
      end
    end
  end

  wire [1:0] result;
  check_win _check_win (result, occ_square, occ_player);

endmodule

/* 3 in a row means a winner.
 * No winner with 9 occupied spaces means cat's game.
 * No winner with less than 9 occupied spaces means the game is still going
 */
/* First bit being high ==> there's a winner. If there's a winner, second bit
 * says who */
module check_win(result, occ_square, occ_player);
  output reg [1:0] result; //output state
  input [8:0] occ_square; //is there an X or O here?
  input [8:0] occ_player; //if so, which one is it.

  /* The grid looks like this:
   * 8 | 7 | 6
   * --|---|---
   * 5 | 4 | 3
   * --|---|---
   * 2 | 1 | 0
   */

  /* Winning combinations (treys):
   * 852, 741, 630, 876, 543, 210, 840, 642
   * Check for a victory in each trey
   */
  wire [7:0] trey_winner;
  wire [7:0] trey_player;
  check_trey col0 (trey_winner[0], trey_player[0], {occ_square[8], occ_square[5], occ_square[2]}, {occ_player[8], occ_player[5], occ_player[2]});
  check_trey col1 (trey_winner[1], trey_player[1], {occ_square[7], occ_square[4], occ_square[1]}, {occ_player[7], occ_player[4], occ_player[1]});
  check_trey col2 (trey_winner[2], trey_player[2], {occ_square[6], occ_square[3], occ_square[0]}, {occ_player[6], occ_player[3], occ_player[0]});
  check_trey row0 (trey_winner[3], trey_player[3], {occ_square[8], occ_square[7], occ_square[6]}, {occ_player[8], occ_player[7], occ_player[6]});
  check_trey row1 (trey_winner[4], trey_player[4], {occ_square[5], occ_square[4], occ_square[3]}, {occ_player[5], occ_player[4], occ_player[3]});
  check_trey row2 (trey_winner[5], trey_player[5], {occ_square[2], occ_square[1], occ_square[0]}, {occ_player[2], occ_player[1], occ_player[0]});
  check_trey dag0 (trey_winner[6], trey_player[6], {occ_square[8], occ_square[4], occ_square[0]}, {occ_player[8], occ_player[4], occ_player[0]});
  check_trey dag1 (trey_winner[7], trey_player[7], {occ_square[6], occ_square[4], occ_square[2]}, {occ_player[6], occ_player[4], occ_player[2]});

  wire isWinner, winningPlayer;
  assign isWinner = (& trey_winner);
  assign winningPlayer = (| trey_player);

  always @(*) begin
    if (isWinner) begin
      result <= {isWinner, winningPlayer};
    end else if (& occ_square) begin
      result <= `RESULT_CATS;
    end else begin
      result <= `RESULT_NONE;
    end
  end
endmodule

/* checks 3 inline squares (row/column/diagonal) (a.k.a. a "trey") to see if
 * a victory has been scored across them */
module check_trey(win, player, occ_square, occ_player);
  output win; //was there a winner in this trey?
  output player; //who won?
  input [2:0] occ_square; // is there an X or an O in this spot
  input [2:0] occ_player; // if so, which one is it

  /* Is the same player in all squares of this trey? */
  //assign samePlayer = (occ_player[0] == occ_player[1]) & (occ_player[0] == occ_player[2]);
  wire samePlayer;
  assign samePlayer = (& occ_player) == (| occ_player);

  /* If so, and all the squares are occupied (meaning the occ_player data isn't
   * garbage), then that means someone won */
  assign win = samePlayer & (& occ_square);
  /* filter the player output s.t. ORing them all together will give the
   * winning player (default 'player' to 0, unless there was a winner. Then
   * let it have it's true value */
  assign player = win & occ_player[0];
endmodule

/* (2) logic that checks a move for validity */
module check_valid_move(valid, occ_square, sel_pos);
  output valid;

  input [8:0] occ_square;
  input [8:0] sel_pos;
  input [3:0] game_state;

  /* Only place a tile in an unoccupied square */
  wire isUnoccupied;
  assign isUnoccupied = (occ_square & sel_pos) == 9'b000000000;

  /* Only place 1 tile at a time */
  wire isOneHot;
  assign isOneHot = (sel_pos[0] + sel_pos[1] + sel_pos[2] + sel_pos[3] + sel_pos[4] + sel_pos[5] + sel_pos[6] + sel_pos[7] + sel_pos[8]) == 4'b0001;

  assign valid = isUnoccupied & isOneHot;
endmodule

`define ASCII_X 8'b01011000
`define ASCII_O 8'b01001111
`define ASCII_C 8'b01000011
`define ASCII_E 8'b01000101
`define ASCII_NONE 8'b01101110
/* Driver between internal game state and ASCII output */
module game_st_driver (game_st_ascii, game_st);
  output reg [7:0] game_st_ascii;
  input [3:0] game_st;
  always @(*) begin
    case (game_st)
      `GAME_ST_WIN_X: game_st_ascii <= `ASCII_X;
      `GAME_ST_WIN_O: game_st_ascii <= `ASCII_O;
      `GAME_ST_CATS: game_st_ascii <= `ASCII_C;
      `GAME_ST_ERR_X,
      `GAME_ST_ERR_O: game_st_ascii <= `ASCII_E;
      default: game_st_ascii <= `ASCII_NONE;
    endcase
  end
endmodule

module occ_pos_driver (occ_pos, occ_square, occ_player, trey_winner, flash_clk, rst);
  output [8:0] occ_pos;
  input [8:0] occ_square;
  input [8:0] occ_player;
  input [7:0] trey_winner;
  input rst;
  input flash_clk;

  /* a mask that gets applied to occ_player at a rate of 1/2 flash_clk */
  reg [8:0] occ_O_mask;

  always @(posedge flash_clk) begin
    if (rst) occ_O_mask = 9'b000000000;
    else occ_O_mask = ~occ_O_mask;
  end

  wire [8:0] pre_occ_pos;
  assign pre_occ_pos = occ_square & (occ_player | occ_O_mask);
  /* Each occ_pos signal is 1'b0 to indicate unoccupied
   * 1'b1 to indicate occupied by X
   * flashing 1'b1 at a rate of ½ flash_clk to indicate occupied by O */
  /* Only for occupied tiles, display high for all the X's, and only display
   * high for the Os when occ_O_mask is high */

  wire [8:0] flash_clk_mask;
  assign flash_clk_mask = {flash_clk, flash_clk, flash_clk, flash_clk, flash_clk, flash_clk, flash_clk, flash_clk, flash_clk};

  reg [8:0] trey_mask;
  always @(*) begin
    if (trey_winner[0]) trey_mask <= 9'b110110110; //852
    else if (trey_winner[1]) trey_mask <= 9'b101101101; //741
    else if (trey_winner[2]) trey_mask <= 9'b011011011; //630
    else if (trey_winner[3]) trey_mask <= 9'b111111000; //876
    else if (trey_winner[4]) trey_mask <= 9'b111000111; //543
    else if (trey_winner[5]) trey_mask <= 9'b000111111; //210
    else if (trey_winner[6]) trey_mask <= 9'b011101110; //840
    else if (trey_winner[7]) trey_mask <= 9'b110101011; //642
    else trey_mask <= 9'b111111111; //no winner
  end

  assign occ_pos = pre_occ_pos & (trey_mask | flash_clk_mask);
  /* For example, is the winning trey is '012', then trey_mask ORed with
   * flash_clk_mask alters between 000111111 and 111111111. */
endmodule

/* A 2-bit debouncer is basically just a posedge detector */
/* To properly use this as a debouncer, we might wanna have more than 8 bits
 * in the shift register. Or, we could downsample the clock */
module debouncer(data_out, data_in, clk_in, reset);
  input data_in, clk_in, reset;
  output data_out;

  reg [3:0] q;

  always @ ( posedge clk_in or posedge reset) begin

    if (reset == 1'b1) begin
      q <= 8'b0;
    end else begin
      /* Shift all the bits one to the right. Shift in "data_in" */
      q[0] <= data_in;
      q[1] <= q[0];
      q[2] <= q[1];
      q[3] <= q[2];
    end
  end

  /* If the oldest data is low and ALL of the newest datas are high, then we
   * have a button press */
  assign data_out = !q[3] & q[2] & q[1] & q[0];
endmodule

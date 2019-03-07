/* For my internal state, X is 1, O is 0 */

//TODO we can be more clever with our state scheme later
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
module game(turnX, turnO, occ_pos, game_st, reset, clk, flash_clk, sel_pos, buttonX, buttonO);
  output turnX, turn0;
  output occ_pos[8:0];
  output game_st[7:0];

  input reset, clk, flash_clk;
  input sel_pos[8:0];
  input buttonX, buttonO;

  wire occ_square[8:0];
  wire occ_player[8:0];
  wire game_state[3:0];

  wire valid_move;
  check_valid_move cvm (valid_move, occ_square, sel_pos);

  debouncer db_buttonX (buttonX_debounce, buttonX, clk, rst);
  debouncer db_buttonO (buttonO_debounce, buttonO, clk, rst);

  game_st_driver _game_st_driver (game_st, game_state);

  /* asynchronous resets */
  always @ (posedge clk, posedge reset) begin
    if (reset) begin
      occ_square <= 9'b000000000;
      occ_player <= 9'b000000000;
      game_state <= `GAME_ST_START;
    else begin
      if (game_state == `GAME_ST_START) begin
        game_state <= `GAME_ST_TURN_X;
      end else if (game_state == `GAME_ST_TURN_X) begin
        if (buttonX_debounce &valid_move) begin
          occ_square <= (occ_square) | (sel_pos); //mark this square as occupied
          occ_player <= (occ_player) | (sel_pos); //set the selected position to high (X)
        end else if ((buttonX_debounce | buttonO_debounce) & ~valid_move) begin
          game_state == `GAME_ST_ERR_X;
        end else game_state <= game_state;
      end else if (game_state == `GAME_ST_TURN_O) begin
        if (buttonO_debounce &valid_move) begin
          occ_square <= (occ_square) | (sel_pos); //mark this square as occupied
          occ_player <= (occ_player) & (~sel_pos); //set the selected position to low (O)
        end else if ((buttonX_debounce | buttonO_debounce) & ~valid_move) begin
          game_state == `GAME_ST_ERR_O;
        end else game_state <= game_state;
      end else if (game_state == `GAME_ST_ERR_X) begin
        if (buttonX_debounce & valid_move) begin
          occ_square <= (occ_square) | (sel_pos); //mark this square as occupied
          occ_player <= (occ_player) | (sel_pos); //set the selected position to high (X)
        end else game_state <= game_state;
      end else if (game_state == `GAME_ST_ERR_O) begin
        if (buttonO_debounce & valid_move) begin
          occ_square <= (occ_square) | (sel_pos); //mark this square as occupied
          occ_player <= (occ_player) & (~sel_pos); //set the selected position to low (O)
        end else game_state <= game_state;
      end else if (game_state == `GAME_ST_CHECK_X) begin
        if (~valid) game_state == `GAME_ST_ERR_X
        else if (result == `WIN_ST_WINX) game_state <= `GAME_ST_WIN_X;
        else if (result == `WIN_ST_CATS) game_state <= `GAME_ST_CATS;
        else if (result == `WIN_ST_NONE) game_state <= `GAME_ST_TURN_O;
        else game_state <= game_state;
      end else if (game_state == `GAME_ST_CHECK_O) begin
        if (~valid) game_state == `GAME_ST_ERR_O)
        else if (result == `WIN_ST_WINO) game_state <= `GAME_ST_WIN_O;
        else if (result == `WIN_ST_CATS) game_state <= `GAME_ST_CATS;
        else if (result == `WIN_ST_NONE) game_state <= `GAME_ST_TURN_X;
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

  wire result[1:0];
  check_win checker (result, occ_square, occ_player);

endmodule

/* 3 in a row means a winner.
 * No winner with 9 occupied spaces means cat's game.
 * No winner with less than 9 occupied spaces means the game is still going
 */
/* First bit being high ==> there's a winner. If there's a winner, second bit
 * says who */
`define WIN_ST_NONE 2'd0
`define WIN_ST_CATS 2'd1
`define WIN_ST_WIN0 2'd2
`define WIN_ST_WINX 2'd3
module check_win(result, occ_square, occ_player);
  output result[1:0]; //output state
  input occ_square[8:0]; //is there an X or O here?
  input occ_player[8:0]; //if so, which one is it.

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
  wire trey_winner[7:0];
  wire trey_player[7:0];
  check_trey col0 (trey_winner[0], trey_player[0], {occ_square[8], occ_square[5], occ_square[2]}, {occ_player[8], occ_player[5], occ_player[2]});
  check_trey col1 (trey_winner[1], trey_player[1], {occ_square[7], occ_square[4], occ_square[1]}, {occ_player[7], occ_player[4], occ_player[1]});
  check_trey col2 (trey_winner[2], trey_player[2], {occ_square[6], occ_square[3], occ_square[0]}, {occ_player[6], occ_player[3], occ_player[0]});
  check_trey row0 (trey_winner[3], trey_player[3], {occ_square[8], occ_square[7], occ_square[6]}, {occ_player[8], occ_player[7], occ_player[6]});
  check_trey row1 (trey_winner[4], trey_player[4], {occ_square[5], occ_square[4], occ_square[3]}, {occ_player[5], occ_player[4], occ_player[3]});
  check_trey row2 (trey_winner[5], trey_player[5], {occ_square[2], occ_square[1], occ_square[0]}, {occ_player[2], occ_player[1], occ_player[0]});
  check_trey dag0 (trey_winner[6], trey_player[6], {occ_square[8], occ_square[4], occ_square[0]}, {occ_player[8], occ_player[4], occ_player[0]});
  check_trey dag1 (trey_winner[7], trey_player[7], {occ_square[6], occ_square[4], occ_square[2]}, {occ_player[6], occ_player[4], occ_player[2]});

  assign wire isWinner = (& trey_winner);
  assign wire winningPlayer = (| trey_player);

  always @(*) begin
    if (isWinner) begin
      result <= {isWinner, winningPlayer};
    end else if (& occ_square) begin
      result <= `WIN_ST_CATS;
    end else begin
      result <= `WIN_ST_NONE;
    end
  end
endmodule

/* checks 3 inline squares (row/column/diagonal) (a.k.a. a "trey") to see if
 * a victory has been scored across them */
module check_trey(win, player, occ_square, occ_player);
  output win; //was there a winner in this trey?
  output player; //who won?
  input occ_square[2:0]; // is there an X or an O in this spot
  input occ_player[2:0]; // if so, which one is it

  /* Is the same player in all squares of this trey? */
  //assign samePlayer = (occ_player[0] == occ_player[1]) & (occ_player[0] == occ_player[2]);
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

  input occ_square[8:0];
  input sel_pos[8:0];
  input game_state[3:0];

  /* Only place a tile in an unoccupied square */
  assign wire isUnoccupied = (occ_square & sel_pos) == 9'b000000000;

  /* Only place 1 tile at a time */
  assign wire isOneHot = sel_pos[0] + sel_pos[1] + sel_pos[2] + sel_pos[3] + sel_pos[4] + sel_pos[5] + sel_pos[6] + sel_pos[7] + sel_pos[8]) == 4'b0001;

  assign valid = isUnoccupied & isOneHot;
endmodule

`define ASCII_X 7'b01011000
`define ASCII_O 7'b01001111
`define ASCII_C 7'b01000011
`define ASCII_E 7'b01000101
`define ASCII_NONE 7'b01101110
/* Driver between internal game state and ASCII output */
module game_st_driver (game_st, game_state);
  output game_st[7:0];
  input game_state[3:0];
  always @(*) begin
    case (game_state)
      `GAME_ST_WIN_X: game_st <= `ASCII_X;
      `GAME_ST_WIN_O: game_st <= `ASCII_O;
      `GAME_ST_CATS: game_st <= `ASCII_C;
      `GAME_ST_ERR_X,
      `GAME_ST_ERR_O: game_st <= `ASCII_E;
      default: game_st <= `ASCII_NONE;
    endcase
  end
endmodule

module occ_pos_driver (occ_pos, occ_square, occ_player, trey_winner, flash_clk, rst);
  output occ_pos[8:0];
  input occ_square[8:0];
  input occ_player[8:0];
  input trey_winner[7:0];
  input rst;
  input flash_clk;

  /* a mask that gets applied to occ_player at a rate of 1/2 flash_clk */
  reg occ_O_mask[8:0];

  always @(posedge flash_clk) begin
    if (rst) occ_O_mask = 9'b000000000;
    else occ_O_mask = ~occ_O_mask;
  end

  wire pre_occ_pos[8:0];
  assign pre_occ_pos = occ_square & (occ_player | occ_O_mask);
  /* Each occ_pos signal is 1'b0 to indicate unoccupied
   * 1'b1 to indicate occupied by X
   * flashing 1'b1 at a rate of ½ flash_clk to indicate occupied by O */
  /* Only for occupied tiles, display high for all the X's, and only display
   * high for the Os when occ_O_mask is high */

  wire flash_clk_mask[8:0];
  assign wire flash_clk_mask = {flash_clk, flash_clk, flash_clk, flash_clk, flash_clk, flash_clk, flash_clk, flash_clk, flash_clk};

  reg trey_mask[8:0];
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

/* TODO, do we wanna debounce, or do we wanna only detect posedge... */
module debouncer (btn_posedge, btn, clk_in, rst);
  parameter POW = 16; /* downsample the clock by 2^POW */
  output reg btn_posedge;
  input btn, clk_in, rst;

  reg clk_en, clk_en_d; /* slower clocks - downsampled */
  reg [2:0] step_d;		/* state of button press - stepd[2] is most recent */
  reg [POW:0] clk_dv;	/* counter buffer to divide the clock */
  wire [POW+1:0] clk_dv_inc;	/* counter buffer with overflow - used to pulse downsampled clock */

  assign clk_dv_inc = clk_dv + 1;
  always @ (posedge clk_in) begin
    if (rst) begin
      clk_dv <= 0;
      clk_en <= 0;
      clk_en_d <= 0;
    end else begin
      clk_dv <= clk_dv_inc[POW:0]; /* increment counter */
      clk_en <= clk_dv_inc[POW+1]; /* the overflow bit in the counter IS the clock tick - simply downsample by a factor of 2 */
      clk_en_d <= clk_en; /* delay this downsampled clock by 1 tick */
    end
  end

  always @ (posedge clk_in) begin
    if (rst) step_d[2:0] <= 0;
    else if (clk_en) step_d[2:0] <= {btn, step_d[2:1]};
  end

  // Detecting posedge of btn
  wire is_btn_posedge;
  assign is_btn_posedge = ~ step_d[0] & step_d[1];
  always @ (posedge clk_in) begin
    if (rst) btn_posedge <= 0;
    else if (clk_en_d) btn_posedge <= is_btn_posedge;
    else btn_posedge <= 0;
  end

endmodule

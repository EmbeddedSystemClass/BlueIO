module BG_UART(
	output	[31 : 0] bluetile_request_DOUT,
	output		bluetile_request_valid,
	input		bluetile_request_accept,
	input	[31 : 0] bluetile_response_DIN,
	output		bluetile_response_canaccept,
	input		bluetile_response_commit,
	input		CLK,
	input		RST_N);
mkBG_UART inner(
	.EN_bluetile_request_get(bluetile_request_accept),
	.bluetile_request_get(bluetile_request_DOUT),
	.RDY_bluetile_request_get(bluetile_request_valid),
	.bluetile_response_put(bluetile_response_DIN),
	.EN_bluetile_response_put(bluetile_response_commit),
	.RDY_bluetile_response_put(bluetile_response_canaccept),

	.CLK(CLK),
	.RST_N(RST_N)
);

endmodule

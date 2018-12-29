module maze(clk,start,change_map,direction1,direction2,direction3,direction4,digit_seg0,digit_con,r_col,g_col,row);
	input clk;	//时钟信号
	input start;	//开始按键（复位按键）
	input change_map;	//切换地图
	input direction1;	//控制小绿点的移动方向，分别为上、下、左、右
	input direction2;
	input direction3;
	input direction4;


	output [7:0] digit_seg0;	//数码管
	output [7:0] digit_con;		//数码管选位控制
	output [7:0] r_col;		//红色点阵
	output [7:0] g_col;		//绿色点阵
	output [7:0] row;		//点阵行数选择器

	wire [4:0] time_sign;
	wire suc;
	wire [6:0] step_cnt;
	wire [3:0] one;
	wire [3:0] ten;
	reg rst1=1'b0;
	wire rst;
	assign rst=rst1;
	countdown l3(.clk(clk),.but(start),.time1(time_sign),.ten(ten),.one(one),.suc(suc));
	lattice_on l1(.clk(clk),.rst(rst),.start(start),.change_map(change_map),.direction1(direction1),.direction2(direction2),.direction3(direction3),.direction4(direction4),.time_sign(time_sign),.row(row),.g_col(g_col),.r_col(r_col),.suc(suc),.step_cnt(step_cnt));
	digit_tube l2(.clk(clk),.start(start),.change_map(change_map),.time_sign(time_sign),.step_cnt(step_cnt),.digit_con(digit_con),.digit_seg0(digit_seg0));

endmodule


//数码管显示模块
module lattice_on(clk,rst,start,change_map,direction1,direction2,direction3,direction4,time_sign,row,g_col,r_col,suc,step_cnt);
	input clk;
	input start;
	input rst;
	input change_map;
	input direction1;
	input direction2;
	input direction3;
	input direction4;
	input [4:0] time_sign;

	output reg [7:0] row;
	output reg [7:0] g_col;
	output reg [7:0] r_col;
	output reg suc=1'b0;	//判断小绿点是否到达终点
	output reg [6:0] step_cnt=7'b000_0000;		//计步器
	reg [7:0] map_row [7:0];	//地图信息
	reg [7:0] map_row_1 [7:0];		//第一张地图信息
	reg [7:0] map_row_2 [7:0];		//第二张地图信息

	//地图信息初始化
	initial
	begin
	map_row_1[0]=8'b1111_1000;
	map_row_1[1]=8'b1000_0011;
	map_row_1[2]=8'b1011_1111;
	map_row_1[3]=8'b1010_0001;
	map_row_1[4]=8'b1000_1101;
	map_row_1[5]=8'b1111_1101;
	map_row_1[6]=8'b0000_0001;
	map_row_1[7]=8'b1111_1111;

	map_row_2[0]=8'b1111_1111;
	map_row_2[1]=8'b0001_1100;
	map_row_2[2]=8'b1100_0101;
	map_row_2[3]=8'b0101_0101;
	map_row_2[4]=8'b0101_0101;
	map_row_2[5]=8'b0101_1101;
	map_row_2[6]=8'b0100_0001;
	map_row_2[7]=8'b0111_1111;
	
	end

	reg [2:0] start_point_col;	//起始点行数信息
	reg [2:0] start_point_row;	//起点列数信息
	reg [2:0] terminal_point_row;	//终点信息
	reg [7:0] terminal_point_col;	
	reg [7:0] start_point_1=6'b110_111;
	reg [5:0] terminal_point_1=6'b000_000;
	reg [5:0] start_point_2=6'b001_000;
	reg [5:0] terminal_point_2=6'b001_111;

	reg [2:0] location_row_num;		//小绿点位置信息
	reg [2:0] location_col_num;


	wire [2:0] maze_con;  //三位信息分别代表开始，切换地图，以及切换模式
	reg start_con=1'b0;
	reg map_con=1'b0;
	reg mode_con=1'b0;

	assign maze_con = {mode_con,map_con,start_con};

	wire start_lock;
	wire change_map_lock;
	sw a1(.clk(clk),.key_in(start),.key_out(start_lock));	//start按键消抖（好像没什么必要）
	sw a2(.clk(clk),.key_in(change_map),.key_out(change_map_lock));		//change_map按键消抖

	always @(posedge start_lock) begin    
		if(start_lock==1) begin
			start_con<=1'b1;
		end
	end

	always @(change_map_lock) begin
		if(change_map_lock==1) begin
			map_con<=1'b1;
		end
		else begin
			map_con<=1'b0;
		end
	end

	always @(posedge clk) begin      //由map_con的值决定map_row的取值，即地图信息及起点、终点位置信息
		if(map_con==0) begin
			map_row[0]=map_row_1[0];
			map_row[1]=map_row_1[1];
			map_row[2]=map_row_1[2];
			map_row[3]=map_row_1[3];
			map_row[4]=map_row_1[4];
			map_row[5]=map_row_1[5];
			map_row[6]=map_row_1[6];
			map_row[7]=map_row_1[7];
			start_point_row=start_point_1[5:3];
			start_point_col=start_point_1[2:0];
			terminal_point_row=terminal_point_1[5:3];
			terminal_point_col=terminal_point_1[2:0];
		end
		else if(map_con==1)begin
			map_row[0]=map_row_2[0];
			map_row[1]=map_row_2[1];
			map_row[2]=map_row_2[2];
			map_row[3]=map_row_2[3];
			map_row[4]=map_row_2[4];
			map_row[5]=map_row_2[5];
			map_row[6]=map_row_2[6];
			map_row[7]=map_row_2[7];
			start_point_row=start_point_2[5:3];
			start_point_col=start_point_2[2:0];
			terminal_point_row=terminal_point_2[5:3];
			terminal_point_col=terminal_point_2[2:0];
		end
	end

	wire direction_lock1;
	wire direction_lock2;
	wire direction_lock3;
	wire direction_lock4;

	//方向控制键按键消抖
	debounce c1(clk,~rst,direction1,direction2,direction3,direction4,direction_lock1,direction_lock2,direction_lock3,direction_lock4);
	
	//sw c1(.clk(clk),.key_in(direction1),.key_out(direction_lock1));
	//sw c2(.clk(clk),.key_in(direction2),.key_out(direction_lock2));
	//sw c3(.clk(clk),.key_in(direction3),.key_out(direction_lock3));
	//sw c4(.clk(clk),.key_in(direction4),.key_out(direction_lock4));

	always @(posedge clk) 
	begin
	if(start_lock==1) begin        //按下start键后，计步器归零，小绿点回到起始位置
		step_cnt<=7'b0000000;
		location_row_num=start_point_row;
		location_col_num=start_point_col;
	end
	
		if(location_row_num!=terminal_point_row||location_col_num!=terminal_point_col)      //小绿点移动及判断
		begin
			if(direction_lock1&&location_row_num<7)		//按下向上键，并且小绿点的行数小于7时，执行系列操作
			
				begin
							if(map_row[location_row_num+1][location_col_num]==0)		//当小绿点的上方为‘0’，即小绿点上方没有墙时，小绿点向上移动一个，并且计步器加1
							begin
								step_cnt<=step_cnt+1;
								location_row_num=location_row_num+1;
							end
							else begin
								location_col_num=location_col_num;
								location_row_num=location_row_num;
							end
					end
				if(direction_lock2&&location_row_num>0)
					begin
						if(map_row[location_row_num-1][location_col_num]==0) begin
								step_cnt<=step_cnt+1;
								location_row_num=location_row_num-1;
								end
								else begin
									location_row_num=location_row_num;
									location_col_num=location_col_num;
								end
					end
				if(direction_lock3&&location_col_num>0)
			
					begin
						if(map_row[location_row_num][location_col_num-1]==0)
						begin
								step_cnt<=step_cnt+1;
								location_col_num=location_col_num-1;
							end
							else begin
								location_col_num=location_col_num;
								location_row_num=location_row_num;
							end
					end
				if(direction_lock4&&location_col_num<7)
					begin
							if(map_row[location_row_num][location_col_num+1]==0)
							begin
								step_cnt<=step_cnt+1;
								location_col_num=location_col_num+1;
							end
							else begin
								location_row_num=location_row_num;
								location_col_num=location_col_num;
							end
					end
		end


end

	//当小绿点到达终点后，成功
	always @(posedge clk) begin
	if((location_row_num==terminal_point_row)&&(location_col_num==terminal_point_col)) begin
			suc<=1'b1;
		end
	else
		suc<=1'b0;
	end

	reg [31:0] count=32'd0;
	reg clk_1kHz;

	always @(posedge clk) begin  //1k频率的时钟
		if(count==50000) begin
			count<=32'd0;
			clk_1kHz<=~clk_1kHz;
		end
		else begin
			count<=count+1;
		end
	end

	//点阵行数控制器，采用1kHz的频率动态扫描点阵
	reg [3:0] row_num=4'b0000; 
	
	always @(posedge clk_1kHz) begin
	if(row_num!=4'b0111) begin
		row_num<=row_num+1;
	end
	else row_num<=4'b0000;
	end

	//当扫描到不同的行时，给点阵选行器赋予相应的值
	always @(posedge clk_1kHz) begin
	case(row_num)
	4'h0: begin
		row<=8'b1111_1110;
	end
	4'h1: begin
		row<=8'b1111_1101;
	end
	4'h2: begin
		row<=8'b1111_1011;
	end
	4'h3: begin
		row<=8'b1111_0111;
	end
	4'h4: begin
		row<=8'b1110_1111;
	end
	4'h5: begin
		row<=8'b1101_1111;
	end
	4'h6: begin
		row<=8'b1011_1111;
	end
	4'h7: begin
		row<=8'b0111_1111;
	end
	endcase
	end


	always @(posedge clk_1kHz) begin
		if(start_con==0) begin   	//当没有按下start键时，点阵不显示
			r_col<=8'b000_0000;
			g_col<=8'b000_0000;
		end
		else if(start_con==1&&time_sign!=0&&suc==0) begin 		//当倒计时没有结束，小绿点没有到达终点，点阵显示
			case(row_num)
			4'd0:r_col<=map_row[0];
			4'd1:r_col<=map_row[1];
			4'd2:r_col<=map_row[2];
			4'd3:r_col<=map_row[3];
			4'd4:r_col<=map_row[4];
			4'd5:r_col<=map_row[5];
			4'd6:r_col<=map_row[6];
			4'd7:r_col<=map_row[7];
		endcase
		if(row_num==location_row_num) begin
			case(location_col_num)
				3'd0:g_col<=8'b0000_0001;
				3'd1:g_col<=8'b0000_0010;
				3'd2:g_col<=8'b0000_0100;
				3'd3:g_col<=8'b0000_1000;
				3'd4:g_col<=8'b0001_0000;
				3'd5:g_col<=8'b0010_0000;
				3'd6:g_col<=8'b0100_0000;
				3'd7:g_col<=8'b1000_0000;
			endcase
		end
		if((row_num)!=location_row_num)
		begin
			g_col<=8'b0000_0000;
		end
		end
		else if(start_con==1&&time_sign==0&&suc==0) begin 		//倒计时结束时的哭脸显示
			case(row_num)
				4'd0:r_col<=8'b0000_0000;
				4'd1:r_col<=8'b0100_0010;
				4'd2:r_col<=8'b0011_1100;
				4'd3:r_col<=8'b0000_0000;
				4'd4:r_col<=8'b0110_0110;
				4'd5:r_col<=8'b0110_0110;
				4'd6:r_col<=8'b0000_0000;
				4'd7:r_col<=8'b0000_0000;
			endcase
			g_col<=8'b0000_0000;
		end
		else if(start_con==1&&time_sign!=0&&suc==1) begin 		//小绿点到达终点的绿色笑脸显示
			case(row_num)
				4'd0:g_col<=8'b0000_0000;
				4'd1:g_col<=8'b0011_1100;
				4'd2:g_col<=8'b0100_0010;
				4'd3:g_col<=8'b0000_0000;
				4'd4:g_col<=8'b0110_0110;
				4'd5:g_col<=8'b0110_0110;
				4'd6:g_col<=8'b0000_0000;
				4'd7:g_col<=8'b0000_0000;
			endcase
			r_col<=8'b0000_0000;
		end
	end

endmodule



//数码管显示模块
module digit_tube(clk,start,change_map,time_sign,step_cnt,digit_con,digit_seg0);
	input clk;
	input start;
	input change_map;
	input [4:0] time_sign; 		//倒计时所剩时间
	input [6:0] step_cnt; 	 	//计步器

	output reg [7:0] digit_con;
	output reg [7:0] digit_seg0;

	wire [3:0] ten;
	wire [3:0] one;
	reg [3:0] ten_step;
	reg [3:0] one_step;
	//将时间信号二进制数转化为十进制
	two_ten t1(.clk(clk),.num(time_sign),.ten(ten),.one(one));
	
	//将步数的二进制数转化为十进制
	integer i;
	
			always @(posedge clk)
			begin
				ten_step=4'd0;
				one_step=4'd0;
		
				for(i=6;i>=0;i=i-1)
				begin
					if(ten_step>4)
						ten_step=ten_step+4'd3;
					if(one_step>4)
						one_step=one_step+4'd3;
					ten_step=ten_step<<1;
					ten_step[0]=one_step[3];
					one_step=one_step<<1;
					one_step[0]=step_cnt[i];
				end
			end

	reg [31:0] count=32'd0;
	reg clk_1kHz;

	always @(posedge clk) begin  //1k频率的时钟
		if(count==50000) begin
			count<=32'd0;
			clk_1kHz<=~clk_1kHz;
		end
		else begin
			count<=count+1;
		end
	end

	reg [3:0] row_num=4'b0000; 
	

	//与点阵显示模块中的选行控制器相同，这里做数码管选位控制器
	always @(posedge clk_1kHz) begin
	if(row_num!=4'b0111) begin
		row_num<=row_num+1;
	end
	else row_num<=4'b0000;
	end

	always @(posedge clk_1kHz) begin
	case(row_num)
	4'h0: begin
		digit_con<=8'b1111_1110;
	end
	4'h1: begin
		digit_con<=8'b1111_1101;
	end
	4'h2: begin
		digit_con<=8'b1111_1011;
	end
	4'h3: begin
		digit_con<=8'b1111_0111;
	end
	4'h4: begin
		digit_con<=8'b1110_1111;
	end
	4'h5: begin
		digit_con<=8'b1101_1111;
	end
	4'h6: begin
		digit_con<=8'b1011_1111;
	end
	4'h7: begin
		digit_con<=8'b0111_1111;
	end
	endcase
end

	always @(posedge clk_1kHz) begin
		
	end

	wire [2:0] maze_con;  //三位信息分别代表开始，切换地图，以及切换模式
	reg start_con=1'b0;
	reg map_con=1'b0;
	reg mode_con=1'b0;

	assign maze_con = {mode_con,map_con,start_con};

	wire start_lock;
	wire change_map_lock;

	//start、change_map键的消抖
	sw b1(.clk(clk),.key_in(start),.key_out(start_lock));
	sw b2(.clk(clk),.key_in(change_map),.key_out(change_map_lock));

	always @(posedge start_lock) begin
		if(start_lock==1) begin
			start_con<=1'b1;
		end
	end

	always @(change_map_lock) begin
		if(change_map_lock==0) begin
			map_con<=1'b0;
		end
		else begin
			map_con<=1'b1;
		end
	end

	always @(posedge clk_1kHz) begin
		if(start_con==0) begin 		//初始状态，数码管不显示
			digit_seg0<=8'b0000_0000;
		end
		if(start_con==1) begin
		if(row_num==1) begin 		//扫描到1号数码管，显示倒计时的十位
			case(ten)
			4'd0:digit_seg0<=8'b11111100;
			4'd1:digit_seg0<=8'b01100000;
			4'd2:digit_seg0<=8'b11011010;	
			4'd3:digit_seg0<=8'b11110010;
			4'd4:digit_seg0<=8'b01100110;
			4'd5:digit_seg0<=8'b10110110;
			4'd6:digit_seg0<=8'b10111110;
			4'd7:digit_seg0<=8'b11100000;
			4'd8:digit_seg0<=8'b11111110;
			4'd9:digit_seg0<=8'b11110110;
		endcase
		end
		if(row_num==0) begin 		//扫描到0号数码管，显示倒计时的个位
		case(one)
			4'd0:digit_seg0<=8'b11111100;
			4'd1:digit_seg0<=8'b01100000;
			4'd2:digit_seg0<=8'b11011010;	
			4'd3:digit_seg0<=8'b11110010;
			4'd4:digit_seg0<=8'b01100110;
			4'd5:digit_seg0<=8'b10110110;
			4'd6:digit_seg0<=8'b10111110;
			4'd7:digit_seg0<=8'b11100000;
			4'd8:digit_seg0<=8'b11111110;
			4'd9:digit_seg0<=8'b11110110;
		endcase
		end
		if(row_num==2||row_num==3||row_num==4||row_num==5) begin 		//其余位数码管不显示
			digit_seg0<=8'b0000_0000;
		end
		if(row_num==6) begin 		//扫描到6号数码管，显示计步器的个位
		case(one_step)
			4'd0:digit_seg0<=8'b11111100;
			4'd1:digit_seg0<=8'b01100000;
			4'd2:digit_seg0<=8'b11011010;	
			4'd3:digit_seg0<=8'b11110010;
			4'd4:digit_seg0<=8'b01100110;
			4'd5:digit_seg0<=8'b10110110;
			4'd6:digit_seg0<=8'b10111110;
			4'd7:digit_seg0<=8'b11100000;
			4'd8:digit_seg0<=8'b11111110;
			4'd9:digit_seg0<=8'b11110110;
		endcase
		end
		if(row_num==7) begin 		//扫描到7号数码管，显示计步器的十位
			case(ten_step)
			4'd0:digit_seg0<=8'b11111100;
			4'd1:digit_seg0<=8'b01100000;
			4'd2:digit_seg0<=8'b11011010;	
			4'd3:digit_seg0<=8'b11110010;
			4'd4:digit_seg0<=8'b01100110;
			4'd5:digit_seg0<=8'b10110110;
			4'd6:digit_seg0<=8'b10111110;
			4'd7:digit_seg0<=8'b11100000;
			4'd8:digit_seg0<=8'b11111110;
			4'd9:digit_seg0<=8'b11110110;
		endcase
		end
		end
	end

endmodule


//倒计时模块
module countdown(clk,but,one,ten,time1,suc);		
		input but;	//复位按键
		input clk;
		input suc;	//小绿点是否到达终点的信息
		output [3:0] ten;
		output [3:0] one;
		output reg[4:0] time1=5'd30;
		reg [31:0] time_count=32'd0;
		
		always @(posedge div_clk or posedge but) begin
			if(but==1) time1<=5'd30;		//按下复位键，重新倒计时
			else time1<=time1-1;
		end
		 reg div_clk;
		always @(posedge clk)
			begin
			if(time1!=0&&suc==0) begin
			if(time_count==25000000)
			begin
				time_count<=32'd0;
				div_clk<=~div_clk;
			end
			else begin
			time_count<=time_count+1;
			end
			end
			end
		
	two_ten t1(.clk(clk),.num(time1),.ten(ten),.one(one));

endmodule				

//二进制转十进制模块
module two_ten(clk,num,ten,one);
input [4:0] num;	//待转的二进制数
input clk;
output reg [3:0] ten;	//转化后的十位
output reg [3:0] one;	//转化后的个位

integer i;
	
			always @(posedge clk)
			begin
				ten=4'd0;
				one=4'd0;
		
				for(i=4;i>=0;i=i-1)
				begin
					if(ten>4)
						ten=ten+4'd3;
					if(one>4)
						one=one+4'd3;
					ten=ten<<1;
					ten[0]=one[3];
					one=one<<1;
					one[0]=num[i];
				end
			end
endmodule

//多个按键消抖模块
module debounce (clk,rst,key[0],key[1],key[2],key[3],key_pulse[0],key_pulse[1],key_pulse[2],key_pulse[3]);
 
        parameter       N  =  4;                      //要消除的按键的数量
 
	input             clk;
        input             rst;
        input 	[N-1:0]   key;             		  //输入的按键					
	output  [N-1:0]   key_pulse;                  //按键动作产生的脉冲	
 
        reg     [N-1:0]   key_rst_pre;                //定义一个寄存器型变量存储上一个触发时的按键值
        reg     [N-1:0]   key_rst;                    //定义一个寄存器变量储存储当前时刻触发的按键值
 
        wire    [N-1:0]   key_edge;                   //检测到按键由高到低变化是产生一个高脉冲
 
        //利用非阻塞赋值特点，将两个时钟触发时按键状态存储在两个寄存器变量中
        always @(posedge clk  or  negedge rst)
          begin
             if (!rst) begin
                 key_rst <= {N{1'b1}};                //初始化时给key_rst赋值全为1，{}中表示N个1
                 key_rst_pre <= {N{1'b1}};
             end
             else begin
                 key_rst <= key;                     //第一个时钟上升沿触发之后key的值赋给key_rst,同时key_rst的值赋给key_rst_pre
                 key_rst_pre <= key_rst;             //非阻塞赋值。相当于经过两个时钟触发，key_rst存储的是当前时刻key的值，key_rst_pre存储的是前一个时钟的key的值
             end    
           end
 
        assign  key_edge = key_rst_pre & (~key_rst);//脉冲边沿检测。当key检测到下降沿时，key_edge产生一个时钟周期的高电平
 
        reg	[19:0]	  cnt;                       //产生延时所用的计数器，系统时钟12MHz，要延时20ms左右时间，至少需要18位计数器     
 
        //产生20ms延时，当检测到key_edge有效是计数器清零开始计数
        always @(posedge clk or negedge rst)
           begin
             if(!rst)
                cnt <= 20'h0;
             else if(key_edge)
                cnt <= 20'h0;
             else
                cnt <= cnt + 1'h1;
             end  
 
        reg     [N-1:0]   key_sec_pre;                //延时后检测电平寄存器变量
        reg     [N-1:0]   key_sec;                    
 
 
        //延时后检测key，如果按键状态变低产生一个时钟的高脉冲。如果按键状态是高的话说明按键无效
        always @(posedge clk  or  negedge rst)
          begin
             if (!rst) 
                 key_sec <= {N{1'b1}};                
             else if (cnt==20'hf_ffff)
                 key_sec <= key;  
          end
          
       always @(posedge clk  or  negedge rst)
          begin
             if (!rst)
                 key_sec_pre <= {N{1'b1}};
             else                   
                 key_sec_pre <= key_sec;             
                 
         end      
       assign  key_pulse = key_sec_pre & (~key_sec);     
 
endmodule

//单个按键消抖模块
module sw(clk,key_in,key_out);
	input key_in;
	input clk;
	output reg key_out;
	reg [19:0]tcnt1;
	
	always @(posedge clk or negedge key_in)
	begin
	if(!key_in)tcnt1<=20'd0;
	else tcnt1<=tcnt1+1;
	end
	always @(posedge clk or negedge key_in)
	begin
	if(!key_in)key_out<=0;
		else if(tcnt1==20'hfffff)key_out<=key_in;
	end
endmodule

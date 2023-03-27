program automatic test(router_io.TB rtr_io);
    bit   [3:0]     sa;//source address          
    bit   [3:0]     da;//destination address
    logic [7:0]     payload[$];//packet data array
    int             run_for_n_packets;//number of packets to test


    initial begin
        $vcdpluson;
        run_for_n_packets = 21;
        reset();
        repeat(run_for_n_packets) begin
            gen();
            send();
        end
        repeat(10)@(rtr_io.cb);
    end

    
    task reset();//define a task called reset to reset the DUT
        rtr_io.reset_n     = 1'b0;//asynchronous reset
        rtr_io.cb.frame_n <= '1;
        rtr_io.cb.valid_n <= '1;
        ##2 rtr_io.cb.reset_n <= 1'b1;//synchronous release 
        repeat(15) @(rtr_io.cb);

    endtask:reset


    task gen();//define the gen task
        sa = 3;
        da = 7;
        payload.delete();//clear previous data
        repeat($urandom_range(4,2))
            payload.push_back($urandom);//fill payload queue with 2 to 4 random bytes
    endtask:gen


    task send();
        send_addrs();
        send_pad();
        send_payload();
    endtask:send


    task send_addrs();
        rtr_io.cb.frame_n[sa] <= 1'b0;//start of packet
        for(int i=0;i<4;i++) begin
            rtr_io.cb.din[sa] <= da[i];
            @(rtr_io.cb);
        end
    endtask:send_addrs


    task send_pad();
        rtr_io.cb.frame_n[sa] <= 1'b0;
        rtr_io.cb.valid_n[sa] <= 1'b1;
        rtr_io.cb.din[sa]     <= 1'b1;
        repeat(5) @(rtr_io.cb);
    endtask:send_pad


    task send_payload();
        foreach(payload[index])
            for(int i=0;i<8;i++) begin
                rtr_io.cb.din[sa] <= payload[index][i];
                rtr_io.cb.valid_n[sa] <= 1'b0;
                rtr_io.cb.frame_n[sa] <= ((i==7)&&(index==(payload.size(-1))));
                @(rtr_io.cb);
            end
        rtr_io.cb.valid_n[sa] <= 1'b1;
    endtask:send_payload

endprogram:test

program automatic test(router_io.TB rtr_io);
    bit   [3:0]     sa;//source address          
    bit   [3:0]     da;//destination address
    logic [7:0]     payload[$];//packet data array
    logic [7:0]     pkt2cmp_payload[$];//actual packet data array
    int             run_for_n_packets;//number of packets to test


    initial begin
        $vcdpluson;
        run_for_n_packets = 1000;
        reset();
        repeat(run_for_n_packets) begin
            gen();
            fork
                send();
                recv();
            join  //execute reiceve routine concurrently with send routine
            check();//followed by check routine
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
        sa = $urandom;
        da = $urandom;
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


    task recv();
        get_payload();
    endtask:recv


    task get_payload();
        pkt2cmp_payload.delete();//clear previous data

        fork
            begin:wd_timer_fork
                fork:frameo_wd_timer
                    @(negedge rtr_io.cb.frameo_n[da]);
                    begin
                    repeat(1000) @(rtr_io.cb);
                        $display("\n%m\n[ERROR]%t Frame signal timed out!\n",$realtime);
                        $finish;
                    end
                join_any:frameo_wd_timer
                disable fork;
            end:wd_timer_fork
        join //a watchdog timer of 1000 clocks

        forever begin
            logic [7:0] datum;

            for(int i=0;i<8;i=i) begin //i=i prevents VCS warning messages
                if(!rtr_io.cb.valido_n[da])
                    datum[i++] = rtr_io.cb.dout[da];
                if(rtr_io.cb.frameo_n[da])
                    if(i==8) begin
                        pkt2cmp_payload.push_back(datum);
                        return;
                    end
                    else begin
                        $display("\n%m\n[ERROR]%t Packet payload not byte aligned!\n",$realtime);
                        $finish;
                    end
                    @(rtr_io.cb);
            end
            pkt2cmp_payload.push_back(datum);
        end
    endtask:get_payload


    function bit compare(ref string message);
        if(payload.size()!=pkt2cmp_payload.size()) begin
            message = "Payload Size Mismatch:\n";
            message = {message,$sformatf("payload.size()=%0d,pkt2cmp_payload.size()=%0d\n",payload.size(),pkt2cmp_payload.size())};
            return(0);
        end
        if(payload==pkt2cmp_payload);
        else begin
            message = "Payload Content Mismatch:\n";
            message = {message,$sformatf("Packet Sent:  %p\nPacket Received:  %p",payload,pkt2cmp_payload)};
            return(0);
        end
        message = "Successfully Compared!";
        return(1);
    endfunction:compare


    task check();
        string message;
        static int pkts_checked = 0;//keep a count of packets checked with variable pkts_checked

        if(!compare(message)) begin
            $display("\n%m\n[ERROR]%t Packet #%0d %s\n",$realtime,pkts_checked,message);
            $finish;
        end
        else
            $display("[NOTE]%t Packet %%0d %s",$realtime,pkts_checked++,message);
    endtask:check

endprogram:test

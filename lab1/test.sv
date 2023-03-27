program automatic test(router_io.TB rtr_io);
    initial begin
        $vcdpluson;
        reset();
    end

    
    task reset();//define a task called reset to reset the DUT
        rtr_io.reset_n     = 1'b0;//asynchronous reset
        rtr_io.cb.frame_n <= '1;
        rtr_io.cb.valid_n <= '1;
        ##2 rtr_io.cb.reset_n <= 1'b1;//synchronous release 
        repeat(15) @(rtr_io.cb);

    endtask:reset

endprogram:test

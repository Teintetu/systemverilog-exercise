program automatic test(router_io.TB rtr_io);
    
import router_test_pkg::*;
    
    Environment env;

    initial begin
        $vcdpluson;

        env = new("env",rtr_io);
        env.configure();
        run_for_n_packets = env.run_for_n_packets;//needed by gen and sb
        env.run();
    end    
                 
endprogram:test

interface router_io(input bit clock);
    logic           reset_n;
    logic  [15:0]   din;
    logic  [15:0]   frame_n;
    logic  [15:0]   valid_n;
    logic  [15:0]   dout;
    logic  [15:0]   frameo_n;
    logic  [15:0]   valido_n;
    logic  [15:0]   busy_n;

    clocking cb @(posedge clock);//Declare a clocking block driven by posedge of signal clock
        default input #1ns output #1ns;

        output reset_n;
        output din;
        output frame_n;
        output valid_n;

        input  dout;
        input  frameo_n;
        input  valido_n;
        input  busy_n;
    endclocking:cb

    modport TB(clocking cb,output reset_n);//add a modport to connect to test program
endinterface    
    

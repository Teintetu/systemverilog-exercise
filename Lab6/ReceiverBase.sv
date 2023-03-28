`ifndef INC_RECEIVERBASE_SV
`define INC_RECEIVERBASE_SV

class ReceiverBase;
    virtual router_io.TB rtr_io;
    string               name;
    bit     [3:0]        da;
    logic   [7:0]        pkt2cmp_payload[$];
    Packet               pkt2cmp;

    extern function new(string name = "Receiver",virtual router_io.TB rtr_io);
    extern virtual task recv();
    extern virtual task get_payload();
endclass


function ReceiverBase::new(string name,virtual router_io.TB rtr_io);
    if(TRACE_ON) $display("[TRACE]%t %s:%m",$realtime,name);
    this.name = name;
    this.rtr_io = rtr_io;
    this.pkt2cmp = new();
endfunction


task ReceiverBase::recv();
    if(TRACE_ON) $display("[TRACE]%t %s:%m",$realtime,this.name);
    static int pkt_cnt = 0;
    this.get_payload();
    this.pkt2cmp.da = da;
    this.pkt2cmp.payload = pkt2cmp_payload;
    this.pkt2cmp.name = $sformatf("rcvdPkt[%0d]",pkt_cnt++);
endtask


task ReceiverBase::get_payload();
    if(TRACE_ON) $display("[TRACE]%t %s:%m",$realtime,this.name);
    this.pkt2cmp_payload.delete();//clear previous data
    fork
        begin:wd_timer_fork
        fork:frameo_wd_timer
            @(negedge this.rtr_io.cb.frameo_n[da]);
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
            if(!this.rtr_io.cb.valido_n[da])
                datum[i++] = this.rtr_io.cb.dout[da];
                if(this.rtr_io.cb.frameo_n[da])
                    if(i==8) begin
                        this.pkt2cmp_payload.push_back(datum);
                        return;
                    end
                    else begin
                        $display("\n%m\n[ERROR]%t Packet payload not byte aligned!\n",$realtime);
                        $finish;
                    end
                    @(this.rtr_io.cb);
        end
        this.pkt2cmp_payload.push_back(datum);
    end
endtask  
`endif

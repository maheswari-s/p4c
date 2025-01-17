#include <core.p4>
#define V1MODEL_VERSION 20200408
#include <v1model.p4>

struct intrinsic_metadata_t {
    bit<4> mcast_grp;
    bit<4> egress_rid;
}

struct meta_t {
    bit<32> register_tmp;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct metadata {
    bit<32> _meta_register_tmp0;
}

struct headers {
    @name(".ethernet") 
    ethernet_t ethernet;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

@name(".my_indirect_counter") counter<bit<14>>(32w16384, CounterType.packets) my_indirect_counter;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @noWarn("unused") @name(".NoAction") action NoAction_0() {
    }
    @name(".my_direct_counter") direct_counter(CounterType.bytes) my_direct_counter_0;
    @name(".m_action") action m_action_0(@name("idx") bit<14> idx) {
        my_direct_counter_0.count();
        my_indirect_counter.count(idx);
        mark_to_drop(standard_metadata);
    }
    @name("._nop") action _nop_0() {
        my_direct_counter_0.count();
    }
    @name(".m_table") table m_table_0 {
        actions = {
            m_action_0();
            _nop_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.ethernet.srcAddr: exact @name("ethernet.srcAddr") ;
        }
        size = 16384;
        counters = my_direct_counter_0;
        default_action = NoAction_0();
    }
    apply {
        m_table_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;


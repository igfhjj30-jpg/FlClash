package com.follow.clash.service.models

data class PacketTunnelOptions(
    val privateKey: String,
    val publicKey: String,
    val preSharedKey: String = "",
    val endpoint: String,
    val addresses: List<String>,
    val dns: List<String>,
    val mtu: Int = 1280,
    val persistentKeepalive: Int = 25,
    val transportProxy: String,
) {
    fun validate() {
        require(validKey(privateKey) && validKey(publicKey)) { "Invalid WireGuard key" }
        require(preSharedKey.isEmpty() || validKey(preSharedKey)) { "Invalid WireGuard key" }
        val parts = endpoint.split(':')
        require(parts.size == 2 && isIpv4(parts[0]) && parts[1].toIntOrNull() in 1..65535) {
            "The WireGuard endpoint must be an IPv4 address and port"
        }
        require(addresses.isNotEmpty() && addresses.all {
            val cidr = it.split('/')
            cidr.size == 2 && isIpv4(cidr[0]) && cidr[1].toIntOrNull() in 1..32
        }) { "A WireGuard IPv4 interface address is required" }
        require(dns.isNotEmpty() && dns.all(::isIpv4)) { "IPv4 DNS servers are required" }
        require(mtu in 1280..1420 && persistentKeepalive in 0..65535) { "Invalid WireGuard parameters" }
        require(transportProxy.isNotBlank()) { "A transport proxy is required" }
    }

    override fun toString(): String = "PacketTunnelOptions(endpoint=$endpoint, transportProxy=$transportProxy)"

    companion object {
        private val keyPattern = Regex("^[A-Za-z0-9+/]{43}=$")

        private fun validKey(value: String): Boolean =
            keyPattern.matches(value) && value != "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

        private fun isIpv4(value: String): Boolean {
            val parts = value.split('.')
            return parts.size == 4 && parts.all {
                it.isNotEmpty() && it.length <= 3 && it.all(Char::isDigit) && it.toIntOrNull() in 0..255
            }
        }
    }
}

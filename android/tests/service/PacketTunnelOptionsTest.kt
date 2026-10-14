package com.follow.clash.service

import com.follow.clash.service.models.PacketTunnelOptions
import org.junit.Assert.assertFalse
import org.junit.Assert.assertThrows
import org.junit.Test

class PacketTunnelOptionsTest {
    private val key = "AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE="
    private fun options() = PacketTunnelOptions(
        privateKey = key,
        publicKey = key,
        endpoint = "192.0.2.1:51823",
        addresses = listOf("10.204.32.2/32"),
        dns = listOf("1.1.1.1"),
        transportProxy = "test-carrier",
    )

    @Test
    fun acceptsNumericTunnelConfigurationWithoutLoggingKeys() {
        options().validate()
        assertFalse(options().toString().contains(key))
    }

    @Test
    fun rejectsConfigurationsThatCannotCaptureAndResolveTraffic() {
        listOf(
            options().copy(addresses = emptyList()),
            options().copy(addresses = listOf("example.invalid/32")),
            options().copy(dns = listOf("2606:4700:4700::1111")),
            options().copy(endpoint = "example.invalid:51823"),
            options().copy(endpoint = "192.0.2.1:65536"),
            options().copy(transportProxy = ""),
            options().copy(mtu = 9000),
            options().copy(privateKey = "do-not-log-this"),
        ).forEach { invalid ->
            assertThrows(IllegalArgumentException::class.java) { invalid.validate() }
        }
    }
}

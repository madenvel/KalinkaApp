import 'dart:io';
import 'package:logger/logger.dart';

class NetworkUtils {
  static final Logger _logger = Logger();

  /// Get all local network interfaces and their IP addresses
  static Future<List<InternetAddress>> getLocalNetworkAddresses() async {
    final List<InternetAddress> localAddresses = [];

    try {
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
            localAddresses.add(address);
            _logger.d(
                'Found local network interface: ${interface.name} - ${address.address}');
          }
        }
      }
    } catch (e) {
      _logger.e('Error getting network interfaces: $e');
    }

    return localAddresses;
  }

  /// Check if two IP addresses are in the same subnet
  /// Assumes /24 subnet mask (255.255.255.0)
  static bool areInSameSubnet(String ip1, String ip2,
      {String subnetMask = '255.255.255.0'}) {
    try {
      final addr1 = InternetAddress(ip1);
      final addr2 = InternetAddress(ip2);

      if (addr1.type != InternetAddressType.IPv4 ||
          addr2.type != InternetAddressType.IPv4) {
        return false;
      }

      final ip1Parts = ip1.split('.').map(int.parse).toList();
      final ip2Parts = ip2.split('.').map(int.parse).toList();
      final maskParts = subnetMask.split('.').map(int.parse).toList();

      for (int i = 0; i < 4; i++) {
        if ((ip1Parts[i] & maskParts[i]) != (ip2Parts[i] & maskParts[i])) {
          return false;
        }
      }

      return true;
    } catch (e) {
      _logger.w('Error comparing IP addresses $ip1 and $ip2: $e');
      return false;
    }
  }

  /// Find the best IP address for a service based on local network interfaces
  /// This method would need to be extended if bonsoir provided multiple IPs
  /// For now, it validates that the service IP is reachable from local networks
  static Future<String?> findBestServiceAddress(String serviceHost) async {
    final localAddresses = await getLocalNetworkAddresses();

    _logger.d('Checking service host: $serviceHost against local networks');

    // Check if the service host is in the same subnet as any local interface
    for (final localAddr in localAddresses) {
      if (areInSameSubnet(serviceHost, localAddr.address)) {
        _logger.i(
            'Service $serviceHost is in same subnet as ${localAddr.address}');
        return serviceHost;
      }
    }

    _logger.w(
        'Service $serviceHost is not in the same subnet as any local interface');

    // If not in same subnet, still return the service host but log the issue
    // This might happen in complex network setups
    return serviceHost;
  }

  /// Get a list of possible service addresses if multiple were available
  /// This is a placeholder for when bonsoir might provide multiple IPs
  static Future<String?> selectBestAddress(
      List<String> candidateAddresses) async {
    if (candidateAddresses.isEmpty) return null;
    if (candidateAddresses.length == 1) return candidateAddresses.first;

    final localAddresses = await getLocalNetworkAddresses();

    // Try to find an address in the same subnet as a local interface
    for (final candidate in candidateAddresses) {
      for (final localAddr in localAddresses) {
        if (areInSameSubnet(candidate, localAddr.address)) {
          _logger.i(
              'Selected $candidate as it matches local subnet ${localAddr.address}');
          return candidate;
        }
      }
    }

    // If no exact subnet match, return the first address
    _logger.w(
        'No subnet match found, using first address: ${candidateAddresses.first}');
    return candidateAddresses.first;
  }
}

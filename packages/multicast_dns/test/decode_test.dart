// Copyright (c) 2015, the Dartino project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';
import 'package:multicast_dns/src/packet.dart';
import 'package:multicast_dns/src/resource_record.dart';

const int _kSrvHeaderSize = 6;

void main() {
  testValidPackages();
  testBadPackages();
  // testHexDumpList();
  testPTRRData();
  testSRVRData();
}

void testValidPackages() {
  test('Can decode valid packets', () {
    List<ResourceRecord> result = decodeMDnsResponse(package1);
    expect(1, result.length);
    IPAddressResourceRecord ipResult = result[0];
    expect(ipResult.name, 'raspberrypi.local');
    expect(ipResult.address.address, '192.168.1.191');

    result = decodeMDnsResponse(package2);
    expect(result.length, 2);
    ipResult = result[0];
    expect(ipResult.name, 'raspberrypi.local');
    expect(ipResult.address.address, '192.168.1.191');
    ipResult = result[1];
    expect(ipResult.name, 'raspberrypi.local');
    expect(ipResult.address.address, '169.254.95.83');

    result = decodeMDnsResponse(package3);
    expect(result.length, 8);
    expect(result, <ResourceRecord>[
      TxtResourceRecord(
        'raspberrypi [b8:27:eb:03:92:4b]._workstation._tcp.local',
        result[0].validUntil,
        text: '\x00',
      ),
      PtrResourceRecord(
        '_udisks-ssh._tcp.local',
        result[1].validUntil,
        domainName: 'raspberrypi._udisks-ssh._tcp.local',
      ),
      SrvResourceRecord(
        'raspberrypi._udisks-ssh._tcp.local',
        result[2].validUntil,
        target: 'raspberrypi.local',
        port: 22,
        priority: 0,
        weight: 0,
      ),
      TxtResourceRecord(
        'raspberrypi._udisks-ssh._tcp.local',
        result[3].validUntil,
        text: '\x00',
      ),
      PtrResourceRecord('_services._dns-sd._udp.local', result[4].validUntil,
          domainName: '_udisks-ssh._tcp.local'),
      PtrResourceRecord(
        '_workstation._tcp.local',
        result[5].validUntil,
        domainName: 'raspberrypi [b8:27:eb:03:92:4b]._workstation._tcp.local',
      ),
      SrvResourceRecord(
        'raspberrypi [b8:27:eb:03:92:4b]._workstation._tcp.local',
        result[6].validUntil,
        target: 'raspberrypi.local',
        port: 9,
        priority: 0,
        weight: 0,
      ),
      PtrResourceRecord(
        '_services._dns-sd._udp.local',
        result[7].validUntil,
        domainName: '_workstation._tcp.local',
      ),
    ]);

    result = decodeMDnsResponse(packagePtrResponse);
    expect(6, result.length);
    expect(result, <ResourceRecord>[
      PtrResourceRecord(
        '_fletch_agent._tcp.local',
        result[0].validUntil,
        domainName: 'fletch-agent on raspberrypi._fletch_agent._tcp.local',
      ),
      TxtResourceRecord(
        'fletch-agent on raspberrypi._fletch_agent._tcp.local',
        result[1].validUntil,
        text: '\x00',
      ),
      SrvResourceRecord(
        'fletch-agent on raspberrypi._fletch_agent._tcp.local',
        result[2].validUntil,
        target: 'raspberrypi.local',
        port: 12121,
        priority: 0,
        weight: 0,
      ),
      IPAddressResourceRecord(
        'raspberrypi.local',
        result[3].validUntil,
        address: InternetAddress('fe80:0000:0000:0000:ba27:ebff:fe69:6e3a'),
      ),
      IPAddressResourceRecord(
        'raspberrypi.local',
        result[4].validUntil,
        address: InternetAddress('192.168.1.1'),
      ),
      IPAddressResourceRecord(
        'raspberrypi.local',
        result[5].validUntil,
        address: InternetAddress('169.254.167.172'),
      ),
    ]);
  });
}

void testBadPackages() {
  test('Returns null for invalid packets', () {
    for (List<int> p in <List<int>>[package1, package2, package3]) {
      for (int i = 0; i < p.length; i++) {
        expect(decodeMDnsResponse(p.sublist(0, i)), isNull);
      }
    }
  });
}

void testPTRRData() {
  test('Can read FQDN from PTR data', () {
    expect('sgjesse-macbookpro2 [78:31:c1:b8:55:38]._workstation._tcp.local',
        readFQDN(ptrRData));
    expect('fletch-agent._fletch_agent._tcp.local', readFQDN(ptrRData2));
  });
}

void testSRVRData() {
  test('Can read FQDN from SRV data', () {
    expect('fletch.local', readFQDN(srvRData, _kSrvHeaderSize));
  });
}

// One address.
const List<int> package1 = <int>[
  0x00,
  0x00,
  0x84,
  0x00,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x00,
  0x0b,
  0x72,
  0x61,
  0x73,
  0x70,
  0x62,
  0x65,
  0x72,
  0x72,
  0x79,
  0x70,
  0x69,
  0x05,
  0x6c,
  0x6f,
  0x63,
  0x61,
  0x6c,
  0x00,
  0x00,
  0x01,
  0x80,
  0x01,
  0x00,
  0x00,
  0x00,
  0x78,
  0x00,
  0x04,
  0xc0,
  0xa8,
  0x01,
  0xbf
];

// Two addresses.
const List<int> package2 = <int>[
  0x00,
  0x00,
  0x84,
  0x00,
  0x00,
  0x00,
  0x00,
  0x02,
  0x00,
  0x00,
  0x00,
  0x00,
  0x0b,
  0x72,
  0x61,
  0x73,
  0x70,
  0x62,
  0x65,
  0x72,
  0x72,
  0x79,
  0x70,
  0x69,
  0x05,
  0x6c,
  0x6f,
  0x63,
  0x61,
  0x6c,
  0x00,
  0x00,
  0x01,
  0x80,
  0x01,
  0x00,
  0x00,
  0x00,
  0x78,
  0x00,
  0x04,
  0xc0,
  0xa8,
  0x01,
  0xbf,
  0xc0,
  0x0c,
  0x00,
  0x01,
  0x80,
  0x01,
  0x00,
  0x00,
  0x00,
  0x78,
  0x00,
  0x04,
  0xa9,
  0xfe,
  0x5f,
  0x53
];

// Eight mixed answers.
const List<int> package3 = <int>[
  0x00,
  0x00,
  0x84,
  0x00,
  0x00,
  0x00,
  0x00,
  0x08,
  0x00,
  0x00,
  0x00,
  0x00,
  0x1f,
  0x72,
  0x61,
  0x73,
  0x70,
  0x62,
  0x65,
  0x72,
  0x72,
  0x79,
  0x70,
  0x69,
  0x20,
  0x5b,
  0x62,
  0x38,
  0x3a,
  0x32,
  0x37,
  0x3a,
  0x65,
  0x62,
  0x3a,
  0x30,
  0x33,
  0x3a,
  0x39,
  0x32,
  0x3a,
  0x34,
  0x62,
  0x5d,
  0x0c,
  0x5f,
  0x77,
  0x6f,
  0x72,
  0x6b,
  0x73,
  0x74,
  0x61,
  0x74,
  0x69,
  0x6f,
  0x6e,
  0x04,
  0x5f,
  0x74,
  0x63,
  0x70,
  0x05,
  0x6c,
  0x6f,
  0x63,
  0x61,
  0x6c,
  0x00,
  0x00,
  0x10,
  0x80,
  0x01,
  0x00,
  0x00,
  0x11,
  0x94,
  0x00,
  0x01,
  0x00,
  0x0b,
  0x5f,
  0x75,
  0x64,
  0x69,
  0x73,
  0x6b,
  0x73,
  0x2d,
  0x73,
  0x73,
  0x68,
  0xc0,
  0x39,
  0x00,
  0x0c,
  0x00,
  0x01,
  0x00,
  0x00,
  0x11,
  0x94,
  0x00,
  0x0e,
  0x0b,
  0x72,
  0x61,
  0x73,
  0x70,
  0x62,
  0x65,
  0x72,
  0x72,
  0x79,
  0x70,
  0x69,
  0xc0,
  0x50,
  0xc0,
  0x68,
  0x00,
  0x21,
  0x80,
  0x01,
  0x00,
  0x00,
  0x00,
  0x78,
  0x00,
  0x14,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x16,
  0x0b,
  0x72,
  0x61,
  0x73,
  0x70,
  0x62,
  0x65,
  0x72,
  0x72,
  0x79,
  0x70,
  0x69,
  0xc0,
  0x3e,
  0xc0,
  0x68,
  0x00,
  0x10,
  0x80,
  0x01,
  0x00,
  0x00,
  0x11,
  0x94,
  0x00,
  0x01,
  0x00,
  0x09,
  0x5f,
  0x73,
  0x65,
  0x72,
  0x76,
  0x69,
  0x63,
  0x65,
  0x73,
  0x07,
  0x5f,
  0x64,
  0x6e,
  0x73,
  0x2d,
  0x73,
  0x64,
  0x04,
  0x5f,
  0x75,
  0x64,
  0x70,
  0xc0,
  0x3e,
  0x00,
  0x0c,
  0x00,
  0x01,
  0x00,
  0x00,
  0x11,
  0x94,
  0x00,
  0x02,
  0xc0,
  0x50,
  0xc0,
  0x2c,
  0x00,
  0x0c,
  0x00,
  0x01,
  0x00,
  0x00,
  0x11,
  0x94,
  0x00,
  0x02,
  0xc0,
  0x0c,
  0xc0,
  0x0c,
  0x00,
  0x21,
  0x80,
  0x01,
  0x00,
  0x00,
  0x00,
  0x78,
  0x00,
  0x08,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x09,
  0xc0,
  0x88,
  0xc0,
  0xa3,
  0x00,
  0x0c,
  0x00,
  0x01,
  0x00,
  0x00,
  0x11,
  0x94,
  0x00,
  0x02,
  0xc0,
  0x2c
];

const List<int> packagePtrResponse = <int>[
  0x00,
  0x00,
  0x84,
  0x00,
  0x00,
  0x00,
  0x00,
  0x06,
  0x00,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x5f,
  0x66,
  0x6c,
  0x65,
  0x74,
  0x63,
  0x68,
  0x5f,
  0x61,
  0x67,
  0x65,
  0x6e,
  0x74,
  0x04,
  0x5f,
  0x74,
  0x63,
  0x70,
  0x05,
  0x6c,
  0x6f,
  0x63,
  0x61,
  0x6c,
  0x00,
  0x00,
  0x0c,
  0x00,
  0x01,
  0x00,
  0x00,
  0x11,
  0x94,
  0x00,
  0x1e,
  0x1b,
  0x66,
  0x6c,
  0x65,
  0x74,
  0x63,
  0x68,
  0x2d,
  0x61,
  0x67,
  0x65,
  0x6e,
  0x74,
  0x20,
  0x6f,
  0x6e,
  0x20,
  0x72,
  0x61,
  0x73,
  0x70,
  0x62,
  0x65,
  0x72,
  0x72,
  0x79,
  0x70,
  0x69,
  0xc0,
  0x0c,
  0xc0,
  0x30,
  0x00,
  0x10,
  0x80,
  0x01,
  0x00,
  0x00,
  0x11,
  0x94,
  0x00,
  0x01,
  0x00,
  0xc0,
  0x30,
  0x00,
  0x21,
  0x80,
  0x01,
  0x00,
  0x00,
  0x00,
  0x78,
  0x00,
  0x14,
  0x00,
  0x00,
  0x00,
  0x00,
  0x2f,
  0x59,
  0x0b,
  0x72,
  0x61,
  0x73,
  0x70,
  0x62,
  0x65,
  0x72,
  0x72,
  0x79,
  0x70,
  0x69,
  0xc0,
  0x1f,
  0xc0,
  0x6d,
  0x00,
  0x1c,
  0x80,
  0x01,
  0x00,
  0x00,
  0x00,
  0x78,
  0x00,
  0x10,
  0xfe,
  0x80,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0xba,
  0x27,
  0xeb,
  0xff,
  0xfe,
  0x69,
  0x6e,
  0x3a,
  0xc0,
  0x6d,
  0x00,
  0x01,
  0x80,
  0x01,
  0x00,
  0x00,
  0x00,
  0x78,
  0x00,
  0x04,
  0xc0,
  0xa8,
  0x01,
  0x01,
  0xc0,
  0x6d,
  0x00,
  0x01,
  0x80,
  0x01,
  0x00,
  0x00,
  0x00,
  0x78,
  0x00,
  0x04,
  0xa9,
  0xfe,
  0xa7,
  0xac
];

const List<int> ptrRData = <int>[
  0x27,
  0x73,
  0x67,
  0x6a,
  0x65,
  0x73,
  0x73,
  0x65,
  0x2d,
  0x6d,
  0x61,
  0x63,
  0x62,
  0x6f,
  0x6f,
  0x6b,
  0x70,
  0x72,
  0x6f,
  0x32,
  0x20,
  0x5b,
  0x37,
  0x38,
  0x3a,
  0x33,
  0x31,
  0x3a,
  0x63,
  0x31,
  0x3a,
  0x62,
  0x38,
  0x3a,
  0x35,
  0x35,
  0x3a,
  0x33,
  0x38,
  0x5d,
  0x0c,
  0x5f,
  0x77,
  0x6f,
  0x72,
  0x6b,
  0x73,
  0x74,
  0x61,
  0x74,
  0x69,
  0x6f,
  0x6e,
  0x04,
  0x5f,
  0x74,
  0x63,
  0x70,
  0x05,
  0x6c,
  0x6f,
  0x63,
  0x61,
  0x6c,
  0x00
];

const List<int> ptrRData2 = <int>[
  0x0c,
  0x66,
  0x6c,
  0x65,
  0x74,
  0x63,
  0x68,
  0x2d,
  0x61,
  0x67,
  0x65,
  0x6e,
  0x74,
  0x0d,
  0x5f,
  0x66,
  0x6c,
  0x65,
  0x74,
  0x63,
  0x68,
  0x5f,
  0x61,
  0x67,
  0x65,
  0x6e,
  0x74,
  0x04,
  0x5f,
  0x74,
  0x63,
  0x70,
  0x05,
  0x6c,
  0x6f,
  0x63,
  0x61,
  0x6c,
  0x00
];

const List<int> srvRData = <int>[
  0x00,
  0x00,
  0x00,
  0x00,
  0x2f,
  0x59,
  0x06,
  0x66,
  0x6c,
  0x65,
  0x74,
  0x63,
  0x68,
  0x05,
  0x6c,
  0x6f,
  0x63,
  0x61,
  0x6c,
  0x00
];

// Support code to generate the hex-lists above from
// a hex-stream.
void formatHexStream(String hexStream) {
  String s = '';
  for (int i = 0; i < hexStream.length / 2; i++) {
    if (s.isNotEmpty) {
      s += ', ';
    }
    s += '0x';
    final String x = hexStream.substring(i * 2, i * 2 + 2);
    s += x;
    if (((i + 1) % 8) == 0) {
      s += ',';
      print(s);
      s = '';
    }
  }
  if (s.isNotEmpty) {
    print(s);
  }
}

// Support code for generating the hex-lists above.
void hexDumpList(List<int> package) {
  String s = '';
  for (int i = 0; i < package.length; i++) {
    if (s.isNotEmpty) {
      s += ', ';
    }
    s += '0x';
    final String x = package[i].toRadixString(16);
    if (x.length == 1) {
      s += '0';
    }
    s += x;
    if (((i + 1) % 8) == 0) {
      s += ',';
      print(s);
      s = '';
    }
  }
  if (s.isNotEmpty) {
    print(s);
  }
}

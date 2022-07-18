import { Construct } from 'constructs';
import {
  ResourceGroup,
  Subnet,
  VirtualMachine,
  NetworkInterface,
  NetworkSecurityGroup,
  NetworkInterfaceSecurityGroupAssociation
} from '@cdktf/provider-azurerm';

import { createPublicIp } from '../public-ip';

import { custom_data } from '../../config/env';

interface fCCVirtualMachineConfig {
  stackName: string;
  vmName: string;
  rg: ResourceGroup;
  subnet: Subnet;
  env: string;
  size?: string | undefined;
  privateIP?: string | undefined;
  sshPublicKeys?: Array<string> | undefined;
  customImageId?: string | undefined;
}

export const createVirtualMachine = (
  stack: Construct,
  config: fCCVirtualMachineConfig,
  allocatePublicIP = true
) => {
  const {
    stackName,
    vmName,
    rg,
    subnet,
    env,
    size: size = 'Standard_B2s',
    privateIP: privateIP = undefined,
    sshPublicKeys: sshPublicKeys = [],
    customImageId: customImageId = undefined
  } = config;

  const nsgIdentifier = `${env}-nsg-${vmName}`;
  const nsg = new NetworkSecurityGroup(stack, nsgIdentifier, {
    name: nsgIdentifier,
    resourceGroupName: rg.name,
    location: rg.location,
    securityRule: [
      {
        name: 'allow-ssh',
        priority: 100,
        direction: 'Inbound',
        access: 'Allow',
        protocol: 'Tcp',
        sourcePortRange: '*',
        destinationPortRange: '22',
        sourceAddressPrefix: '*',
        destinationAddressPrefix: '*'
      }
    ]
  });

  const niIdentifier = `${env}-ni-${vmName}`;
  const ni = new NetworkInterface(stack, niIdentifier, {
    name: niIdentifier,
    resourceGroupName: rg.name,
    location: rg.location,
    ipConfiguration: [
      {
        name: `ipconfig-${vmName}`,
        primary: true,
        subnetId: subnet.id,
        privateIpAddressAllocation: privateIP ? 'Static' : 'Dynamic',
        privateIpAddress: privateIP,
        publicIpAddressId: allocatePublicIP
          ? createPublicIp(stack, `${stackName}-${vmName}`, rg, env).id
          : ''
      }
    ]
  });

  // Attach the security group to the network interface
  new NetworkInterfaceSecurityGroupAssociation(stack, `${env}-nsga-${vmName}`, {
    networkInterfaceId: ni.id,
    networkSecurityGroupId: nsg.id
  });

  const vmIdentifier = `${env}-vm-${vmName}`;
  const adminUsername = 'freecodecamp';
  new VirtualMachine(stack, vmIdentifier, {
    name: vmIdentifier,
    // computerName: String(vmIdentifier).replaceAll('-', ''),
    resourceGroupName: rg.name,
    location: rg.location,
    vmSize: size,
    osProfile: {
      computerName: vmName,
      adminUsername: adminUsername,
      // https://github.com/freeCodeCamp/infra/blob/master/cloud-init/basic.yaml
      customData: custom_data
    },
    osProfileLinuxConfig: {
      disablePasswordAuthentication: true,
      sshKeys: sshPublicKeys.map(key => {
        return {
          keyData: key,
          path: `/home/${adminUsername}/.ssh/authorized_keys`
        };
      })
    },
    networkInterfaceIds: [ni.id],
    storageOsDisk: {
      name: `${env}-osdisk-${vmName}`,
      createOption: 'FromImage',
      caching: 'ReadWrite',
      diskSizeGb: 30,
      osType: 'Linux'
    },
    storageImageReference: customImageId
      ? { id: customImageId }
      : {
          publisher: 'Canonical',
          offer: 'UbuntuServer',
          sku: '18.04-LTS',
          version: 'latest'
        }
  });
};

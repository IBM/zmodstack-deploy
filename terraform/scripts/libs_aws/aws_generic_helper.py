import boto3
import boto3.session

from botocore.exceptions import ClientError

import hcl
import logging


class AWSGenericHelper():
    '''
    Object used to:
    - create a session object
    - further generic AWS methods to be used by other modules
    '''

    # OpenShift required resources
    # instances are handeled separately
    ocp = {
        'ocs': {
                'single_zone': {
                                    'vpcs': 1,
                                    'network-interfaces': 19,
                                    'nat-gateways': 1,
                                    'security-groups': 8,
                                    'elastic-ips': 1,
                                    'application-load-ballancer': 2,
                                    'classic-load-ballancer': 3,
                                    's3-buckets': 1
                                },
                'multi_zone':  {
                                    'vpcs': 1,
                                    'network-interfaces': 28,
                                    'nat-gateways': 3,
                                    'security-groups': 8,
                                    'elastic-ips': 3,
                                    'application-load-ballancer': 2,
                                    'classic-load-ballancer': 3,
                                    's3-buckets': 1
                                }
                },
        'portworx': {
                'single_zone': {
                                    'vpcs': 1,
                                    'network-interfaces': 13,
                                    'nat-gateways': 1,
                                    'security-groups': 6,
                                    'elastic-ips': 1,
                                    'application-load-ballancer': 2,
                                    'classic-load-ballancer': 1,
                                    's3-buckets': 1
                                },
                'multi_zone':  {
                                    'vpcs': 1,
                                    'network-interfaces': 20,
                                    'nat-gateways': 3,
                                    'security-groups': 6,
                                    'elastic-ips': 3,
                                    'application-load-ballancer': 2,
                                    'classic-load-ballancer': 1,
                                    's3-buckets': 1
                                }
                }
    }

    # IBM Z & Cloud Modernization Stack services required vCPUs according to:
    # TODO
    zmodstack_services_vcpu = {
        'wazi_analyze': 1,
        'wazi_dev_spaces': 1,
        'wazi_sandbox': 1,
        'zos_cloud_broker': 1,
        'zos_connect': 1,
    }

    def __init__(self, aws_config):
        self._aws_config = aws_config

    # Create an AWS session
    def create_session(self):

        try:
            aws_session = boto3.session.Session(
                aws_access_key_id = self._aws_config['access_key'],
                aws_secret_access_key = self._aws_config['secret_access_key'],
                region_name = self._aws_config['region']
            )
            return aws_session
        except ClientError as e:
            # logging.error(e)
            print("  * The AWS session could not be created.")
            print('  * Please, try again.')
            exit(1)

    # parse terraform config
    @staticmethod
    def get_terraform_config_json(terraform_var_file):

        try:
            with open(terraform_var_file, 'r') as f:
                tf_config_json = hcl.load(f)
            return tf_config_json
        except IOError as e:
            # print(e)
            print("ERROR: The terraform variables file " +
                  f"'{terraform_var_file}' was not found.")
            exit(1)

    @staticmethod
    def get_opc_required_resources(storage_type, deploy_type):
        opc_required_resources = {}

        try:
            opc_required_resources = AWSGenericHelper.ocp[storage_type]
        except KeyError as e:
            print(f"ERROR: The storage type '{storage_type}' is not supported.")
            print("Verify you have specified a supported " +
                  "storage type in 'variables.tf'.")
            exit(1)

        try:
            opc_required_resources = opc_required_resources[deploy_type]
        except KeyError as e:
            print(f"ERROR: The deploy type '{deploy_type}' is not supported.")
            print("Verify you have specified a supported " +
                  "deploy type in 'variables.tf'.")
            exit(1)

        return opc_required_resources

    @staticmethod
    def get_services_vcpus(tf_var_file):

        services_vcpu = 0

        tf_config_json = AWSGenericHelper.get_terraform_config_json(tf_var_file)

        svc_vcpu = AWSGenericHelper.zmodstack_services_vcpu
        for service in svc_vcpu:
            if tf_config_json['variable'][service]['default'] == 'yes':
                services_vcpu += svc_vcpu[service]

        return services_vcpu

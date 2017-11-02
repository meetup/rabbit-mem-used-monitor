
import sys, os
# make dependencies available
sys.path.insert(0, './.vendor')
import requests
import boto3


cw = boto3.client('cloudwatch', region_name='us-east-1')

def get_rabbit_mem_used_bytes(node_endpoint='http://queue.int.meetup.com:15672/api/nodes/rabbit@rabbit?memory=true'):
    """
    returns memory used by rabbit in bytes
    """

    rabbit_username = os.environ['RABBIT_USERNAME']
    rabbit_password = os.environ['RABBIT_PASSWORD']
    response = requests.get(node_endpoint, auth=(rabbit_username, rabbit_password))
    return response.json()['mem_used']


def main(event, context):
    """
    main method
    """

    # let's do a quick conversion to GBs, 1 GB is 2^30 Bytes
    mem_used_gb = get_rabbit_mem_used_bytes()/pow(2, 30)
    try:
        response = cw.put_metric_data(
            Namespace='Rabbit/MemUsedGigabytes',
            MetricData=[
                {
                    'MetricName': 'rabbit_mem_used_gb',
                    'Value': float(mem_used_gb),
                    'Unit': 'Gigabytes'
                },
            ]
        )
    except Exception as e:
        print "CloudWatch Put_Metric_Data Failed - Reason:\n", str(e)


if __name__=='__main__':
    main(event, context)

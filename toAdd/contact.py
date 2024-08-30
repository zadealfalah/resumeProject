import json
import boto3
import os

def lambda_handler(event, context):
    try:
        # Parse data from contact event
        form_data = json.loads(event['body'])
        name = form_data.get('name')
        email = form_data.get('email')
        message = form_data.get('message')

        # Send an email using SES
        client = boto3.client('ses')
        response = client.send_email(
            Source="toreply@zadealfalah.com",
            Destination={
                'ToAddresses': [os.environ['RECIPIENT_EMAIL']],
            },
            Message={
                'Subject': {
                    'Data': 'Contact Form Submission',
                },
                'Body': {
                    'Text': {
                        'Data': f'Name: {name}\nEmail: {email}\nMessage: {message}',
                    }
                }
            }
        )

        # Requires headers for API gateway to function I think
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': 'https://zadealfalah.com',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
            'body': json.dumps('Form submitted successfully!'),
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Failed to submit the form: {e}' ),
        }